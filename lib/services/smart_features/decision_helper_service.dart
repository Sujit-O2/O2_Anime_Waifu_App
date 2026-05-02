import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DecisionOption {
  final String id;
  final String text;
  final List<String> pros;
  final List<String> cons;
  final double? score;

  DecisionOption({
    required this.id,
    required this.text,
    this.pros = const [],
    this.cons = const [],
    this.score,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'pros': pros,
        'cons': cons,
        'score': score,
      };

  factory DecisionOption.fromJson(Map<String, dynamic> json) => DecisionOption(
        id: json['id'],
        text: json['text'],
        pros: List<String>.from(json['pros'] ?? []),
        cons: List<String>.from(json['cons'] ?? []),
        score: json['score']?.toDouble(),
      );
}

class DecisionResult {
  final String recommendation;
  final String reasoning;
  final Map<String, double> scores;
  final String riskLevel;
  final List<String> keyFactors;

  DecisionResult({
    required this.recommendation,
    required this.reasoning,
    required this.scores,
    required this.riskLevel,
    required this.keyFactors,
  });

  factory DecisionResult.fromJson(Map<String, dynamic> json) => DecisionResult(
        recommendation: json['recommendation'],
        reasoning: json['reasoning'],
        scores: Map<String, double>.from(
            json['scores']?.map((k, v) => MapEntry(k, v.toDouble())) ?? {}),
        riskLevel: json['riskLevel'],
        keyFactors: List<String>.from(json['keyFactors'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'recommendation': recommendation,
        'reasoning': reasoning,
        'scores': scores,
        'riskLevel': riskLevel,
        'keyFactors': keyFactors,
      };
}

class DecisionRecord {
  final String id;
  final String question;
  final List<DecisionOption> options;
  final DecisionResult? result;
  final DateTime createdAt;
  final String status;

  DecisionRecord({
    required this.id,
    required this.question,
    required this.options,
    this.result,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options.map((e) => e.toJson()).toList(),
        'result': result?.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'status': status,
      };

  factory DecisionRecord.fromJson(Map<String, dynamic> json) => DecisionRecord(
        id: json['id'],
        question: json['question'],
        options: (json['options'] as List)
            .map((e) => DecisionOption.fromJson(e))
            .toList(),
        result: json['result'] != null
            ? DecisionResult.fromJson(json['result'])
            : null,
        createdAt: DateTime.parse(json['createdAt']),
        status: json['status'],
      );
}

class DecisionHelperService {
  static final instance = DecisionHelperService._();
  DecisionHelperService._();

  static const _storageKey = 'decision_history';

  Future<List<DecisionRecord>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded
        .map((e) => DecisionRecord.fromJson(e))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveDecision(DecisionRecord decision) async {
    final history = await getHistory();
    history.insert(0, decision);
    await _saveHistory(history);
  }

  Future<void> _saveHistory(List<DecisionRecord> history) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<DecisionResult> analyzeDecision(
      String question, List<DecisionOption> options) async {
    await Future.delayed(const Duration(seconds: 3));

    final scores = <String, double>{};
    for (var i = 0; i < options.length; i++) {
      final opt = options[i];
      final baseScore = 50.0 + (opt.pros.length * 15) - (opt.cons.length * 10);
      scores[opt.id] = baseScore.clamp(0, 100);
    }

    final bestOption = options.reduce(
        (a, b) => (scores[a.id] ?? 0) > (scores[b.id] ?? 0) ? a : b);

    final risk = scores.values.any((s) => s < 30)
        ? 'High'
        : scores.values.any((s) => s < 50)
            ? 'Medium'
            : 'Low';

    return DecisionResult(
      recommendation: bestOption.text,
      reasoning:
          'Based on the analysis, "${bestOption.text}" has the most favorable balance of pros vs cons with a score of ${scores[bestOption.id]?.toStringAsFixed(0)}. It offers strong advantages with manageable drawbacks.',
      scores: scores,
      riskLevel: risk,
      keyFactors: [
        'Pros/cons balance',
        'Feasibility',
        'Impact potential',
        'Risk assessment',
      ],
    );
  }

  String getRiskColor(String risk) {
    switch (risk) {
      case 'High':
        return '🔴';
      case 'Medium':
        return '🟡';
      default:
        return '🟢';
    }
  }
}
