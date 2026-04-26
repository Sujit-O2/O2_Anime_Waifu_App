import 'dart:async';
import 'package:flutter/foundation.dart';

/// ⌨️ Typing Indicator Service
/// 
/// Shows "Zero Two is thinking..." with animated dots.
/// Makes conversations feel more natural.
class TypingIndicatorService {
  TypingIndicatorService._();
  static final TypingIndicatorService instance = TypingIndicatorService._();

  bool _isTyping = false;
  String _typingText = '';
  Timer? _typingTimer;
  int _dotCount = 0;

  bool get isTyping => _isTyping;
  String get typingText => _typingText;

  final List<Function(bool)> _listeners = [];

  /// Start typing indicator
  void startTyping({String? customText}) {
    if (_isTyping) return;

    _isTyping = true;
    _dotCount = 0;
    _typingText = customText ?? 'Zero Two is thinking';

    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _dotCount = (_dotCount + 1) % 4;
      _typingText = '${customText ?? 'Zero Two is thinking'}${'.' * _dotCount}';
      _notifyListeners();
    });

    _notifyListeners();
    if (kDebugMode) debugPrint('[TypingIndicator] Started');
  }

  /// Stop typing indicator
  void stopTyping() {
    if (!_isTyping) return;

    _isTyping = false;
    _typingTimer?.cancel();
    _typingText = '';
    _dotCount = 0;

    _notifyListeners();
    if (kDebugMode) debugPrint('[TypingIndicator] Stopped');
  }

  /// Add listener for typing state changes
  void addListener(Function(bool) listener) {
    _listeners.add(listener);
  }

  /// Remove listener
  void removeListener(Function(bool) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(_isTyping);
    }
  }

  /// Calculate typing delay based on message length
  Duration calculateTypingDelay(String message) {
    // Simulate realistic typing speed: ~50 chars per second
    final baseDelay = (message.length / 50 * 1000).toInt();
    
    // Add thinking time for longer messages
    final thinkingTime = message.length > 100 ? 800 : 400;
    
    // Clamp between 500ms and 3000ms
    final totalMs = (baseDelay + thinkingTime).clamp(500, 3000);
    
    return Duration(milliseconds: totalMs);
  }

  /// Show typing indicator for a duration based on message length
  Future<void> showTypingFor(String message) async {
    startTyping();
    await Future.delayed(calculateTypingDelay(message));
    stopTyping();
  }

  void dispose() {
    _typingTimer?.cancel();
    _listeners.clear();
  }
}
