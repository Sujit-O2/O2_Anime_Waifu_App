import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 💻 Code Review Helper Service
/// 
/// For developers - analyze code snippets, suggest improvements, detect bugs.
class CodeReviewService {
  CodeReviewService._();
  static final CodeReviewService instance = CodeReviewService._();

  final List<CodeReview> _reviews = [];
  final Map<String, int> _languageStats = {};
  
  int _totalReviews = 0;
  int _issuesFound = 0;
  int _improvementsSuggested = 0;
  
  static const String _storageKey = 'code_review_v1';
  static const int _maxReviews = 200;

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode) debugPrint('[CodeReview] Initialized with $_totalReviews reviews');
  }

  Future<CodeReviewResult> analyzeCode({
    required String code,
    required String language,
    required String context,
  }) async {
    final startTime = DateTime.now();
    
    final issues = <CodeIssue>[];
    final suggestions = <CodeSuggestion>[];
    
    // Analyze for common issues based on language
    if (language.toLowerCase().contains('dart')) {
      issues.addAll(_analyzeDartCode(code));
      suggestions.addAll(_suggestDartImprovements(code));
    } else if (language.toLowerCase().contains('python')) {
      issues.addAll(_analyzePythonCode(code));
      suggestions.addAll(_suggestPythonImprovements(code));
    } else if (language.toLowerCase().contains('javascript') || language.toLowerCase().contains('typescript')) {
      issues.addAll(_analyzeJsCode(code));
      suggestions.addAll(_suggestJsImprovements(code));
    } else {
      issues.addAll(_analyzeGenericCode(code, language));
    }
    
    // General analysis
    issues.addAll(_analyzeGeneralIssues(code, language));
    suggestions.addAll(_suggestGeneralImprovements(code, language));
    
    // Calculate metrics
    final linesOfCode = code.split('\n').length;
    final complexity = _calculateComplexity(code);
    final maintainability = _calculateMaintainability(issues.length, complexity, linesOfCode);
    
    final severityBreakdown = {
      'critical': issues.where((i) => i.severity == IssueSeverity.critical).length,
      'high': issues.where((i) => i.severity == IssueSeverity.high).length,
      'medium': issues.where((i) => i.severity == IssueSeverity.medium).length,
      'low': issues.where((i) => i.severity == IssueSeverity.low).length,
    };
    
    final review = CodeReview(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      language: language,
      context: context,
      linesOfCode: linesOfCode,
      issues: issues,
      suggestions: suggestions,
      complexity: complexity,
      maintainability: maintainability,
      severityBreakdown: severityBreakdown,
      analyzedAt: startTime,
      durationMs: DateTime.now().difference(startTime).inMilliseconds,
    );
    
    _reviews.insert(0, review);
    if (_reviews.length > _maxReviews) {
      _reviews.removeLast();
    }
    
    _totalReviews++;
    _issuesFound += issues.length;
    _improvementsSuggested += suggestions.length;
    _languageStats[language] = (_languageStats[language] ?? 0) + 1;
    
    await _saveData();
    
    return CodeReviewResult(
      review: review,
      summary: _generateSummary(review),
      recommendations: _generateRecommendations(issues, suggestions),
    );
  }

  List<CodeIssue> _analyzeDartCode(String code) {
    final issues = <CodeIssue>[];
    final lines = code.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNum = i + 1;
      
      // Check for print statements (should use logger in production)
      if (line.contains(RegExp(r'\bprint\s*\(')) && !line.contains('//')) {
        issues.add(CodeIssue(
          type: IssueType.performance,
          severity: IssueSeverity.low,
          line: lineNum,
          message: 'Avoid print statements in production code',
          suggestion: 'Use a proper logging framework instead',
        ));
      }
      
      // Check for empty catch blocks
      if (line.contains(RegExp(r'catch\s*\([^)]*\)\s*\{?\s*\}?'))) {
        issues.add(CodeIssue(
          type: IssueType.errorHandling,
          severity: IssueSeverity.high,
          line: lineNum,
          message: 'Empty catch block - errors are being silently ignored',
          suggestion: 'Handle or log the caught exception appropriately',
        ));
      }
      
      // Check for TODO/FIXME comments
      if (line.contains(RegExp(r'//\s*(TODO|FIXME|XXX|HACK)'))) {
        issues.add(CodeIssue(
          type: IssueType.maintainability,
          severity: IssueSeverity.low,
          line: lineNum,
          message: 'TODO/FIXME comment found',
          suggestion: 'Address this technical debt item',
        ));
      }
      
      // Check for missing null safety
      if (line.contains(RegExp(r'\w+\s+\w+\s*=[^=]')) && !line.contains('?') && !line.contains('!')) {
        // Simple check - could be improved
      }
    }
    
    // Check for missing dispose methods in StatefulWidget
    if (code.contains('StatefulWidget') && !code.contains('dispose')) {
      issues.add(CodeIssue(
        type: IssueType.memoryLeak,
        severity: IssueSeverity.medium,
        line: 0,
        message: 'StatefulWidget may need dispose() method for cleanup',
        suggestion: 'Override dispose() to clean up controllers, listeners, and resources',
      ));
    }
    
    return issues;
  }

  List<CodeIssue> _analyzePythonCode(String code) {
    final issues = <CodeIssue>[];
    final lines = code.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNum = i + 1;
      
      // Check for bare except
      if (line.contains(RegExp(r'except\s*:\s*$'))) {
        issues.add(CodeIssue(
          type: IssueType.errorHandling,
          severity: IssueSeverity.high,
          line: lineNum,
          message: 'Bare except clause catches all exceptions including system exits',
          suggestion: 'Catch specific exceptions or use "except Exception:"',
        ));
      }
      
      // Check for mutable default arguments
      if (line.contains(RegExp(r'def\s+\w+\s*\([^)]*=\s*\[\s*\]'))) {
        issues.add(CodeIssue(
          type: IssueType.bug,
          severity: IssueSeverity.high,
          line: lineNum,
          message: 'Mutable default argument can cause unexpected behavior',
          suggestion: 'Use None as default and initialize inside function',
        ));
      }
    }
    
    return issues;
  }

  List<CodeIssue> _analyzeJsCode(String code) {
    final issues = <CodeIssue>[];
    final lines = code.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNum = i + 1;
      
      // Check for == instead of ===
      if (line.contains(RegExp(r'[^=!]==[^=]'))) {
        issues.add(CodeIssue(
          type: IssueType.bug,
          severity: IssueSeverity.medium,
          line: lineNum,
          message: 'Use === instead of == for type-safe comparison',
          suggestion: 'Replace == with === to avoid type coercion issues',
        ));
      }
      
      // Check for var instead of let/const
      if (line.contains(RegExp(r'\bvar\s+\w+'))) {
        issues.add(CodeIssue(
          type: IssueType.bestPractice,
          severity: IssueSeverity.low,
          line: lineNum,
          message: 'Use let or const instead of var',
          suggestion: 'Replace var with const (if not reassigned) or let',
        ));
      }
    }
    
    return issues;
  }

  List<CodeIssue> _analyzeGenericCode(String code, String language) {
    final issues = <CodeIssue>[];
    final lines = code.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNum = i + 1;
      
      // Check for hardcoded secrets - detects password/secret/key/token assignments
      if (line.contains(RegExp(r'(password|secret|key|token)\s*=', caseSensitive: false)) && 
          (line.contains('"') || line.contains("'"))) {
        issues.add(CodeIssue(
          type: IssueType.security,
          severity: IssueSeverity.critical,
          line: lineNum,
          message: 'Hardcoded secret detected',
          suggestion: 'Use environment variables or a secure vault',
        ));
      }
      
      // Check for SQL injection patterns
      if (line.contains(RegExp(r'(SELECT|INSERT|UPDATE|DELETE).*\+.*\$', caseSensitive: false))) {
        issues.add(CodeIssue(
          type: IssueType.security,
          severity: IssueSeverity.critical,
          line: lineNum,
          message: 'Potential SQL injection vulnerability',
          suggestion: 'Use parameterized queries or prepared statements',
        ));
      }
    }
    
    return issues;
  }

  List<CodeIssue> _analyzeGeneralIssues(String code, String language) {
    final issues = <CodeIssue>[];
    final lines = code.split('\n');
    
    // Check for very long lines
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].length > 120) {
        issues.add(CodeIssue(
          type: IssueType.style,
          severity: IssueSeverity.low,
          line: i + 1,
          message: 'Line exceeds 120 characters',
          suggestion: 'Break the line into multiple lines for better readability',
        ));
      }
    }
    
    // Check for commented out code
    if (code.contains(RegExp(r'//\s*[a-zA-Z].*;\s*$', multiLine: true))) {
      issues.add(CodeIssue(
        type: IssueType.maintainability,
        severity: IssueSeverity.low,
        line: 0,
        message: 'Commented out code found',
        suggestion: 'Remove commented out code or move to version control history',
      ));
    }
    
    return issues;
  }

  List<CodeSuggestion> _suggestDartImprovements(String code) {
    final suggestions = <CodeSuggestion>[];
    
    if (code.contains('setState') && !code.contains('mounted')) {
      suggestions.add(CodeSuggestion(
        category: SuggestionCategory.performance,
        title: 'Add mounted check before setState',
        description: 'Always check if widget is mounted before calling setState to avoid memory leaks',
        example: 'if (mounted) setState(() {});',
      ));
    }
    
    if (!code.contains('const') && code.contains('Widget(')) {
      suggestions.add(CodeSuggestion(
        category: SuggestionCategory.performance,
        title: 'Use const constructors',
        description: 'Use const constructors for widgets that don\'t change to improve performance',
        example: 'const Text(\'Hello\') instead of Text(\'Hello\')',
      ));
    }
    
    return suggestions;
  }

  List<CodeSuggestion> _suggestPythonImprovements(String code) {
    final suggestions = <CodeSuggestion>[];
    
    if (code.contains('for') && code.contains('range(len(')) {
      suggestions.add(CodeSuggestion(
        category: SuggestionCategory.performance,
        title: 'Use enumerate instead of range(len())',
        description: 'More Pythonic and slightly faster',
        example: 'for i, item in enumerate(items):',
      ));
    }
    
    return suggestions;
  }

  List<CodeSuggestion> _suggestJsImprovements(String code) {
    final suggestions = <CodeSuggestion>[];
    
    if (code.contains('function(')) {
      suggestions.add(CodeSuggestion(
        category: SuggestionCategory.bestPractice,
        title: 'Use arrow functions',
        description: 'Arrow functions are more concise and preserve lexical this',
        example: 'const func = () => {};',
      ));
    }
    
    return suggestions;
  }

  List<CodeSuggestion> _suggestGeneralImprovements(String code, String language) {
    final suggestions = <CodeSuggestion>[];
    
    if (code.length > 1000 && code.split('\n').length > 50) {
      suggestions.add(CodeSuggestion(
        category: SuggestionCategory.architecture,
        title: 'Consider breaking into smaller functions',
        description: 'Large functions are harder to test and maintain',
        example: 'Extract logical blocks into separate functions',
      ));
    }
    
    return suggestions;
  }

  double _calculateComplexity(String code) {
    int complexity = 1;
    
    // Count decision points
    complexity += RegExp(r'\b(if|else if|for|while|case|catch)\b').allMatches(code).length;
    complexity += RegExp(r'\?').allMatches(code).length; // ternary operators
    complexity += RegExp(r'\&\&|\|\|').allMatches(code).length; // logical operators
    
    return complexity.toDouble();
  }

  double _calculateMaintainability(int issueCount, double complexity, int linesOfCode) {
    if (linesOfCode == 0) return 100.0;
    
    double score = 100.0;
    score -= (issueCount * 2); // -2 points per issue
    score -= (complexity * 0.5); // -0.5 per complexity point
    score -= (linesOfCode / 100); // -1 per 100 lines
    
    return score.clamp(0.0, 100.0);
  }

  String _generateSummary(CodeReview review) {
    final buffer = StringBuffer();
    buffer.writeln('📝 Code Review Summary');
    buffer.writeln('Language: ${review.language}');
    buffer.writeln('Lines: ${review.linesOfCode}');
    buffer.writeln('Complexity: ${review.complexity.toStringAsFixed(0)}');
    buffer.writeln('Maintainability: ${review.maintainability.toStringAsFixed(1)}/100');
    buffer.writeln('');
    buffer.writeln('Issues Found:');
    buffer.writeln('  Critical: ${review.severityBreakdown['critical']}');
    buffer.writeln('  High: ${review.severityBreakdown['high']}');
    buffer.writeln('  Medium: ${review.severityBreakdown['medium']}');
    buffer.writeln('  Low: ${review.severityBreakdown['low']}');
    buffer.writeln('');
    buffer.writeln('Suggestions: ${review.suggestions.length}');
    
    return buffer.toString();
  }

  String _generateRecommendations(List<CodeIssue> issues, List<CodeSuggestion> suggestions) {
    final buffer = StringBuffer();
    
    if (issues.isNotEmpty) {
      final critical = issues.where((i) => i.severity == IssueSeverity.critical);
      if (critical.isNotEmpty) {
        buffer.writeln('🚨 Critical issues must be fixed immediately!');
      }
      
      buffer.writeln('\n📋 Priority fixes:');
      issues.where((i) => i.severity == IssueSeverity.high).take(3).forEach((issue) {
        buffer.writeln('• Line ${issue.line}: ${issue.message}');
      });
    }
    
    if (suggestions.isNotEmpty) {
      buffer.writeln('\n💡 Improvement suggestions:');
      suggestions.take(3).forEach((suggestion) {
        buffer.writeln('• ${suggestion.title}');
      });
    }
    
    if (issues.isEmpty && suggestions.isEmpty) {
      buffer.writeln('✅ Code looks good! No major issues found.');
    }
    
    return buffer.toString();
  }

  List<CodeReview> getReviewsByLanguage(String language) {
    return _reviews.where((r) => r.language.toLowerCase() == language.toLowerCase()).toList();
  }

  Map<String, dynamic> getStats() {
    return {
      'total_reviews': _totalReviews,
      'total_issues': _issuesFound,
      'total_suggestions': _improvementsSuggested,
      'language_stats': _languageStats,
      'avg_issues_per_review': _totalReviews > 0 ? _issuesFound / _totalReviews : 0.0,
    };
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'reviews': _reviews.take(50).map((r) => r.toJson()).toList(),
        'totalReviews': _totalReviews,
        'issuesFound': _issuesFound,
        'improvementsSuggested': _improvementsSuggested,
        'languageStats': _languageStats,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[CodeReview] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        
        _reviews.clear();
        _reviews.addAll(
          (data['reviews'] as List<dynamic>)
              .map((r) => CodeReview.fromJson(r as Map<String, dynamic>))
        );
        
        _totalReviews = data['totalReviews'] as int;
        _issuesFound = data['issuesFound'] as int;
        _improvementsSuggested = data['improvementsSuggested'] as int;
        _languageStats.clear();
        _languageStats.addAll(Map<String, int>.from(data['languageStats'] ?? {}));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[CodeReview] Load error: $e');
    }
  }
}

