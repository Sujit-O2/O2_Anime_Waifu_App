import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:anime_waifu/services/smart_features/expense_analyzer_service.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class ExpenseAnalyzerPage extends StatefulWidget {
  const ExpenseAnalyzerPage({super.key});

  @override
  State<ExpenseAnalyzerPage> createState() => _ExpenseAnalyzerPageState();
}

class _ExpenseAnalyzerPageState extends State<ExpenseAnalyzerPage>
    with SingleTickerProviderStateMixin {
  final _service = ExpenseAnalyzerService.instance;
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _merchantCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  List<ExpenseItem> _expenses = [];
  ExpenseSummary? _summary;
  bool _loading = false;
  String _selectedCategory = 'Other';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _searchQuery = '';
  List<ExpenseItem> _filteredExpenses = [];

  static const _bg = Color(0xFF0A0B14);
  static const _accent = Color(0xFFFF6B35);
  static const _surface = Color(0xFF151620);

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('expense_analyzer'));
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _loadData();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _merchantCtrl.dispose();
    _notesCtrl.dispose();
    _searchCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchCtrl.text.toLowerCase();
      _filterExpenses();
    });
  }

  void _filterExpenses() {
    if (_searchQuery.isEmpty) {
      _filteredExpenses = _expenses;
    } else {
      _filteredExpenses = _expenses
          .where((e) =>
              e.title.toLowerCase().contains(_searchQuery) ||
              e.merchant?.toLowerCase().contains(_searchQuery) == true ||
              e.category.toLowerCase().contains(_searchQuery))
          .toList();
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final expenses = await _service.getExpenses();
      final summary = await _service.getSummary(
          month: _selectedMonth, year: _selectedYear);
      if (mounted) {
        setState(() {
          _expenses = expenses;
          _summary = summary;
          _filteredExpenses = expenses;
          _loading = false;
        });
        _animCtrl.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scanReceipt() async {
    HapticFeedback.mediumImpact();
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() => _loading = true);
    try {
      // Simulate OCR extraction
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _amountCtrl.text = '45.99';
        _merchantCtrl.text = 'Sample Store';
        _titleCtrl.text = 'Scanned Receipt';
        setState(() => _loading = false);
        _showAddExpenseSheet();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddExpenseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20, right: 20, top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Add Expense',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildField(_titleCtrl, 'Title', Icons.title),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField(_amountCtrl, 'Amount', Icons.currency_rupee,
                        inputType: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(_merchantCtrl, 'Merchant', Icons.store),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildCategorySelector(),
              const SizedBox(height: 12),
              _buildField(_notesCtrl, 'Notes (Optional)', Icons.note, maxLines: 2),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Save Expense',
                      style: GoogleFonts.outfit(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveExpense() async {
    if (_titleCtrl.text.isEmpty || _amountCtrl.text.isEmpty) return;
    final expense = ExpenseItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      category: _selectedCategory,
      date: DateTime.now(),
      merchant: _merchantCtrl.text.isEmpty ? null : _merchantCtrl.text,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
    );
    await _service.addExpense(expense);
    _titleCtrl.clear();
    _amountCtrl.clear();
    _merchantCtrl.clear();
    _notesCtrl.clear();
    if (mounted) {
      Navigator.pop(context);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense added!', style: GoogleFonts.outfit()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType inputType = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      maxLines: maxLines,
      style: GoogleFonts.outfit(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: _accent, size: 20),
        filled: true,
        fillColor: _bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: ExpenseAnalyzerService.categories.map((cat) {
            final selected = cat == _selectedCategory;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _accent : _bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? _accent : Colors.grey[700]!),
                ),
                child: Text(
                  '${_service.getCategoryIcon(cat)} $cat',
                  style: GoogleFonts.outfit(
                    color: selected ? Colors.white : Colors.grey[400],
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text('Expense Analyzer', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: _bg,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: _accent),
            onPressed: _pickMonth,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseSheet,
        backgroundColor: _accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add', style: GoogleFonts.outfit(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildSummaryCard(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchCtrl,
                      style: GoogleFonts.outfit(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search expenses...',
                        hintStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: _surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: _buildExpensesList()),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    if (_summary == null) return const SizedBox();
    final s = _summary!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8F5E)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.3),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${s.period} Spend',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
              GestureDetector(
                onTap: _scanReceipt,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text('Scan', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('₹${s.total.toStringAsFixed(2)}',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (s.byCategory.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: s.byCategory.entries.map((e) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_service.getCategoryIcon(e.key)} ₹${e.value.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpensesList() {
    final list = _searchQuery.isNotEmpty ? _filteredExpenses : _expenses;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text('No expenses yet', style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final e = list[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(_service.getCategoryIcon(e.category),
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title,
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                        '${e.merchant ?? e.category} • ${e.date.day}/${e.date.month}',
                        style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Text('₹${e.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                      color: _accent, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: _accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = picked.month;
        _selectedYear = picked.year;
      });
      _loadData();
    }
  }
}
