part of '../main.dart';

extension _SecretNotesPageExtension on _ChatHomePageState {
  Widget _buildSecretNotesPage() {
    return _SecretNotesView();
  }
}

class _SecretNotesView extends StatefulWidget {
  @override
  State<_SecretNotesView> createState() => _SecretNotesViewState();
}

class _SecretNotesViewState extends State<_SecretNotesView> {
  bool _unlocked = false;
  bool _checkingPin = true;
  final _pinCtrl = TextEditingController();
  List<Map<String, String>> _notes = [];
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkPinRequired();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkPinRequired() async {
    final has = await SecretNotesService.hasPin();
    if (!has) {
      _unlocked = true;
      await _loadNotes();
    }
    if (mounted) setState(() => _checkingPin = false);
  }

  Future<void> _loadNotes() async {
    final notes = await SecretNotesService.getAllNotes();
    if (mounted) setState(() => _notes = notes.reversed.toList());
  }

  Future<void> _unlock() async {
    final ok = await SecretNotesService.verifyPin(_pinCtrl.text.trim());
    if (ok) {
      setState(() => _unlocked = true);
      await _loadNotes();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wrong PIN, Darling 😤')));
      }
    }
    _pinCtrl.clear();
  }

  Future<void> _addNote() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty || content.isEmpty) return;
    await SecretNotesService.saveNote(title, content);
    _titleCtrl.clear();
    _contentCtrl.clear();
    await _loadNotes();
    if (mounted) Navigator.of(context).pop();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('New Secret Note',
            style: GoogleFonts.outfit(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write your secret here...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(color: Colors.white38))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white),
              onPressed: _addNote,
              child: Text('Save', style: GoogleFonts.outfit())),
        ],
      ),
    );
  }

  Future<void> _setPin() async {
    final ctlr = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Set PIN', style: GoogleFonts.outfit(color: Colors.white)),
        content: TextField(
          controller: ctlr,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '4–6 digit PIN',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(color: Colors.white38))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white),
              onPressed: () async {
                if (ctlr.text.trim().length >= 4) {
                  await SecretNotesService.setPin(ctlr.text.trim());
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PIN set! 🔒')));
                  }
                }
              },
              child: Text('Set PIN', style: GoogleFonts.outfit())),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPin) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_unlocked) {
      return _buildPinScreen();
    }
    return _buildNotesScreen();
  }

  Widget _buildPinScreen() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded,
                  color: Colors.pinkAccent, size: 64),
              const SizedBox(height: 16),
              Text('Secret Notes',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Enter your PIN to continue, Darling~',
                  style:
                      GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 24),
              TextField(
                controller: _pinCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '● ● ● ●',
                  hintStyle:
                      GoogleFonts.outfit(color: Colors.white24, fontSize: 18),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _unlock(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48)),
                onPressed: _unlock,
                child: Text('Unlock',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesScreen() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('SECRET NOTES ',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2)),
                ),
                IconButton(
                  icon: const Icon(Icons.lock_outline,
                      color: Colors.white38, size: 20),
                  tooltip: 'Set PIN',
                  onPressed: _setPin,
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded,
                      color: Colors.pinkAccent, size: 26),
                  onPressed: _showAddDialog,
                ),
              ],
            ),
          ),
          Expanded(
            child: _notes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.note_add_outlined,
                            color: Colors.white24, size: 56),
                        const SizedBox(height: 12),
                        Text('No secret notes yet, Darling!',
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text('Tap + to add one',
                            style: GoogleFonts.outfit(
                                color: Colors.white24, fontSize: 11)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notes.length,
                    itemBuilder: (ctx, i) {
                      final note = _notes[i];
                      final ts =
                          DateTime.tryParse(note['ts'] ?? '') ?? DateTime.now();
                      return Dismissible(
                        key: Key(note['id'] ?? i.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                        ),
                        onDismissed: (_) async {
                          await SecretNotesService.deleteNote(note['id'] ?? '');
                          await _loadNotes();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    Colors.pinkAccent.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(note['title'] ?? '',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                  const Spacer(),
                                  Text(
                                    '${ts.day}/${ts.month}',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white38, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(note['content'] ?? '',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white70, fontSize: 13),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis),
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
}
