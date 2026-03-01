part of '../main.dart';

extension _AboutPageExtension on _ChatHomePageState {
  Widget _buildAboutPage() {
    return SafeArea(
      child: Column(
        children: [
          _buildAboutHeader(),
          _buildHorizontalDivider(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('SYSTEM STATUS'),
                    const SizedBox(height: 12),
                    _buildStatusGrid(),
                    const SizedBox(height: 28),
                    _buildSectionTitle('ABOUT O2-WAIFU'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'O2-WAIFU is a state-aware voice companion app. '
                      'It supports wake-word entry, typed chat, spoken replies, '
                      'background check-ins, and local memory persistence.',
                    ),
                    const SizedBox(height: 12),
                    _buildBullet(
                      'One-shot idle behavior on chat screen until next real user message.',
                    ),
                    _buildBullet(
                      'Foreground check-ins outside chat and background check-ins via Android service.',
                    ),
                    _buildBullet(
                      'Notification messages are persisted and drained back into chat history on resume.',
                    ),
                    _buildBullet(
                      'Cloudinary episode player with landscape playback and dynamic source loading.',
                    ),
                    const SizedBox(height: 28),
                    _buildSectionTitle('FULL FEATURE LIST'),
                    const SizedBox(height: 12),
                    _buildFeatureCatalog(),
                    const SizedBox(height: 28),
                    _buildSectionTitle('RUNTIME GRAPH'),
                    const SizedBox(height: 12),
                    _buildRuntimeGraph(),
                    const SizedBox(height: 28),
                    _buildSectionTitle('SIGNAL FLOW'),
                    const SizedBox(height: 12),
                    _buildSignalFlowGraph(),
                    const SizedBox(height: 28),
                    _buildSectionTitle('BACKGROUND LOGIC'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'When app is in background and assistant mode is enabled, '
                      'the foreground service continues scheduled check-ins. '
                      'Wake-word remains active if microphone permission is available. '
                      'In background, wake detection sends a notification and keeps wake engine active '
                      'instead of starting a full STT session outside the foreground UI.',
                    ),
                    const SizedBox(height: 28),
                    _buildSectionTitle('VIDEO DELIVERY'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'Episode playback can resolve from Cloudinary Admin API using your cloud name, '
                      'API key, API secret, and video folder. Source URLs are normalized to transformed '
                      'MP4 candidates for stable ExoPlayer playback.',
                    ),
                    const SizedBox(height: 28),
                    _buildSectionTitle('DEV REFERENCE'),
                    const SizedBox(height: 12),
                    _buildPathTile('lib/main.dart',
                        'App lifecycle, chat, wake/STT/TTS orchestration'),
                    _buildPathTile('lib/load_wakeword_code.dart',
                        'Wake-word service manager (Porcupine)'),
                    _buildPathTile('lib/screens/main_notifications.dart',
                        'Notifications page and video player'),
                    _buildPathTile('lib/services/assistant_mode_service.dart',
                        'Android method channel bridge'),
                    _buildPathTile(
                        'android/app/src/main/kotlin/com/example/anime_waifu/AssistantForegroundService.kt',
                        'Background proactive service and notifications'),
                    const SizedBox(height: 28),
                    _buildSectionTitle('BUILD INFO'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'Idle Timer: ${_idleTimerEnabled ? 'Enabled' : 'Disabled'} '
                      '(${_formatCheckInDuration(_idleDurationSeconds)})\n'
                      'Check-in Mode: ${_proactiveRandomEnabled ? 'Random' : 'Manual'} '
                      '(${_formatCheckInDuration(_proactiveIntervalSeconds)})\n'
                      'Assistant Mode: ${_assistantModeEnabled ? 'Enabled' : 'Disabled'}\n'
                      'API Status: $_apiKeyStatus',
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
      child: Column(
        children: [
          ClipOval(
            child: Image(
              image: _imageProviderFor(
                assetPath: _chatImageAsset,
                customPath: _effectiveChatCustomPath,
              ),
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 96,
                height: 96,
                color: Colors.white10,
                child: const Icon(Icons.face, color: Colors.white38, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'O2-WAIFU',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'STATE-AWARE VOICE COMPANION',
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalDivider() {
    return Container(
      height: 1,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.white10, Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 13,
        letterSpacing: 1.8,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildStatusGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _statusChip('Wake', _wakeWordService.isRunning ? 'ACTIVE' : 'IDLE',
            _wakeWordService.isRunning ? Colors.greenAccent : Colors.white38),
        _statusChip('Foreground', _isInForeground ? 'YES' : 'NO',
            _isInForeground ? Colors.cyanAccent : Colors.orangeAccent),
        _statusChip('Assistant', _assistantModeEnabled ? 'ON' : 'OFF',
            _assistantModeEnabled ? Colors.pinkAccent : Colors.white38),
        _statusChip('Idle Timer', _idleTimerEnabled ? 'ON' : 'OFF',
            _idleTimerEnabled ? Colors.orangeAccent : Colors.white38),
      ],
    );
  }

  Widget _statusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: Colors.white70,
          fontSize: 13,
          height: 1.55,
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, color: Colors.white38, size: 7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuntimeGraph() {
    final memoryRatio =
        (_messages.length / _ChatHomePageState._maxConversationMessages)
            .clamp(0.0, 1.0)
            .toDouble();
    final notifRatio = (_notifHistory.length / 100).clamp(0.0, 1.0).toDouble();
    final wakeRatio = _wakeWordService.isRunning ? 0.95 : 0.25;
    final assistantRatio = _assistantModeEnabled ? 0.88 : 0.35;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _graphBar('Wake Engine Activity', wakeRatio, Colors.greenAccent,
              _wakeWordService.isRunning ? 'running' : 'stopped'),
          const SizedBox(height: 10),
          _graphBar(
              'Assistant Background Mode',
              assistantRatio,
              Colors.pinkAccent,
              _assistantModeEnabled ? 'enabled' : 'disabled'),
          const SizedBox(height: 10),
          _graphBar('Conversation Buffer Usage', memoryRatio, Colors.cyanAccent,
              '${_messages.length}/${_ChatHomePageState._maxConversationMessages}'),
          const SizedBox(height: 10),
          _graphBar('Notification History Buffer', notifRatio,
              Colors.orangeAccent, '${_notifHistory.length}/100'),
        ],
      ),
    );
  }

  Widget _graphBar(String label, double value, Color color, String trailing) {
    final pct = (value * 100).clamp(0, 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$pct%  $trailing',
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildSignalFlowGraph() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _flowNode('WAKE', Icons.hearing, Colors.pinkAccent),
              _flowArrow(),
              _flowNode('STT', Icons.mic, Colors.cyanAccent),
              _flowArrow(),
              _flowNode('LLM', Icons.cloud_outlined, Colors.greenAccent),
              _flowArrow(),
              _flowNode('TTS', Icons.volume_up_outlined, Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Background branch: Notification + Queue -> Chat history on resume',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _flowNode(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _flowArrow() {
    return const Icon(Icons.arrow_forward, color: Colors.white30, size: 14);
  }

  Widget _buildPathTile(String path, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            path,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCatalog() {
    return Column(
      children: [
        _buildFeatureGroup('Chat and Conversation', [
          'Persistent chat history with bounded memory window',
          'Typed input and voice-driven interaction',
          'Assistant replies appended to history and memory store',
          'State-aware one-shot idle prompt until next user message',
        ]),
        _buildFeatureGroup('Wake, STT and TTS', [
          'Porcupine wake-word pipeline with runtime recovery',
          'Speech-to-text capture from wake trigger and manual mic',
          'Text-to-speech response playback',
          'Dual-voice mode with selectable secondary voice',
          'Auto-listen mode for continuous flow after response',
        ]),
        _buildFeatureGroup('Background and Check-ins', [
          'Android foreground assistant service for proactive behavior',
          'Manual check-in interval and random check-in mode',
          'Background wake detection notification path',
          'Queued proactive messages restored into chat on resume',
          'Notification history panel with clear/remove actions',
        ]),
        _buildFeatureGroup('Video and Media', [
          'Cloudinary episode loading via Admin API credentials',
          'Folder-based source filtering for episode discovery',
          'Transformed MP4 URL preference for stable playback',
          'Episode selector with in-app player controls',
          'Landscape fullscreen playback route',
        ]),
        _buildFeatureGroup('App Automation and Launch', [
          'Strict assistant action format for app launch commands',
          'Method-channel Android launch resolution',
          'Package, alias, and intent-based app opening strategies',
          'Case-insensitive app name handling',
        ]),
        _buildFeatureGroup('UI and Personalization', [
          'Multi-panel navigation: Chat, Themes, Dev Config, Notifications, Videos, Settings, Debug, About',
          'Fixed top image banners on control panels',
          'Image pack switching (code assets) and system image pick',
          'Chat-log assistant avatar rendering from current image source',
          'Launcher icon variant switch (old/new) on Android',
        ]),
        _buildFeatureGroup('Developer and Debug Tools', [
          'Dev overrides for API key, model, endpoint, and prompt',
          'Debug status cards for wake, STT, TTS, API, and notifications',
          'Quick debug actions for wake and proactive test flows',
          'Runtime diagnostics and persisted feature toggles',
        ]),
        _buildFeatureGroup('Controls and Data', [
          'Wake word toggle and assistant mode toggle',
          'Idle timer toggle with duration slider',
          'Check-in random/manual mode control with interval slider',
          'Clear chat memory and clear notification history actions',
          'Default behavior: idle enabled, random check-in mode enabled',
        ]),
      ],
    );
  }

  Widget _buildFeatureGroup(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in items) _buildBullet(item),
        ],
      ),
    );
  }
}
