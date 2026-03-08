part of '../main.dart';

extension _MainSettingsExtension on _ChatHomePageState {
// —— Page: Settings ————————————————————————————————————————————————————————————————
  Widget _buildVoiceOption(BuildContext context, String id, String label) {
    final bool sel = _voiceModel == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => unawaited(_setVoiceModel(id)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: sel
                ? Colors.cyanAccent.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: sel ? Colors.cyanAccent : Colors.white12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
                color: sel ? Colors.cyanAccent : Colors.white70,
                fontSize: 12,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ),
    );
  }

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
                  _settingsSectionCard('VOICE & ASSISTANT', [
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                      subtitle: _assistantModeEnabled
                          ? 'Running in background'
                          : 'Off',
                      value: _assistantModeEnabled,
                      onChanged: (_) => _toggleAssistantMode(),
                      activeColor: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.02))),
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
                    // TTS Playback Speed slider
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.02))),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.speed,
                                  color: Colors.white54, size: 18),
                              const SizedBox(width: 8),
                              Text('TTS Playback Speed',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text('${_ttsSpeed.toStringAsFixed(1)}x',
                                  style: GoogleFonts.outfit(
                                      color: Colors.lightBlueAccent,
                                      fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Slider(
                            value: _ttsSpeed,
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            onChanged: (v) {
                              unawaited(_setTtsSpeed(v));
                            },
                            activeColor: Colors.lightBlueAccent,
                            inactiveColor: Colors.white12,
                          ),
                          Text(
                            _ttsSpeed < 1.0
                                ? 'Slower and clearer'
                                : _ttsSpeed > 1.0
                                    ? 'Fast paced'
                                    : 'Normal speed',
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    ),

                    // Voice Engine Model Chooser
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.02))),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.language_rounded,
                                  color: Colors.white54, size: 18),
                              const SizedBox(width: 8),
                              Text('Voice Model',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(
                                  _voiceModel == 'arabic'
                                      ? 'Aisha'
                                      : _voiceModel == 'lulwa'
                                          ? 'Lulwa'
                                          : _voiceModel == 'autumn'
                                              ? 'Autumn'
                                              : 'Hannah',
                                  style: GoogleFonts.outfit(
                                      color: Colors.cyanAccent, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: [
                              Row(
                                children: [
                                  _buildVoiceOption(context, 'arabic', 'Aisha'),
                                  const SizedBox(width: 8),
                                  _buildVoiceOption(context, 'lulwa', 'Lulwa'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildVoiceOption(
                                      context, 'english', 'Hannah'),
                                  const SizedBox(width: 8),
                                  _buildVoiceOption(
                                      context, 'autumn', 'Autumn'),
                                ],
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
                    _buildOutfitChangerCard(),
                    const SizedBox(height: 16),
                  ]),
                  const SizedBox(height: 16),
                  _settingsSectionCard('ROUTINES & BEHAVIOR', [
                    _buildToolShortcut(
                      icon: Icons.wb_sunny_rounded,
                      label: 'Morning Routine',
                      subtitle:
                          'Say "Good morning" or trigger from home screen widget',
                      color: Colors.amberAccent,
                      onTap: () {
                        updateState(() => _navIndex = 0);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Go to chat and say "Good morning" to start!'),
                            duration: Duration(seconds: 3)));
                      },
                    ),
                    _buildToolShortcut(
                      icon: Icons.nights_stay_rounded,
                      label: 'Night Routine',
                      subtitle: 'Say "Good night" to trigger nightly wind-down',
                      color: Colors.indigoAccent,
                      onTap: () {
                        updateState(() => _navIndex = 0);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Go to chat and say "Good night" to start!'),
                                duration: Duration(seconds: 3)));
                      },
                    ),
                    _buildToolShortcut(
                      icon: Icons.alarm_rounded,
                      label: 'Set Waifu Alarm',
                      subtitle:
                          'Say "Wake me up at 7 AM" to set a dynamic alarm',
                      color: Colors.orangeAccent,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Say "Wake me up at [time]" in chat to set a dynamic alarm!')));
                      },
                    ),
                    _buildToolShortcut(
                      icon: Icons.task_alt_rounded,
                      label: 'Daily Quests',
                      subtitle:
                          'See and complete your daily relationship challenges',
                      color: Colors.greenAccent,
                      onTap: () {
                        updateState(() => _navIndex = 11);
                      },
                    ),
                    const SizedBox(height: 24),
                  ]),
                  const SizedBox(height: 16),
                  _settingsSectionCard('RELATIONSHIP & PERSONA', [
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.pinkAccent.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.theater_comedy_rounded,
                                  color: Colors.pinkAccent, size: 18),
                              const SizedBox(width: 8),
                              Text('Persona',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(_selectedPersona,
                                  style: GoogleFonts.outfit(
                                      color: Colors.pinkAccent, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Default', 'Tsundere', 'Shy', 'Yandere']
                                .map((p) => ChoiceChip(
                                      label: Text(p,
                                          style: GoogleFonts.outfit(
                                            color: _selectedPersona == p
                                                ? Colors.black
                                                : Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          )),
                                      selected: _selectedPersona == p,
                                      selectedColor: Colors.pinkAccent,
                                      backgroundColor: Colors.white10,
                                      onSelected: (sel) {
                                        if (sel) _setPersona(p);
                                      },
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Controls her name, tone, and greeting style in the system prompt.',
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                    _settingsTile(
                      icon: Icons.nightlight_round,
                      label: 'Sleep Mode',
                      subtitle: _sleepModeEnabled
                          ? 'Auto-mutes midnight – 7 AM'
                          : 'Always active (no mute)',
                      value: _sleepModeEnabled,
                      onChanged: (v) => _setSleepMode(v),
                      activeColor: Colors.indigoAccent,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.pinkAccent.withValues(alpha: 0.12),
                            Colors.deepPurple.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.pinkAccent.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.favorite_rounded,
                                  color: Colors.pinkAccent, size: 20),
                              const SizedBox(width: 10),
                              Text('Affection Status',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              const Spacer(),
                              ValueListenableBuilder<int>(
                                valueListenable: ValueNotifier(
                                    AffectionService.instance.points),
                                builder: (_, pts, __) => Text(
                                    '${AffectionService.instance.points} pts',
                                    style: GoogleFonts.outfit(
                                        color: Colors.pinkAccent,
                                        fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your relationship: ${AffectionService.instance.levelName}',
                            style: GoogleFonts.outfit(
                                color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: AffectionService.instance.levelProgress,
                              minHeight: 6,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.pinkAccent),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Earn points by chatting, completing quests, and daily routines. '
                            'Inactivity for 2+ days causes decay.',
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 10.5),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await AffectionService.instance.addPoints(10);
                              if (context.mounted) updateState(() {});
                            },
                            icon: const Icon(Icons.add_circle_outline,
                                color: Colors.pinkAccent, size: 16),
                            label: Text('Grant +10 pts (test)',
                                style: GoogleFonts.outfit(
                                    color: Colors.pinkAccent, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Colors.pinkAccent, width: 0.8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ]),
                  const SizedBox(height: 16),
                  _settingsSectionCard('MEMORY & DATA', [
                    FutureBuilder<String>(
                      future: MemoryService.buildMemoryPromptBlock(),
                      builder: (ctx, snap) {
                        final block = snap.data ?? '';
                        final count = '\nFact:'.allMatches(block).length;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    Colors.purpleAccent.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.psychology_rounded,
                                  color: Colors.purpleAccent, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Saved Facts',
                                        style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                      count == 0
                                          ? 'No facts saved yet — tell her something to remember!'
                                          : '$count fact${count == 1 ? '' : 's'} stored in memory',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white54, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await MemoryService.clearAll();
                                  if (mounted) updateState(() {});
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Memory cleared'),
                                            duration: Duration(seconds: 2)));
                                  }
                                },
                                child: Text('Clear',
                                    style: GoogleFonts.outfit(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    // Google Drive Backup UI
                    _GoogleDriveBackupWidget(
                        onRestoreComplete: () => updateState(() {})),

                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () => unawaited(_clearMemory()),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.25)),
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
                      onTap: () => unawaited(_clearNotifHistory()),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.2)),
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
                    const SizedBox(height: 20),
                  ]),
                  const SizedBox(height: 16),
                  _settingsSectionCard('CHAT & DISPLAY', [
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.02))),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.02))),
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
                            children:
                                ['Short', 'Normal', 'Detailed'].map((mode) {
                              final sel = _responseLengthMode == mode;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => _setResponseLength(mode),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? Colors.amberAccent
                                              .withValues(alpha: 0.2)
                                          : Colors.white
                                              .withValues(alpha: 0.05),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.02))),
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
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? Colors.cyanAccent
                                              .withValues(alpha: 0.15)
                                          : Colors.white
                                              .withValues(alpha: 0.05),
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
                  ]),
                  const SizedBox(height: 16),
                  _settingsSectionCard('APPS & WIDGETS', [
                    _settingsTile(
                      icon: Icons.fingerprint_rounded,
                      label: 'App Privacy Lock',
                      subtitle: _appLockEnabled
                          ? 'Biometric/PIN required on startup'
                          : 'No authentication required',
                      value: _appLockEnabled,
                      onChanged: (_) => _toggleAppLock(),
                      activeColor: Colors.pinkAccent,
                    ),
                    _buildToolShortcut(
                      icon: Icons.mood_rounded,
                      label: 'Mood Tracker',
                      subtitle: 'Check your feeling history',
                      color: Colors.orangeAccent,
                      onTap: () {
                        updateState(() => _navIndex = 9);
                      },
                    ),
                    _buildToolShortcut(
                      icon: Icons.lock_outline_rounded,
                      label: 'Secret Notes',
                      subtitle: 'Encrypted local journal',
                      color: Colors.tealAccent,
                      onTap: () {
                        updateState(() => _navIndex = 10);
                      },
                    ),
                    _buildToolShortcut(
                      icon: Icons.casino_rounded,
                      label: 'Gacha Quotes',
                      subtitle: 'Roll for a daily quote',
                      color: Colors.pinkAccent,
                      onTap: () {
                        updateState(() => _navIndex = 8);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildToolShortcut(
                      icon: Icons.music_note_rounded,
                      label: 'Music Player',
                      subtitle:
                          'Play local music — in-app player with album art',
                      color: Colors.purpleAccent,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MusicPlayerPage())),
                    ),
                    _buildToolShortcut(
                      icon: Icons.record_voice_over_rounded,
                      label: 'Test Current Voice',
                      subtitle: 'Tap to hear a sample of $_voiceModel',
                      color: Colors.cyanAccent,
                      onTap: () async {
                        if (_isSpeaking) {
                          await _ttsService.stop();
                          // State refresh will happen via speech listeners
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Testing $_voiceModel voice...'),
                            duration: const Duration(seconds: 2),
                          ));
                          await _ttsService.speak('Hello Darling, I am ready!');
                        }
                      },
                    ),
                    _buildToolShortcut(
                      icon: Icons.auto_fix_high_rounded,
                      label: 'AI Drawing',
                      subtitle:
                          'Say "Draw me a cat" to generate images (Pollinations.ai)',
                      color: Colors.pinkAccent,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Say "Draw me a [thing]" in chat to generate images!')));
                      },
                    ),
                    _buildToolShortcut(
                      icon: Icons.games_rounded,
                      label: 'Mini-Games',
                      subtitle:
                          'RPS · Tic-Tac-Toe · Anime Trivia — all in chat',
                      color: Colors.amberAccent,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Say "Rock", "tic tac toe", or "trivia" in chat!')));
                      },
                    ),
                    _buildToolShortcut(
                      icon: Icons.alarm_rounded,
                      label: 'Waifu Alarm',
                      subtitle: 'Say "Wake me up at 7 AM" to set an alarm',
                      color: Colors.orangeAccent,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Say "Wake me up at 7 AM" in chat to set an alarm!')));
                      },
                    ),
                    _buildToolShortcut(
                      icon: Icons.image_outlined,
                      label: 'Image Pack',
                      subtitle: 'Customize app icon and chat image',
                      color: Colors.blueAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ImagePackPage(),
                          ),
                        );
                      },
                    ),
                    _buildToolShortcut(
                      icon: Icons.palette_outlined,
                      label: 'Theme & Accent',
                      subtitle: 'Change app theme and accent color',
                      color: Colors.greenAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ThemeAccentPage(),
                          ),
                        );
                      },
                    ),
                    _buildToolShortcut(
                      icon: Icons.tune_outlined,
                      label: 'Advanced Settings',
                      subtitle: 'Fine-tune app behavior and features',
                      color: Colors.white54,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdvancedSettingsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blueAccent.withValues(alpha: 0.10),
                            Colors.tealAccent.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.blueAccent.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.widgets_rounded,
                                  color: Colors.blueAccent, size: 20),
                              const SizedBox(width: 10),
                              Text('Your 20 Widgets',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...[
                            (
                              '❤️ Affection (Small)',
                              'Shows relationship tier on home screen'
                            ),
                            (
                              '💖 Affection (Large)',
                              'Detailed progress bar with points'
                            ),
                            ('💬 Daily Quote', 'New quote every day'),
                            ('⚡ Zero Two Quote', 'Her iconic lines'),
                            (
                              '🎮 Quick Actions Row',
                              'Talk / Routine / Quests buttons'
                            ),
                            (
                              '🔲 Quick Actions Grid',
                              '6-button shortcut panel'
                            ),
                            ('🌤 Weather Status', 'Synced weather glance'),
                            ('🔋 Battery Status', 'Device battery level'),
                            ('😊 Mood Tracker', 'Your current logged mood'),
                            ('⏰ Next Alarm', 'Upcoming alarm or event'),
                            ('🔦 Flashlight Toggle', '1-tap flashlight button'),
                            ('🔇 DND Toggle', 'Do Not Disturb quick toggle'),
                            ('💬 Open Chat Shortcut', 'Jump directly to chat'),
                            ('🌅 Morning Routine', 'Trigger morning briefing'),
                            ('🌙 Night Routine', 'Trigger night wind-down'),
                            ('🍅 Pomodoro Status', 'Current focus timer'),
                            ('🧠 Memory Flashcard', 'Random saved fact'),
                            ('📋 Daily Summary', 'Today\'s briefing glance'),
                            (
                              '🕐 Greeting & Clock',
                              'Clock + Zero Two greeting'
                            ),
                            ('📡 Device Stats', 'Wi-Fi & system info'),
                          ].map((item) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.$1,
                                        style: GoogleFonts.outfit(
                                            color: Colors.white70,
                                            fontSize: 12)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text('— ${item.$2}',
                                          style: GoogleFonts.outfit(
                                              color: Colors.white38,
                                              fontSize: 11)),
                                    ),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 10),
                          Text(
                            'To add: long-press your home screen → Widgets → S-002',
                            style: GoogleFonts.outfit(
                                color: Colors.blueAccent, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ]),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolShortcut({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: const Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white24, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsSectionCard(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
          child: Text(title,
              style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
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
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.6),
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

  Widget _buildOutfitChangerCard() {
    final List<String> outfits = [
      'assets/img/z2s.jpg',
      'assets/img/logi.png',
      'assets/img/z12.jpg',
      'assets/img/bll.jpg',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.02))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checkroom_outlined,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                'Outfit Changer',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_chatImageFromSystem)
                Text(
                  'Custom Active',
                  style: GoogleFonts.outfit(
                    color: Colors.orangeAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: outfits.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final outfit = outfits[index];
                final isSelected =
                    !_chatImageFromSystem && _selectedOutfit == outfit;
                return GestureDetector(
                  onTap: () {
                    if (_chatImageFromSystem) {
                      _resetCustomImages();
                    }
                    _setOutfit(outfit);
                  },
                  child: Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? Colors.redAccent : Colors.transparent,
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: AssetImage(outfit),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _imageActionBtn(
                label: 'Custom Outfit',
                icon: Icons.photo_library_outlined,
                onTap: () => _pickImageFromGallery(forChatImage: true),
              ),
              _imageActionBtn(
                label: 'Custom Logo',
                icon: Icons.add_photo_alternate_outlined,
                onTap: () => _pickImageFromGallery(forChatImage: false),
              ),
              if (_chatImageFromSystem || _appIconFromCustom)
                _imageActionBtn(
                  label: 'Reset Gallery',
                  icon: Icons.layers_clear_outlined,
                  onTap: _resetCustomImages,
                ),
            ],
          ),
        ],
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
          color: Colors.white.withValues(alpha: 0.06),
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
  return InkWell(
    onTap: () => onChanged(!value),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.02))),
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
                    style: GoogleFonts.outfit(
                        color: Colors.white38, fontSize: 11)),
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
    ),
  );
}

