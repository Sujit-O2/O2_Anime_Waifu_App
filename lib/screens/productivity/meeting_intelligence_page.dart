import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/productivity/meeting_intelligence_service.dart';

class MeetingIntelligencePage extends StatefulWidget {
  const MeetingIntelligencePage({super.key});

  @override
  State<MeetingIntelligencePage> createState() =>
      _MeetingIntelligencePageState();
}

class _MeetingIntelligencePageState extends State<MeetingIntelligencePage> {
  final _service = MeetingIntelligenceService.instance;
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _participantsCtrl = TextEditingController();
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  MeetingType _type = MeetingType.teamSync;
  bool _creating = false;

  static const _typeColors = {
    MeetingType.teamSync: Color(0xFF4FC3F7),
    MeetingType.oneOnOne: Color(0xFFFF80AB),
    MeetingType.planning: Color(0xFF81C784),
    MeetingType.projectReview: Color(0xFFFFB74D),
    MeetingType.clientMeeting: Color(0xFFCE93D8),
    MeetingType.other: Color(0xFF80CBC4),
  };

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _participantsCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _creating = true);
    await _service.createMeeting(
      title: _titleCtrl.text.trim(),
      participants: _participantsCtrl.text.trim(),
      startTime: _startTime,
      endTime: _endTime,
      type: _type,
    );
    _titleCtrl.clear();
    _participantsCtrl.clear();
    if (mounted) {
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meeting created! 🤝',
              style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: Colors.deepPurple.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showDateTimePicker(context, isStart ? _startTime : _endTime);
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          if (_endTime.isBefore(_startTime)) {
            _endTime = _startTime.add(const Duration(hours: 1));
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<DateTime?> showDateTimePicker(BuildContext ctx, DateTime initial) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Colors.deepPurpleAccent),
        ),
        child: child!,
      ),
    );
    if (date == null) return null;
    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Colors.deepPurpleAccent),
        ),
        child: child!,
      ),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _fmt(DateTime dt) =>
      '${dt.day}/${dt.month}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Color _typeColor(MeetingType t) => _typeColors[t] ?? Colors.deepPurpleAccent;

  @override
  Widget build(BuildContext context) {
    final activeColor = _typeColor(_type);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('🤝 Meeting Intelligence',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            // Insights card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.deepPurpleAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.insights_rounded,
                      color: Colors.deepPurpleAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_service.getMeetingInsights(),
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 13, height: 1.4)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Form card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Meeting',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(height: 14),

                  // Title
                  _field(_titleCtrl, 'Meeting Title', Icons.title_rounded,
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Title required' : null),
                  const SizedBox(height: 10),

                  // Participants
                  _field(_participantsCtrl, 'Participants (comma separated)',
                      Icons.people_rounded,
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Add participants' : null),
                  const SizedBox(height: 14),

                  // Meeting type
                  Text('Meeting Type',
                      style: GoogleFonts.outfit(
                          color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MeetingType.values.map((t) {
                      final sel = _type == t;
                      final c = _typeColor(t);
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _type = t);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel
                                ? c.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: sel
                                    ? c.withValues(alpha: 0.5)
                                    : Colors.white12,
                                width: sel ? 1.5 : 1),
                          ),
                          child: Text(t.name,
                              style: GoogleFonts.outfit(
                                  color: sel ? c : Colors.white54,
                                  fontSize: 11,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.normal)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Time pickers
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickTime(true),
                        child: _timeChip('Start', _fmt(_startTime),
                            Icons.play_arrow_rounded, activeColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickTime(false),
                        child: _timeChip('End', _fmt(_endTime),
                            Icons.stop_rounded, Colors.redAccent),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),

                  // Duration display
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: activeColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(children: [
                      Icon(Icons.timer_rounded, color: activeColor, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Duration: ${_endTime.difference(_startTime).inMinutes} min',
                        style: GoogleFonts.outfit(
                            color: activeColor, fontSize: 12),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Create button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _creating ? null : _create,
                      icon: _creating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                          _creating ? 'Creating...' : 'Create Meeting',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.08))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: Colors.deepPurpleAccent.withValues(alpha: 0.5))),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.redAccent)),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _timeChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10)),
            Text(value,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ]),
        ),
        Icon(Icons.edit_rounded, color: color.withValues(alpha: 0.5), size: 14),
      ]),
    );
  }
}
