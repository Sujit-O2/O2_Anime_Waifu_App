part of '../main.dart';

extension _MainDebugExtension on _ChatHomePageState {
// ── Page: Debug ──────────────────────────────────────────────────────────────

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
            child: Text('All features — live status & quick tests',
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
                  // ── FEATURE STATUS ──────────────────────────────────────────
                  _debugSectionLabel('FEATURE STATUS'),
                  const SizedBox(height: 10),

                  _debugStatusCard(
                    label: 'Wake Word Engine',
                    status: _wakeWordActivationLimitHit
                        ? 'Limit Hit'
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
                    extra:
                        'Enabled: $_wakeWordEnabledByUser | Running: ${_wakeWordService.isRunning}',
                  ),

                  _debugStatusCard(
                    label: 'STT (Microphone)',
                    status: _speechService.listening ? 'Listening' : 'Idle',
                    color: _speechService.listening
                        ? Colors.greenAccent
                        : Colors.white54,
                    icon: Icons.mic,
                    extra:
                        'Auto Listen: $_isAutoListening | Manual: $_isManualMicSession',
                  ),

                  _debugStatusCard(
                    label: 'TTS (Voice)',
                    status: _isSpeaking ? 'Speaking' : 'Idle',
                    color: _isSpeaking ? Colors.orangeAccent : Colors.white54,
                    icon: Icons.volume_up_outlined,
                    extra:
                        'Voice: ${_devTtsVoiceOverride.isNotEmpty ? _devTtsVoiceOverride : "aisha"} | Dual: $_dualVoiceEnabled',
                  ),

                  _debugStatusCard(
                    label: 'AI / API',
                    status: _apiKeyStatus,
                    color: _apiKeyStatus == 'Systems Online'
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    icon: Icons.cloud_outlined,
                    extra:
                        'Model: ${_devModelOverride.isNotEmpty ? _devModelOverride : "kimi-k2-instruct"} | Busy: $_isBusy',
                  ),

                  _debugStatusCard(
                    label: 'Notifications',
                    status: _notificationsAllowed ? 'Allowed' : 'Blocked',
                    color: _notificationsAllowed
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    icon: Icons.notifications_active_outlined,
                    extra:
                        'In-App: ${_showInAppNotif ? "Visible" : "Hidden"} | History: ${_notifHistory.length} items',
                  ),

                  _debugStatusCard(
                    label: 'Background Assistant',
                    status: _assistantModeEnabled ? 'Running' : 'Stopped',
                    color: _assistantModeEnabled
                        ? Colors.greenAccent
                        : Colors.white38,
                    icon: Icons.hearing_outlined,
                    extra:
                        'Foreground: $_isInForeground | Wake BG: $_backgroundWakeEnabled',
                  ),

                  _debugStatusCard(
                    label: 'Wife Mode (Proactive)',
                    status: _proactiveEnabled ? 'Active' : 'Disabled',
                    color:
                        _proactiveEnabled ? Colors.pinkAccent : Colors.white38,
                    icon: Icons.favorite,
                    extra:
                        'Mode: ${_proactiveRandomEnabled ? "Random" : "Manual interval ${_proactiveIntervalSeconds}s"}',
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
                        'Timeout: ${_idleDurationSeconds}s | Enabled: $_idleTimerEnabled | Blocked: $_idleBlockedUntilUserMessage',
                  ),

                  _debugStatusCard(
                    label: 'Dual Voice',
                    status: _dualVoiceEnabled ? 'Enabled' : 'Disabled',
                    color:
                        _dualVoiceEnabled ? Colors.cyanAccent : Colors.white38,
                    icon: Icons.record_voice_over_outlined,
                    extra:
                        'Secondary: $_dualVoiceSecondary | Turn: $_dualVoiceTurn',
                  ),

                  _debugStatusCard(
                    label: 'Lite Mode',
                    status: _liteModeEnabled ? 'On' : 'Off',
                    color:
                        _liteModeEnabled ? Colors.amberAccent : Colors.white38,
                    icon: Icons.speed_outlined,
                    extra: 'Reduces animations and background effects',
                  ),

                  _debugStatusCard(
                    label: 'Outfit Picker',
                    status: _selectedOutfit.split('/').last,
                    color: Colors.purpleAccent,
                    icon: Icons.image_outlined,
                    extra:
                        'Custom chat: ${_chatImageFromSystem ? "Yes" : "No"} | Custom icon: ${_appIconFromCustom ? "Yes" : "No"}',
                  ),

                  _debugStatusCard(
                    label: 'Chat Memory',
                    status:
                        '${_messages.length} / ${_ChatHomePageState._maxConversationMessages} msgs',
                    color: _messages.isEmpty ? Colors.grey : Colors.greenAccent,
                    icon: Icons.chat_bubble_outline,
                    extra:
                        'User msgs: $_userMessageCount | Payload cap: ${_ChatHomePageState._maxPayloadMessages}',
                  ),

                  _debugStatusCard(
                    label: 'Wake Word Suspend',
                    status: _suspendWakeWord ? 'Suspended' : 'Running',
                    color: _suspendWakeWord
                        ? Colors.orangeAccent
                        : Colors.greenAccent,
                    icon: Icons.pause_circle_outline,
                    extra:
                        'Pending reply: $_pendingReplyDispatch | Needs voice: $_pendingReplyNeedsVoice',
                  ),

                  _debugStatusCard(
                    label: 'App Lifecycle',
                    status: _appLifecycleState.name.toUpperCase(),
                    color: _appLifecycleState == AppLifecycleState.resumed
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    icon: Icons.phone_android_outlined,
                    extra: 'Nav tab index: $_navIndex',
                  ),

                  _debugStatusCard(
                    label: 'New Settings',
                    status:
                        'Timestamps: ${_showMessageTimestamps ? "On" : "Off"}',
                    color: _showMessageTimestamps
                        ? Colors.greenAccent
                        : Colors.white38,
                    icon: Icons.access_time_outlined,
                    extra:
                        'Haptic: ${_hapticFeedbackEnabled ? "On" : "Off"} | Auto-Scroll: ${_autoScrollChat ? "On" : "Off"}',
                  ),

                  _debugStatusCard(
                    label: 'Response Length',
                    status: _responseLengthMode,
                    color: _responseLengthMode == 'Detailed'
                        ? Colors.cyanAccent
                        : _responseLengthMode == 'Short'
                            ? Colors.amberAccent
                            : Colors.white54,
                    icon: Icons.short_text,
                    extra:
                        'Chat Text Size: $_chatTextSize | Mode wired into system prompt',
                  ),

                  _debugStatusCard(
                    label: 'Dev Config Overrides',
                    status: (_devApiKeyOverride.isNotEmpty ||
                            _devModelOverride.isNotEmpty ||
                            _devApiUrlOverride.isNotEmpty ||
                            _devSystemQuery.isNotEmpty)
                        ? 'Overrides Active'
                        : 'Using Defaults',
                    color: (_devApiKeyOverride.isNotEmpty ||
                            _devModelOverride.isNotEmpty ||
                            _devApiUrlOverride.isNotEmpty ||
                            _devSystemQuery.isNotEmpty)
                        ? Colors.orangeAccent
                        : Colors.white38,
                    icon: Icons.tune_rounded,
                    extra:
                        'TTS: ${_devTtsVoiceOverride.isNotEmpty ? _devTtsVoiceOverride : "default"} | Wake: ${_devWakeKeyOverride.isNotEmpty ? "Custom" : "Default"}',
                  ),

                  _debugStatusCard(
                    label: 'Video Player',
                    status: 'Available',
                    color: Colors.tealAccent,
                    icon: Icons.play_circle_outline,
                    extra:
                        'Episodes: ready | Landscape: supported | Speed cycle: enabled',
                  ),

                  _debugStatusCard(
                    label: 'AI Persona',
                    status: _selectedPersona,
                    color: Colors.pinkAccent,
                    icon: Icons.theater_comedy_rounded,
                    extra: 'Affects system prompt greeting + tone',
                  ),

                  _debugStatusCard(
                    label: 'Sleep Mode',
                    status: _sleepModeEnabled ? 'Enabled' : 'Disabled',
                    color: _sleepModeEnabled
                        ? Colors.indigoAccent
                        : Colors.white38,
                    icon: Icons.nightlight_round,
                    extra: _isSleepTime
                        ? '🌙 Currently in sleep window (midnight–7AM) — TTS muted'
                        : 'Not in sleep window right now',
                  ),

                  _debugStatusCard(
                    label: 'Memory Service',
                    status: _cachedMemoryBlock.isEmpty ? 'Empty' : 'Has facts',
                    color: _cachedMemoryBlock.isEmpty
                        ? Colors.white38
                        : Colors.purpleAccent,
                    icon: Icons.psychology_rounded,
                    extra: 'Facts injected into system prompt each request',
                  ),

                  _debugStatusCard(
                    label: 'Image Attach (Vision)',
                    status:
                        _selectedImage != null ? 'Image selected' : 'No image',
                    color: _selectedImage != null
                        ? Colors.orangeAccent
                        : Colors.white38,
                    icon: Icons.image_outlined,
                    extra: _selectedImage != null
                        ? 'Path: ${_selectedImage!.path.split('/').last}'
                        : 'Tap 📎 in chat input to attach',
                  ),

                  _debugStatusCard(
                    label: 'API Key Rotation',
                    status: 'Round-robin active',
                    color: Colors.greenAccent,
                    icon: Icons.vpn_key_rounded,
                    extra: 'Comma-separate up to 5 keys in .env API_KEY field',
                  ),

                  _debugStatusCard(
                    label: 'Weather API',
                    status: WeatherService.isConfigured
                        ? 'Configured ✅'
                        : 'Key missing ❌',
                    color: WeatherService.isConfigured
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    icon: Icons.cloud_outlined,
                    extra: WeatherService.isConfigured
                        ? 'OPENWEATHER_API_KEY set in .env'
                        : 'Add OPENWEATHER_API_KEY to .env file',
                  ),

                  // ── NEW FEATURES STATUS ────────────────────────────────────
                  _debugStatusCard(
                    label: '🎵 Music Player',
                    status: MusicPlayerService().currentSong.value != null
                        ? (MusicPlayerService().isPlaying.value
                            ? 'Playing'
                            : 'Paused')
                        : 'Idle',
                    color: MusicPlayerService().isPlaying.value
                        ? Colors.purpleAccent
                        : Colors.white38,
                    icon: Icons.music_note_rounded,
                    extra: MusicPlayerService().currentSong.value != null
                        ? 'Now: ${MusicPlayerService().currentSong.value!.title}'
                        : 'Library: ${MusicPlayerService().songList.value.length} songs loaded',
                  ),

                  _debugStatusCard(
                    label: '⏰ Waifu Alarm',
                    status: 'Ready',
                    color: Colors.orangeAccent,
                    icon: Icons.alarm_rounded,
                    extra:
                        'Say "Wake me up at 7 AM" to set. android_alarm_manager_plus',
                  ),

                  _debugStatusCard(
                    label: '📞 Contacts Lookup',
                    status: 'Available',
                    color: Colors.greenAccent,
                    icon: Icons.contacts_rounded,
                    extra:
                        'Say "Who is [name]?" — requires READ_CONTACTS permission',
                  ),

                  _debugStatusCard(
                    label: '🖼️ AI Drawing',
                    status: 'Online',
                    color: Colors.cyanAccent,
                    icon: Icons.auto_fix_high_rounded,
                    extra:
                        'Say "Draw me a cat" — Uses Pollinations.ai (no API key needed)',
                  ),

                  _debugStatusCard(
                    label: '🎮 Mini-Games',
                    status: MiniGameService.hasPendingTTT()
                        ? 'Tic-Tac-Toe Active'
                        : 'Ready',
                    color: MiniGameService.hasPendingTTT()
                        ? Colors.amberAccent
                        : Colors.white54,
                    icon: Icons.games_rounded,
                    extra: 'Rock-Paper-Scissors · Tic-Tac-Toe · Anime Trivia',
                  ),

                  _debugStatusCard(
                    label: '🔎 Chat Search',
                    status: _isChatSearchActive ? 'Active' : 'Hidden',
                    color: _isChatSearchActive ? Colors.blue : Colors.white38,
                    icon: Icons.search_rounded,
                    extra: 'Tap SEARCH chip in chat header to activate',
                  ),

                  _debugStatusCard(
                    label: '⚔️ Quests Service',
                    status: 'Active',
                    color: Colors.pinkAccent,
                    icon: Icons.flag_circle_outlined,
                    extra:
                        'Total daily quests: ${QuestsService.instance.dailyQuests.length}',
                  ),

                  _debugStatusCard(
                    label: '📱 Home Widgets',
                    status: 'Active',
                    color: Colors.lightBlueAccent,
                    icon: Icons.widgets_rounded,
                    extra:
                        'Real-time data pushing enabled via HomeWidgetService',
                  ),

                  _debugStatusCard(
                    label: '💾 Local Storage',
                    status: 'Ready',
                    color: Colors.deepPurpleAccent,
                    icon: Icons.storage_rounded,
                    extra:
                        'All SharedPreferences data is synced correctly across app instances',
                  ),

                  _debugStatusCard(
                    label: '🛠️ Build Compiler Notes',
                    status: 'Safe',
                    color: Colors.greenAccent,
                    icon: Icons.verified_user_rounded,
                    extra:
                        'Android intent warnings (-Xlint:unchecked) are harmless library notices',
                  ),

                  const SizedBox(height: 20),

                  // ── ACTION BUTTONS ──────────────────────────────────────────
                  _debugSectionLabel('TESTS & ACTIONS'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Wake Word
                      _debugActionBtn('Test Wake', Icons.record_voice_over,
                          () => _testTriggerWakeWord()),
                      _debugActionBtn(
                          'Reinit Wake', Icons.refresh, () => _initWakeWord()),
                      _debugActionBtn('Wake Debug', Icons.bug_report,
                          () => Navigator.pushNamed(context, '/wake-debug')),

                      // System Tests
                      _debugActionBtn(
                          'Simulate Exception',
                          Icons.warning_amber_rounded,
                          () => throw Exception(
                              'Simulated test exception from Debug page')),
                      _debugActionBtn(
                          'Trigger Battery Intent', Icons.battery_alert_rounded,
                          () async {
                        try {
                          await const MethodChannel(
                                  'anime_waifu/assistant_mode')
                              .invokeMethod('triggerBatteryIntent');
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Battery intent error: $e')));
                          }
                        }
                      }),

                      // TTS
                      _debugActionBtn(
                          'Test TTS',
                          Icons.volume_up,
                          () => _speakAssistantText(
                              "Hello Darling, all systems online!")),
                      _debugActionBtn('Stop TTS', Icons.volume_off,
                          () => _ttsService.stop()),

                      // API
                      _debugActionBtn('Check API', Icons.cloud_done_outlined,
                          () async {
                        _checkApiKey();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('API: $_apiKeyStatus'),
                              duration: const Duration(seconds: 2)));
                        }
                      }),

                      // Notifications
                      _debugActionBtn('Test Notif', Icons.notifications_active,
                          () => _sendProactiveBackgroundNotification()),
                      _debugActionBtn('Quick Test Notif', Icons.bolt_rounded,
                          () {
                        final testMessages = [
                          'Miss me, honey? 💕',
                          'Darling, come back to me~',
                          'I\'m waiting for you~ 🌸',
                          'Don\'t forget about me, okay? 😤',
                        ];
                        final msg = testMessages[
                            DateTime.now().millisecond % testMessages.length];
                        updateState(() {
                          _notifHistory.insert(0, {
                            'msg': msg,
                            'ts': DateTime.now().toIso8601String(),
                          });
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(children: [
                              const Icon(Icons.notifications_active,
                                  color: Colors.pinkAccent, size: 16),
                              const SizedBox(width: 8),
                              Text('Test notification added!',
                                  style: GoogleFonts.outfit(fontSize: 12)),
                            ]),
                            backgroundColor: Colors.black87,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }),
                      _debugActionBtn(
                          'Show In-App Notif',
                          Icons.announcement_outlined,
                          () => _showInAppNotificationPopup(
                              "Test in-app notification!")),
                      _debugActionBtn(
                          'Clear Notif History',
                          Icons.delete_sweep_outlined,
                          () => _clearNotifHistory()),

                      // Idle / Proactive
                      _debugActionBtn('Send Wife Msg', Icons.favorite,
                          () => _sendProactiveBackgroundNotification()),
                      _debugActionBtn(
                          'Trigger Idle', Icons.timer, () => _onIdleTimeout()),

                      // Memory
                      _debugActionBtn('Clear Chat', Icons.delete_outline,
                          () => unawaited(_clearMemory())),

                      // New Settings Quick Actions
                      _debugActionBtn('Toggle Timestamps', Icons.access_time,
                          () => _toggleShowTimestamps()),
                      _debugActionBtn('Toggle Haptics', Icons.vibration,
                          () => _toggleHapticFeedback()),
                      _debugActionBtn(
                          'Toggle Auto-Scroll',
                          Icons.vertical_align_bottom,
                          () => _toggleAutoScrollChat()),
                      _debugActionBtn('Cycle Response Length', Icons.short_text,
                          () {
                        final modes = ['Normal', 'Short', 'Detailed'];
                        final next = modes[
                            (modes.indexOf(_responseLengthMode) + 1) %
                                modes.length];
                        _setResponseLength(next);
                      }),
                      _debugActionBtn('Cycle Text Size', Icons.text_fields, () {
                        final sizes = ['Medium', 'Small', 'Large'];
                        final next = sizes[
                            (sizes.indexOf(_chatTextSize) + 1) % sizes.length];
                        _setChatTextSize(next);
                      }),
                      _debugActionBtn('Quick Test Notif', Icons.bolt_rounded,
                          () {
                        updateState(() {
                          _notifHistory.insert(0, {
                            'msg': 'Debug test: System check-in complete! 💕',
                            'ts': DateTime.now().toIso8601String(),
                          });
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test notification injected'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }),
                      // Feature Tests
                      _debugActionBtn('Test Weather', Icons.cloud_rounded,
                          () async {
                        final result =
                            await WeatherService.getWeather('Bhubaneswar');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(result),
                              duration: const Duration(seconds: 4)));
                        }
                      }),
                      _debugActionBtn(
                          'Toggle Sleep Mode',
                          Icons.nightlight_round,
                          () => _setSleepMode(!_sleepModeEnabled)),
                      _debugActionBtn(
                          'Cycle Persona', Icons.theater_comedy_rounded, () {
                        final personas = [
                          'Default',
                          'Tsundere',
                          'Shy',
                          'Yandere'
                        ];
                        final next = personas[
                            (personas.indexOf(_selectedPersona) + 1) %
                                personas.length];
                        _setPersona(next);
                      }),
                      _debugActionBtn(
                          'Refresh Memory', Icons.psychology_rounded, () async {
                        await _refreshMemoryCache();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(_cachedMemoryBlock.isEmpty
                                  ? 'Memory empty'
                                  : 'Memory refreshed: ${_cachedMemoryBlock.length} chars'),
                              duration: const Duration(seconds: 2)));
                        }
                      }),
                      _debugActionBtn(
                          'Reset Dev Config', Icons.settings_backup_restore,
                          () {
                        updateState(() {
                          _devApiKeyOverride = '';
                          _devModelOverride = '';
                          _devApiUrlOverride = '';
                          _devSystemQuery = '';
                          _devTtsVoiceOverride = '';
                          _devTtsApiKeyOverride = '';
                          _devTtsModelOverride = '';
                          _devWakeKeyOverride = '';
                          _devMailJetApiOverride = '';
                          _devMailJetSecOverride = '';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Dev config reset to defaults'),
                              duration: Duration(seconds: 2)),
                        );
                      }),

                      // ── NEW FEATURE TESTS ─────────────────────────────────
                      _debugActionBtn('🎵 Play Music', Icons.play_arrow_rounded,
                          () async {
                        final svc = MusicPlayerService();
                        await svc.init();
                        if (svc.songList.value.isNotEmpty) {
                          await svc.playSongAt(0);
                          if (mounted) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const MusicPlayerPage()));
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'No local music found on device')));
                          }
                        }
                      }),
                      _debugActionBtn('⏸️ Pause Music', Icons.pause_rounded,
                          () => MusicPlayerService().playPause()),
                      _debugActionBtn('🖼️ Test Draw', Icons.auto_fix_high,
                          () async {
                        final url = await ImageGenService.generateImage(
                                'anime cat girl') ??
                            'Error: null result';
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text((url).startsWith('http')
                                  ? '✅ Image: ${url.substring(0, url.length.clamp(0, 40))}...'
                                  : '❌ $url'),
                              duration: const Duration(seconds: 3)));
                        }
                      }),
                      _debugActionBtn('📞 Test Contacts', Icons.contacts,
                          () async {
                        final result =
                            await ContactsLookupService.findContact('John');
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(result)));
                        }
                      }),
                      _debugActionBtn('⏰ Test Alarm', Icons.alarm, () async {
                        final t =
                            DateTime.now().add(const Duration(minutes: 1));
                        final result =
                            await WaifuAlarmService.setAlarm(t, 'Zero Two');
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(result)));
                        }
                      }),
                      _debugActionBtn('🎮 RPS Game', Icons.sports_esports, () {
                        final r = MiniGameService.playRPS('rock');
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(r)));
                        }
                      }),
                      _debugActionBtn('🎮 Trivia', Icons.quiz_rounded, () {
                        final q = MiniGameService.getNextTrivia();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(q),
                              duration: const Duration(seconds: 5)));
                        }
                      }),
                      _debugActionBtn('📱 Refresh Widgets', Icons.sync_rounded,
                          () async {
                        await HomeWidgetService.forceUpdateAll();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'Sent force-refresh to all Android widgets!')));
                        }
                      }),
                      _debugActionBtn(
                          '💾 Check Storage', Icons.data_object_rounded,
                          () async {
                        final prefs = await SharedPreferences.getInstance();
                        final keys = prefs.getKeys().length;
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Preferences: $keys total keys stored in memory')));
                        }
                      }),
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

  Widget _debugSectionLabel(String label) {
    return Text(label,
        style: GoogleFonts.outfit(
            color: Colors.white38, fontSize: 11, letterSpacing: 2));
  }

  Widget _buildDebugHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: double.infinity,
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/gif/debug_area.gif',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.65),
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
                    '${_messages.length} msgs · ${_notifHistory.length} notifs · API: $_apiKeyStatus',
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
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
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
          color: Colors.white.withValues(alpha: 0.06),
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
