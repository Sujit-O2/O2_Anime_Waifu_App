import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';
import 'voice_provider.dart';
import 'theme_provider.dart';
import 'settings_provider.dart';
import 'persona_provider.dart';

class AppProviders extends StatelessWidget {
  final Widget child;
  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => PersonaProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
      ],
      child: _AppBootstrap(child: child),
    );
  }
}

class _AppBootstrap extends StatefulWidget {
  final Widget child;
  const _AppBootstrap({required this.child});

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  late final Future<void> _initializationFuture;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    try {
      final themeProvider = context.read<ThemeProvider>();
      final settingsProvider = context.read<SettingsProvider>();
      final personaProvider = context.read<PersonaProvider>();
      final chatProvider = context.read<ChatProvider>();

      await Future.wait([
        themeProvider.restore(),
        settingsProvider.loadAll(),
        personaProvider.initialize(),
        chatProvider.loadPersistedState(),
      ]);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Provider init error: $e\n$st');
      }
      if (mounted) {
        setState(() => _initError = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Material(
            color: Color(0xFF08000F),
            child: Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            ),
          );
        }
        if (snapshot.hasError) {
          return Material(
            color: const Color(0xFF08000F),
            child: Center(
              child: Text(
                'Init Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }
        return widget.child;
      },
    );
  }
}


