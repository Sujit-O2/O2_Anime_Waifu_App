import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class RewardSystemPage extends StatefulWidget {
  const RewardSystemPage({super.key});

  @override
  State<RewardSystemPage> createState() => _RewardSystemPageState();
}

class _RewardSystemPageState extends State<RewardSystemPage>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;
  List<Reward> _rewards = [];
  int _userPoints = 0;
  int _totalEarned = 0;
  bool _isLoading = true;
  final Set<String> _redeemedRewards = {};

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _headerAnimation =
        CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic);
    _headerController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await V2Storage.init();
    setState(() {
      _rewards = _generateRewards();
      _userPoints = V2Storage.prefs.getInt('user_points') ?? 500;
      _totalEarned = V2Storage.prefs.getInt('total_points_earned') ?? 850;
      _redeemedRewards.addAll(V2Storage.getList('redeemed_rewards'));
      _isLoading = false;
    });
  }

  List<Reward> _generateRewards() {
    return [
      Reward(
          id: '1',
          title: 'Extra Life Boost',
          description: '+50 XP for your waifu',
          points: 100,
          icon: Icons.favorite,
          color: Colors.pink),
      Reward(
          id: '2',
          title: 'Theme Unlock',
          description: 'Access exclusive themes',
          points: 200,
          icon: Icons.palette,
          color: Colors.purple),
      Reward(
          id: '3',
          title: 'Premium Feature',
          description: 'Unlock a premium feature',
          points: 300,
          icon: Icons.star,
          color: Colors.amber),
      Reward(
          id: '4',
          title: 'Achievement Badge',
          description: 'Display rare badge',
          points: 150,
          icon: Icons.military_tech,
          color: Colors.blue),
      Reward(
          id: '5',
          title: 'Custom Voice',
          description: 'Set custom waifu voice',
          points: 500,
          icon: Icons.record_voice_over,
          color: Colors.teal),
      Reward(
          id: '6',
          title: 'Background Pack',
          description: '3 new animated backgrounds',
          points: 250,
          icon: Icons.image,
          color: Colors.orange),
      Reward(
          id: '7',
          title: 'Double EXP',
          description: '2x EXP for 24 hours',
          points: 75,
          icon: Icons.bolt,
          color: Colors.yellow),
      Reward(
          id: '8',
          title: 'Friend Slots',
          description: '+5 friend capacity',
          points: 350,
          icon: Icons.group_add,
          color: Colors.green),
    ];
  }

  Future<void> _redeemReward(Reward reward) async {
    if (_userPoints < reward.points) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Not enough points! Need ${reward.points - _userPoints} more')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: V2Theme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Text('Redeem Reward?', style: TextStyle(color: Colors.white)),
        content: Text('Use ${reward.points} points for "${reward.title}"?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: V2Theme.primaryColor),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      setState(() {
        _userPoints -= reward.points;
        _redeemedRewards.add(reward.id);
      });
      await V2Storage.prefs.setInt('user_points', _userPoints);
      await V2Storage.setList('redeemed_rewards', _redeemedRewards.toList());
      if (mounted) {
        showSuccessSnackbar(context, 'Reward redeemed successfully! 🎉');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          _buildPointsCard(),
          _buildWaifuCommentary(),
          _buildRewardsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: V2Theme.surfaceDark,
      flexibleSpace: FlexibleSpaceBar(
        title: FadeTransition(
          opacity: _headerAnimation,
          child: const Text('Reward System',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                V2Theme.primaryColor.withValues(alpha: 0.3),
                Colors.transparent
              ],
            ),
          ),
        ),
      ),
      leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context)),
      actions: [
        IconButton(icon: const Icon(Icons.leaderboard), onPressed: () {}),
      ],
    );
  }

  Widget _buildPointsCard() {
    return SliverToBoxAdapter(
      child: AnimatedEntry(
        index: 0,
        child: GlassCard(
          glow: true,
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: V2Theme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_userPoints',
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Text(
                      'Available Points',
                      style:
                          TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text('$_totalEarned',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text('Total Earned',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaifuCommentary() {
    final mood = _rewards.where((r) => !_redeemedRewards.contains(r.id)).isEmpty
        ? 'achievement'
        : 'neutral';
    return SliverToBoxAdapter(
      child: AnimatedEntry(
        index: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: WaifuCommentary(mood: mood),
        ),
      ),
    );
  }

  Widget _buildRewardsList() {
    if (_isLoading) {
      return const SliverFillRemaining(
          child: Center(
              child: CircularProgressIndicator(color: V2Theme.primaryColor)));
    }

    if (_rewards.isEmpty) {
      return const SliverFillRemaining(
          child: EmptyState(
        icon: Icons.card_giftcard,
        title: 'No Rewards Yet',
        subtitle: 'Check back later for exciting rewards!',
      ));
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final reward = _rewards[index];
            final isRedeemed = _redeemedRewards.contains(reward.id);
            return AnimatedEntry(
              index: index + 2,
              child: _buildRewardCard(reward, isRedeemed),
            );
          },
          childCount: _rewards.length,
        ),
      ),
    );
  }

  Widget _buildRewardCard(Reward reward, bool isRedeemed) {
    return GlassCard(
      onTap: isRedeemed ? null : () => _redeemReward(reward),
      child: Opacity(
        opacity: isRedeemed ? 0.5 : 1.0,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: reward.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(reward.icon, color: reward.color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(reward.title,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      if (isRedeemed) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('✓',
                              style: TextStyle(color: Colors.green)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(reward.description,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: isRedeemed
                    ? null
                    : LinearGradient(
                        colors: [V2Theme.primaryColor, V2Theme.secondaryColor]),
                color: isRedeemed ? Colors.grey.withValues(alpha: 0.3) : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isRedeemed ? 'Redeemed' : '${reward.points} pts',
                style: TextStyle(
                  color: isRedeemed ? Colors.white54 : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Reward {
  final String id;
  final String title;
  final String description;
  final int points;
  final IconData icon;
  final Color color;

  Reward(
      {required this.id,
      required this.title,
      required this.description,
      required this.points,
      required this.icon,
      required this.color});
}



