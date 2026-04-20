import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Waifu Tier List Maker — Drag-and-drop builder with save/share.
class WaifuTierListPage extends StatefulWidget {
  const WaifuTierListPage({super.key});
  @override
  State<WaifuTierListPage> createState() => _WaifuTierListPageState();
}

class _WaifuTierListPageState extends State<WaifuTierListPage> with SingleTickerProviderStateMixin {
  final List<_TierRow> _tiers = [
    _TierRow('S', const Color(0xFFFF7F7F), []),
    _TierRow('A', const Color(0xFFFFBF7F), []),
    _TierRow('B', const Color(0xFFFFDF7F), []),
    _TierRow('C', const Color(0xFFFFFF7F), []),
    _TierRow('D', const Color(0xFFBFFF7F), []),
  ];

  final List<_TierItem> _pool = [
    _TierItem('1', 'Zero Two', 'Darling in the FRANXX'),
    _TierItem('2', 'Rem', 'Re:Zero'),
    _TierItem('3', 'Makima', 'Chainsaw Man'),
    _TierItem('4', 'Miku', 'Vocaloid'),
    _TierItem('5', 'Asuna', 'Sword Art Online'),
    _TierItem('6', 'Marin', 'My Dress-Up Darling'),
    _TierItem('7', 'Yor', 'Spy x Family'),
    _TierItem('8', 'Power', 'Chainsaw Man'),
    _TierItem('9', 'Aqua', 'Konosuba'),
    _TierItem('10', 'Megumin', 'Konosuba'),
    _TierItem('11', 'Emilia', 'Re:Zero'),
    _TierItem('12', 'Nezuko', 'Demon Slayer'),
  ];
  late AnimationController _animCtrl;


  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    try {
      final d = prefs.getString('waifu_tier_list');
      if (d != null) {
        final data = jsonDecode(d) as Map<String, dynamic>;
        // Restore tiers
        for (int i = 0; i < _tiers.length; i++) {
          final items = (data['tier_$i'] as List?)?.map((e) =>
            _TierItem(e['id'], e['name'], e['series'])).toList() ?? [];
          _tiers[i].items.clear();
          _tiers[i].items.addAll(items);
        }
        // Restore pool
        final poolData = (data['pool'] as List?)?.map((e) =>
          _TierItem(e['id'], e['name'], e['series'])).toList() ?? [];
        _pool.clear();
        _pool.addAll(poolData);
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{};
    for (int i = 0; i < _tiers.length; i++) {
      data['tier_$i'] = _tiers[i].items.map((e) =>
        {'id': e.id, 'name': e.name, 'series': e.series}).toList();
    }
    data['pool'] = _pool.map((e) =>
      {'id': e.id, 'name': e.name, 'series': e.series}).toList();
    await prefs.setString('waifu_tier_list', jsonEncode(data));
  }

  void _shareTierList() {
    final lines = <String>[];
    for (final tier in _tiers) {
      if (tier.items.isNotEmpty) {
        lines.add('${tier.label}: ${tier.items.map((i) => i.name).join(', ')}');
      }
    }
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add characters to tiers first!')));
      return;
    }
    final text = '🏆 My Waifu Tier List\n${lines.join('\n')}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tier list copied to clipboard! ✅'),
          backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('🏆 Waifu Tier List', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: Colors.transparent, elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: _shareTierList),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: () {
            setState(() {
              for (final tier in _tiers) {
                _pool.addAll(tier.items);
                tier.items.clear();
              }
            });
            _save();
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _tiers.length,
              itemBuilder: (context, index) {
                final tier = _tiers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: IntrinsicHeight(child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 80,
                        decoration: BoxDecoration(
                          color: tier.color,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                          border: Border.all(color: Colors.black45, width: 1),
                        ),
                        child: Center(
                          child: Text(tier.label, style: const TextStyle(
                            color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 66),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                            border: Border.all(color: Colors.black45, width: 1),
                          ),
                          child: DragTarget<_TierItem>(
                            onWillAcceptWithDetails: (details) => true,
                            onAcceptWithDetails: (details) {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _removeFromCurrentLocation(details.data);
                                tier.items.add(details.data);
                              });
                              _save();
                            },
                            builder: (context, candidateData, rejectedData) {
                              return Container(
                                color: candidateData.isNotEmpty ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Wrap(
                                    spacing: 4, runSpacing: 4,
                                    children: tier.items.map((item) => _buildDraggableItem(item)).toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  )),
                );
              },
            ),
          ),
          Container(height: 2, color: Colors.grey.shade800),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: Colors.white.withValues(alpha: 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Character Pool (${_pool.length})', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: DragTarget<_TierItem>(
                      onWillAcceptWithDetails: (details) => true,
                      onAcceptWithDetails: (details) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _removeFromCurrentLocation(details.data);
                          _pool.add(details.data);
                        });
                        _save();
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          width: double.infinity,
                          color: candidateData.isNotEmpty ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(8),
                            child: Wrap(
                              spacing: 8, runSpacing: 8,
                              children: _pool.map((item) => _buildDraggableItem(item)).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _removeFromCurrentLocation(_TierItem item) {
    _pool.remove(item);
    for (var tier in _tiers) {
      tier.items.remove(item);
    }
  }

  Widget _buildDraggableItem(_TierItem item) {
    return LongPressDraggable<_TierItem>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
            border: Border.all(color: Colors.purpleAccent, width: 2),
          ),
          child: Center(child: Text(item.name.substring(0, min(item.name.length, 4)),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, decoration: TextDecoration.none))),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildItemCard(item),
      ),
      child: _buildItemCard(item),
    );
  }

  Widget _buildItemCard(_TierItem item) {
    return Container(
      width: 66, height: 66,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(item.name,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            Text(item.series,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 7),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

class _TierRow {
  final String label;
  final Color color;
  final List<_TierItem> items;
  _TierRow(this.label, this.color, this.items);
}

class _TierItem {
  final String id;
  final String name;
  final String series;
  _TierItem(this.id, this.name, this.series);
}