class _GoogleDriveBackupWidget extends StatefulWidget {
  final VoidCallback onRestoreComplete;
  const _GoogleDriveBackupWidget({required this.onRestoreComplete});

  @override
  State<_GoogleDriveBackupWidget> createState() =>
      _GoogleDriveBackupWidgetState();
}

class _GoogleDriveBackupWidgetState extends State<_GoogleDriveBackupWidget> {
  bool _isBackingUp = false;
  bool _isRestoring = false;

  Future<void> _performBackup() async {
    setState(() => _isBackingUp = true);
    final service = GoogleDriveService();
    final success = await service.backupData();
    if (!mounted) return;
    setState(() => _isBackingUp = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Backup successful! 🎉' : 'Backup failed.'),
      backgroundColor: success ? Colors.green.shade800 : Colors.red.shade800,
    ));
  }

  Future<void> _performRestore() async {
    setState(() => _isRestoring = true);
    final service = GoogleDriveService();
    final success = await service.restoreData();
    if (!mounted) return;
    setState(() => _isRestoring = false);
    if (success) widget.onRestoreComplete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? 'Restore completed!'
          : 'Restore failed. No backup found or auth error.'),
      backgroundColor: success ? Colors.blue.shade800 : Colors.orange.shade800,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.cloud_sync_rounded,
                color: Colors.blueAccent, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text('Cloud Sync',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 8),
          Text('Backup your Secret Notes and Settings to Google Drive.',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _isBackingUp ? null : _performBackup,
                icon: _isBackingUp
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.backup_rounded, size: 16),
                label: Text(_isBackingUp ? 'Syncing...' : 'Backup',
                    style: GoogleFonts.outfit(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                  foregroundColor: Colors.blueAccent,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isRestoring ? null : _performRestore,
                icon: _isRestoring
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.restore_rounded, size: 16),
                label: Text(_isRestoring ? 'Downloading...' : 'Restore',
                    style: GoogleFonts.outfit(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
