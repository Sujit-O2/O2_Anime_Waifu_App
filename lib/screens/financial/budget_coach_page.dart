import 'package:anime_waifu/services/financial/budget_coach_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class BudgetCoachPage extends StatefulWidget {
  const BudgetCoachPage({super.key});

  @override
  State<BudgetCoachPage> createState() => _BudgetCoachPageState();
}

class _BudgetCoachPageState extends State<BudgetCoachPage>
    with SingleTickerProviderStateMixin {
  final _service = BudgetCoachService.instance;
  late TabController _tabs;
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _goalNameCtrl = TextEditingController();
  final _goalAmountCtrl = TextEditingController();
  String _category = 'Other';
  TransactionType _type = TransactionType.expense;
  bool _loading = true;
  bool _saving = false;

  static const _bg = Color(0xFF0A0B14);
  static const _green = Color(0xFF4CAF50);
  static const _red = Color(0xFFEF5350);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _goalNameCtrl.dispose();
    _goalAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) {
      final cats = _service.getCategories();
      setState(() {
        _category = cats.isEmpty ? 'Other' : cats.first.name;
        _loading = false;
      });
    }
  }

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    await _service.addTransaction(
      description: _descCtrl.text.trim().isEmpty
          ? (_type == TransactionType.income ? 'Income' : 'Expense')
          : _descCtrl.text.trim(),
      amount: amount,
      category: _category,
      date: DateTime.now(),
      type: _type,
    );
    _amountCtrl.clear();
    _descCtrl.clear();
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _createGoal() async {
    final amount = double.tryParse(_goalAmountCtrl.text.trim()) ?? 0;
    if (_goalNameCtrl.text.trim().isEmpty || amount <= 0) return;
    HapticFeedback.mediumImpact();
    await _service.createSavingsGoal(
      name: _goalNameCtrl.text.trim(),
      targetAmount: amount,
      targetDate: DateTime.now().add(const Duration(days: 180)),
      description: 'Created from Budget Coach',
    );
    _goalNameCtrl.clear();
    _goalAmountCtrl.clear();
    if (mounted) setState(() {});
  }

  DateTime get _monthStart =>
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime get _monthEnd =>
      DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white60, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('💰 Budget Coach',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _green,
          labelColor: _green,
          unselectedLabelColor: Colors.white38,
          labelStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Add'),
            Tab(text: 'Goals'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _green))
          : TabBarView(
              controller: _tabs,
              children: [
                _buildOverviewTab(),
                _buildAddTab(),
                _buildGoalsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final income =
        _service.getTotalIncome(startDate: _monthStart, endDate: _monthEnd);
    final expenses =
        _service.getTotalExpenses(startDate: _monthStart, endDate: _monthEnd);
    final savings = income - expenses;
    final savingsRate = income > 0 ? (savings / income * 100) : 0.0;
    final recent = _service.getRecentTransactions(limit: 8);
    final spending = _service.getSpendingByCategory(
        startDate: _monthStart, endDate: _monthEnd);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary row
        Row(children: [
          Expanded(
              child: _statCard('Income', '\$${income.toStringAsFixed(0)}',
                  Icons.trending_up_rounded, _green)),
          const SizedBox(width: 8),
          Expanded(
              child: _statCard('Expenses', '\$${expenses.toStringAsFixed(0)}',
                  Icons.trending_down_rounded, _red)),
          const SizedBox(width: 8),
          Expanded(
              child: _statCard(
                  'Saved',
                  '\$${savings.toStringAsFixed(0)}',
                  Icons.savings_rounded,
                  savings >= 0 ? Colors.cyanAccent : _red)),
        ]),
        const SizedBox(height: 12),

        // Savings rate bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _green.withValues(alpha: 0.25)),
          ),
          child: Column(children: [
            Row(children: [
              Text('Savings Rate',
                  style: GoogleFonts.outfit(
                      color: Colors.white70, fontSize: 12)),
              const Spacer(),
              Text('${savingsRate.toStringAsFixed(1)}%',
                  style: GoogleFonts.outfit(
                      color: _green,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (savingsRate / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(
                    savingsRate >= 20 ? _green : Colors.amberAccent),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text(_service.getFinancialHealthScore(),
                style: GoogleFonts.outfit(
                    color: Colors.white54, fontSize: 11)),
          ]),
        ),
        const SizedBox(height: 12),

        _infoCard(Icons.tips_and_updates_rounded, 'Savings Tips',
            _service.getSavingsRecommendations(), Colors.amberAccent),
        const SizedBox(height: 16),

        // Spending by category
        if (spending.isNotEmpty) ...[
          _sectionLabel('Spending by Category'),
          const SizedBox(height: 8),
          ...(() {
              final sorted = spending.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              return sorted.take(6).map((e) {
              final pct = expenses > 0 ? e.value / expenses : 0.0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: Column(children: [
                  Row(children: [
                    Text(e.key,
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 12)),
                    const Spacer(),
                    Text('\$${e.value.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                    const SizedBox(width: 6),
                    Text('${(pct * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.outfit(
                            color: Colors.white38, fontSize: 11)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation(
                          _red.withValues(alpha: 0.7)),
                      minHeight: 4,
                    ),
                  ),
                ]),
              );
            }).toList();
            })(),
        ],
        const SizedBox(height: 16),

        // Recent transactions
        if (recent.isNotEmpty) ...[
          _sectionLabel('Recent Transactions'),
          const SizedBox(height: 8),
          ...recent.map((tx) {
            final isIncome = tx.type == TransactionType.income;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (isIncome ? _green : _red)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isIncome
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: isIncome ? _green : _red,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(tx.description,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                    Text(tx.category,
                        style: GoogleFonts.outfit(
                            color: Colors.white38, fontSize: 10)),
                  ]),
                ),
                Text(
                  '${isIncome ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                      color: isIncome ? _green : _red,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ]),
            );
          }),
        ] else
          _emptyState('No transactions yet',
              'Add income and expenses to see insights'),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildAddTab() {
    final categories = _service.getCategories();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('Add Transaction',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(height: 14),

            // Type toggle
            Row(children: [
              Expanded(
                  child: _typeBtn('Expense', TransactionType.expense, _red)),
              const SizedBox(width: 8),
              Expanded(
                  child: _typeBtn('Income', TransactionType.income, _green)),
            ]),
            const SizedBox(height: 12),

            _field(_amountCtrl, 'Amount (\$)', Icons.attach_money_rounded,
                type: TextInputType.number),
            const SizedBox(height: 10),
            _field(_descCtrl, 'Description (optional)',
                Icons.description_rounded),
            const SizedBox(height: 10),

            // Category dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  dropdownColor: const Color(0xFF1A1B2E),
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontSize: 13),
                  icon: const Icon(Icons.expand_more_rounded,
                      color: Colors.white38),
                  isExpanded: true,
                  items: categories
                      .map((c) => DropdownMenuItem(
                            value: c.name,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveTransaction,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_saving ? 'Saving...' : 'Save Transaction',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _type == TransactionType.income ? _green : _red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildGoalsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('New Savings Goal',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(height: 12),
            _field(_goalNameCtrl, 'Goal Name', Icons.flag_rounded),
            const SizedBox(height: 10),
            _field(_goalAmountCtrl, 'Target Amount (\$)',
                Icons.savings_rounded,
                type: TextInputType.number),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createGoal,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('Create Goal',
                    style:
                        GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _typeBtn(String label, TransactionType t, Color color) {
    final sel = _type == t;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _type = t);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: sel ? color.withValues(alpha: 0.5) : Colors.white12,
              width: sel ? 1.5 : 1),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.outfit(
                  color: sel ? color : Colors.white54,
                  fontWeight:
                      sel ? FontWeight.w700 : FontWeight.normal,
                  fontSize: 13)),
        ),
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14)),
        Text(label,
            style: GoogleFonts.outfit(
                color: Colors.white54, fontSize: 10),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _infoCard(
      IconData icon, String title, String body, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.outfit(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        Text(body,
            style: GoogleFonts.outfit(
                color: Colors.white70, fontSize: 12, height: 1.5)),
      ]),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        const Text('💰', style: TextStyle(fontSize: 36)),
        const SizedBox(height: 12),
        Text(title,
            style: GoogleFonts.outfit(
                color: Colors.white70, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: GoogleFonts.outfit(
                color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: GoogleFonts.outfit(
            color: Colors.white54,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.8));
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