class CodeReviewResult {
  final CodeReview review;
  final String summary;
  final String recommendations;

  CodeReviewResult({
    required this.review,
    required this.summary,
    required this.recommendations,
  });
}

class CodeReview {
  final String id;
  final String language;
  final String context;
  final int linesOfCode;
  final List<CodeIssue> issues;
  final List<CodeSuggestion> suggestions;
  final double complexity;
  final double maintainability;
  final Map<String, int> severityBreakdown;
  final DateTime analyzedAt;
  final int durationMs;

  CodeReview({
    required this.id,
    required this.language,
    required this.context,
    required this.linesOfCode,
    required this.issues,
    required this.suggestions,
    required this.complexity,
    required this.maintainability,
    required this.severityBreakdown,
    required this.analyzedAt,
    required this.durationMs,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'language': language,
    'context': context,
    'linesOfCode': linesOfCode,
    'issues': issues.map((i) => i.toJson()).toList(),
    'suggestions': suggestions.map((s) => s.toJson()).toList(),
    'complexity': complexity,
    'maintainability': maintainability,
    'severityBreakdown': severityBreakdown,
    'analyzedAt': analyzedAt.toIso8601String(),
    'durationMs': durationMs,
  };

  factory CodeReview.fromJson(Map<String, dynamic> json) => CodeReview(
    id: json['id'],
    language: json['language'],
    context: json['context'],
    linesOfCode: json['linesOfCode'],
    issues: (json['issues'] as List<dynamic>)
        .map((i) => CodeIssue.fromJson(i as Map<String, dynamic>))
        .toList(),
    suggestions: (json['suggestions'] as List<dynamic>)
        .map((s) => CodeSuggestion.fromJson(s as Map<String, dynamic>))
        .toList(),
    complexity: (json['complexity'] as num).toDouble(),
    maintainability: (json['maintainability'] as num).toDouble(),
    severityBreakdown: Map<String, int>.from(json['severityBreakdown'] ?? {}),
    analyzedAt: DateTime.parse(json['analyzedAt']),
    durationMs: json['durationMs'],
  );
}

class CodeIssue {
  final IssueType type;
  final IssueSeverity severity;
  final int line;
  final String message;
  final String suggestion;

