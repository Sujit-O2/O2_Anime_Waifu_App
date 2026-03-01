part of '../main.dart';

extension _MainNotificationsExtension on _ChatHomePageState {
// ── Page: Notification History ────────────────────────────────────────────
  Widget _buildNotificationsPage() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Text('NOTIFICATIONS',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2)),
                const Spacer(),
                if (_notifHistory.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_sweep_outlined,
                        color: Colors.redAccent, size: 18),
                    label: const Text('Clear All',
                        style:
                            TextStyle(color: Colors.redAccent, fontSize: 12)),
                    onPressed: _clearNotifHistory,
                  ),
              ],
            ),
          ),
          Expanded(
            child: _notifHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.notifications_off_outlined,
                            color: Colors.white24, size: 48),
                        const SizedBox(height: 12),
                        Text('No notifications yet',
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: _notifHistory.length,
                    itemBuilder: (ctx, i) {
                      final item = _notifHistory[i];
                      final msg = item['msg'] ?? '';
                      final ts = item['ts'] ?? '';
                      DateTime? time;
                      try {
                        time = ts.isNotEmpty ? DateTime.parse(ts) : null;
                      } catch (_) {}
                      return Dismissible(
                        key: ValueKey(ts),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                        ),
                        onDismissed: (_) => _removeNotifAt(i),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.favorite,
                                      color: Colors.pinkAccent, size: 14),
                                  const SizedBox(width: 6),
                                  Text('Zero Two',
                                      style: GoogleFonts.outfit(
                                          color: Colors.pinkAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700)),
                                  const Spacer(),
                                  if (time != null)
                                    Text(
                                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white38, fontSize: 10),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(msg,
                                  style: GoogleFonts.outfit(
                                      color: Colors.white.withOpacity(0.87),
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

// ── Page: Coming Soon ─────────────────────────────────────────────────────
  Widget _buildComingSoonPage() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Icon(Icons.videocam_outlined,
                    color: Colors.white38, size: 52),
              ),
              const SizedBox(height: 24),
              Text('Video Streaming',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text('Coming Soon',
                  style: GoogleFonts.outfit(
                      color: Colors.white38, fontSize: 14, letterSpacing: 2)),
              const SizedBox(height: 16),
              Text(
                'Zero Two will be able to send you video clips, express herself visually, and stream real-time content.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    color: Colors.white54, fontSize: 13, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
