import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 💰 Budget Coach Service
///
/// Analyze spending patterns, suggest savings strategies.
class BudgetCoachService {
  BudgetCoachService._();
  static final BudgetCoachService instance = BudgetCoachService._();

  final List<Budget> _budgets = [];
  final List<Transaction> _transactions = [];
  final List<Category> _categories = [];
  final List<SavingsGoal> _savingsGoals = [];

  int _totalTransactions = 0;
  double _totalSpent = 0;
  double _totalSaved = 0;

  static const String _storageKey = 'budget_coach_v1';
  static const int _maxTransactions = 1000;

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode)
      debugPrint(
          '[BudgetCoach] Initialized with $_totalTransactions transactions');

    // Initialize default categories if empty
    if (_categories.isEmpty) {
      _initializeDefaultCategories();
    }
  }

  void _initializeDefaultCategories() {
    final defaultCategories = [
      Category(name: 'Housing', budget: 0, color: '#FF6B6B'),
      Category(name: 'Food & Dining', budget: 0, color: '#4ECDC4'),
      Category(name: 'Transportation', budget: 0, color: '#45B7D1'),
      Category(name: 'Utilities', budget: 0, color: '#96CEB4'),
      Category(name: 'Entertainment', budget: 0, color: '#FFEAA7'),
      Category(name: 'Shopping', budget: 0, color: '#DDA0DD'),
      Category(name: 'Healthcare', budget: 0, color: '#98D8C8'),
      Category(name: 'Personal Care', budget: 0, color: '#F7DC6F'),
      Category(name: 'Education', budget: 0, color: '#BB8FCE'),
      Category(name: 'Savings', budget: 0, color: '#85C1E9'),
      Category(name: 'Debt Payment', budget: 0, color: '#F1948A'),
      Category(name: 'Other', budget: 0, color: '#D5D8DC'),
    ];

    _categories.addAll(defaultCategories);
  }

  Future<Budget> createBudget({
    required String name,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> categories,
  }) async {
    final budget = Budget(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      categories: categories,
      status: BudgetStatus.active,
      createdAt: DateTime.now(),
    );

    _budgets.insert(0, budget);

    await _saveData();

    if (kDebugMode) debugPrint('[BudgetCoach] Created budget: $name');
    return budget;
  }

  Future<Transaction> addTransaction({
    required String description,
    required double amount,
    required String category,
    required DateTime date,
    required TransactionType type,
    String? notes,
  }) async {
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: description,
      amount: amount,
      category: category,
      date: date,
      type: type,
      notes: notes,
      createdAt: DateTime.now(),
    );

    _transactions.insert(0, transaction);
    _totalTransactions++;

    if (type == TransactionType.expense) {
      _totalSpent += amount;
    } else {
      _totalSaved += amount;
    }

    await _saveData();

    if (kDebugMode)
      debugPrint(
          '[BudgetCoach] Added transaction: $description (\$${amount.toStringAsFixed(2)})');
    return transaction;
  }

  Future<SavingsGoal> createSavingsGoal({
    required String name,
    required double targetAmount,
    required DateTime targetDate,
    required String description,
  }) async {
    final goal = SavingsGoal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      targetAmount: targetAmount,
      currentAmount: 0,
      targetDate: targetDate,
      description: description,
      status: GoalStatus.inProgress,
      createdAt: DateTime.now(),
    );

    _savingsGoals.insert(0, goal);

    await _saveData();

    if (kDebugMode) debugPrint('[BudgetCoach] Created savings goal: $name');
    return goal;
  }

  Future<void> updateSavingsGoalProgress(String goalId, double amount) async {
    final goalIndex = _savingsGoals.indexWhere((g) => g.id == goalId);
    if (goalIndex == -1) return;

    final goal = _savingsGoals[goalIndex];
    final newAmount = goal.currentAmount + amount;

    _savingsGoals[goalIndex] = goal.copyWith(
      currentAmount: newAmount,
      status: newAmount >= goal.targetAmount
          ? GoalStatus.completed
          : GoalStatus.inProgress,
    );

    await _saveData();

    if (kDebugMode) debugPrint('[BudgetCoach] Updated savings goal: $goalId');
  }

  Future<void> addCategory(String name, double budget, String color) async {
    if (_categories.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
      return; // Category already exists
    }

    final category = Category(name: name, budget: budget, color: color);
    _categories.add(category);

    await _saveData();

    if (kDebugMode) debugPrint('[BudgetCoach] Added category: $name');
  }

  Future<void> updateCategoryBudget(String categoryName, double budget) async {
    final categoryIndex = _categories.indexWhere((c) => c.name == categoryName);
    if (categoryIndex == -1) return;

    _categories[categoryIndex] =
        _categories[categoryIndex].copyWith(budget: budget);

    await _saveData();

    if (kDebugMode)
      debugPrint(
          '[BudgetCoach] Updated budget for $categoryName: \$${budget.toStringAsFixed(2)}');
  }

  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _transactions
        .where((t) =>
            t.date.isAfter(start.subtract(const Duration(days: 1))) &&
            t.date.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  List<Transaction> getTransactionsByCategory(String category) {
    return _transactions.where((t) => t.category == category).toList();
  }

  List<Transaction> getRecentTransactions({int limit = 10}) {
    return _transactions.take(limit).toList();
  }

  double getCategorySpending(String category,
      {DateTime? startDate, DateTime? endDate}) {
    var filteredTransactions = _transactions.where(
        (t) => t.category == category && t.type == TransactionType.expense);

    if (startDate != null) {
      filteredTransactions =
          filteredTransactions.where((t) => t.date.isAfter(startDate));
    }

    if (endDate != null) {
      filteredTransactions =
          filteredTransactions.where((t) => t.date.isBefore(endDate));
    }

    return filteredTransactions.fold<double>(0, (sum, t) => sum + t.amount);
  }

  double getTotalIncome({DateTime? startDate, DateTime? endDate}) {
    var incomeTransactions =
        _transactions.where((t) => t.type == TransactionType.income);

    if (startDate != null) {
      incomeTransactions =
          incomeTransactions.where((t) => t.date.isAfter(startDate));
    }

    if (endDate != null) {
      incomeTransactions =
          incomeTransactions.where((t) => t.date.isBefore(endDate));
    }

    return incomeTransactions.fold<double>(0, (sum, t) => sum + t.amount);
  }

  double getTotalExpenses({DateTime? startDate, DateTime? endDate}) {
    var expenseTransactions =
        _transactions.where((t) => t.type == TransactionType.expense);

    if (startDate != null) {
      expenseTransactions =
          expenseTransactions.where((t) => t.date.isAfter(startDate));
    }

    if (endDate != null) {
      expenseTransactions =
          expenseTransactions.where((t) => t.date.isBefore(endDate));
    }

    return expenseTransactions.fold<double>(0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getSpendingByCategory(
      {DateTime? startDate, DateTime? endDate}) {
    final spending = <String, double>{};

    for (final category in _categories) {
      final amount = getCategorySpending(category.name,
          startDate: startDate, endDate: endDate);
      if (amount > 0) {
        spending[category.name] = amount;
      }
    }

    return spending;
  }

  String getBudgetAnalysis() {
    if (_transactions.isEmpty) {
      return 'No transactions recorded yet. Start tracking your expenses to get insights!';
    }

    final thisMonth = DateTime.now();
    final monthStart = DateTime(thisMonth.year, thisMonth.month, 1);
    final monthEnd = DateTime(thisMonth.year, thisMonth.month + 1, 0);

    final monthlyIncome =
        getTotalIncome(startDate: monthStart, endDate: monthEnd);
    final monthlyExpenses =
        getTotalExpenses(startDate: monthStart, endDate: monthEnd);
    final monthlySavings = monthlyIncome - monthlyExpenses;

    final spendingByCategory =
        getSpendingByCategory(startDate: monthStart, endDate: monthEnd);

    final buffer = StringBuffer();
    buffer.writeln('💰 Monthly Budget Analysis');
    buffer.writeln('');
    buffer.writeln('Income: \$${monthlyIncome.toStringAsFixed(2)}');
    buffer.writeln('Expenses: \$${monthlyExpenses.toStringAsFixed(2)}');
    buffer.writeln('Savings: \$${monthlySavings.toStringAsFixed(2)}');
    buffer.writeln('');

    if (monthlyIncome > 0) {
      final savingsRate =
          (monthlySavings / monthlyIncome * 100).toStringAsFixed(1);
      buffer.writeln('Savings Rate: $savingsRate%');
      buffer.writeln('');
    }

    if (spendingByCategory.isNotEmpty) {
      buffer.writeln('Spending by Category:');
      final sortedCategories = spendingByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final entry in sortedCategories) {
        final percentage = monthlyExpenses > 0
            ? (entry.value / monthlyExpenses * 100).toStringAsFixed(1)
            : '0';
        buffer.writeln(
            '• ${entry.key}: \$${entry.value.toStringAsFixed(2)} ($percentage%)');
      }
    }

    return buffer.toString();
  }

  String getSavingsRecommendations() {
    if (_transactions.isEmpty) {
      return 'Start tracking your income and expenses to get savings recommendations!';
    }

    final recommendations = <String>[];
    final thisMonth = DateTime.now();
    final monthStart = DateTime(thisMonth.year, thisMonth.month, 1);
    final monthEnd = DateTime(thisMonth.year, thisMonth.month + 1, 0);

    final monthlyIncome =
        getTotalIncome(startDate: monthStart, endDate: monthEnd);
    final monthlyExpenses =
        getTotalExpenses(startDate: monthStart, endDate: monthEnd);
    final spendingByCategory =
        getSpendingByCategory(startDate: monthStart, endDate: monthEnd);

    // Check savings rate
    if (monthlyIncome > 0) {
      final monthlySavings = monthlyIncome - monthlyExpenses;
      final savingsRate = monthlySavings / monthlyIncome;
      if (savingsRate < 0.1) {
        recommendations.add(
            'Try to save at least 10% of your income (\$${(monthlyIncome * 0.1).toStringAsFixed(2)})');
      } else if (savingsRate < 0.2) {
        recommendations.add(
            'Good progress! Aim to save 20% of your income (\$${(monthlyIncome * 0.2).toStringAsFixed(2)})');
      }
    }

    // Identify high-spending categories
    if (spendingByCategory.isNotEmpty) {
      final sortedCategories = spendingByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topCategory = sortedCategories.first;
      final topCategorySpending = topCategory.value;

      if (topCategorySpending > monthlyIncome * 0.3) {
        recommendations.add(
            'Consider reducing ${topCategory.key} expenses (currently \$${topCategorySpending.toStringAsFixed(2)})');
      }

      // Check for dining/entertainment overspending
      final diningCategories = ['Food & Dining', 'Entertainment', 'Shopping'];
      double leisureSpending = 0;
      for (final category in diningCategories) {
        leisureSpending += spendingByCategory[category] ?? 0;
      }

      if (leisureSpending > monthlyIncome * 0.2) {
        recommendations.add(
            'Leisure spending is high (\$${leisureSpending.toStringAsFixed(2)}). Consider budget-friendly alternatives.');
      }
    }

    // General recommendations
    recommendations.add('Automate savings transfers to make saving effortless');
    recommendations.add('Review subscriptions and cancel unused services');
    recommendations.add('Use the 30-day rule for non-essential purchases');

    if (recommendations.length <= 3) {
      recommendations.add(
          'You\'re doing well! Keep tracking your expenses to maintain good habits');
    }

    return '💡 Savings Recommendations:\n' +
        recommendations.map((r) => '• $r').join('\n');
  }

  String getSpendingTrends() {
    if (_transactions.length < 2) {
      return 'Need more transaction data to analyze spending trends.';
    }

    final buffer = StringBuffer();
    buffer.writeln('📊 Spending Trends Analysis');
    buffer.writeln('');

    // Analyze last 3 months
    final now = DateTime.now();
    final months = <DateTime>[];
    for (int i = 0; i < 3; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      months.add(month);
    }

    for (final month in months) {
      final monthEnd = DateTime(month.year, month.month + 1, 0);
      final income = getTotalIncome(startDate: month, endDate: monthEnd);
      final expenses = getTotalExpenses(startDate: month, endDate: monthEnd);

      buffer.writeln('${month.month}/${month.year}:');
      buffer.writeln('  Income: \$${income.toStringAsFixed(2)}');
      buffer.writeln('  Expenses: \$${expenses.toStringAsFixed(2)}');
      buffer.writeln('  Net: \$${(income - expenses).toStringAsFixed(2)}');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  String getFinancialHealthScore() {
    if (_transactions.isEmpty) {
      return 'No transaction data available to calculate financial health score.';
    }

    final thisMonth = DateTime.now();
    final monthStart = DateTime(thisMonth.year, thisMonth.month, 1);
    final monthEnd = DateTime(thisMonth.year, thisMonth.month + 1, 0);

    final monthlyIncome =
        getTotalIncome(startDate: monthStart, endDate: monthEnd);
    final monthlyExpenses =
        getTotalExpenses(startDate: monthStart, endDate: monthEnd);

    double score = 100;

    // Deduct points for high expense-to-income ratio
    if (monthlyIncome > 0) {
      final expenseRatio = monthlyExpenses / monthlyIncome;
      if (expenseRatio > 0.9)
        score -= 30;
      else if (expenseRatio > 0.7)
        score -= 20;
      else if (expenseRatio > 0.5) score -= 10;
    }

    // Deduct points for no savings goals
    if (_savingsGoals.isEmpty) score -= 10;

    // Deduct points for incomplete savings goals
    final incompleteGoals =
        _savingsGoals.where((g) => g.status != GoalStatus.completed).length;
    if (incompleteGoals > 0) score -= 5;

    // Deduct points for high spending in discretionary categories
    final spendingByCategory =
        getSpendingByCategory(startDate: monthStart, endDate: monthEnd);
    final discretionarySpending = (spendingByCategory['Entertainment'] ?? 0) +
        (spendingByCategory['Shopping'] ?? 0);
    if (monthlyIncome > 0 && discretionarySpending > monthlyIncome * 0.2) {
      score -= 10;
    }

    score = score.clamp(0, 100);

    String rating;
    if (score >= 80)
      rating = 'Excellent';
    else if (score >= 60)
      rating = 'Good';
    else if (score >= 40)
      rating = 'Fair';
    else
      rating = 'Needs Improvement';

    return '🏦 Financial Health Score: ${score.toStringAsFixed(0)}/100 ($rating)';
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'budgets': _budgets.map((b) => b.toJson()).toList(),
        'transactions': _transactions
            .take(_maxTransactions)
            .map((t) => t.toJson())
            .toList(),
        'categories': _categories.map((c) => c.toJson()).toList(),
        'savingsGoals': _savingsGoals.map((g) => g.toJson()).toList(),
        'totalTransactions': _totalTransactions,
        'totalSpent': _totalSpent,
        'totalSaved': _totalSaved,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[BudgetCoach] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        _budgets.clear();
        _budgets.addAll((data['budgets'] as List<dynamic>? ?? [])
            .map((b) => Budget.fromJson(b as Map<String, dynamic>)));

        _transactions.clear();
        _transactions.addAll((data['transactions'] as List<dynamic>? ?? [])
            .map((t) => Transaction.fromJson(t as Map<String, dynamic>)));

        _categories.clear();
        _categories.addAll((data['categories'] as List<dynamic>? ?? [])
            .map((c) => Category.fromJson(c as Map<String, dynamic>)));

        _savingsGoals.clear();
        _savingsGoals.addAll((data['savingsGoals'] as List<dynamic>? ?? [])
            .map((g) => SavingsGoal.fromJson(g as Map<String, dynamic>)));

        _totalTransactions = data['totalTransactions'] as int? ?? 0;
        _totalSpent = (data['totalSpent'] as num?)?.toDouble() ?? 0;
        _totalSaved = (data['totalSaved'] as num?)?.toDouble() ?? 0;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[BudgetCoach] Load error: $e');
    }
  }
}

class Budget {
  final String id;
  final String name;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> categories;
  BudgetStatus status;
  final DateTime createdAt;

  Budget({
    required this.id,
    required this.name,
    required this.amount,
    required this.startDate,
    required this.endDate,
    required this.categories,
    required this.status,
    required this.createdAt,
  });

  Budget copyWith({
    BudgetStatus? status,
  }) {
    return Budget(
      id: id,
      name: name,
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      categories: categories,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'categories': categories,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: json['id'],
        name: json['name'],
        amount: (json['amount'] as num).toDouble(),
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        categories: List<String>.from(json['categories'] ?? []),
        status: BudgetStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => BudgetStatus.active,
        ),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class Transaction {
  final String id;
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final TransactionType type;
  final String? notes;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'type': type.name,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        description: json['description'],
        amount: (json['amount'] as num).toDouble(),
        category: json['category'],
        date: DateTime.parse(json['date']),
        type: TransactionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TransactionType.expense,
        ),
        notes: json['notes'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class Category {
  final String name;
  final double budget;
  final String color;

  Category({
    required this.name,
    required this.budget,
    required this.color,
  });

  Category copyWith({
    double? budget,
  }) {
    return Category(
      name: name,
      budget: budget ?? this.budget,
      color: color,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'budget': budget,
        'color': color,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        name: json['name'],
        budget: (json['budget'] as num).toDouble(),
        color: json['color'],
      );
}

class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  double currentAmount;
  final DateTime targetDate;
  final String description;
  GoalStatus status;
  final DateTime createdAt;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  SavingsGoal copyWith({
    double? currentAmount,
    GoalStatus? status,
  }) {
    return SavingsGoal(
      id: id,
      name: name,
      targetAmount: targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate,
      description: description,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'targetDate': targetDate.toIso8601String(),
        'description': description,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
        id: json['id'],
        name: json['name'],
        targetAmount: (json['targetAmount'] as num).toDouble(),
        currentAmount: (json['currentAmount'] as num).toDouble(),
        targetDate: DateTime.parse(json['targetDate']),
        description: json['description'],
        status: GoalStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => GoalStatus.inProgress,
        ),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

enum BudgetStatus { active, completed, cancelled }

enum TransactionType { income, expense }

enum GoalStatus { inProgress, completed, cancelled }
