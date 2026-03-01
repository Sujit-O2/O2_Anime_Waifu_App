part of '../main.dart';

extension _MainDrawerExtension on _ChatHomePageState {
// ── Navigation Drawer ─────────────────────────────────────────────────────
  Widget _buildNavDrawer(AppThemeMode mode) {
    final theme = AppThemes.getTheme(mode);
    final primary = theme.primaryColor;
    final gradient = AppThemes.getGradient(mode);

    const labels = [
      '💬  Chat',
      '🎨  Themes',
      '⚙️  Dev Config',
      '🔔  Notifications',
      '🎬  Coming Soon',
      '🛠️  Settings',
      '🐛  Debug',
      'ℹ️  About',
    ];
    const icons = [
      Icons.chat_bubble_outline,
      Icons.palette_outlined,
      Icons.terminal,
      Icons.notifications_outlined,
      Icons.videocam_outlined,
      Icons.settings_outlined,
      Icons.bug_report_outlined,
      Icons.info_outline,
    ];

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradient.first.withOpacity(0.97),
              gradient.last.withOpacity(0.97),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary.withOpacity(0.2),
                        border: Border.all(color: primary.withOpacity(0.5)),
                      ),
                      child: Icon(Icons.auto_awesome, color: primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ZERO TWO',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            )),
                        Text('CORE 002',
                            style: GoogleFonts.outfit(
                              color: Colors.white38,
                              fontSize: 10,
                              letterSpacing: 2,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white.withOpacity(0.08), height: 1),
              // Auto-listen pinned toggle
              _buildDrawerAutoListenTile(primary),
              Divider(color: Colors.white.withOpacity(0.08), height: 1),
              const SizedBox(height: 8),
              // Nav items
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: labels.length,
                  itemBuilder: (ctx, i) {
                    final selected = _navIndex == i;
                    return InkWell(
                      onTap: () {
                        updateState(() => _navIndex = i);
                        Navigator.of(ctx).pop();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: selected
                              ? primary.withOpacity(0.18)
                              : Colors.transparent,
                          border: Border.all(
                            color: selected
                                ? primary.withOpacity(0.4)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(icons[i],
                                color: selected ? primary : Colors.white54,
                                size: 20),
                            const SizedBox(width: 14),
                            Text(
                              labels[i],
                              style: GoogleFonts.outfit(
                                color: selected ? Colors.white : Colors.white60,
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            if (i == 3 && _notifHistory.isNotEmpty) ...[
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_notifHistory.length}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Divider(color: Colors.white.withOpacity(0.08), height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Zero Two • CORE 002',
                      style: GoogleFonts.outfit(
                          color: Colors.white24,
                          fontSize: 11,
                          letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dev by Sujit-O2',
                      style: GoogleFonts.outfit(
                          color: Colors.white10,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerAutoListenTile(Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(
            _isAutoListening ? Icons.mic : Icons.mic_off,
            color: _isAutoListening ? primary : Colors.white38,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text('Auto Listen',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Switch(
            value: _isAutoListening,
            onChanged: (_) => _toggleAutoListen(),
            activeColor: primary,
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }
}
