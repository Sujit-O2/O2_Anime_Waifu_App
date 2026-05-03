import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ExpenseItem {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? merchant;
  final String? notes;

  ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.merchant,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'merchant': merchant,
        'notes': notes,
      };

  factory ExpenseItem.fromJson(Map<String, dynamic> json) => ExpenseItem(
        id: json['id'],
        title: json['title'],
        amount: json['amount'].toDouble(),
        category: json['category'],
        date: DateTime.parse(json['date']),
        merchant: json['merchant'],
        notes: json['notes'],
      );
}

class ExpenseSummary {
  final double total;
  final Map<String, double> byCategory;
  final List<ExpenseItem> recent;
  final String period;

  ExpenseSummary({
    required this.total,
    required this.byCategory,
    required this.recent,
    required this.period,
  });
}

class ExpenseAnalyzerService {
  static final instance = ExpenseAnalyzerService._();
  ExpenseAnalyzerService._();

  static const _storageKey = 'expenses_data';
  static const _categories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Bills & Utilities',
    'Entertainment',
    'Health',
    'Education',
    'Travel',
    'Groceries',
    'Other',
  ];

  Future<List<ExpenseItem>> getExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map((e) => ExpenseItem.fromJson(e)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addExpense(ExpenseItem expense) async {
    final expenses = await getExpenses();
    expenses.add(expense);
    await _saveExpenses(expenses);
  }

  Future<void> deleteExpense(String id) async {
    final expenses = await getExpenses();
    expenses.removeWhere((e) => e.id == id);
    await _saveExpenses(expenses);
  }

  Future<void> _saveExpenses(List<ExpenseItem> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(expenses.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<ExpenseSummary> getSummary({int? month, int? year}) async {
    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;

    final expenses = await getExpenses();
    final filtered = expenses.where((e) =>
        e.date.month == targetMonth && e.date.year == targetYear).toList();

    final byCategory = <String, double>{};
    for (final e in filtered) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }

    return ExpenseSummary(
      total: filtered.fold(0, (sum, e) => sum + e.amount),
      byCategory: byCategory,
      recent: filtered.take(10).toList(),
      period: '$targetMonth/${targetYear.toString().substring(2)}',
    );
  }

  Future<Map<String, double>> getMonthlyTrend(int months) async {
    final expenses = await getExpenses();
    final result = <String, double>{};
    final now = DateTime.now();

    for (int i = 0; i < months; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthExpenses = expenses.where((e) =>
          e.date.month == date.month && e.date.year == date.year);
      final total = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
      result['${date.month}/${date.year}'] = total;
    }
    return result;
  }

  String getCategoryIcon(String category) {
    switch (category) {
      case 'Food & Dining':
        return '🍽️';
      case 'Transportation':
        return '🚗';
      case 'Shopping':
        return '🛍️';
      case 'Bills & Utilities':
        return '📄';
      case 'Entertainment':
        return '🎮';
      case 'Health':
        return '💊';
      case 'Education':
        return '📚';
      case 'Travel':
        return '✈️';
      case 'Groceries':
        return '🛒';
      default:
        return '📦';
    }
  }

  static List<String> get categories => _categories;
}
