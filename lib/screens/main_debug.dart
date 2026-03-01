part of '../main.dart';

extension _MainDebugExtension on _ChatHomePageState {
// —— Page: Debug ————————————————————————————————————————————————————————————————
  Widget _buildDebugPage() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
            child: Text('DEBUG PANEL',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Component health status',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: _buildDebugHero(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _debugStatusCard(
                    label: 'Wake Word Engine',
                    status: _wakeWordActivationLimitHit
                        ? 'Activation Limit Hit'
                        : _wakeWordReady
                            ? 'Ready'
                            : _wakeInitInProgress
                                ? 'Initializing...'
                                : 'Offline',
                    color: _wakeWordActivationLimitHit
                        ? Colors.redAccent
                        : _wakeWordReady
                            ? Colors.greenAccent
                            : _wakeInitInProgress
                                ? Colors.orangeAccent
                                : Colors.grey,
                    icon: Icons.hearing,
                    extra: 'Running: ${_wakeWordService.isRunning}',
                  ),
                  _debugStatusCard(
                    label: 'STT (Microphone)',
                    status: _speechService.listening ? 'Listening' : 'Idle',
                    color: _speechService.listening
                        ? Colors.greenAccent
                        : Colors.white54,
                    icon: Icons.mic,
                    extra: 'Auto Listen: $_isAutoListening',
                  ),
                  _debugStatusCard(
                    label: 'TTS (Voice)',
                    status: _isSpeaking ? 'Speaking' : 'Idle',
                    color: _isSpeaking ? Colors.orangeAccent : Colors.white54,
                    icon: Icons.volume_up_outlined,
                    extra:
                        'Voice: ${_devTtsVoiceOverride.isNotEmpty ? _devTtsVoiceOverride : "lulwa"}',
                  ),
                  _debugStatusCard(
                    label: 'API',
                    status: _apiKeyStatus,
                    color: _apiKeyStatus == 'Systems Online'
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    icon: Icons.cloud_outlined,
                    extra:
                        'Model: ${_devModelOverride.isNotEmpty ? _devModelOverride : "kimi-k2-instruct"}',
                  ),
                  _debugStatusCard(
                    label: 'Notifications',
                    status: _notificationsAllowed ? 'Allowed' : 'Blocked',
                    color: _notificationsAllowed
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    icon: Icons.notifications_active_outlined,
                    extra:
                        'Permission status: ${_notificationsAllowed ? "Granted" : "Denied"}',
                  ),
                  _debugStatusCard(
                    label: 'Background Assistant',
                    status: _assistantModeEnabled ? 'Running' : 'Stopped',
                    color: _assistantModeEnabled
                        ? Colors.greenAccent
                        : Colors.white38,
                    icon: Icons.hearing_outlined,
                    extra:
                        'Wife Mode: $_proactiveEnabled | Foreground: $_isInForeground',
                  ),
                  _debugStatusCard(
                    label: 'Chat Memory',
                    status:
                        '${_messages.length} / ${_ChatHomePageState._maxConversationMessages} msgs',
                    color: _messages.isEmpty ? Colors.grey : Colors.greenAccent,
                    icon: Icons.chat_bubble_outline,
                    extra: 'Notif history: ${_notifHistory.length} items',
                  ),
                  _debugStatusCard(
                    label: 'Idle Timer',
                    status:
                        _idleTimer?.isActive == true ? 'Active' : 'Inactive',
                    color: _idleTimer?.isActive == true
                        ? Colors.greenAccent
                        : Colors.white38,
                    icon: Icons.timer_outlined,
                    extra:
                        'Idle: ${_idleDurationSeconds}s | Check-in: ${_proactiveIntervalSeconds}s',
                  ),
                  const SizedBox(height: 20),
                  Text('ACTIONS',
                      style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 11,
                          letterSpacing: 2)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _debugActionBtn('Test Wake', Icons.record_voice_over,
                          () => _testTriggerWakeWord()),
                      _debugActionBtn(
                          'Test TTS',
                          Icons.volume_up,
                          () => _speakAssistantText(
                              "Hello Darling, systems online!")),
                      _debugActionBtn('Test Wife Msg', Icons.favorite,
                          () => _sendProactiveBackgroundNotification()),
                      _debugActionBtn('Check API', Icons.cloud_done_outlined,
                          () async {
                        _checkApiKey();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('API Status: $_apiKeyStatus'),
                              duration: const Duration(seconds: 2)));
                        }
                      }),
                      _debugActionBtn(
                          'Reinit Wake', Icons.refresh, () => _initWakeWord()),
                      _debugActionBtn('Wake Debug', Icons.bug_report,
                          () => Navigator.pushNamed(context, '/wake-debug')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: double.infinity,
        height: 250,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'bll2.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.08),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'System Monitor',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Realtime engine state and quick tests',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _debugStatusCard({
    required String label,
    required String status,
    required Color color,
    required IconData icon,
    String? extra,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                if (extra != null)
                  Text(extra,
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(status,
                style: GoogleFonts.outfit(
                    color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _debugActionBtn(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _testTriggerWakeWord() {
    _wakeWordService.testTriggerByIndex(0);
  }
}
