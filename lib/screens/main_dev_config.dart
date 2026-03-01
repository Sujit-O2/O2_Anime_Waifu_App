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
