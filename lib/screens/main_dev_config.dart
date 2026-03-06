part of '../main.dart';

extension _MainDevConfigExtension on _ChatHomePageState {
  Widget _buildDevConfigPage() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'DEV CONFIG',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: _buildDevConfigHero(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Edit All Config Fields'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _openDevConfigSheet,
                  ),
                  const SizedBox(height: 16),
                  // ── AI / API ──────────────────────────────────────────────
                  _devSectionLabel('AI / API'),
                  _devInfoCard(
                      'API Key',
                      _devApiKeyOverride.isNotEmpty
                          ? '${_devApiKeyOverride.substring(0, _devApiKeyOverride.length.clamp(0, 12))}...'
                          : 'Using .env default',
                      _devApiKeyOverride.isNotEmpty),
                  _devInfoCard(
                      'Model',
                      _devModelOverride.isNotEmpty
                          ? _devModelOverride
                          : 'Using .env default',
                      _devModelOverride.isNotEmpty),
                  _devInfoCard(
                      'API URL',
                      _devApiUrlOverride.isNotEmpty
                          ? _devApiUrlOverride
                          : 'Default endpoint',
                      _devApiUrlOverride.isNotEmpty),
                  _devInfoCard(
                      'System Persona',
                      _devSystemQuery.isNotEmpty
                          ? 'Custom active (${_devSystemQuery.length} chars)'
                          : 'Default persona',
                      _devSystemQuery.isNotEmpty),
                  const SizedBox(height: 8),
                  // ── TTS ───────────────────────────────────────────────────
                  _devSectionLabel('TTS'),
                  _devInfoCard(
                      'TTS Voice',
                      _devTtsVoiceOverride.isNotEmpty
                          ? _devTtsVoiceOverride
                          : 'aisha (default)',
                      _devTtsVoiceOverride.isNotEmpty),
                  _devInfoCard(
                      'TTS API Key',
                      _devTtsApiKeyOverride.isNotEmpty
                          ? '${_devTtsApiKeyOverride.substring(0, _devTtsApiKeyOverride.length.clamp(0, 10))}...'
                          : 'Using .env default',
                      _devTtsApiKeyOverride.isNotEmpty),
                  _devInfoCard(
                      'TTS Model',
                      _devTtsModelOverride.isNotEmpty
                          ? _devTtsModelOverride
                          : 'Using .env default',
                      _devTtsModelOverride.isNotEmpty),
                  const SizedBox(height: 8),
                  // ── Wake Word ─────────────────────────────────────────────
                  _devSectionLabel('WAKE WORD'),
                  _devInfoCard(
                      'Wake Key',
                      _devWakeKeyOverride.isNotEmpty
                          ? 'Custom key set'
                          : 'Using .env default',
                      _devWakeKeyOverride.isNotEmpty),
                  const SizedBox(height: 8),
                  // ── STT ───────────────────────────────────────────────────
                  _devSectionLabel('STT (Speech-to-Text)'),
                  _devInfoCard(
                      'STT Lang',
                      _devSttLangOverride.isNotEmpty
                          ? _devSttLangOverride
                          : 'System Default',
                      _devSttLangOverride.isNotEmpty),
                  _devInfoCard(
                      'STT Timeout',
                      _devSttTimeoutOverride > 0
                          ? '$_devSttTimeoutOverride seconds'
                          : 'System Default',
                      _devSttTimeoutOverride > 0),
                  const SizedBox(height: 8),
                  // ── Mail ──────────────────────────────────────────────────
                  _devSectionLabel('MAIL (MailJet)'),
                  _devInfoCard(
                      'API Key',
                      _devMailJetApiOverride.isNotEmpty
                          ? '${_devMailJetApiOverride.substring(0, _devMailJetApiOverride.length.clamp(0, 10))}...'
                          : 'Using .env default',
                      _devMailJetApiOverride.isNotEmpty),
                  _devInfoCard(
                      'Secret Key',
                      _devMailJetSecOverride.isNotEmpty
                          ? 'Custom secret set'
                          : 'Using .env default',
                      _devMailJetSecOverride.isNotEmpty),
                  const SizedBox(height: 8),
                  // ── FEATURE STATUS ────────────────────────────────────────
                  _devSectionLabel('FEATURE STATUS'),
                  _devInfoCard('API Key Rotation', () {
                    final keys = (dotenv.env['API_KEY'] ?? '')
                        .split(',')
                        .where((k) => k.trim().isNotEmpty)
                        .toList();
                    return '${keys.length} key${keys.length == 1 ? '' : 's'} configured (round-robin)';
                  }(), true),
                  _devInfoCard(
                      'Weather API',
                      (dotenv.env['OPENWEATHER_API_KEY'] ?? '').isNotEmpty
                          ? 'OPENWEATHER_API_KEY set ✅'
                          : '❌ Missing — add to .env',
                      (dotenv.env['OPENWEATHER_API_KEY'] ?? '').isNotEmpty),
                  _devInfoCard('AI Persona', _selectedPersona, true),
                  _devInfoCard(
                      'Sleep Mode',
                      _sleepModeEnabled
                          ? 'Enabled (mutes midnight–7AM)'
                          : 'Disabled',
                      _sleepModeEnabled),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _devSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildDevConfigHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 250,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/img/z12.jpg',
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
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Runtime Controls',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Live override values and diagnostics',
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

