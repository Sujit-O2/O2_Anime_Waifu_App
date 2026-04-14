import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 🎮 COMPREHENSIVE GAME SOUNDS SERVICE
/// All sound effects for battles, achievements, events, raids, tournaments, guilds, and mini-games
/// Uses HapticFeedback + AudioPlayer for maximum compatibility
class GameSoundsService {
  GameSoundsService._();
  static final GameSoundsService instance = GameSoundsService._();

  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;

  /// ===== BASIC UI SOUNDS (Tap, Navigation) =====
  Future<void> playTap() async {
    await HapticFeedback.lightImpact();
    await _tryPlay('tap');
  }

  Future<void> playCorrect() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('correct');
  }

  Future<void> playWrong() async {
    await HapticFeedback.heavyImpact();
    await _tryPlay('wrong');
  }

  Future<void> playSpin() async {
    await HapticFeedback.selectionClick();
    await _tryPlay('spin');
  }

  Future<void> playReveal() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('reveal');
  }

  /// ===== BATTLE SYSTEM SOUNDS =====
  /// Battle hit/damage sound
  Future<void> playBattleHit() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('battle_hit');
  }

  /// Enemy attack sound
  Future<void> playEnemyAttack() async {
    await HapticFeedback.heavyImpact();
    await _tryPlay('enemy_attack');
  }

  /// Critical hit - dramatic sound
  Future<void> playCriticalHit() async {
    await HapticFeedback.heavyImpact();
    await _tryPlay('critical_hit');
  }

  /// Battle victory fanfare
  Future<void> playBattleVictory() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('battle_victory');
  }

  /// Battle defeat/loss sound
  Future<void> playBattleDefeat() async {
    await HapticFeedback.heavyImpact();
    await _tryPlay('battle_defeat');
  }

  /// Blocking/Shield sound
  Future<void> playBlock() async {
    await HapticFeedback.lightImpact();
    await _tryPlay('block');
  }

  /// Special ability used
  Future<void> playSpecialAbility() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('special_ability');
  }

  /// Magic/Energy casting
  Future<void> playMagic() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('magic');
  }

  /// ===== ACHIEVEMENT & REWARD SOUNDS =====
  /// Achievement unlocked - triumphant fanfare
  Future<void> playAchievementUnlocked() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('achievement_unlocked');
  }

  /// Level up sound
  Future<void> playLevelUp() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('level_up');
  }

  /// Coin/reward collected
  Future<void> playRewardCollect() async {
    await HapticFeedback.lightImpact();
    await _tryPlay('reward_collect');
  }

  /// Treasure/bonus reward - exciting sound
  Future<void> playTreasureFound() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('treasure_found');
  }

  /// ===== SEASONAL EVENTS & GACHA =====
  /// Gacha pull/roll sound
  Future<void> playGachaPull() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('gacha_pull');
  }

  /// Gacha 5-star/legendary pull
  Future<void> playGachaLegendary() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('gacha_legendary');
  }

  /// Event started/activated
  Future<void> playEventStart() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('event_start');
  }

  /// Event completed
  Future<void> playEventComplete() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('event_complete');
  }

  /// Battle pass tier completed
  Future<void> playBattlePassTier() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('battle_pass_tier');
  }

  /// ===== TOURNAMENT & RANKED =====
  /// Tournament match started
  Future<void> playTournamentStart() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('tournament_start');
  }

  /// Tournament match won
  Future<void> playTournamentWin() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('tournament_win');
  }

  /// Tournament final victory
  Future<void> playTournamentChampion() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('tournament_champion');
  }

  /// Rank up/promotion sound
  Future<void> playRankUp() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('rank_up');
  }

  /// ===== GUILD & TEAM SOUNDS =====
  /// Guild war declaration
  Future<void> playGuildWarStart() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('guild_war_start');
  }

  /// Guild war victory
  Future<void> playGuildWarVictory() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('guild_war_victory');
  }

  /// Guild member joined
  Future<void> playGuildMemberJoined() async {
    await HapticFeedback.lightImpact();
    await _tryPlay('guild_member_joined');
  }

  /// Treasury deposited
  Future<void> playTreasuryDeposit() async {
    await HapticFeedback.lightImpact();
    await _tryPlay('treasury_deposit');
  }

  /// Guild perk unlocked
  Future<void> playGuildPerkUnlocked() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('guild_perk_unlocked');
  }

  /// ===== RAID SOUNDS =====
  /// Raid battle started
  Future<void> playRaidStart() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('raid_start');
  }

  /// Raid phase boss appears
  Future<void> playRaidBossAppear() async {
    await HapticFeedback.heavyImpact();
    await _tryPlay('raid_boss_appear');
  }

  /// Raid completed - victory
  Future<void> playRaidComplete() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('raid_complete');
  }

  /// Raid treasure reward
  Future<void> playRaidTreasure() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('raid_treasure');
  }

  /// ===== MINI-GAME SOUNDS =====
  /// Mini-game win
  Future<void> playMiniGameWin() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('mini_game_win');
  }

  /// Mini-game lose
  Future<void> playMiniGameLose() async {
    await HapticFeedback.heavyImpact();
    await _tryPlay('mini_game_lose');
  }

  /// Mini-game round complete
  Future<void> playMiniGameRound() async {
    await HapticFeedback.lightImpact();
    await _tryPlay('mini_game_round');
  }

  /// ===== COMBO & STREAK SOUNDS =====
  /// Combo hit
  Future<void> playCombo() async {
    await HapticFeedback.lightImpact();
    await _tryPlay('combo');
  }

  /// Combo multiplier increase
  Future<void> playComboBurst() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('combo_burst');
  }

  /// Streak milestone reached
  Future<void> playStreakBonus() async {
    await HapticFeedback.mediumImpact();
    await _tryPlay('streak_bonus');
  }

  /// ===== GENERAL NOTIFICATIONS =====
  /// Warning/alert sound
  Future<void> playAlert() async {
    await HapticFeedback.heavyImpact();
    await _tryPlay('alert');
  }

  /// Notification received
  Future<void> playNotification() async {
    await HapticFeedback.lightImpact();
    await _tryPlay('notification');
  }

  /// Affection increase
  Future<void> playAffectionIncrease() async {
    await HapticFeedback.lightImpact();
    await _tryPlay('affection_increase');
  }

  /// Affection decrease
  Future<void> playAffectionDecrease() async {
    await HapticFeedback.heavyImpact();
    await _tryPlay('affection_decrease');
  }

  /// ===== CONTROLS =====
  /// Toggle sound on/off
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  /// Internal: Try to play audio asset with fallback
  Future<void> _tryPlay(String name) async {
    if (!_soundEnabled) return;
    try {
      await _player.play(AssetSource('sounds/$name.mp3'));
    } catch (e) {
      debugPrint('[GameSounds] Failed to play $name: $e');
      // Silently fail — haptic feedback already provided
    }
  }

  /// Play sound with custom duration (for looping battle music, etc)
  Future<void> playCustom(String assetPath) async {
    if (!_soundEnabled) return;
    try {
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('[GameSounds] Failed to play custom sound: $e');
    }
  }

  /// Stop current sound
  Future<void> stop() async {
    await _player.stop();
  }

  /// Preload sounds for faster playback
  Future<void> preloadSounds() async {
    const sounds = [
      'tap', 'correct', 'wrong', 'spin', 'reveal',
      'battle_hit', 'enemy_attack', 'critical_hit', 'battle_victory', 'battle_defeat', 'block', 'special_ability', 'magic',
      'achievement_unlocked', 'level_up', 'reward_collect', 'treasure_found',
      'gacha_pull', 'gacha_legendary', 'event_start', 'event_complete', 'battle_pass_tier',
      'tournament_start', 'tournament_win', 'tournament_champion', 'rank_up',
      'guild_war_start', 'guild_war_victory', 'guild_member_joined', 'treasury_deposit', 'guild_perk_unlocked',
      'raid_start', 'raid_boss_appear', 'raid_complete', 'raid_treasure',
      'mini_game_win', 'mini_game_lose', 'mini_game_round',
      'combo', 'combo_burst', 'streak_bonus',
      'alert', 'notification', 'affection_increase', 'affection_decrease',
    ];
    for (final sound in sounds) {
      try {
        await _player.play(AssetSource('sounds/$sound.mp3'));
        await _player.stop();
      } catch (_) {
        // Preload failed for this sound, skip
      }
    }
  }
}


