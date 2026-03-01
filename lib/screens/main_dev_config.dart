part of '../main.dart';

extension _MainDevConfigExtension on _ChatHomePageState {
// ── Page: Dev Config ──────────────────────────────────────────────────────
  Widget _buildDevConfigPage() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('DEV CONFIG',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2)),
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
                    icon: const Icon(Icons.code),
                    label: const Text('Open Full Dev Config'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _openDevConfigSheet,
                  ),
                  const SizedBox(height: 16),
                  _devInfoCard(
                      'API Key',
                      _devApiKeyOverride.isNotEmpty
                          ? '${_devApiKeyOverride.substring(0, _devApiKeyOverride.length.clamp(0, 12))}...'
                          : 'Using .env default'),
                  _devInfoCard(
                      'Model',
                      _devModelOverride.isNotEmpty
                          ? _devModelOverride
                          : 'Using .env default'),
                  _devInfoCard(
                      'TTS Voice',
                      _devTtsVoiceOverride.isNotEmpty
                          ? _devTtsVoiceOverride
                          : 'lulwa (default)'),
                  _devInfoCard(
                      'Wake Key',
                      _devWakeKeyOverride.isNotEmpty
                          ? 'Custom key set'
                          : 'Using .env default'),
                  _devInfoCard(
                      'System Query',
                      _devSystemQuery.isNotEmpty
                          ? _devSystemQuery
                          : 'Default persona'),
                ],
              ),
            ),
          ),
        ],
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
              'z12.jpg',
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
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.55),
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

  Widget _devInfoCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