  Widget _devInfoCard(String label, String value, [bool isOverriding = false]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOverriding
            ? Colors.greenAccent.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isOverriding
                ? Colors.greenAccent.withValues(alpha: 0.3)
                : Colors.white12),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
          ),
          if (isOverriding) ...[
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
            ),
          ],
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: isOverriding ? Colors.greenAccent : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDevConfigSheet() {
    final apiKeyC = TextEditingController(text: _devApiKeyOverride);
    final modelC = TextEditingController(text: _devModelOverride);
    final apiUrlC = TextEditingController(text: _devApiUrlOverride);
    final ttsVoiceC = TextEditingController(text: _devTtsVoiceOverride);
    final ttsApiKeyC = TextEditingController(text: _devTtsApiKeyOverride);
    final ttsModelC = TextEditingController(text: _devTtsModelOverride);
    final wakeKeyC = TextEditingController(text: _devWakeKeyOverride);
    final systemC = TextEditingController(text: _devSystemQuery);
    final sttLangC = TextEditingController(text: _devSttLangOverride);
    final sttTimeoutC = TextEditingController(
        text: _devSttTimeoutOverride > 0
            ? _devSttTimeoutOverride.toString()
            : '');
    final mjApiC = TextEditingController(text: _devMailJetApiOverride);
    final mjSecC = TextEditingController(text: _devMailJetSecOverride);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, color: Colors.white70),
                      const SizedBox(width: 10),
                      Text('Runtime Config',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _cfgLabel('AI / API'),
                  _buildConfigTextField('Gemini API Key Override', apiKeyC),
                  const SizedBox(height: 10),
                  _buildConfigTextField('Model Override', modelC),
                  const SizedBox(height: 10),
                  _buildConfigTextField('API URL Override', apiUrlC),
                  const SizedBox(height: 10),
                  _buildConfigTextField('System Persona Prompt', systemC,
                      maxLines: 3),
                  const SizedBox(height: 14),
                  _cfgLabel('TTS (Text-to-Speech)'),
                  _buildConfigTextField('TTS Voice Override', ttsVoiceC),
                  const SizedBox(height: 10),
                  _buildConfigTextField('TTS API Key Override', ttsApiKeyC),
                  const SizedBox(height: 10),
                  _buildConfigTextField('TTS Model Override', ttsModelC),
                  const SizedBox(height: 14),
                  _cfgLabel('WAKE WORD'),
                  _buildConfigTextField('Wake-Word API Key Override', wakeKeyC),
                  const SizedBox(height: 14),
                  _cfgLabel('STT (Speech-to-Text)'),
                  _buildConfigTextField(
                      'STT Language Code (e.g., en-US)', sttLangC),
                  const SizedBox(height: 10),
                  _buildConfigTextField(
                      'STT Timeout (seconds, e.g., 5)', sttTimeoutC),
                  const SizedBox(height: 14),
                  _cfgLabel('MAIL (MailJet)'),
                  _buildConfigTextField('MailJet API Key', mjApiC),
                  const SizedBox(height: 10),
                  _buildConfigTextField('MailJet Secret Key', mjSecC),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            updateState(() {
                              _devApiKeyOverride = '';
                              _devModelOverride = '';
                              _devApiUrlOverride = '';
                              _devSystemQuery = '';
                              _devTtsVoiceOverride = '';
                              _devTtsApiKeyOverride = '';
                              _devTtsModelOverride = '';
                              _devWakeKeyOverride = '';
                              _devSttLangOverride = '';
                              _devSttTimeoutOverride = 0;
                              _devMailJetApiOverride = '';
                              _devMailJetSecOverride = '';
                            });
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white54,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Reset All',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            updateState(() {
                              _devApiKeyOverride = apiKeyC.text.trim();
                              _devModelOverride = modelC.text.trim();
                              _devApiUrlOverride = apiUrlC.text.trim();
                              _devSystemQuery = systemC.text.trim();
                              _devTtsVoiceOverride = ttsVoiceC.text.trim();
                              _devTtsApiKeyOverride = ttsApiKeyC.text.trim();
                              _devTtsModelOverride = ttsModelC.text.trim();
                              _devWakeKeyOverride = wakeKeyC.text.trim();
                              _devSttLangOverride = sttLangC.text.trim();
                              _devSttTimeoutOverride =
                                  int.tryParse(sttTimeoutC.text.trim()) ?? 0;
                              _devMailJetApiOverride = mjApiC.text.trim();
                              _devMailJetSecOverride = mjSecC.text.trim();
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(ctx).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Apply Changes',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cfgLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: GoogleFonts.outfit(
              color: Colors.cyanAccent,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5)),
    );
  }

  Widget _buildConfigTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
      ),
    );
  }
}
