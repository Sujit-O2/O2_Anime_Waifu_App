import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';
import 'voice_provider.dart';
import 'theme_provider.dart';
import 'settings_provider.dart';
import 'persona_provider.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppProviders
///
/// Wraps the widget tree with all ChangeNotifier providers. This is the single
/// entry point for dependency injection across the entire app.
/// ─────────────────────────────────────────────────────────────────────────────
class AppProviders extends StatelessWidget {
  final Widget child;
  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..restore()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadAll()),
        ChangeNotifierProvider(create: (_) => PersonaProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ChatProvider()..loadPersistedState()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
      ],
      child: child,
    );
  }
}
