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
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                color: Colors.black.withValues(alpha: 0.12),
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
                  Colors.black.withValues(alpha: 0.20),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.50),
                ],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: _AboutFireflyLayer(),
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
                          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.24),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.30),
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
                                    _buildSectionTitle('PROJECT INFO'),
                                    const SizedBox(height: 12),
                                    _buildProjectInfoCard(),
                                    const SizedBox(height: 28),
                                    _buildSectionTitle('FEATURE SNAPSHOT'),
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const FeaturesPage(),
                                          ),
                                        );
                                      },
                                      child: _buildFeatureSnapshot(),
                                    ),
                                    const SizedBox(height: 28),
                                    _buildSectionTitle('NEW FEATURE GUIDE'),
                                    const SizedBox(height: 12),
                                    _buildFeatureGuideButton(),
                                    const SizedBox(height: 28),
                                    _buildSectionTitle('FEATURE COVERAGE'),
                                    const SizedBox(height: 12),
                                    _buildFeatureCoverageGraph(),
                                    const SizedBox(height: 28),
                                    _buildSectionTitle('RUNTIME GRAPH'),
                                    const SizedBox(height: 12),
                                    _buildRuntimeGraph(),
                                    const SizedBox(height: 28),
                                    _buildSectionTitle('SIGNAL FLOW'),
                                    const SizedBox(height: 12),
                                    _buildSignalFlowGraph(),
                                    const SizedBox(height: 28),
                                    _buildSectionTitle('CMD REFERENCE'),
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const CommandsPage(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.pinkAccent
                                                  .withValues(alpha: 0.10),
                                              Colors.purpleAccent
                                                  .withValues(alpha: 0.08),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.pinkAccent
                                                  .withValues(alpha: 0.35)),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.pinkAccent
                                                    .withValues(alpha: 0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.terminal_rounded,
                                                color: Colors.pinkAccent,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Example Commands',
                                                    style: GoogleFonts.outfit(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    'See all things your AI can do →',
                                                    style: GoogleFonts.outfit(
                                                        color: Colors.white54,
                                                        fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                                Icons.chevron_right_rounded,
                                                color: Colors.white38,
                                                size: 20),
                                          ],
                                        ),
                                      ),
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
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
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
        color: Colors.white.withValues(alpha: 0.04),
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
                  Expanded(
                    child: Text(
                      _projectGitHubUrl,
                      style: GoogleFonts.outfit(
                        color: Colors.cyanAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
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
        'Wake word toggle and 002 mode toggle',
        'Idle timer toggle with duration slider',
        'Check-in random/manual mode control with interval slider',
        'Clear chat memory and clear notification history actions',
        'Default behavior: idle enabled, random check-in mode enabled',
        'Notification and memory buffers capped for stable runtime usage',
      ]),
      _AboutFeatureSection('Utilities and Minigames', [
        'Gacha system for random Zero Two quotes',
        'Mood Tracker with persistent emotion history',
        'Secret Notes secured with local PIN code and XOR masking',
        'Pomodoro timer utilizing system alarms',
        'On-demand chat summary condensation via LLM',
        'Chat export to local .txt file using the native share sheet',
        'Instant translation through MyMemory API integration',
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

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSnapshotCard('Feature Groups', '${sections.length}',
                  Icons.dashboard_customize_outlined, Colors.cyanAccent),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSnapshotCard('Listed Features', '$totalFeatures',
                  Icons.list_alt_outlined, Colors.greenAccent),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSnapshotCard('Navigation Panels', '11',
                  Icons.space_dashboard, Colors.pinkAccent),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSnapshotCard(
                  'Runtime Flags',
                  '$activeRuntimeFlags/4',
                  Icons.speed_outlined,
                  Colors.orangeAccent),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureGuideButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => _FeatureGuideDialog(),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_book_rounded,
                  color: Colors.greenAccent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How To Use App Features',
                    style: GoogleFonts.outfit(
                      color: Colors.greenAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to view the full instruction guide',
                    style: GoogleFonts.outfit(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.greenAccent, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
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
        color: Colors.white.withValues(alpha: 0.04),
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
        color: Colors.white.withValues(alpha: 0.04),
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

    // Group flows logically for the tree
    final inputFlows = flows.sublist(0, 4);
    final brainFlows = flows.sublist(4, 9);
    final coreFlows = flows.sublist(9, 15);
    final uiFlows = flows.sublist(15, 20);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Solve pixel overflow on narrow screens
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _flowNode('WAKE', Icons.hearing, Colors.pinkAccent, 0.5),
                _flowArrow(0.5),
                _flowNode('STT', Icons.mic, Colors.cyanAccent, 0.5),
                _flowArrow(0.5),
                _flowNode('LLM', Icons.cloud_outlined, Colors.greenAccent, 0.5),
                _flowArrow(0.5),
                _flowNode(
                    'TTS', Icons.volume_up_outlined, Colors.orangeAccent, 0.5),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tree Root
          Row(
            children: [
              const Icon(Icons.hub_rounded, color: Colors.blueAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                'RUNTIME SIGNAL ARCHITECTURE',
                style: GoogleFonts.outfit(
                  color: Colors.blueAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildFlowGroup(
              'Input & Sensory Processing', Colors.cyanAccent, inputFlows),
          _buildFlowGroup(
              'Neural & Cognitive Routing', Colors.greenAccent, brainFlows),
          _buildFlowGroup(
              'Core Services & State Memory', Colors.purpleAccent, coreFlows),
          _buildFlowGroup(
              'UI, Media & Presentation', Colors.orangeAccent, uiFlows,
              isLast: true),
        ],
      ),
    );
  }

  Widget _buildFlowGroup(
      String title, Color color, List<_AboutSignalFlow> flows,
      {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(width: 1, height: 18, color: Colors.white24),
                Container(width: 14, height: 1, color: Colors.white24),
                if (!isLast)
                  Expanded(child: Container(width: 1, color: Colors.white24))
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            boxShadow: [
                              BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 6)
                            ]),
                      ),
                      const SizedBox(width: 7),
                      Text(title,
                          style: GoogleFonts.outfit(
                              color: color,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < flows.length; i++)
                          _buildFlowLeaf(flows[i],
                              isLast: i == flows.length - 1),
                      ],
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

  Widget _buildFlowLeaf(_AboutSignalFlow flow, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(width: 1, height: 16, color: Colors.white24),
                Container(width: 10, height: 1, color: Colors.white24),
                if (!isLast)
                  Expanded(child: Container(width: 1, color: Colors.white24))
                else
                  const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(
                      child: Text(flow.title,
                          style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: flow.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: flow.color.withValues(alpha: 0.4)),
                      ),
                      child: Text(flow.tag,
                          style: GoogleFonts.outfit(
                              color: flow.color.withValues(alpha: 0.9),
                              fontSize: 8,
                              fontWeight: FontWeight.w800)),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Text(flow.detail,
                      style: GoogleFonts.outfit(
                          color: Colors.white54, fontSize: 10, height: 1.3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _flowNode(String label, IconData icon, Color color, double pulse) {
    final borderOpacity = 0.30 + (pulse * 0.45);
    final fillOpacity = 0.10 + (pulse * 0.20);
    final iconScale = 1 + (pulse * 0.08);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: fillOpacity),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: borderOpacity)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.26 * pulse),
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
      color: Colors.white.withValues(alpha: 0.20 + (pulse * 0.62)),
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

class _Firefly {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double alphaBase;
  Color color;

  _Firefly({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.alphaBase,
    required this.color,
  });
}

class _AboutFireflyLayer extends StatefulWidget {
  const _AboutFireflyLayer();

  @override
  State<_AboutFireflyLayer> createState() => _AboutFireflyLayerState();
}

class _AboutFireflyLayerState extends State<_AboutFireflyLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Firefly> _fireflies = [];
  Offset? _touchPos;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )
      ..addListener(_updateParticles)
      ..repeat();
  }

  void _initParticles(Size size) {
    if (_fireflies.isNotEmpty) return;
    final random = math.Random();
    const colors = [
      Colors.amberAccent,
      Colors.orangeAccent,
      Colors.deepOrangeAccent
    ];
    for (int i = 0; i < 40; i++) {
      _fireflies.add(_Firefly(
        x: random.nextDouble() * size.width,
        y: random.nextDouble() * size.height,
        vx: (random.nextDouble() - 0.5) * 0.5,
        vy: -0.2 - random.nextDouble() * 0.8,
        size: 1.5 + random.nextDouble() * 2.5,
        alphaBase: 0.2 + random.nextDouble() * 0.6,
        color: colors[random.nextInt(colors.length)],
      ));
    }
  }

  void _updateParticles() {
    if (_fireflies.isEmpty) return;
    final size = MediaQuery.of(context).size;

    for (final f in _fireflies) {
      // Normal drift
      f.x += f.vx;
      f.y += f.vy;

      // Interaction
      if (_touchPos != null) {
        final dx = f.x - _touchPos!.dx;
        final dy = f.y - _touchPos!.dy;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < 120) {
          final force = (120 - dist) / 120;
          f.x += (dx / dist) * force * 5.0;
          f.y += (dy / dist) * force * 5.0;
        }
      }

      // Sine wobble
      f.x += math.sin(f.y * 0.02) * 0.3;

      // Wrap around
      if (f.y < -10) f.y = size.height + 10;
      if (f.x < -10) f.x = size.width + 10;
      if (f.x > size.width + 10) f.x = -10;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _initParticles(Size(constraints.maxWidth, constraints.maxHeight));
        return GestureDetector(
          onPanUpdate: (d) => _touchPos = d.localPosition,
          onPanEnd: (_) => _touchPos = null,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => CustomPaint(
              painter: _AboutFireflyPainter(
                  t: _controller.value, fireflies: _fireflies),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }
}

class _AboutFireflyPainter extends CustomPainter {
  final double t;
  final List<_Firefly> fireflies;
  const _AboutFireflyPainter({required this.t, required this.fireflies});

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    final core = Paint()..style = PaintingStyle.fill;

    for (final f in fireflies) {
      // Twinkle effect
      final twinkle = 0.5 + 0.5 * math.sin((t * math.pi * 20) + (f.x + f.y));
      final alpha = (f.alphaBase * twinkle).clamp(0.0, 1.0);

      glow.color = f.color.withValues(alpha: alpha * 0.6);
      core.color = Colors.white.withValues(alpha: alpha);

      canvas.drawCircle(Offset(f.x, f.y), f.size * 2, glow);
      canvas.drawCircle(Offset(f.x, f.y), f.size, core);
    }
  }

  @override
  bool shouldRepaint(covariant _AboutFireflyPainter oldDelegate) => true;
}

class _FeatureGuideDialog extends StatelessWidget {
  const _FeatureGuideDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: const Color(0xFF161618),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Feature Guide',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildFeatureItem(
                    icon: Icons.timer,
                    color: Colors.redAccent,
                    title: 'Pomodoro Timer',
                    description:
                        'A focus timer that sets a system alarm for you.',
                    howTo:
                        'Tap the mic and say: "Start a 25 minute pomodoro" or "Set a focus timer for 30 minutes".',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.summarize,
                    color: Colors.blueAccent,
                    title: 'Conversation Summary',
                    description: 'Let the AI recap the chat history for you.',
                    howTo:
                        'Tap the mic and say: "Summarize our conversation" or "What were we just talking about?".',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.file_download,
                    color: Colors.greenAccent,
                    title: 'Chat Export',
                    description: 'Save your memories to a local text file.',
                    howTo:
                        'Tap the mic and say: "Export the chat history" or "Save our conversation".',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.content_paste,
                    color: Colors.orangeAccent,
                    title: 'Clipboard Assistant',
                    description: 'Have the AI read what you recently copied.',
                    howTo:
                        'Tap the mic and say: "What did I copy?" or "Read my clipboard".',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.sms,
                    color: Colors.pinkAccent,
                    title: 'SMS Reader',
                    description:
                        'Have the AI securely read your latest text messages.',
                    howTo:
                        'Tap the mic and say: "Read my last SMS" or "Check my texts".',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.person_pin_circle,
                    color: Colors.cyanAccent,
                    title: 'Persona Switcher',
                    description: 'Change the AI\'s personality and TTS voice.',
                    howTo:
                        'Open Settings -> AI PERSONA -> Select Personality. Choose between Zero Two, Rem, Miku, or Custom.',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.lock,
                    color: Colors.purpleAccent,
                    title: 'Secret Notes',
                    description:
                        'A private vault where you can securely store personal information the AI can remember.',
                    howTo:
                        'Open Settings -> APPS & TOOLS -> Secret Notes (or say "Open my notes").',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.casino,
                    color: Colors.amberAccent,
                    title: 'Gacha Minigame',
                    description:
                        'A fun minigame to get random iconic anime quotes.',
                    howTo:
                        'Open Settings -> APPS & TOOLS -> Gacha Quotes (Or say "Roll a quote").',
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: Icons.mood,
                    color: Colors.tealAccent,
                    title: 'Mood Tracker',
                    description: 'Keep a daily journal of your emotions.',
                    howTo:
                        'Open Settings -> APPS & TOOLS -> Mood Tracker (Or say "Track my mood").',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required String howTo,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.mic, color: Colors.white54, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  howTo,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
