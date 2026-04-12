import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Monetization Core Service
/// Manages in-app purchases, subscriptions, rewards, and battle pass
class MonetizationService {
  static final MonetizationService _instance = MonetizationService._internal();

  factory MonetizationService() {
    return _instance;
  }

  MonetizationService._internal();

  late SharedPreferences _prefs;
  final Map<String, PurchaseItem> _purchaseHistory = {};
  final Map<String, Subscription> _activeSubscriptions = {};
  final Map<String, CosmeticItem> _inventory = {};

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPurchaseHistory();
    await _loadSubscriptions();
    await _loadInventory();
    debugPrint('[Monetization] Service initialized');
  }

  // ===== CURRENCY MANAGEMENT =====
  Future<UserWallet> getUserWallet() async {
    final stored = _prefs.getString('user_wallet');
    if (stored == null) {
      final wallet = UserWallet(
        coins: 0,
        premiumCurrency: 0,
        lastUpdated: DateTime.now(),
      );
      await _saveWallet(wallet);
      return wallet;
    }
    return UserWallet.fromJson(jsonDecode(stored));
  }

  Future<void> addCoins(int amount, String reason) async {
    final wallet = await getUserWallet();
    wallet.coins += amount;
    wallet.lastUpdated = DateTime.now();
    await _saveWallet(wallet);
    debugPrint('[Monetization] Added $amount coins. Reason: $reason');
  }

  Future<void> addPremiumCurrency(int amount, String transactionId) async {
    final wallet = await getUserWallet();
    wallet.premiumCurrency += amount;
    wallet.lastUpdated = DateTime.now();
    await _saveWallet(wallet);

    // Record transaction
    final transaction = MonetaryTransaction(
      id: transactionId,
      type: 'premium_purchase',
      amount: amount,
      timestamp: DateTime.now(),
      distributor: 'store',
    );
    await _recordTransaction(transaction);
  }

  Future<bool> spendCoins(int amount, String purpose) async {
    final wallet = await getUserWallet();
    if (wallet.coins < amount) {
      debugPrint('[Monetization] Insufficient coins for $purpose');
      return false;
    }

    wallet.coins -= amount;
    await _saveWallet(wallet);
    debugPrint('[Monetization] Spent $amount coins on $purpose');
    return true;
  }

  // ===== IN-APP PURCHASES =====
  Future<void> recordPurchase({
    required String itemId,
    required String itemName,
    required double price,
    required String currency,
    required String category, // 'cosmetic', 'battle_pass', 'feature'
  }) async {
    final purchase = PurchaseItem(
      id: itemId,
      name: itemName,
      price: price,
      currency: currency,
      category: category,
      purchaseDate: DateTime.now(),
      expiresAt: _getExpirationDate(category),
    );

    _purchaseHistory[itemId] = purchase;
    await _savePurchaseHistory();

    // Add to inventory if cosmetic
    if (category == 'cosmetic') {
      final cosmetic = CosmeticItem(
        id: itemId,
        name: itemName,
        type: _categorizeCosmeticType(itemName),
        rarity: _determineRarity(price),
        acquiredDate: DateTime.now(),
      );
      _inventory[itemId] = cosmetic;
      await _saveInventory();
    }

    // Grant currency equivalence
    await addCoins((price * 100).toInt(), 'purchase_reward_$itemId');

    debugPrint('[Monetization] Purchase recorded: $itemName for $price $currency');
  }

  Future<List<PurchaseItem>> getPurchaseHistory() async {
    await _loadPurchaseHistory();
    return _purchaseHistory.values.toList()
      ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
  }

  Future<double> getTotalSpent() async {
    final history = await getPurchaseHistory();
    return history.fold<double>(0.0, (sum, item) => sum + item.price);
  }

  // ===== SUBSCRIPTIONS =====
  Future<void> activateSubscription({
    required String subscriptionId,
    required String tier, // 'free', 'pro', 'premium'
    required int durationDays,
  }) async {
    final subscription = Subscription(
      id: subscriptionId,
      tier: tier,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: durationDays)),
      autoRenew: true,
      features: _getTierFeatures(tier),
    );

    _activeSubscriptions[tier] = subscription;
    await _saveSubscriptions();

    // Grant monthly bonus
    final bonusCoins = tier == 'premium' ? 1000 : tier == 'pro' ? 500 : 100;
    await addCoins(bonusCoins, 'subscription_bonus_$tier');

    debugPrint('[Monetization] Subscription activated: $tier');
  }

  Future<Subscription?> getActiveSubscription(String tier) async {
    final stored = _activeSubscriptions[tier];
    if (stored != null && stored.endDate.isAfter(DateTime.now())) {
      return stored;
    }
    return null;
  }

  Future<List<String>> getUnlockedFeatures() async {
    final features = <String>{'free_features'};

    for (final tier in ['pro', 'premium']) {
      final sub = await getActiveSubscription(tier);
      if (sub != null) {
        features.addAll(sub.features);
      }
    }

    return features.toList();
  }

  // ===== COSMETICS & INVENTORY =====
  Future<void> unlockCosmetic(CosmeticItem item) async {
    _inventory[item.id] = item;
    await _saveInventory();
    debugPrint('[Monetization] Cosmetic unlocked: ${item.name}');
  }

  Future<List<CosmeticItem>> getInventory({String? type}) async {
    await _loadInventory();
    var items = _inventory.values.toList();
    if (type != null) {
      items = items.where((c) => c.type == type).toList();
    }
    return items..sort((a, b) => b.acquiredDate.compareTo(a.acquiredDate));
  }

  Future<CosmeticItem?> getEquippedCosmetic(String slot) async {
    final equipped = _prefs.getString('equipped_cosmetic_$slot');
    if (equipped == null) return null;
    return CosmeticItem.fromJson(jsonDecode(equipped));
  }

  Future<void> equipCosmetic(String slot, CosmeticItem item) async {
    await _prefs.setString('equipped_cosmetic_$slot', jsonEncode(item.toJson()));
    debugPrint('[Monetization] Equipped: ${item.name} to $slot');
  }

  // ===== BATTLE PASS =====
  Future<BattlePassData> getBattlePassData() async {
    final stored = _prefs.getString('battle_pass_data');
    if (stored == null) {
      return BattlePassData(
        level: 1,
        experience: 0,
        tier: 'free',
        currentSeason: 1,
        seasonStartDate: DateTime.now(),
        seasonEndDate: DateTime.now().add(const Duration(days: 90)),
        rewards: _generateBattlePassRewards(1, 'free'),
        claimedRewards: [],
      );
    }
    return BattlePassData.fromJson(jsonDecode(stored));
  }

  Future<void> addBattlePassExperience(int xp, String activity) async {
    final bpData = await getBattlePassData();
    bpData.experience += xp;

    // Level up check (1000 xp per level)
    final newLevel = (bpData.experience ~/ 1000) + 1;
    if (newLevel > bpData.level) {
      bpData.level = newLevel;
      await addCoins(500, 'bp_level_up_$newLevel');
    }

    await _prefs.setString('battle_pass_data', jsonEncode(bpData.toJson()));
    debugPrint('[Monetization] Battle Pass XP +$xp from $activity');
  }

  Future<List<BattlePassReward>> claimBattlePassReward(int rewardLevel) async {
    final bpData = await getBattlePassData();

    if (bpData.level < rewardLevel) {
      debugPrint('[Monetization] Cannot claim reward - insufficient level');
      return [];
    }

    if (bpData.claimedRewards.contains(rewardLevel)) {
      debugPrint('[Monetization] Reward already claimed');
      return [];
    }

    final reward = bpData.rewards.firstWhere(
      (r) => r.level == rewardLevel,
      orElse: () => BattlePassReward(
        level: rewardLevel,
        description: 'Unknown Reward',
        itemId: '',
      ),
    );

    bpData.claimedRewards.add(rewardLevel);

    // Grant reward
    if (reward.itemId.startsWith('cosmetic_')) {
      await unlockCosmetic(CosmeticItem(
        id: reward.itemId,
        name: reward.description,
        type: 'seasonal',
        rarity: 'mythic',
        acquiredDate: DateTime.now(),
      ));
    } else if (reward.itemId.startsWith('coins_')) {
      final coins = int.tryParse(reward.itemId.replaceFirst('coins_', '')) ?? 0;
      await addCoins(coins, 'bp_reward_level_$rewardLevel');
    }

    await _prefs.setString('battle_pass_data', jsonEncode(bpData.toJson()));
    return bpData.rewards;
  }

  // ===== REWARDS MARKETPLACE =====
  Future<List<RewardShopItem>> getRewardShopItems() async {
    return [
      RewardShopItem(
        id: 'cosmetic_avatar_1',
        name: 'Celestial Avatar',
        description: 'Rare avatar cosmetic',
        price: 2500,
        currency: 'coins',
        rarity: 'rare',
        stock: 999,
      ),
      RewardShopItem(
        id: 'cosmetic_theme_1',
        name: 'Midnight Premium Theme',
        description: 'Exclusive theme unlock',
        price: 1500,
        currency: 'coins',
        rarity: 'epic',
        stock: 999,
      ),
      RewardShopItem(
        id: 'feature_premium_chat',
        name: 'Premium Chat Mode',
        description: 'Unlock advanced copilot features',
        price: 1000,
        currency: 'coins',
        rarity: 'rare',
        stock: 999,
      ),
      RewardShopItem(
        id: 'cosmetic_badge_collector',
        name: 'Collector\'s Badge',
        description: 'Show your achievement status',
        price: 500,
        currency: 'coins',
        rarity: 'uncommon',
        stock: 999,
      ),
    ];
  }

  Future<bool> purchaseFromShop(String itemId) async {
    final items = await getRewardShopItems();
    final item = items.firstWhere(
      (i) => i.id == itemId,
      orElse: () => RewardShopItem(
        id: '',
        name: '',
        description: '',
        price: 0,
        currency: 'coins',
        rarity: 'common',
        stock: 0,
      ),
    );

    if (item.stock <= 0) {
      debugPrint('[Monetization] Item out of stock');
      return false;
    }

    if (item.currency == 'coins') {
      if (!await spendCoins(item.price, 'shop_purchase_$itemId')) {
        return false;
      }
    }

    // Process reward
    if (itemId.startsWith('cosmetic_')) {
      await unlockCosmetic(CosmeticItem(
        id: itemId,
        name: item.name,
        type: 'shop',
        rarity: item.rarity,
        acquiredDate: DateTime.now(),
      ));
    }

    debugPrint('[Monetization] Purchased from shop: ${item.name}');
    return true;
  }

  // ===== ANALYTICS & REPORTING =====
  Future<MonetizationReport> generateReport() async {
    final wallet = await getUserWallet();
    final history = await getPurchaseHistory();
    final inventory = await getInventory();
    final totalSpent = await getTotalSpent();
    final bpData = await getBattlePassData();

    return MonetizationReport(
      totalCoinsEarned: wallet.coins,
      totalPremiumCurrency: wallet.premiumCurrency,
      totalSpent: totalSpent,
      purchaseCount: history.length,
      uniqueItems: inventory.length,
      battlePassLevel: bpData.level,
      activeSubscriptions: _activeSubscriptions.length,
      generatedAt: DateTime.now(),
    );
  }

  // ===== INTERNAL HELPERS =====
  DateTime _getExpirationDate(String category) {
    switch (category) {
      case 'battle_pass':
        return DateTime.now().add(const Duration(days: 90));
      case 'subscription':
        return DateTime.now().add(const Duration(days: 30));
      default:
        return DateTime.now().add(const Duration(days: 365));
    }
  }

  String _categorizeCosmeticType(String name) {
    if (name.toLowerCase().contains('avatar') || name.toLowerCase().contains('profile')) {
      return 'avatar';
    } else if (name.toLowerCase().contains('theme') || name.toLowerCase().contains('background')) {
      return 'theme';
    } else if (name.toLowerCase().contains('effect') || name.toLowerCase().contains('particle')) {
      return 'effect';
    }
    return 'other';
  }

  String _determineRarity(double price) {
    if (price > 50) return 'mythic';
    if (price > 20) return 'epic';
    if (price > 10) return 'rare';
    if (price > 5) return 'uncommon';
    return 'common';
  }

  List<String> _getTierFeatures(String tier) {
    switch (tier) {
      case 'premium':
        return [
          'ad_free',
          'advanced_chat',
          'priority_support',
          'exclusive_cosmetics',
          'increased_rewards',
          'vip_badge',
        ];
      case 'pro':
        return [
          'advanced_chat',
          'increased_rewards',
          'exclusive_cosmetics',
        ];
      default:
        return ['basic_chat', 'standard_rewards'];
    }
  }

  List<BattlePassReward> _generateBattlePassRewards(int season, String tier) {
    return [
      for (int i = 1; i <= 100; i++)
        BattlePassReward(
          level: i,
          description: 'Season $season Level $i Reward',
          itemId: i % 5 == 0 ? 'cosmetic_bp_s${season}_l$i' : 'coins_${i * 100}',
        ),
    ];
  }

  Future<void> _recordTransaction(MonetaryTransaction transaction) async {
    final stored = _prefs.getStringList('monetary_transactions') ?? [];
    stored.add(jsonEncode(transaction.toJson()));
    await _prefs.setStringList('monetary_transactions', stored);
  }

  Future<void> _saveWallet(UserWallet wallet) async {
    await _prefs.setString('user_wallet', jsonEncode(wallet.toJson()));
  }

  Future<void> _savePurchaseHistory() async {
    final data = _purchaseHistory.entries
        .map((e) => jsonEncode(e.value.toJson()))
        .toList();
    await _prefs.setStringList('purchase_history', data);
  }

  Future<void> _loadPurchaseHistory() async {
    final data = _prefs.getStringList('purchase_history') ?? [];
    _purchaseHistory.clear();
    for (final item in data) {
      try {
        final purchase = PurchaseItem.fromJson(jsonDecode(item));
        _purchaseHistory[purchase.id] = purchase;
      } catch (e) {
        debugPrint('[Monetization] Error loading purchase: $e');
      }
    }
  }

  Future<void> _saveSubscriptions() async {
    final data = _activeSubscriptions.entries
        .map((e) => jsonEncode(e.value.toJson()))
        .toList();
    await _prefs.setStringList('subscriptions', data);
  }

  Future<void> _loadSubscriptions() async {
    final data = _prefs.getStringList('subscriptions') ?? [];
    _activeSubscriptions.clear();
    for (final item in data) {
      try {
        final sub = Subscription.fromJson(jsonDecode(item));
        _activeSubscriptions[sub.tier] = sub;
      } catch (e) {
        debugPrint('[Monetization] Error loading subscription: $e');
      }
    }
  }

  Future<void> _saveInventory() async {
    final data = _inventory.entries
        .map((e) => jsonEncode(e.value.toJson()))
        .toList();
    await _prefs.setStringList('cosmetic_inventory', data);
  }

  Future<void> _loadInventory() async {
    final data = _prefs.getStringList('cosmetic_inventory') ?? [];
    _inventory.clear();
    for (final item in data) {
      try {
        final cosmetic = CosmeticItem.fromJson(jsonDecode(item));
        _inventory[cosmetic.id] = cosmetic;
      } catch (e) {
        debugPrint('[Monetization] Error loading cosmetic: $e');
      }
    }
  }
}

