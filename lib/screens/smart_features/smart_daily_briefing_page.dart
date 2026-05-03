import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/smart_features/daily_briefing_service.dart';

class SmartDailyBriefingPage extends StatefulWidget {
  const SmartDailyBriefingPage({super.key});

  @override
  State<SmartDailyBriefingPage> createState() => _SmartDailyBriefingPageState();
}

class _SmartDailyBriefingPageState extends State<SmartDailyBriefingPage>
    with SingleTickerProviderStateMixin {
  final _service = DailyBriefingService.instance;
  bool _loading = false;
  Map<String, dynamic>? _briefing;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const _bg = Color(0xFF0A0B14);
  static const _accent = Color(0xFF00BCD4);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _loadBriefing();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBriefing() async {
    final briefing = await _service.getBriefing();
    if (mounted) {
      setState(() => _briefing = briefing);
      if (briefing != null) {
        _animCtrl.forward();
      }
    }
  }

  Future<void> _generateBriefing() async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      final briefing = await _service.generateBriefing();
      if (mounted) {
        setState(() {
          _briefing = briefing;
          _loading = false;
        });
        _animCtrl.reset();
        _animCtrl.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to generate briefing',
              style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Late Night';
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 5) return '🌙';
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    if (hour < 21) return '🌅';
    return '✨';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h12:$minute $period';
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _weatherIcon(String code) {
    if (code.isEmpty) return '🌡️';
    final iconCode = int.tryParse(code) ?? 0;
    if (iconCode >= 200 && iconCode < 300) return '⛈️';
    if (iconCode >= 300 && iconCode < 400) return '🌧️';
    if (iconCode >= 500 && iconCode < 600) return '🌧️';
    if (iconCode >= 600 && iconCode < 700) return '❄️';
    if (iconCode >= 700 && iconCode < 800) return '🌫️';
    if (iconCode == 800) return '☀️';
    if (iconCode == 801) return '🌤️';
    if (iconCode == 802) return '⛅';
    if (iconCode > 802) return '☁️';
    return '🌡️';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('✨ Smart Daily Briefing',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        actions: [
          if (_briefing != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: _accent),
              onPressed: _generateBriefing,
              tooltip: 'Refresh Briefing',
            ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Generating your briefing...',
                      style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 8),
                  Text('Zero Two is preparing your day~',
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            )
          : _briefing == null
              ? _buildEmptyState()
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeader(now),
                      const SizedBox(height: 20),
                      _buildWeatherCard(),
                      const SizedBox(height: 12),
                      _buildCalendarCard(),
                      const SizedBox(height: 12),
                      _buildTasksCard(),
                      const SizedBox(height: 12),
                      _buildRemindersCard(),
                      const SizedBox(height: 12),
                      _buildMemoriesCard(),
                      const SizedBox(height: 12),
                      _buildAITipCard(),
                      const SizedBox(height: 24),
                      _buildRefreshButton(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_getGreetingEmoji(), style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('${_getGreeting()}, Darling~',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 22)),
          const SizedBox(height: 8),
          Text('Tap the button below to generate your daily briefing',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildHeader(DateTime now) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent.withValues(alpha: 0.15), _accent.withValues(alpha: 0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_getGreetingEmoji(), style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_getGreeting()}, Darling~',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(_formatTime(now),
                        style: GoogleFonts.outfit(
                            color: _accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Today',
                    style: GoogleFonts.outfit(
                        color: _accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_formatDate(now),
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    final weather = _briefing?['weather'] as Map<String, dynamic>?;
    if (weather == null) return const SizedBox.shrink();

    final temp = weather['temp'] ?? '?';
    final feelsLike = weather['feels_like'] ?? '?';
    final desc = weather['description'] ?? 'unknown';
    final location = weather['location'] ?? 'Unknown';
    final humidity = weather['humidity'] ?? '?';
    final wind = weather['wind'] ?? '?';
    final iconCode = weather['icon'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌤️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('Weather',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(location,
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(_weatherIcon(iconCode), style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$temp°C',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 32)),
                    Text(desc,
                        style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                            fontSize: 13)),
                    Text('Feels like $feelsLike°C',
                        style: GoogleFonts.outfit(
                            color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _weatherStat('💧', '$humidity%', 'Humidity'),
              const SizedBox(width: 12),
              _weatherStat('💨', '$wind m/s', 'Wind'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weatherStat(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
                Text(label,
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    final calendar = _briefing?['calendar'] as List?;
    if (calendar == null || calendar.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('Today\'s Schedule',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          ...calendar.map<Map<String, String>>((e) => Map<String, String>.from(e as Map)).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['time'] ?? '',
                            style: GoogleFonts.outfit(
                                color: _accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 11)),
                        Text(item['event'] ?? '',
                            style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTasksCard() {
    final tasks = _briefing?['tasks'] as List?;
    if (tasks == null || tasks.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('Tasks',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          ...tasks.map<Map<String, String>>((e) => Map<String, String>.from(e as Map)).map((task) {
            final priorityColor = _priorityColor(task['priority'] ?? 'low');
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: priorityColor.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.task_alt_rounded, color: priorityColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(task['title'] ?? '',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(task['status'] ?? 'pending',
                        style: GoogleFonts.outfit(color: priorityColor, fontSize: 10)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRemindersCard() {
    final reminders = _briefing?['reminders'] as List?;
    if (reminders == null || reminders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🔔', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('Reminders',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text('No reminders for today!',
                      style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontWeight: FontWeight.w500,
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔔', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('Reminders',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${reminders.length}',
                    style: GoogleFonts.outfit(color: _accent, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...reminders.map((r) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _accent.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_rounded, color: _accent, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(r.toString(),
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 12, height: 1.3)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMemoriesCard() {
    final memories = _briefing?['memories'] as List?;
    if (memories == null || memories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💭', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('Memories',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  const Text('📝', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text('No recent memories',
                      style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontWeight: FontWeight.w500,
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💭', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('Memories',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          ...memories.map((m) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.12)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.favorite_rounded,
                      color: Colors.purple.withValues(alpha: 0.6), size: 14),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(m.toString(),
                        style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.3,
                            fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAITipCard() {
    final aiTip = _briefing?['ai_tip'] as String?;
    if (aiTip == null || aiTip.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.08),
            Colors.orange.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 16),
              ),
              const SizedBox(width: 10),
              Text('Zero Two\'s Tip',
                  style: GoogleFonts.outfit(
                      color: Colors.amber,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Text(aiTip,
              style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generateBriefing,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: Text('Generate Briefing',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFFF7043);
      case 'medium':
        return const Color(0xFFFFB74D);
      case 'low':
      default:
        return const Color(0xFF81C784);
    }
  }
}
