import 'dart:io';

import 'package:flutter/services.dart';

class OpenAppActionResult {
  final bool launched;
  final String assistantMessage;

  const OpenAppActionResult({
    required this.launched,
    required this.assistantMessage,
  });
}

class OpenAppService {
  static const MethodChannel _nativeChannel =
      MethodChannel('anime_waifu/assistant_mode');

  static final RegExp _openActionPattern = RegExp(
    r'Action\s*:\s*open[\s_-]*app',
    caseSensitive: false,
  );

  static final RegExp _appLinePattern = RegExp(
    r'^\s*App\s*:\s*(.+?)\s*$',
    caseSensitive: false,
    multiLine: true,
  );

  static final RegExp _appInlinePattern = RegExp(
    r'Action\s*:\s*open[\s_-]*app[\s\S]*?App\s*:\s*([^\r\n]+)',
    caseSensitive: false,
  );

  static Future<OpenAppActionResult?> handleAssistantReply(String reply) async {
    if (!_openActionPattern.hasMatch(reply)) return null;

    final appName = _extractAppName(reply);
    if (appName == null || appName.isEmpty) {
      return const OpenAppActionResult(
        launched: false,
        assistantMessage:
            'App name missing. Use Action: OPEN_APP and App: <app name>.',
      );
    }

    if (!Platform.isAndroid) {
      return const OpenAppActionResult(
        launched: false,
        assistantMessage: 'I can open apps only on Android right now.',
      );
    }

    try {
      final resolvedPackage = await _nativeChannel.invokeMethod<String>(
        'openAppByName',
        {'query': appName},
      );
      if (resolvedPackage != null && resolvedPackage.trim().isNotEmpty) {
        return OpenAppActionResult(
          launched: true,
          assistantMessage: 'Opened ${_titleCase(appName)}.',
        );
      }
    } catch (_) {
      // Return unified failure message below.
    }

    return OpenAppActionResult(
      launched: false,
      assistantMessage:
          'I could not open ${_titleCase(appName)}. It may be unavailable, disabled, or not installed.',
    );
  }

  static String? _extractAppName(String reply) {
    final line = _appLinePattern.firstMatch(reply)?.group(1)?.trim();
    if (line != null && line.isNotEmpty) {
      return _sanitizeAppName(line);
    }

    final inline = _appInlinePattern.firstMatch(reply)?.group(1)?.trim();
    if (inline != null && inline.isNotEmpty) {
      return _sanitizeAppName(inline);
    }

    return null;
  }

  static String _sanitizeAppName(String value) {
    return value
        .trim()
        .replaceAll(RegExp("^[\"']+"), '')
        .replaceAll(RegExp("[\"']+\$"), '')
        .replaceAll(RegExp(r'[\.;,\)\]]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _titleCase(String input) {
    if (input.isEmpty) return input;
    return input
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
      final lower = word.toLowerCase();
      return '${lower.substring(0, 1).toUpperCase()}${lower.length > 1 ? lower.substring(1) : ''}';
    }).join(' ');
  }
}