// ===== DATA MODELS =====

class UserWallet {
  int coins;
  int premiumCurrency;
  DateTime lastUpdated;

  UserWallet({
    required this.coins,
    required this.premiumCurrency,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'coins': coins,
    'premium': premiumCurrency,
    'updated': lastUpdated.toIso8601String(),
  };

  factory UserWallet.fromJson(Map<String, dynamic> json) {
    return UserWallet(
      coins: json['coins'] as int,
      premiumCurrency: json['premium'] as int,
      lastUpdated: DateTime.parse(json['updated'] as String),
    );
  }
}

class PurchaseItem {
  final String id;
  final String name;
  final double price;
  final String currency;
  final String category;
  final DateTime purchaseDate;
  final DateTime? expiresAt;

  PurchaseItem({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.category,
    required this.purchaseDate,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'currency': currency,
    'category': category,
    'purchaseDate': purchaseDate.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
  };

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      category: json['category'] as String,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
    );
  }
}

class Subscription {
  final String id;
  final String tier;
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;
  final List<String> features;

  Subscription({
    required this.id,
    required this.tier,
    required this.startDate,
    required this.endDate,
    required this.autoRenew,
    required this.features,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'tier': tier,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'autoRenew': autoRenew,
    'features': features,
  };

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      tier: json['tier'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      autoRenew: json['autoRenew'] as bool,
      features: List<String>.from(json['features'] as List),
    );
  }
}

