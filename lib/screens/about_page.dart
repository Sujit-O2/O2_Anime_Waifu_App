part of '../main.dart';

extension _AboutPageExtension on _ChatHomePageState {
  Widget _buildAboutPage() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/gif/background_of_about_section_blurry.gif',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.12),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.34),
                  Colors.black.withOpacity(0.56),
                  Colors.black.withOpacity(0.74),
                ],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: _AboutLightDropLayer(),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              _buildAboutHeader(),
              _buildHorizontalDivider(),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.24),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.18)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.30),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.zero,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 24, 16, 24),
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
                                    _buildSectionTitle('PROJECT INFO'),
                                    const SizedBox(height: 12),
                                    _buildProjectInfoCard(),
                                    const SizedBox(height: 28),
                                    _buildSectionTitle('FEATURE SNAPSHOT'),
                                    const SizedBox(height: 12),
                                    _buildFeatureSnapshot(),
                                    const SizedBox(height: 28),
                                    _buildSectionTitle(
                                        'FEATURE COVERAGE GRAPH'),
                                    const SizedBox(height: 12),
                                    _buildFeatureCoverageGraph(),
                                    const SizedBox(height: 28),
                                    _buildSectionTitle('FULL FEATURE LIST'),
                                    const SizedBox(height: 12),
                                    _buildFeatureCatalog(),
                                    const SizedBox(height: 28),
                                    _buildSectionTitle('RUNTIME GRAPH'),
                                    const SizedBox(height: 12),
                                    _buildRuntimeGraph(),
                                    const SizedBox(height: 28),
                                    _buildSectionTitle('ANIMATED SIGNAL FLOW'),
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
                                    _buildPathTile(
                                        'lib/load_wakeword_code.dart',
                                        'Wake-word service manager (Porcupine)'),
                                    _buildPathTile(
                                        'lib/screens/main_notifications.dart',
                                        'Notifications page and video player'),
                                    _buildPathTile(
                                        'lib/services/assistant_mode_service.dart',
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
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
            textAlign: TextAlign.center,
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
            textAlign: TextAlign.center,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.10),
            Colors.white.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: Colors.white.withOpacity(0.86),
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

  static const String _projectGitHubUrl =
      'https://github.com/Sujit-O2/O2_Anime_Waifu-Mobile-App';

  Future<void> _openProjectGitHub() async {
    final uri = Uri.parse(_projectGitHubUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open GitHub link.')),
    );
  }

  Widget _buildProjectInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Version', '02'),
          const SizedBox(height: 6),
          _buildInfoRow('Dev By', 'Sujit 02'),
          const SizedBox(height: 10),
          InkWell(
            onTap: _openProjectGitHub,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.link,
                    color: Colors.cyanAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _projectGitHubUrl,
                    style: GoogleFonts.outfit(
                      color: Colors.cyanAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label:',
          style: GoogleFonts.outfit(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  List<_AboutFeatureSection> _aboutFeatureSections() {
    return const [
      _AboutFeatureSection('Chat and Conversation', [
        'Persistent chat history with bounded memory window',
        'Typed input and voice-driven interaction',
        'Assistant replies appended to history and memory store',
        'State-aware one-shot idle prompt until next user message',
        'Animated list insertion for user and assistant turns',
        'Conversation payload trimming for predictable model context size',
      ]),
      _AboutFeatureSection('Wake, STT and TTS', [
        'Porcupine wake-word pipeline with runtime recovery',
        'Speech-to-text capture from wake trigger and manual mic',
        'Text-to-speech response playback',
        'Dual-voice mode with selectable secondary voice',
        'Auto-listen mode for continuous flow after response',
        'Wake watchdog timer to recover stopped wake listeners',
        'Speech status and error callbacks wired to runtime state',
      ]),
      _AboutFeatureSection('Background and Check-ins', [
        'Android foreground assistant service for proactive behavior',
        'Manual check-in interval and random check-in mode',
        'Background wake detection notification path',
        'Queued proactive messages restored into chat on resume',
        'Notification history panel with clear/remove actions',
        'Foreground/background awareness to shift assistant behavior',
        'Shared preference persistence for check-in configuration',
      ]),
      _AboutFeatureSection('Video and Media', [
        'Cloudinary episode loading via Admin API credentials',
        'Folder-based source filtering for episode discovery',
        'Transformed MP4 URL preference for stable playback',
        'Episode selector with in-app player controls',
        'Landscape fullscreen playback route',
        'Tap-to-toggle controls with 2-second auto-hide in landscape',
        'Playback resume position restored when exiting fullscreen',
      ]),
      _AboutFeatureSection('App Automation and Launch', [
        'Strict assistant action format for app launch commands',
        'Method-channel Android launch resolution',
        'Package, alias, and intent-based app opening strategies',
        'Case-insensitive app name handling',
        'Play Store fallback when direct launch path is unavailable',
      ]),
      _AboutFeatureSection('UI and Personalization', [
        'Multi-panel navigation: Chat, Themes, Dev Config, Notifications, Videos, Settings, Debug, About',
        'Fixed top image banners on control panels',
        'Image pack switching (code assets) and system image pick',
        'Chat-log assistant avatar rendering from current image source',
        'Launcher icon variant switch (old/new) on Android',
        'Theme mode persistence across app restarts',
        'Opening overlay animation with branded style',
      ]),
      _AboutFeatureSection('Developer and Debug Tools', [
        'Dev overrides for API key, model, endpoint, and prompt',
        'Debug status cards for wake, STT, TTS, API, and notifications',
        'Quick debug actions for wake and proactive test flows',
        'Runtime diagnostics and persisted feature toggles',
        'Wake-word debug route exposed through app navigation',
        'Verbose startup diagnostics in debug logging paths',
      ]),
      _AboutFeatureSection('Controls and Data', [
        'Wake word toggle and assistant mode toggle',
        'Idle timer toggle with duration slider',
        'Check-in random/manual mode control with interval slider',
        'Clear chat memory and clear notification history actions',
        'Default behavior: idle enabled, random check-in mode enabled',
        'Notification and memory buffers capped for stable runtime usage',
      ]),
      _AboutFeatureSection('Reliability and Safety', [
        'Mic and notification permission gating before sensitive actions',
        'Wake-word stop fallback when user disables wake mode',
        'Mount guards and async safety checks before setState calls',
        'Controller attach/detach lifecycle management for media playback',
        'Portrait orientation restoration after leaving landscape player',
      ]),
    ];
  }

  Widget _buildFeatureSnapshot() {
    final sections = _aboutFeatureSections();
    final totalFeatures = sections.fold<int>(
      0,
      (sum, section) => sum + section.items.length,
    );
    final activeRuntimeFlags = [
      _wakeWordService.isRunning,
      _assistantModeEnabled,
      _idleTimerEnabled,
      _notificationsAllowed,
    ].where((enabled) => enabled).length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildSnapshotCard('Feature Groups', '${sections.length}',
            Icons.dashboard_customize_outlined, Colors.cyanAccent),
        _buildSnapshotCard('Listed Features', '$totalFeatures',
            Icons.list_alt_outlined, Colors.greenAccent),
        _buildSnapshotCard(
            'Navigation Panels', '8', Icons.space_dashboard, Colors.pinkAccent),
        _buildSnapshotCard('Runtime Flags', '$activeRuntimeFlags/4',
            Icons.speed_outlined, Colors.orangeAccent),
      ],
    );
  }

  Widget _buildSnapshotCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      width: 184,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCoverageGraph() {
    final sections = _aboutFeatureSections();
    final maxFeaturesInGroup = sections
        .map((section) => section.items.length)
        .reduce((a, b) => a > b ? a : b);
    const palette = [
      Colors.cyanAccent,
      Colors.pinkAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.amberAccent,
      Colors.lightBlueAccent,
      Colors.redAccent,
      Colors.tealAccent,
      Colors.white70,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          for (int i = 0; i < sections.length; i++) ...[
            _buildAnimatedFeatureBar(
              label: sections[i].title,
              value: sections[i].items.length / maxFeaturesInGroup,
              color: palette[i % palette.length],
              trailing: '${sections[i].items.length} features',
              delayMs: i * 80,
            ),
            if (i != sections.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimatedFeatureBar({
    required String label,
    required double value,
    required Color color,
    required String trailing,
    required int delayMs,
  }) {
    final duration = 520 + delayMs;
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: duration),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      builder: (_, animatedValue, __) {
        final pct = (animatedValue * 100).clamp(0, 100).toInt();
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
                value: animatedValue,
                minHeight: 8,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        );
      },
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
    final flows = _aboutSignalFlows();
    return AnimatedBuilder(
      animation: _floatController,
      builder: (_, __) {
        final t = _floatController.value;
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
                  _flowNode('WAKE', Icons.hearing, Colors.pinkAccent,
                      _flowPulse(t, 0.05)),
                  _flowArrow(_flowPulse(t, 0.15)),
                  _flowNode(
                      'STT', Icons.mic, Colors.cyanAccent, _flowPulse(t, 0.25)),
                  _flowArrow(_flowPulse(t, 0.35)),
                  _flowNode('LLM', Icons.cloud_outlined, Colors.greenAccent,
                      _flowPulse(t, 0.45)),
                  _flowArrow(_flowPulse(t, 0.55)),
                  _flowNode('TTS', Icons.volume_up_outlined,
                      Colors.orangeAccent, _flowPulse(t, 0.65)),
                ],
              ),
              const SizedBox(height: 10),
              for (int i = 0; i < flows.length; i++)
                _buildFeatureSignalTrack(
                  flow: flows[i],
                  index: i,
                  progress: ((t + ((i * 0.071) % 1.0)) % 1.0).toDouble(),
                  pulse: _flowPulse(t, (i * 0.071) % 1.0),
                ),
              const SizedBox(height: 10),
              Text(
                '20 animated lanes: full runtime coverage from wake, input, memory, notifications, media, and diagnostics.',
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
      },
    );
  }

  Widget _buildFeatureSignalTrack({
    required _AboutSignalFlow flow,
    required int index,
    required double progress,
    required double pulse,
  }) {
    final borderOpacity = 0.14 + (pulse * 0.26);
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: flow.color.withOpacity(borderOpacity)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${(index + 1).toString().padLeft(2, '0')}.',
                style: GoogleFonts.outfit(
                  color: flow.color.withOpacity(0.90),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  flow.title,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.90),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                flow.tag,
                style: GoogleFonts.outfit(
                  color: flow.color.withOpacity(0.86),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            flow.detail,
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 10,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          _buildFeatureSignalBar(
            color: flow.color,
            progress: progress,
            pulse: pulse,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSignalBar({
    required Color color,
    required double progress,
    required double pulse,
  }) {
    const headWidth = 52.0;
    const barHeight = 7.0;
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    return LayoutBuilder(
      builder: (_, constraints) {
        final travel = math.max(0.0, constraints.maxWidth - headWidth);
        final rawX = travel * clampedProgress;
        final snappedX = _snapToDevicePixel(rawX);
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: barHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white10,
                          color.withOpacity(0.15),
                          Colors.white10,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: snappedX,
                  child: Container(
                    width: headWidth,
                    height: barHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          color.withOpacity(0.96),
                          color.withOpacity(0.66),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.44 + (pulse * 0.34)),
                          blurRadius: 10 + (pulse * 8),
                          spreadRadius: 0.5 + pulse,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _snapToDevicePixel(double value) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    if (dpr <= 0) return value;
    return (value * dpr).roundToDouble() / dpr;
  }

  double _flowPulse(double progress, double center) {
    final distance = (progress - center).abs();
    final wrappedDistance = math.min(distance, 1 - distance);
    final normalized =
        (1 - (wrappedDistance / 0.20)).clamp(0.0, 1.0).toDouble();
    return Curves.easeOut.transform(normalized);
  }

  Widget _flowNode(String label, IconData icon, Color color, double pulse) {
    final borderOpacity = 0.30 + (pulse * 0.45);
    final fillOpacity = 0.10 + (pulse * 0.20);
    final iconScale = 1 + (pulse * 0.08);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(fillOpacity),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(borderOpacity)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.26 * pulse),
            blurRadius: 10 + (pulse * 8),
            spreadRadius: pulse,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: iconScale,
            child: Icon(icon, color: color, size: 14),
          ),
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

  Widget _flowArrow(double pulse) {
    return Icon(
      Icons.arrow_forward,
      color: Colors.white.withOpacity(0.20 + (pulse * 0.62)),
      size: 14 + (pulse * 1.4),
    );
  }

  List<_AboutSignalFlow> _aboutSignalFlows() {
    return const [
      _AboutSignalFlow(
        title: 'Wake Engine Trigger',
        detail: 'Keyword detection wakes command path with cooldown guard.',
        tag: 'WAKE',
        color: Colors.pinkAccent,
      ),
      _AboutSignalFlow(
        title: 'Manual Mic Session',
        detail: 'Tap mic toggles live speech capture and stop/recover logic.',
        tag: 'MIC',
        color: Colors.cyanAccent,
      ),
      _AboutSignalFlow(
        title: 'Speech-To-Text Stream',
        detail: 'Partial and final transcripts are pushed to chat UI.',
        tag: 'STT',
        color: Colors.lightBlueAccent,
      ),
      _AboutSignalFlow(
        title: 'Text Input Pipeline',
        detail: 'Typed messages enter bounded memory and API payload context.',
        tag: 'TEXT',
        color: Colors.greenAccent,
      ),
      _AboutSignalFlow(
        title: 'System Prompt Injection',
        detail: 'Core behavior prompt is prepended on every completion call.',
        tag: 'PROMPT',
        color: Colors.orangeAccent,
      ),
      _AboutSignalFlow(
        title: 'LLM Completion',
        detail: 'Groq-compatible endpoint returns assistant content.',
        tag: 'LLM',
        color: Colors.amberAccent,
      ),
      _AboutSignalFlow(
        title: 'Action Dispatch',
        detail:
            'OPEN_APP actions are parsed and routed through Android intents.',
        tag: 'ACTION',
        color: Colors.redAccent,
      ),
      _AboutSignalFlow(
        title: 'Dual Voice TTS',
        detail: 'Replies can alternate between configured voice profiles.',
        tag: 'TTS',
        color: Colors.deepOrangeAccent,
      ),
      _AboutSignalFlow(
        title: 'Idle One-Shot Logic',
        detail: 'Single idle reply per user turn until next real message.',
        tag: 'IDLE',
        color: Colors.tealAccent,
      ),
      _AboutSignalFlow(
        title: 'Proactive Foreground Tick',
        detail: 'Periodic check-ins on non-chat screens when active.',
        tag: 'PROACTIVE',
        color: Colors.limeAccent,
      ),
      _AboutSignalFlow(
        title: 'Background Service',
        detail: 'Foreground service sustains proactive/wake loops off-screen.',
        tag: 'SERVICE',
        color: Colors.yellowAccent,
      ),
      _AboutSignalFlow(
        title: 'Notification Queue Persist',
        detail: 'Background messages are stored and deduplicated safely.',
        tag: 'QUEUE',
        color: Colors.purpleAccent,
      ),
      _AboutSignalFlow(
        title: 'Resume Drain To Chat',
        detail: 'Pending queue is restored back into local chat history.',
        tag: 'DRAIN',
        color: Colors.indigoAccent,
      ),
      _AboutSignalFlow(
        title: 'Conversation Memory Save',
        detail: 'Recent messages are persisted with rolling window control.',
        tag: 'MEMORY',
        color: Colors.blueGrey,
      ),
      _AboutSignalFlow(
        title: 'Image Source Switching',
        detail: 'Asset/system gallery sources swap for chat and app visuals.',
        tag: 'MEDIA',
        color: Colors.lightGreenAccent,
      ),
      _AboutSignalFlow(
        title: 'Theme Runtime Shader',
        detail: 'Dynamic particle/background/effect metadata by theme mode.',
        tag: 'THEME',
        color: Colors.cyan,
      ),
      _AboutSignalFlow(
        title: 'Video Episode Resolve',
        detail: 'Cloudinary IDs/URLs normalize to stable playback candidates.',
        tag: 'VIDEO',
        color: Colors.orange,
      ),
      _AboutSignalFlow(
        title: 'Landscape Control Layer',
        detail: 'Tap-to-toggle controls with timed auto-hide behavior.',
        tag: 'PLAYER',
        color: Colors.white70,
      ),
      _AboutSignalFlow(
        title: 'Permission Guard Rail',
        detail: 'Mic/notification permissions are checked before mode changes.',
        tag: 'PERM',
        color: Colors.green,
      ),
      _AboutSignalFlow(
        title: 'Runtime Debug Telemetry',
        detail:
            'Status cards expose wake, STT, TTS, API and notification state.',
        tag: 'DEBUG',
        color: Colors.blueAccent,
      ),
    ];
  }

  Widget _buildPathTile(String path, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.10),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            path,
            softWrap: true,
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
    final sections = _aboutFeatureSections();
    return Column(
      children: [
        for (int i = 0; i < sections.length; i++)
          _AboutStaggerReveal(
            delayMs: i * 70,
            child: _buildFeatureGroup(sections[i].title, sections[i].items),
          ),
      ],
    );
  }

  Widget _buildFeatureGroup(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.10),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
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

class _AboutFeatureSection {
  final String title;
  final List<String> items;

  const _AboutFeatureSection(this.title, this.items);
}

class _AboutSignalFlow {
  final String title;
  final String detail;
  final String tag;
  final Color color;

  const _AboutSignalFlow({
    required this.title,
    required this.detail,
    required this.tag,
    required this.color,
  });
}

class _AboutStaggerReveal extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const _AboutStaggerReveal({
    required this.child,
    this.delayMs = 0,
  });

  @override
  State<_AboutStaggerReveal> createState() => _AboutStaggerRevealState();
}

class _AboutStaggerRevealState extends State<_AboutStaggerReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class _AboutLightDropLayer extends StatefulWidget {
  const _AboutLightDropLayer();

  @override
  State<_AboutLightDropLayer> createState() => _AboutLightDropLayerState();
}

class _AboutLightDropLayerState extends State<_AboutLightDropLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _AboutLightDropPainter(t: _controller.value),
      ),
    );
  }
}

class _AboutLightDropPainter extends CustomPainter {
  final double t;
  const _AboutLightDropPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.5);
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const drops = 18;
    for (int i = 0; i < drops; i++) {
      final phase = ((i * 37) % 100) / 100.0;
      final xBase = size.width * (((i * 53) % 100) / 100.0);
      final x = (xBase + math.sin((t * math.pi * 2) + i) * 14)
          .clamp(8.0, size.width - 8.0);
      final y = ((t + phase) * (size.height + 220)) % (size.height + 220) - 120;
      final length = 28.0 + ((i * 19) % 22);
      final alpha = 0.16 + (((i * 29) % 70) / 320.0);
      final width = 1.6 + ((i % 3) * 0.65);

      glow
        ..strokeWidth = width * 3.1
        ..color = Colors.cyanAccent.withOpacity(alpha * 0.85);
      core
        ..strokeWidth = width
        ..color = Colors.white.withOpacity(alpha);

      final p1 = Offset(x, y);
      final p2 = Offset(x, y + length);
      canvas.drawLine(p1, p2, glow);
      canvas.drawLine(p1, p2, core);
    }
  }

  @override
  bool shouldRepaint(covariant _AboutLightDropPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}
