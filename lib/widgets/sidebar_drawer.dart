import 'package:flutter/material.dart';
import 'package:o2_waifu/config/app_themes.dart';
import 'package:o2_waifu/services/music_player_service.dart';
import 'package:o2_waifu/services/affection_service.dart';
import 'package:o2_waifu/models/relationship_stage.dart';

/// Redesigned side drawer with mini-music controller,
/// hub navigation, and relationship status display.
class SidebarDrawer extends StatelessWidget {
  final AppThemeConfig themeConfig;
  final MusicPlayerService musicService;
  final AffectionService affectionService;
  final VoidCallback onSettingsTap;
  final VoidCallback onGachaTap;
  final VoidCallback onSecretNotesTap;
  final VoidCallback onMoodTrackingTap;
  final VoidCallback onBackupTap;

  const SidebarDrawer({
    super.key,
    required this.themeConfig,
    required this.musicService,
    required this.affectionService,
    required this.onSettingsTap,
    required this.onGachaTap,
    required this.onSecretNotesTap,
    required this.onMoodTrackingTap,
    required this.onBackupTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: themeConfig.backgroundColor.withValues(alpha: 0.95),
        child: SafeArea(
          child: Column(
            children: [
              // Header with avatar and relationship status
              _buildHeader(),
              const Divider(height: 1, color: Colors.white10),

              // Mini Music Player
              _buildMiniMusicPlayer(),
              const Divider(height: 1, color: Colors.white10),

              // Navigation items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildNavItem(
                      icon: Icons.settings,
                      label: 'Settings',
                      onTap: onSettingsTap,
                    ),
                    _buildNavItem(
                      icon: Icons.casino,
                      label: 'Gacha',
                      onTap: onGachaTap,
                    ),
                    _buildNavItem(
                      icon: Icons.lock,
                      label: 'Secret Notes',
                      onTap: onSecretNotesTap,
                    ),
                    _buildNavItem(
                      icon: Icons.mood,
                      label: 'Mood Tracking',
                      onTap: onMoodTrackingTap,
                    ),
                    _buildNavItem(
                      icon: Icons.cloud_upload,
                      label: 'Backup',
                      onTap: onBackupTap,
                    ),
                  ],
                ),
              ),

              // Version info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'O2-WAIFU v3.0',
                  style: TextStyle(
                    color: themeConfig.textColor.withValues(alpha: 0.3),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar with glow
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: themeConfig.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor:
                  themeConfig.primaryColor.withValues(alpha: 0.2),
              child: Icon(
                Icons.favorite,
                color: themeConfig.primaryColor,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Zero Two',
            style: TextStyle(
              color: themeConfig.primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${affectionService.stage.displayName} | ${affectionService.points} pts',
            style: TextStyle(
              color: themeConfig.textColor.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          // Affection progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: affectionService.progressToNextStage,
              backgroundColor:
                  themeConfig.surfaceColor.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation(themeConfig.primaryColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMusicPlayer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            musicService.isPlaying ? Icons.music_note : Icons.music_off,
            color: themeConfig.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  musicService.currentTrack ?? 'No music',
                  style: TextStyle(
                    color: themeConfig.textColor,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  musicService.currentArtist ?? '',
                  style: TextStyle(
                    color: themeConfig.textColor.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _miniButton(
                icon: musicService.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                onTap: () {
                  if (musicService.isPlaying) {
                    musicService.pause();
                  } else {
                    musicService.resume();
                  }
                },
              ),
              _miniButton(
                icon: Icons.stop,
                onTap: () => musicService.stop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniButton(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: themeConfig.primaryColor, size: 18),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: themeConfig.primaryColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: themeConfig.textColor,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }
}