class CosmeticItem {
  final String id;
  final String name;
  final String type; // avatar, theme, effect, etc
  final String rarity; // common, uncommon, rare, epic, mythic
  final DateTime acquiredDate;

  CosmeticItem({
    required this.id,
    required this.name,
    required this.type,
    required this.rarity,
    required this.acquiredDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'rarity': rarity,
    'acquiredDate': acquiredDate.toIso8601String(),
  };

  factory CosmeticItem.fromJson(Map<String, dynamic> json) {
    return CosmeticItem(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      rarity: json['rarity'] as String,
      acquiredDate: DateTime.parse(json['acquiredDate'] as String),
    );
  }
}

class BattlePassData {
  int level;
  int experience;
  final String tier;
  final int currentSeason;
  final DateTime seasonStartDate;
  final DateTime seasonEndDate;
  final List<BattlePassReward> rewards;
  final List<int> claimedRewards;

  BattlePassData({
    required this.level,
    required this.experience,
    required this.tier,
    required this.currentSeason,
    required this.seasonStartDate,
    required this.seasonEndDate,
    required this.rewards,
    required this.claimedRewards,
  });

  Map<String, dynamic> toJson() => {
    'level': level,
    'experience': experience,
    'tier': tier,
    'season': currentSeason,
    'seasonStart': seasonStartDate.toIso8601String(),
    'seasonEnd': seasonEndDate.toIso8601String(),
    'rewards': rewards.map((r) => r.toJson()).toList(),
    'claimed': claimedRewards,
  };

