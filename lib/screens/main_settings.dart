part of '../main.dart';

extension _MainSettingsExtension on _ChatHomePageState {
// —— Page: Settings ————————————————————————————————————————————————————————————————
  Widget _buildSettingsPage() {
    final primary = Theme.of(context).primaryColor;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('SETTINGS',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: _buildSettingsHero(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _settingsTile(
                    icon: Icons.hearing,
                    label: 'Wake Word',
                    subtitle: _wakeWordEnabledByUser
                        ? 'Listening for trigger words'
                        : 'Disabled',
                    value: _wakeWordEnabledByUser,
                    onChanged: (_) => _toggleWakeWordEnabled(),
                    activeColor: primary,
                  ),
                  _settingsTile(
                    icon: Icons.speed_rounded,
                    label: 'Lite Mode',
                    subtitle: _liteModeEnabled
                        ? 'Performance mode with reduced effects'
                        : 'Full visual effects',
                    value: _liteModeEnabled,
                    onChanged: (_) => _toggleLiteMode(),
                    activeColor: Colors.lightGreenAccent,
                  ),
                  _settingsTile(
                    icon: Icons.favorite,
                    label: 'Wife Mode',
                    subtitle: _proactiveEnabled
                        ? 'Zero Two will check up on you'
                        : 'Passive mode',
                    value: _proactiveEnabled,
                    onChanged: (_) => _toggleProactiveMode(),
                    activeColor: Colors.pinkAccent,
                  ),
                  _settingsTile(
                    icon: Icons.timer_outlined,
                    label: 'Idle Timer',
                    subtitle: _idleTimerEnabled
                        ? 'Check-in when you are quiet'
                        : 'Disabled',
                    value: _idleTimerEnabled,
                    onChanged: (_) => _toggleIdleTimer(),
                    activeColor: Colors.orangeAccent,
                  ),
                  if (_idleTimerEnabled)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'Idle (In-app): ${_formatCheckInDuration(_idleDurationSeconds)}',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white70, fontSize: 13)),
                              Text('Timer',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white24, fontSize: 11)),
                            ],
                          ),
                          Slider(
                            value: _idleDurationSeconds.toDouble(),
                            min: 60,
                            max: 3600,
                            divisions: 59,
                            onChanged: (v) => _updateIdleDuration(v.toInt()),
                            activeColor: Colors.orangeAccent,
                          ),
                        ],
                      ),
                    ),
                  if (_proactiveEnabled)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Check-in Mode',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white70, fontSize: 13)),
                              Text(
                                  _proactiveRandomEnabled
                                      ? 'Randomized'
                                      : 'Manual',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white24, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: Text('Manual',
                                    style: GoogleFonts.outfit(
                                      color: !_proactiveRandomEnabled
                                          ? Colors.black
                                          : Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    )),
                                selected: !_proactiveRandomEnabled,
                                selectedColor: Colors.redAccent,
                                backgroundColor: Colors.white10,
                                onSelected: (selected) {
                                  if (selected) {
                                    _setProactiveTimingMode(false);
                                  }
                                },
                              ),
                              ChoiceChip(
                                label: Text('Random',
                                    style: GoogleFonts.outfit(
                                      color: _proactiveRandomEnabled
                                          ? Colors.black
                                          : Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    )),
                                selected: _proactiveRandomEnabled,
                                selectedColor: Colors.redAccent,
                                backgroundColor: Colors.white10,
                                onSelected: (selected) {
                                  if (selected) {
                                    _setProactiveTimingMode(true);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (!_proactiveRandomEnabled) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    'Check-in (Background): ${_formatCheckInDuration(_proactiveIntervalSeconds)}',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white70, fontSize: 13)),
                                Text('Manual interval',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white24, fontSize: 11)),
                              ],
                            ),
                            Slider(
                              value: _proactiveIntervalSeconds.toDouble(),
                              min: 60,
                              max: 18000,
                              divisions: 299,
                              onChanged: (v) =>
                                  _updateProactiveInterval(v.toInt()),
                              activeColor: Colors.redAccent,
                            ),
                          ] else ...[
                            Text(
                              'Random pool: ${_proactiveRandomIntervalOptionsSeconds.map(_formatCheckInDuration).join(", ")}',
                              style: GoogleFonts.outfit(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Zero Two picks a different delay every cycle.',
                              style: GoogleFonts.outfit(
                                  color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
                  _settingsTile(
                    icon: Icons.hearing_outlined,
                    label: 'Background Assistant',
                    subtitle:
                        _assistantModeEnabled ? 'Running in background' : 'Off',
                    value: _assistantModeEnabled,
                    onChanged: (_) => _toggleAssistantMode(),
                    activeColor: Colors.redAccent,
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          color: Colors.lightGreenAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Grant Full Access',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Required for reliable background wake + popup mic',
                                style: GoogleFonts.outfit(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              unawaited(_grantFullAccessForBackgroundWake()),
                          child: Text(
                            'Grant',
                            style: GoogleFonts.outfit(
                              color: Colors.lightGreenAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _settingsTile(
                    icon: Icons.mic,
                    label: 'Auto Listen',
                    subtitle: _isAutoListening
                        ? 'Always listening after response'
                        : 'Manual mic only',
                    value: _isAutoListening,
                    onChanged: (_) => _toggleAutoListen(),
                    activeColor: primary,
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.mic_external_on_rounded,
                                color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'STT Engine',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _sttEngineMode == 'android'
                                  ? 'Android'
                                  : 'Current',
                              style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'STT only. TTS is unchanged.',
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text(
                                'Current (Default)',
                                style: GoogleFonts.outfit(
                                  color: _sttEngineMode == 'current'
                                      ? Colors.black
                                      : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              selected: _sttEngineMode == 'current',
                              selectedColor: Colors.tealAccent,
                              backgroundColor: Colors.white10,
                              onSelected: (selected) {
                                if (selected) {
                                  unawaited(_setSttEngineMode('current'));
                                }
                              },
                            ),
                            ChoiceChip(
                              label: Text(
                                'Android',
                                style: GoogleFonts.outfit(
                                  color: _sttEngineMode == 'android'
                                      ? Colors.black
                                      : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              selected: _sttEngineMode == 'android',
                              selectedColor: Colors.tealAccent,
                              backgroundColor: Colors.white10,
                              onSelected: (selected) {
                                if (selected) {
                                  unawaited(_setSttEngineMode('android'));
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _settingsTile(
                    icon: Icons.record_voice_over_outlined,
                    label: 'Dual Voice',
                    subtitle: _dualVoiceEnabled
                        ? 'Alternates between two voices'
                        : 'Single voice output',
                    value: _dualVoiceEnabled,
                    onChanged: (_) => _toggleDualVoice(),
                    activeColor: Colors.cyanAccent,
                  ),
                  if (_dualVoiceEnabled)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secondary Voice',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['alloy', 'lulwa', 'nova', 'echo']
                                .map(
                                  (voice) => ChoiceChip(
                                    label: Text(
                                      voice,
                                      style: GoogleFonts.outfit(
                                        color: _dualVoiceSecondary == voice
                                            ? Colors.black
                                            : Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    selected: _dualVoiceSecondary == voice,
                                    selectedColor: Colors.cyanAccent,
                                    backgroundColor: Colors.white10,
                                    onSelected: (selected) {
                                      if (selected) {
                                        _setDualVoiceSecondary(voice);
                                      }
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  _buildImagePackCard(),
                  const SizedBox(height: 16),
                  // ── NEW USER SETTINGS ─────────────────────────────────────
                  Text('CHAT & DISPLAY',
                      style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 11,
                          letterSpacing: 2)),
                  const SizedBox(height: 10),
                  _settingsTile(
                    icon: Icons.access_time_rounded,
                    label: 'Message Timestamps',
                    subtitle: _showMessageTimestamps
                        ? 'Time shown on each message'
                        : 'Timestamps hidden',
                    value: _showMessageTimestamps,
                    onChanged: (_) => _toggleShowTimestamps(),
                    activeColor: Colors.tealAccent,
                  ),
                  _settingsTile(
                    icon: Icons.vibration_rounded,
                    label: 'Haptic Feedback',
                    subtitle: _hapticFeedbackEnabled
                        ? 'Vibrates on AI response & wake'
                        : 'No vibration',
                    value: _hapticFeedbackEnabled,
                    onChanged: (_) => _toggleHapticFeedback(),
                    activeColor: Colors.purpleAccent,
                  ),
                  _settingsTile(
                    icon: Icons.picture_in_picture_alt_rounded,
                    label: 'Wake Popup',
                    subtitle: _wakePopupEnabled
                        ? 'Shows popup on wake detection'
                        : 'Popup off, notification only',
                    value: _wakePopupEnabled,
                    onChanged: (_) => _toggleWakePopupEnabled(),
                    activeColor: Colors.cyanAccent,
                  ),
                  _settingsTile(
                    icon: Icons.sync_alt_rounded,
                    label: 'Auto-Scroll Chat',
                    subtitle: _autoScrollChat
                        ? 'Scrolls down when new message arrives'
                        : 'Manual scroll',
                    value: _autoScrollChat,
                    onChanged: (_) => _toggleAutoScrollChat(),
                    activeColor: Colors.blueAccent,
                  ),
                  _settingsTile(
                    icon: Icons.music_note_rounded,
                    label: 'Sound on Wake',
                    subtitle: _soundOnWake
                        ? 'Plays a sound when wake word triggers'
                        : 'Silent wake activation',
                    value: _soundOnWake,
                    onChanged: (_) => unawaited(_toggleSoundOnWake()),
                    activeColor: Colors.deepOrangeAccent,
                  ),
                  _settingsTile(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'Show Chat Hint',
                    subtitle: _showChatHint
                        ? 'Shows a hint in the input box'
                        : 'Clean input field',
                    value: _showChatHint,
                    onChanged: (_) => unawaited(_toggleShowChatHint()),
                    activeColor: Colors.yellowAccent,
                  ),
                  // Wallpaper Brightness slider
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.brightness_6_rounded,
                                color: Colors.white54, size: 18),
                            const SizedBox(width: 8),
                            Text('Wallpaper Brightness',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(
                                '${(_wallpaperBrightness * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.outfit(
                                    color: Colors.amberAccent, fontSize: 11)),
                          ],
                        ),
                        Slider(
                          value: _wallpaperBrightness,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          onChanged: (v) {
                            unawaited(
                              _setWallpaperBrightness(v, persist: false),
                            );
                          },
                          onChangeEnd: (v) =>
                              unawaited(_setWallpaperBrightness(v)),
                          activeColor: Colors.amberAccent,
                          inactiveColor: Colors.white12,
                        ),
                        Text(
                          _wallpaperBrightness < 0.3
                              ? 'Very dark overlay'
                              : _wallpaperBrightness > 0.7
                                  ? 'Bright background'
                                  : 'Balanced overlay',
                          style: GoogleFonts.outfit(
                              color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.short_text_rounded,
                                color: Colors.white54, size: 18),
                            const SizedBox(width: 8),
                            Text('Response Length',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(_responseLengthMode,
                                style: GoogleFonts.outfit(
                                    color: Colors.amberAccent, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: ['Short', 'Normal', 'Detailed'].map((mode) {
                            final sel = _responseLengthMode == mode;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => _setResponseLength(mode),
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? Colors.amberAccent.withOpacity(0.2)
                                        : Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: sel
                                            ? Colors.amberAccent
                                            : Colors.white12),
                                  ),
                                  child: Text(mode,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                          color: sel
                                              ? Colors.amberAccent
                                              : Colors.white54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  // Chat Text Size chooser
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.format_size_rounded,
                                color: Colors.white54, size: 18),
                            const SizedBox(width: 8),
                            Text('Chat Text Size',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text('${_chatFontSize.toStringAsFixed(0)}px',
                                style: GoogleFonts.outfit(
                                    color: Colors.cyanAccent, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: ['Small', 'Medium', 'Large'].map((sz) {
                            final sel = _chatTextSize == sz;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => _setChatTextSize(sz),
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? Colors.cyanAccent.withOpacity(0.15)
                                        : Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: sel
                                            ? Colors.cyanAccent
                                            : Colors.white12),
                                  ),
                                  child: Text(sz,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                          color: sel
                                              ? Colors.cyanAccent
                                              : Colors.white54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text('DATA',
                      style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 11,
                          letterSpacing: 2)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _clearMemory,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Delete All Chat',
                                  style: GoogleFonts.outfit(
                                      color: Colors.redAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              Text('Clears conversation history',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _clearNotifHistory,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_off_outlined,
                              color: Colors.orangeAccent),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Clear Notification History',
                                  style: GoogleFonts.outfit(
                                      color: Colors.orangeAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                  '${_notifHistory.length} notifications stored',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildSettingsHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: double.infinity,
        height: 250,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/img/bg.png',
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
                    'Control Panel',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Wake, idle and check-in behavior',
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

  Widget _buildImagePackCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image_outlined, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                'Image Pack: $_imagePackLabel',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _toggleImagePack,
                child: Text(
                  'Switch',
                  style: GoogleFonts.outfit(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _packPreview(
                label: 'App Icon',
                asset: _appIconImageAsset,
                customPath: _effectiveAppIconCustomPath,
              ),
              const SizedBox(width: 10),
              _packPreview(
                label: 'Chat Image',
                asset: _chatImageAsset,
                customPath: _effectiveChatCustomPath,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _imageActionBtn(
                label: 'Gallery Chat',
                icon: Icons.photo_library_outlined,
                onTap: () => _pickImageFromGallery(forChatImage: true),
              ),
              _imageActionBtn(
                label: 'Gallery Logo',
                icon: Icons.add_photo_alternate_outlined,
                onTap: () => _pickImageFromGallery(forChatImage: false),
              ),
              _imageActionBtn(
                label: 'Reset',
                icon: Icons.refresh_outlined,
                onTap: _resetCustomImages,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _packPreview({
    required String label,
    required String asset,
    required String? customPath,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image(
                image: _imageProviderFor(
                  assetPath: asset,
                  customPath: customPath,
                ),
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.white24,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageActionBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _settingsTile({
  required IconData icon,
  required String label,
  required String subtitle,
  required bool value,
  required ValueChanged<bool> onChanged,
  required Color activeColor,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
          color: value ? activeColor.withOpacity(0.25) : Colors.white10),
    ),
    child: Row(
      children: [
        Icon(icon, color: value ? activeColor : Colors.white38, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style:
                      GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
          inactiveThumbColor: Colors.white38,
          inactiveTrackColor: Colors.white12,
        ),
      ],
    ),
  );
}
