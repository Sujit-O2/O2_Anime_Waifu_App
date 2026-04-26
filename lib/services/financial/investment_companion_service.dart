import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 📈 Investment Companion Service
///
/// Explain financial concepts, track portfolio performance (educational).
class InvestmentCompanionService {
  InvestmentCompanionService._();
  static final InvestmentCompanionService instance =
      InvestmentCompanionService._();

  final List<Portfolio> _portfolios = [];
  final List<Investment> _investments = [];
  final List<FinancialConcept> _concepts = [];
  final List<MarketWatch> _marketWatches = [];

  int _totalPortfolios = 0;
  int _totalInvestments = 0;

  static const String _storageKey = 'investment_companion_v1';
  static const int _maxPortfolios = 20;

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode)
      debugPrint(
          '[InvestmentCompanion] Initialized with $_totalPortfolios portfolios');

    // Initialize default concepts if empty
    if (_concepts.isEmpty) {
      _initializeDefaultConcepts();
    }
  }

  void _initializeDefaultConcepts() {
    final defaultConcepts = [
      FinancialConcept(
        title: 'Compound Interest',
        description:
            'Earning interest on both your initial investment and the accumulated interest over time.',
        category: ConceptCategory.fundamental,
        difficulty: ConceptDifficulty.beginner,
        keyPoints: [
          'Start early to maximize compounding',
          'Reinvest dividends for compound growth',
          'Time is more important than timing'
        ],
        examples: [
          r'$1000 invested at 7% for 30 years = $7612',
          r'$1000 invested at 7% for 40 years = $14974'
        ],
      ),
      FinancialConcept(
        title: 'Diversification',
        description:
            'Spreading investments across different assets to reduce risk.',
        category: ConceptCategory.riskManagement,
        difficulty: ConceptDifficulty.beginner,
        keyPoints: [
          'Don\'t put all eggs in one basket',
          'Mix stocks, bonds, and other assets',
          'Consider international diversification'
        ],
        examples: [
          '60% stocks, 40% bonds',
          'Include small-cap, mid-cap, and large-cap stocks'
        ],
      ),
      FinancialConcept(
        title: 'Dollar-Cost Averaging',
        description:
            'Investing a fixed amount regularly regardless of market conditions.',
        category: ConceptCategory.strategy,
        difficulty: ConceptDifficulty.beginner,
        keyPoints: [
          'Reduces impact of volatility',
          'No need to time the market',
          'Builds discipline'
        ],
        examples: [
          r'Invest $500 monthly regardless of price',
          'Automate contributions to 401(k)'
        ],
      ),
      FinancialConcept(
        title: 'Risk vs Return',
        description:
            'Higher potential returns typically come with higher risk.',
        category: ConceptCategory.fundamental,
        difficulty: ConceptDifficulty.intermediate,
        keyPoints: [
          'Understand your risk tolerance',
          'Young investors can take more risk',
          'Bonds are generally less risky than stocks'
        ],
        examples: [
          'Stocks: 7-10% average return, high volatility',
          'Bonds: 3-5% average return, lower volatility'
        ],
      ),
      FinancialConcept(
        title: 'Asset Allocation',
        description: 'Dividing investments among different asset categories.',
        category: ConceptCategory.strategy,
        difficulty: ConceptDifficulty.intermediate,
        keyPoints: [
          'Based on age and risk tolerance',
          'Rebalance periodically',
          'Changes as you approach goals'
        ],
        examples: [
          'Age 30: 80% stocks, 20% bonds',
          'Age 50: 60% stocks, 40% bonds'
        ],
      ),
    ];

    _concepts.addAll(defaultConcepts);
  }

  Future<Portfolio> createPortfolio({
    required String name,
    required String description,
    required PortfolioType type,
    required double initialInvestment,
    required List<String> holdings,
  }) async {
    final portfolio = Portfolio(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      type: type,
      initialInvestment: initialInvestment,
      currentValue: initialInvestment,
      holdings: holdings,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    _portfolios.insert(0, portfolio);
    _totalPortfolios++;

    await _saveData();

    if (kDebugMode)
      debugPrint('[InvestmentCompanion] Created portfolio: $name');
    return portfolio;
  }

  Future<Investment> addInvestment({
    required String portfolioId,
    required String symbol,
    required String name,
    required String type,
    required int quantity,
    required double purchasePrice,
    required DateTime purchaseDate,
    String? notes,
  }) async {
    final investment = Investment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      portfolioId: portfolioId,
      symbol: symbol,
      name: name,
      type: type,
      quantity: quantity,
      purchasePrice: purchasePrice,
      currentPrice: purchasePrice, // Simplified - would fetch real-time data
      purchaseDate: purchaseDate,
      notes: notes,
      createdAt: DateTime.now(),
    );

    _investments.insert(0, investment);
    _totalInvestments++;

    // Update portfolio
    final portfolioIndex = _portfolios.indexWhere((p) => p.id == portfolioId);
    if (portfolioIndex != -1) {
      final portfolio = _portfolios[portfolioIndex];
      final newHolding = '${quantity} shares of $symbol';
      _portfolios[portfolioIndex] = portfolio.copyWith(
        holdings: [...portfolio.holdings, newHolding],
        currentValue: portfolio.currentValue + (quantity * purchasePrice),
        lastUpdated: DateTime.now(),
      );
    }

    await _saveData();

    if (kDebugMode)
      debugPrint('[InvestmentCompanion] Added investment: $symbol');
    return investment;
  }

  Future<void> updateInvestmentPrice(
      String investmentId, double newPrice) async {
    final investmentIndex =
        _investments.indexWhere((i) => i.id == investmentId);
    if (investmentIndex == -1) return;

    final investment = _investments[investmentIndex];
    _investments[investmentIndex] = investment.copyWith(
      currentPrice: newPrice,
    );

    // Update portfolio value
    final portfolioIndex =
        _portfolios.indexWhere((p) => p.id == investment.portfolioId);
    if (portfolioIndex != -1) {
      final portfolio = _portfolios[portfolioIndex];
      final priceChange =
          (newPrice - investment.purchasePrice) * investment.quantity;
      _portfolios[portfolioIndex] = portfolio.copyWith(
        currentValue: portfolio.currentValue + priceChange,
        lastUpdated: DateTime.now(),
      );
    }

    await _saveData();

    if (kDebugMode)
      debugPrint('[InvestmentCompanion] Updated price for: $investmentId');
  }

  Future<MarketWatch> addToWatchlist({
    required String symbol,
    required String name,
    required String type,
    required String exchange,
  }) async {
    final watch = MarketWatch(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: symbol,
      name: name,
      type: type,
      exchange: exchange,
      currentPrice: 0,
      change: 0,
      changePercent: 0,
      addedAt: DateTime.now(),
    );

    _marketWatches.insert(0, watch);

    await _saveData();

    if (kDebugMode)
      debugPrint('[InvestmentCompanion] Added to watchlist: $symbol');
    return watch;
  }

  String getPortfolioPerformance(String portfolioId) {
    final portfolio = _portfolios.firstWhere((p) => p.id == portfolioId);
    final gainLoss = portfolio.currentValue - portfolio.initialInvestment;
    final gainLossPercent = portfolio.initialInvestment > 0
        ? (gainLoss / portfolio.initialInvestment * 100)
        : 0;

    final buffer = StringBuffer();
    buffer.writeln('📊 Portfolio Performance: ${portfolio.name}');
    buffer.writeln('');
    buffer.writeln(
        'Initial Investment: \$${portfolio.initialInvestment.toStringAsFixed(2)}');
    buffer.writeln(
        'Current Value: \$${portfolio.currentValue.toStringAsFixed(2)}');
    buffer.writeln(
        'Gain/Loss: \$${gainLoss.toStringAsFixed(2)} (${gainLossPercent.toStringAsFixed(2)}%)');
    buffer.writeln('');
    buffer.writeln('Holdings:');
    for (final holding in portfolio.holdings) {
      buffer.writeln('• $holding');
    }
    buffer.writeln('');
    buffer.writeln('Last Updated: ${portfolio.lastUpdated}');

    return buffer.toString();
  }

  String getInvestmentAnalysis(String investmentId) {
    final investment = _investments.firstWhere((i) => i.id == investmentId);
    final gainLoss = (investment.currentPrice - investment.purchasePrice) *
        investment.quantity;
    final gainLossPercent = investment.purchasePrice > 0
        ? ((investment.currentPrice - investment.purchasePrice) /
            investment.purchasePrice *
            100)
        : 0;

    final buffer = StringBuffer();
    buffer.writeln(
        '📈 Investment Analysis: ${investment.name} (${investment.symbol})');
    buffer.writeln('');
    buffer.writeln('Type: ${investment.type}');
    buffer.writeln('Quantity: ${investment.quantity} shares');
    buffer.writeln(
        'Purchase Price: \$${investment.purchasePrice.toStringAsFixed(2)}');
    buffer.writeln(
        'Current Price: \$${investment.currentPrice.toStringAsFixed(2)}');
    buffer.writeln(
        'Total Investment: \$${(investment.quantity * investment.purchasePrice).toStringAsFixed(2)}');
    buffer.writeln(
        'Current Value: \$${(investment.quantity * investment.currentPrice).toStringAsFixed(2)}');
    buffer.writeln(
        'Gain/Loss: \$${gainLoss.toStringAsFixed(2)} (${gainLossPercent.toStringAsFixed(2)}%)');
    buffer.writeln('');

    if (gainLossPercent > 0) {
      buffer.writeln('✅ This investment is profitable!');
    } else if (gainLossPercent < 0) {
      buffer.writeln('⚠️ This investment is currently at a loss.');
    } else {
      buffer.writeln('➡️ This investment is at break-even.');
    }

    if (investment.notes != null && investment.notes!.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Notes: ${investment.notes}');
    }

    return buffer.toString();
  }

  String getFinancialConcept(String conceptTitle) {
    final concept = _concepts.firstWhere(
      (c) => c.title.toLowerCase() == conceptTitle.toLowerCase(),
      orElse: () => _concepts.first,
    );

    final buffer = StringBuffer();
    buffer.writeln('📚 ${concept.title}');
    buffer.writeln('');
    buffer.writeln('Category: ${concept.category.label}');
    buffer.writeln('Difficulty: ${concept.difficulty.label}');
    buffer.writeln('');
    buffer.writeln('Description:');
    buffer.writeln(concept.description);
    buffer.writeln('');
    buffer.writeln('Key Points:');
    for (final point in concept.keyPoints) {
      buffer.writeln('• $point');
    }
    buffer.writeln('');
    buffer.writeln('Examples:');
    for (final example in concept.examples) {
      buffer.writeln('• $example');
    }

    return buffer.toString();
  }

  List<FinancialConcept> getConceptsByCategory(ConceptCategory category) {
    return _concepts.where((c) => c.category == category).toList();
  }

  List<FinancialConcept> getConceptsByDifficulty(ConceptDifficulty difficulty) {
    return _concepts.where((c) => c.difficulty == difficulty).toList();
  }

  String getInvestmentRecommendations() {
    final recommendations = <String>[];

    recommendations
        .add('Start with low-cost index funds for broad market exposure');
    recommendations
        .add('Consider your time horizon - longer time allows more risk');
    recommendations
        .add('Rebalance your portfolio annually to maintain target allocation');
    recommendations
        .add('Keep emergency fund separate from investment portfolio');
    recommendations
        .add('Avoid trying to time the market - stay invested long-term');
    recommendations.add('Consider tax-advantaged accounts (401k, IRA) first');
    recommendations.add('Keep investment costs low - choose low-fee options');
    recommendations
        .add('Don\'t chase past performance - focus on fundamentals');

    return '💡 Investment Recommendations:\n' +
        recommendations.map((r) => '• $r').join('\n');
  }

  String getPortfolioSummary() {
    if (_portfolios.isEmpty) {
      return 'No portfolios created yet. Start building your investment portfolio!';
    }

    double totalInitial = 0;
    double totalCurrent = 0;

    for (final portfolio in _portfolios) {
      totalInitial += portfolio.initialInvestment;
      totalCurrent += portfolio.currentValue;
    }

    final totalGainLoss = totalCurrent - totalInitial;
    final totalGainLossPercent =
        totalInitial > 0 ? (totalGainLoss / totalInitial * 100) : 0;

    final buffer = StringBuffer();
    buffer.writeln('📊 Investment Portfolio Summary');
    buffer.writeln('');
    buffer.writeln('Total Portfolios: $_totalPortfolios');
    buffer.writeln('Total Investments: $_totalInvestments');
    buffer.writeln('');
    buffer.writeln('Overall Performance:');
    buffer.writeln('Initial Investment: \$${totalInitial.toStringAsFixed(2)}');
    buffer.writeln('Current Value: \$${totalCurrent.toStringAsFixed(2)}');
    buffer.writeln(
        'Total Gain/Loss: \$${totalGainLoss.toStringAsFixed(2)} (${totalGainLossPercent.toStringAsFixed(2)}%)');
    buffer.writeln('');
    buffer.writeln('Individual Portfolios:');

    for (final portfolio in _portfolios) {
      final gainLoss = portfolio.currentValue - portfolio.initialInvestment;
      final gainLossPercent = portfolio.initialInvestment > 0
          ? (gainLoss / portfolio.initialInvestment * 100)
          : 0;

      buffer.writeln(
          '• ${portfolio.name}: \$${portfolio.currentValue.toStringAsFixed(2)} (${gainLossPercent.toStringAsFixed(1)}%)');
    }

    return buffer.toString();
  }

  String getMarketWatchlist() {
    if (_marketWatches.isEmpty) {
      return 'No stocks in watchlist. Add stocks to track their performance!';
    }

    final buffer = StringBuffer();
    buffer.writeln('📈 Market Watchlist');
    buffer.writeln('');

    for (final watch in _marketWatches) {
      final changeSign = watch.change >= 0 ? '+' : '';
      final changeColor = watch.change >= 0 ? '🟢' : '🔴';

      buffer.writeln('$changeColor ${watch.symbol} - ${watch.name}');
      buffer.writeln('   Price: \$${watch.currentPrice.toStringAsFixed(2)}');
      buffer.writeln(
          '   Change: $changeSign${watch.change.toStringAsFixed(2)} ($changeSign${watch.changePercent.toStringAsFixed(2)}%)');
      buffer.writeln('   Exchange: ${watch.exchange}');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'portfolios':
            _portfolios.take(_maxPortfolios).map((p) => p.toJson()).toList(),
        'investments': _investments.take(100).map((i) => i.toJson()).toList(),
        'concepts': _concepts.map((c) => c.toJson()).toList(),
        'marketWatches':
            _marketWatches.take(50).map((m) => m.toJson()).toList(),
        'totalPortfolios': _totalPortfolios,
        'totalInvestments': _totalInvestments,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[InvestmentCompanion] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        _portfolios.clear();
        _portfolios.addAll((data['portfolios'] as List<dynamic>? ?? [])
            .map((p) => Portfolio.fromJson(p as Map<String, dynamic>)));

        _investments.clear();
        _investments.addAll((data['investments'] as List<dynamic>? ?? [])
            .map((i) => Investment.fromJson(i as Map<String, dynamic>)));

        _concepts.clear();
        _concepts.addAll((data['concepts'] as List<dynamic>? ?? [])
            .map((c) => FinancialConcept.fromJson(c as Map<String, dynamic>)));

        _marketWatches.clear();
        _marketWatches.addAll((data['marketWatches'] as List<dynamic>? ?? [])
            .map((m) => MarketWatch.fromJson(m as Map<String, dynamic>)));

        _totalPortfolios = data['totalPortfolios'] as int? ?? 0;
        _totalInvestments = data['totalInvestments'] as int? ?? 0;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[InvestmentCompanion] Load error: $e');
    }
  }
}