  CodeIssue({
    required this.type,
    required this.severity,
    required this.line,
    required this.message,
    required this.suggestion,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'severity': severity.name,
    'line': line,
    'message': message,
    'suggestion': suggestion,
  };

  factory CodeIssue.fromJson(Map<String, dynamic> json) => CodeIssue(
    type: IssueType.values.firstWhere((e) => e.name == json['type']),
    severity: IssueSeverity.values.firstWhere((e) => e.name == json['severity']),
    line: json['line'],
    message: json['message'],
    suggestion: json['suggestion'],
  );
}

class CodeSuggestion {
  final SuggestionCategory category;
  final String title;
  final String description;
  final String example;

  CodeSuggestion({
    required this.category,
    required this.title,
    required this.description,
    required this.example,
  });

  Map<String, dynamic> toJson() => {
    'category': category.name,
    'title': title,
    'description': description,
    'example': example,
  };

  factory CodeSuggestion.fromJson(Map<String, dynamic> json) => CodeSuggestion(
    category: SuggestionCategory.values.firstWhere((e) => e.name == json['category']),
    title: json['title'],
    description: json['description'],
    example: json['example'],
  );
}

enum IssueType { bug, security, performance, maintainability, style, errorHandling, memoryLeak, bestPractice }
enum IssueSeverity { low, medium, high, critical }
enum SuggestionCategory { performance, bestPractice, architecture, security, readability }