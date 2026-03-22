import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Waifu Tier List Maker — Drag-and-drop builder for tier lists.
class WaifuTierListPage extends StatefulWidget {
  const WaifuTierListPage({super.key});
  @override
  State<WaifuTierListPage> createState() => _WaifuTierListPageState();
}

class _WaifuTierListPageState extends State<WaifuTierListPage> {
  // Define tiers
  final List<_TierRow> _tiers = [
    _TierRow('S', const Color(0xFFFF7F7F), []),
    _TierRow('A', const Color(0xFFFFBF7F), []),
    _TierRow('B', const Color(0xFFFFDF7F), []),
    _TierRow('C', const Color(0xFFFFFF7F), []),
    _TierRow('D', const Color(0xFFBFFF7F), []),
  ];

  // Unassigned pool
  final List<_TierItem> _pool = [
    _TierItem('1', 'Zero Two', 'Darling in the FRANXX', 'assets/icons/classic.png'), // placeholders using text if no image
    _TierItem('2', 'Rem', 'Re:Zero', ''),
    _TierItem('3', 'Makima', 'Chainsaw Man', ''),
    _TierItem('4', 'Miku', 'Vocaloid', ''),
    _TierItem('5', 'Asuna', 'Sword Art Online', ''),
    _TierItem('6', 'Marin', 'My Dress-Up Darling', ''),
    _TierItem('7', 'Yor', 'Spy x Family', ''),
    _TierItem('8', 'Power', 'Chainsaw Man', ''),
    _TierItem('9', 'Aqua', 'Konosuba', ''),
    _TierItem('10', 'Megumin', 'Konosuba', ''),
    _TierItem('11', 'Emilia', 'Re:Zero', ''),
    _TierItem('12', 'Nezuko', 'Demon Slayer', ''),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('🏆 Waifu Tier List', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: Colors.transparent, elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving coming soon...')));
          }),
        ],
      ),
      body: Column(
        children: [
          // Tiers List
          Expanded(
            flex: 3,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _tiers.length,
              itemBuilder: (context, index) {
                final tier = _tiers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tier Label
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
                      // Drop Area
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
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
                  ),
                );
              },
            ),
          ),
          
          // Divider
          Container(height: 2, color: Colors.grey.shade800),
          
          // Bottom Pool
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: const Color(0xFF1A1A1A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Character Pool', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
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
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
            border: Border.all(color: Colors.purpleAccent, width: 2),
          ),
          child: Center(child: Text(item.name.substring(0, min(item.name.length, 4)), 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fallback text if no image
          Center(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Text(item.name, 
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
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
  final String imagePath;
  _TierItem(this.id, this.name, this.series, this.imagePath);
}
