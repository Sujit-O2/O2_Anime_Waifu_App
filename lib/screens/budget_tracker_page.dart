import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/waifu_background.dart';

class BudgetTrackerPage extends StatefulWidget {
  const BudgetTrackerPage({super.key});
  @override
  State<BudgetTrackerPage> createState() => _BudgetTrackerPageState();
}

class _BudgetTrackerPageState extends State<BudgetTrackerPage>
    with SingleTickerProviderStateMixin {
  final _amountCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  List<Map<String, dynamic>> _transactions = [];
  double _budget = 5000;
  bool _isExpense = true;
  int _selectedCat = 0;
  late AnimationController _fadeCtrl;

  static const _expCats = [
    '🍔 Food',
    '🚕 Transport',
    '🛍️ Shopping',
    '🎮 Games',
    '💊 Health',
    '📚 Education',
    '💡 Bills',
    '❤️ Waifu Fund'
  ];
  static const _incCats = [
    '💼 Salary',
    '🎁 Gift',
    '💰 Bonus',
    '📈 Investment',
    '🛒 Freelance'
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _amountCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  List<String> get _cats => _isExpense ? _expCats : _incCats;

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('budget_transactions') ?? '[]';
    final b = p.getDouble('budget_limit') ?? 5000;
    try {
      _transactions = (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {}
    setState(() => _budget = b);
    _fadeCtrl.forward();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('budget_transactions', jsonEncode(_transactions));
    await p.setDouble('budget_limit', _budget);
  }

  void _addTransaction() {
    final amt = double.tryParse(_amountCtrl.text.trim());
    if (amt == null || amt <= 0) return;
    HapticFeedback.mediumImpact();
    final label = _labelCtrl.text.trim().isEmpty
        ? _cats[_selectedCat]
        : _labelCtrl.text.trim();
    setState(() {
      _transactions.insert(0, {
        'label': label,
        'amount': _isExpense ? -amt : amt,
        'cat': _cats[_selectedCat],
        'time': DateTime.now().millisecondsSinceEpoch,
        'isExpense': _isExpense,
      });
    });
    _amountCtrl.clear();
    _labelCtrl.clear();
    _save();
  }

  void _delete(int idx) {
    setState(() => _transactions.removeAt(idx));
    _save();
  }

  double get _totalIncome => _transactions
      .where((t) => !(t['isExpense'] as bool))
      .fold(0, (s, t) => s + (t['amount'] as num).toDouble());
  double get _totalExpense => _transactions
      .where((t) => t['isExpense'] as bool)
      .fold(0, (s, t) => s + (t['amount'] as num).abs().toDouble());
  double get _balance => _totalIncome - _totalExpense;
  double get _spendPct =>
      _budget > 0 ? (_totalExpense / _budget).clamp(0, 1) : 0;

  String _timeAgo(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      resizeToAvoidBottomInset: true,
      body: WaifuBackground(
        opacity: 0.09,
        tint: const Color(0xFF080A10),
        child: SafeArea(
            child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12)),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white60, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('BUDGET TRACKER',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5)),
                    Text('Balance: ₹${_balance.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                            color: _balance >= 0
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ])),
            ]),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              _statCard('Income', _totalIncome, Colors.greenAccent),
              const SizedBox(width: 10),
              _statCard('Spent', _totalExpense, Colors.redAccent),
              const SizedBox(width: 10),
              _statCard('Balance', _balance.abs(),
                  _balance >= 0 ? Colors.cyanAccent : Colors.orangeAccent),
            ]),
          ),

          // Budget progress
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Budget: ₹${_budget.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                        color: Colors.white38, fontSize: 10)),
                Text('${(_spendPct * 100).round()}% used',
                    style: GoogleFonts.outfit(
                        color:
                            _spendPct > 0.8 ? Colors.redAccent : Colors.white38,
                        fontSize: 10)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _spendPct,
                  backgroundColor: Colors.white.withOpacity(0.07),
                  valueColor: AlwaysStoppedAnimation(
                      _spendPct > 0.8 ? Colors.redAccent : Colors.tealAccent),
                  minHeight: 5,
                ),
              ),
            ]),
          ),

          // Add transaction
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(children: [
              // Income / Expense toggle
              Row(children: [
                Expanded(
                    child: GestureDetector(
                  onTap: () => setState(() {
                    _isExpense = true;
                    _selectedCat = 0;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: _isExpense
                          ? Colors.redAccent.withOpacity(0.15)
                          : Colors.white.withOpacity(0.04),
                      border: Border.all(
                          color:
                              _isExpense ? Colors.redAccent : Colors.white12),
                    ),
                    child: Center(
                        child: Text('− Expense',
                            style: GoogleFonts.outfit(
                                color: _isExpense
                                    ? Colors.redAccent
                                    : Colors.white38,
                                fontSize: 13,
                                fontWeight: FontWeight.w700))),
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: GestureDetector(
                  onTap: () => setState(() {
                    _isExpense = false;
                    _selectedCat = 0;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: !_isExpense
                          ? Colors.greenAccent.withOpacity(0.15)
                          : Colors.white.withOpacity(0.04),
                      border: Border.all(
                          color: !_isExpense
                              ? Colors.greenAccent
                              : Colors.white12),
                    ),
                    child: Center(
                        child: Text('+ Income',
                            style: GoogleFonts.outfit(
                                color: !_isExpense
                                    ? Colors.greenAccent
                                    : Colors.white38,
                                fontSize: 13,
                                fontWeight: FontWeight.w700))),
                  ),
                )),
              ]),
              const SizedBox(height: 8),
              // Category row
              SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _cats.length,
                  itemBuilder: (ctx, i) => GestureDetector(
                    onTap: () => setState(() => _selectedCat = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: _selectedCat == i
                            ? Colors.tealAccent.withOpacity(0.15)
                            : Colors.white.withOpacity(0.04),
                        border: Border.all(
                            color: _selectedCat == i
                                ? Colors.tealAccent
                                : Colors.white12),
                      ),
                      child: Text(_cats[i],
                          style: GoogleFonts.outfit(
                              color: _selectedCat == i
                                  ? Colors.tealAccent
                                  : Colors.white38,
                              fontSize: 11)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                  cursorColor: Colors.tealAccent,
                  decoration: InputDecoration(
                    hintText: 'Amount ₹',
                    hintStyle:
                        GoogleFonts.outfit(color: Colors.white30, fontSize: 13),
                    prefixText: '₹ ',
                    prefixStyle: GoogleFonts.outfit(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.04),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.tealAccent.withOpacity(0.2))),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                  controller: _labelCtrl,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                  cursorColor: Colors.tealAccent,
                  decoration: InputDecoration(
                    hintText: 'Label (optional)',
                    hintStyle:
                        GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.04),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                )),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addTransaction,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Colors.tealAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.tealAccent.withOpacity(0.4))),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.tealAccent, size: 22),
                  ),
                ),
              ]),
            ]),
          ),

          const Divider(color: Colors.white12, height: 16),

          // Transactions list
          Expanded(
            child: _transactions.isEmpty
                ? Center(
                    child: Text('No transactions yet~',
                        style: GoogleFonts.outfit(color: Colors.white38)))
                : FadeTransition(
                    opacity: _fadeCtrl,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _transactions.length,
                      itemBuilder: (ctx, i) {
                        final t = _transactions[i];
                        final isExp = t['isExpense'] as bool;
                        final amt = (t['amount'] as num).toDouble();
                        return Dismissible(
                          key: ValueKey(t['time']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.redAccent.withOpacity(0.15)),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent),
                          ),
                          onDismissed: (_) => _delete(i),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white.withOpacity(0.04),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.07)),
                            ),
                            child: Row(children: [
                              Text(t['cat'].toString().split(' ').first,
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(t['label'] as String,
                                        style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                    Text(_timeAgo(t['time'] as int),
                                        style: GoogleFonts.outfit(
                                            color: Colors.white24,
                                            fontSize: 10)),
                                  ])),
                              Text(
                                  '${isExp ? '-' : '+'}₹${amt.abs().toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(
                                      color: isExp
                                          ? Colors.redAccent
                                          : Colors.greenAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800)),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ])),
      ),
    );
  }

  Widget _statCard(String label, double value, Color color) => Expanded(
          child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.07),
            border: Border.all(color: color.withOpacity(0.25))),
        child: Column(children: [
          Text('₹${value.toStringAsFixed(0)}',
              style: GoogleFonts.outfit(
                  color: color, fontSize: 14, fontWeight: FontWeight.w800)),
          Text(label,
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9)),
        ]),
      ));
}
