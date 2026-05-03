import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:anime_waifu/services/smart_features/voice_automation_service.dart';

class VoiceAutomationPage extends StatefulWidget {
  const VoiceAutomationPage({super.key});

  @override
  State<VoiceAutomationPage> createState() => _VoiceAutomationPageState();
}

class _VoiceAutomationPageState extends State<VoiceAutomationPage>
    with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final VoiceAutomationService _service = VoiceAutomationService.instance;
  final TextEditingController _textCtrl = TextEditingController();
  TabController? _tabCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _resultCtrl;

  bool _isListening = false;
  bool _speechReady = false;
  String _recognizedText = '';
  String _lastResult = '';
  bool _lastSuccess = false;
  List<VoiceCommandEntry> _history = [];
  List<Map<String, dynamic>> _commands = [];

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _resultCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _initSpeech();
    _loadData();
  }

  @override
  void dispose() {
    _speech.stop();
    _textCtrl.dispose();
    _tabCtrl?.dispose();
    _pulseCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' && _isListening) {
          if (!mounted) return;
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _lastResult = 'Mic error: ${error.errorMsg}';
          _lastSuccess = false;
        });
        _resultCtrl.forward(from: 0);
      },
    );
    if (mounted) {
      setState(() => _speechReady = available);
    }
  }

  Future<void> _loadData() async {
    final commands = _service.getAvailableCommands();
    final history = await _service.getCommandHistory();
    if (mounted) {
      setState(() {
        _commands = commands;
        _history = history;
        _tabCtrl = TabController(length: 2, vsync: this);
      });
    }
  }

  Future<void> _toggleListening() async {
    HapticFeedback.lightImpact();
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
      if (_recognizedText.isNotEmpty) {
        await _processCommand(_recognizedText);
      }
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _lastResult = '';
    });

    _speech.listen(
      onResult: (val) {
        if (!mounted) return;
        setState(() {
          _recognizedText = val.recognizedWords;
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
    );
  }

  Future<void> _processCommand(String text) async {
    if (text.trim().isEmpty) return;
    final result = await _service.processVoiceCommand(text);
    final actionType = result['actionType'] as String;
    final params =
        Map<String, dynamic>.from(result['parameters'] as Map? ?? {});

    if (actionType == 'unknown') {
      setState(() {
        _lastResult = 'Command not recognized. Try: "open youtube"';
        _lastSuccess = false;
      });
    } else {
      final success = await _service.executeAction(actionType, params);
      setState(() {
        _lastSuccess = success;
        _lastResult = success
            ? 'Executed: ${_formatActionName(actionType)}'
            : 'Failed to execute: ${_formatActionName(actionType)}';
      });
      await _loadData();
    }
    _resultCtrl.forward(from: 0);
  }

  Future<void> _submitTextInput() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    _textCtrl.clear();
    await _processCommand(text);
  }

  String _formatActionName(String actionType) {
    return actionType
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  IconData _getCommandIcon(Map<String, dynamic> cmd) {
    switch (cmd['id']) {
      case 'call':
        return Icons.phone_rounded;
      case 'message':
        return Icons.message_rounded;
      case 'open_app':
        return Icons.apps_rounded;
      case 'set_reminder':
        return Icons.notifications_active_rounded;
      case 'play_music':
        return Icons.music_note_rounded;
      case 'search':
        return Icons.search_rounded;
      case 'weather':
        return Icons.wb_sunny_rounded;
      case 'alarm':
        return Icons.alarm_rounded;
      case 'note':
        return Icons.note_add_rounded;
      case 'email':
        return Icons.email_rounded;
      default:
        return Icons.mic_rounded;
    }
  }

  Color _getCommandColor(Map<String, dynamic> cmd) {
    return Color(cmd['color'] as int? ?? 0xFF00BCD4);
  }

  String _formatTimestamp(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B14),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text('VOICE AUTOMATION',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: Colors.white54, size: 20),
                    onPressed: _loadData,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabCtrl,
              labelColor: const Color(0xFF00BCD4),
              unselectedLabelColor: Colors.white38,
              indicatorColor: const Color(0xFF00BCD4),
              indicatorWeight: 2,
              labelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700, fontSize: 14),
              unselectedLabelStyle:
                  GoogleFonts.outfit(fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Commands', icon: Icon(Icons.mic_rounded, size: 16)),
                Tab(
                    text: 'History',
                    icon: Icon(Icons.history_rounded, size: 16)),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [_buildCommandsTab(), _buildHistoryTab()],
              ),
            ),
            _buildBottomPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text('Tap a command or use voice input',
                style: GoogleFonts.outfit(
                    color: Colors.white38, fontSize: 12)),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: _commands.length,
            itemBuilder: (_, i) {
              final cmd = _commands[i];
              final color = _getCommandColor(cmd);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  final examples =
                      (cmd['examples'] as List?)?.first?.toString() ?? '';
                  if (examples.isNotEmpty) {
                    _textCtrl.text = examples;
                    _submitTextInput();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getCommandIcon(cmd),
                            color: color, size: 24),
                      ),
                      const SizedBox(height: 10),
                      Text(cmd['label'] as String? ?? '',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(cmd['description'] as String? ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                              color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QUICK EXAMPLES',
                    style: GoogleFonts.outfit(
                        color: const Color(0xFF00BCD4),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildExampleChip('open youtube'),
                    _buildExampleChip('play lofi music'),
                    _buildExampleChip('weather today'),
                    _buildExampleChip('search flutter tips'),
                    _buildExampleChip('set alarm 7am'),
                    _buildExampleChip('note buy groceries'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleChip(String example) {
    return GestureDetector(
      onTap: () {
        _textCtrl.text = example;
        _submitTextInput();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF00BCD4).withValues(alpha: 0.3)),
        ),
        child: Text('"$example"',
            style: GoogleFonts.outfit(
                color: Colors.white70, fontSize: 11)),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return _history.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history_rounded,
                    color: Colors.white12, size: 64),
                const SizedBox(height: 12),
                Text('No commands yet',
                    style: GoogleFonts.outfit(
                        color: Colors.white38, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Your voice commands will appear here',
                    style: GoogleFonts.outfit(
                        color: Colors.white24, fontSize: 12)),
              ],
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final entry = _history[i];
              final color =
                  entry.success ? const Color(0xFF4CAF50) : Colors.redAccent;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                          entry.success
                              ? Icons.check_rounded
                              : Icons.close_rounded,
                          color: color,
                          size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '"${entry.rawText.length > 40 ? '${entry.rawText.substring(0, 40)}...' : entry.rawText}"',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                              '${_formatActionName(entry.actionType)} • ${_formatTimestamp(entry.timestamp)}',
                              style: GoogleFonts.outfit(
                                  color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white12, size: 12),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0B14).withValues(alpha: 0),
            const Color(0xFF0A0B14).withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_lastResult.isNotEmpty)
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _resultCtrl,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: _resultCtrl,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _lastSuccess
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
                        : Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _lastSuccess
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                          : Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          _lastSuccess
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          color: _lastSuccess
                              ? const Color(0xFF4CAF50)
                              : Colors.redAccent,
                          size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_lastResult,
                            style: GoogleFonts.outfit(
                                color: _lastSuccess
                                    ? const Color(0xFF4CAF50)
                                    : Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: TextField(
                    controller: _textCtrl,
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Type a command...',
                      hintStyle: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 13),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send_rounded,
                            color: Color(0xFF00BCD4), size: 20),
                        onPressed: _submitTextInput,
                      ),
                    ),
                    onSubmitted: (_) => _submitTextInput(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _speechReady ? _toggleListening : null,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) {
                    final scale =
                        _isListening ? 1.0 + _pulseCtrl.value * 0.12 : 1.0;
                    final pulseOpacity = _isListening
                        ? 0.3 * (1 - _pulseCtrl.value)
                        : 0.0;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF00BCD4)
                                  .withValues(alpha: pulseOpacity),
                              width: 2,
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: _isListening
                                    ? [
                                        const Color(0xFF00BCD4)
                                            .withValues(alpha: 0.4),
                                        const Color(0xFF00BCD4)
                                            .withValues(alpha: 0.1),
                                      ]
                                    : [
                                        const Color(0xFF00BCD4)
                                            .withValues(alpha: 0.25),
                                        const Color(0xFF00BCD4)
                                            .withValues(alpha: 0.05),
                                      ],
                              ),
                              border: Border.all(
                                color: const Color(0xFF00BCD4)
                                    .withValues(
                                        alpha: _isListening ? 0.8 : 0.4),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                                _isListening
                                    ? Icons.mic_rounded
                                    : Icons.mic_none_rounded,
                                color: _speechReady
                                    ? const Color(0xFF00BCD4)
                                    : Colors.white24,
                                size: 28),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              _isListening
                  ? 'Listening... tap to stop'
                  : _speechReady
                      ? 'Tap mic to speak'
                      : 'Speech not available',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  color: _isListening
                      ? const Color(0xFF00BCD4)
                      : Colors.white38,
                  fontSize: 11)),
          if (_recognizedText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('"$_recognizedText"',
                  style: GoogleFonts.outfit(
                      color: Colors.white60,
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }
}