class Portfolio {
  final String id;
  final String name;
  final String description;
  final PortfolioType type;
  final double initialInvestment;
  double currentValue;
  final List<String> holdings;
  final DateTime createdAt;
  DateTime lastUpdated;

  Portfolio({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.initialInvestment,
    required this.currentValue,
    required this.holdings,
    required this.createdAt,
    required this.lastUpdated,
  });

  Portfolio copyWith({
    List<String>? holdings,
    double? currentValue,
    DateTime? lastUpdated,
  }) {
    return Portfolio(
      id: id,
      name: name,
      description: description,
      type: type,
      initialInvestment: initialInvestment,
      currentValue: currentValue ?? this.currentValue,
      holdings: holdings ?? this.holdings,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'initialInvestment': initialInvestment,
        'currentValue': currentValue,
        'holdings': holdings,
        'createdAt': createdAt.toIso8601String(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory Portfolio.fromJson(Map<String, dynamic> json) => Portfolio(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        type: PortfolioType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => PortfolioType.stocks,
        ),
        initialInvestment: (json['initialInvestment'] as num).toDouble(),
        currentValue: (json['currentValue'] as num).toDouble(),
        holdings: List<String>.from(json['holdings'] ?? []),
        createdAt: DateTime.parse(json['createdAt']),
        lastUpdated: DateTime.parse(json['lastUpdated']),
      );
}

class Investment {
  final String id;
  final String portfolioId;
  final String symbol;
  final String name;
  final String type;
  final int quantity;
  final double purchasePrice;
  double currentPrice;
  final DateTime purchaseDate;
  final String? notes;
  final DateTime createdAt;

  Investment({
    required this.id,
    required this.portfolioId,
    required this.symbol,
    required this.name,
    required this.type,
    required this.quantity,
    required this.purchasePrice,
    required this.currentPrice,
    required this.purchaseDate,
    this.notes,
    required this.createdAt,
  });

  Investment copyWith({
    double? currentPrice,
  }) {
    return Investment(
      id: id,
      portfolioId: portfolioId,
      symbol: symbol,
      name: name,
      type: type,
      quantity: quantity,
      purchasePrice: purchasePrice,
      currentPrice: currentPrice ?? this.currentPrice,
      purchaseDate: purchaseDate,
      notes: notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'portfolioId': portfolioId,
        'symbol': symbol,
        'name': name,
        'type': type,
        'quantity': quantity,
        'purchasePrice': purchasePrice,
        'currentPrice': currentPrice,
        'purchaseDate': purchaseDate.toIso8601String(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Investment.fromJson(Map<String, dynamic> json) => Investment(
        id: json['id'],
        portfolioId: json['portfolioId'],
        symbol: json['symbol'],
        name: json['name'],
        type: json['type'],
        quantity: json['quantity'],
        purchasePrice: (json['purchasePrice'] as num).toDouble(),
        currentPrice: (json['currentPrice'] as num).toDouble(),
        purchaseDate: DateTime.parse(json['purchaseDate']),
        notes: json['notes'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class FinancialConcept {
  final String title;
  final String description;
  final ConceptCategory category;
  final ConceptDifficulty difficulty;
  final List<String> keyPoints;
  final List<String> examples;

  FinancialConcept({
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.keyPoints,
    required this.examples,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category.name,
        'difficulty': difficulty.name,
        'keyPoints': keyPoints,
        'examples': examples,
      };

  factory FinancialConcept.fromJson(Map<String, dynamic> json) =>
      FinancialConcept(
        title: json['title'],
        description: json['description'],
        category: ConceptCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => ConceptCategory.fundamental,
        ),
        difficulty: ConceptDifficulty.values.firstWhere(
          (e) => e.name == json['difficulty'],
          orElse: () => ConceptDifficulty.beginner,
        ),
        keyPoints: List<String>.from(json['keyPoints'] ?? []),
        examples: List<String>.from(json['examples'] ?? []),
      );
}

class MarketWatch {
  final String id;
  final String symbol;
  final String name;
  final String type;
  final String exchange;
  double currentPrice;
  double change;
  double changePercent;
  final DateTime addedAt;

  MarketWatch({
    required this.id,
    required this.symbol,
    required this.name,
    required this.type,
    required this.exchange,
    required this.currentPrice,
    required this.change,
    required this.changePercent,
    required this.addedAt,
  });

  MarketWatch copyWith({
    double? currentPrice,
    double? change,
    double? changePercent,
  }) {
    return MarketWatch(
      id: id,
      symbol: symbol,
      name: name,
      type: type,
      exchange: exchange,
      currentPrice: currentPrice ?? this.currentPrice,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      addedAt: addedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'name': name,
        'type': type,
        'exchange': exchange,
        'currentPrice': currentPrice,
        'change': change,
        'changePercent': changePercent,
        'addedAt': addedAt.toIso8601String(),
      };

  factory MarketWatch.fromJson(Map<String, dynamic> json) => MarketWatch(
        id: json['id'],
        symbol: json['symbol'],
        name: json['name'],
        type: json['type'],
        exchange: json['exchange'],
        currentPrice: (json['currentPrice'] as num).toDouble(),
        change: (json['change'] as num).toDouble(),
        changePercent: (json['changePercent'] as num).toDouble(),
        addedAt: DateTime.parse(json['addedAt']),
      );
}

enum PortfolioType { stocks, bonds, mutualFunds, etf, crypto, mixed }

enum ConceptCategory {
  fundamental('Fundamental'),
  strategy('Strategy'),
  riskManagement('Risk Management'),
  technical('Technical'),
  behavioral('Behavioral');

  final String label;
  const ConceptCategory(this.label);
}

enum ConceptDifficulty {
  beginner('Beginner'),
  intermediate('Intermediate'),
  advanced('Advanced');

  final String label;
  const ConceptDifficulty(this.label);
}
