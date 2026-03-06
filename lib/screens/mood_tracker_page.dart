part of '../main.dart';

extension _MoodTrackerPageExtension on _ChatHomePageState {
  Widget _buildMoodTrackerPage() {
    return _MoodTrackerView();
  }
}

class _MoodTrackerView extends StatefulWidget {
  @override
  State<_MoodTrackerView> createState() => _MoodTrackerViewState();
}

class _MoodTrackerViewState extends State<_MoodTrackerView> {
  List<Map<String, String>> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await MoodService.getAll();
    if (mounted) {
      setState(() {
        _entries = entries.reversed.toList();
        _loading = false;
      });
    }
  }

  Future<void> _logMood(String mood) async {
    await MoodService.saveMood(mood);
    await _load();
  }

  Future<void> _clear() async {
    final messenger = ScaffoldMessenger.of(context);
    await MoodService.clearAll();
    await _load();
    messenger
        .showSnackBar(const SnackBar(content: Text('Mood history cleared')));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('MOOD TRACKER',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2)),
                ),
                if (_entries.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 20),
                    onPressed: _clear,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('How are you feeling today, Darling?',
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
          ),
          const SizedBox(height: 12),

          // Mood chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MoodService.moods.map((mood) {
                return GestureDetector(
                  onTap: () => _logMood(mood),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(mood,
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),

          // History
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? Center(
                        child: Text('No moods logged yet, Darling! 💕',
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 13)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        itemBuilder: (ctx, i) {
                          final e = _entries[i];
                          final ts = DateTime.tryParse(e['ts'] ?? '') ??
                              DateTime.now();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              children: [
                                Text(e['mood'] ?? '',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white, fontSize: 14)),
                                const Spacer(),
                                Text(
                                  '${ts.day}/${ts.month} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white38, fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