  factory BattlePassData.fromJson(Map<String, dynamic> json) {
    return BattlePassData(
      level: json['level'] as int,
      experience: json['experience'] as int,
      tier: json['tier'] as String,
      currentSeason: json['season'] as int,
      seasonStartDate: DateTime.parse(json['seasonStart'] as String),
      seasonEndDate: DateTime.parse(json['seasonEnd'] as String),
      rewards: (json['rewards'] as List)
          .map((r) => BattlePassReward.fromJson(r as Map<String, dynamic>))
          .toList(),
      claimedRewards: List<int>.from(json['claimed'] as List),
    );
  }
}

class BattlePassReward {
  final int level;
  final String description;
  final String itemId;

  BattlePassReward({
    required this.level,
    required this.description,
    required this.itemId,
  });

  Map<String, dynamic> toJson() => {
    'level': level,
    'description': description,
    'itemId': itemId,
  };

  factory BattlePassReward.fromJson(Map<String, dynamic> json) {
    return BattlePassReward(
      level: json['level'] as int,
      description: json['description'] as String,
      itemId: json['itemId'] as String,
    );
  }
}

class RewardShopItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final String currency;
  final String rarity;
  final int stock;

  RewardShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.rarity,
    required this.stock,
  });
}

class MonetaryTransaction {
  final String id;
  final String type; // purchase, reward, refund
  final int amount;
  final DateTime timestamp;
  final String distributor;

  MonetaryTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.timestamp,
    required this.distributor,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
    'distributor': distributor,
  };
}

class MonetizationReport {
  final int totalCoinsEarned;
  final int totalPremiumCurrency;
  final double totalSpent;
  final int purchaseCount;
  final int uniqueItems;
  final int battlePassLevel;
  final int activeSubscriptions;
  final DateTime generatedAt;

  MonetizationReport({
    required this.totalCoinsEarned,
    required this.totalPremiumCurrency,
    required this.totalSpent,
    required this.purchaseCount,
    required this.uniqueItems,
    required this.battlePassLevel,
    required this.activeSubscriptions,
    required this.generatedAt,
  });

  String exportAsReport() {
    return '''
=== MONETIZATION REPORT ===
Generated: $generatedAt

CURRENCY:
- Total Coins: $totalCoinsEarned
- Premium Currency: $totalPremiumCurrency
- Total Spent: \$$totalSpent

INVENTORY:
- Purchases: $purchaseCount
- Unique Items: $uniqueItems
- Battle Pass Level: $battlePassLevel

SUBSCRIPTIONS:
- Active: $activeSubscriptions
''';
  }
}


