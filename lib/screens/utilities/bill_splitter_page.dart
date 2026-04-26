import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class BillSplitterPage extends StatefulWidget {
  const BillSplitterPage({super.key});

  @override
  State<BillSplitterPage> createState() => _BillSplitterPageState();
}

class _BillSplitterPageState extends State<BillSplitterPage> {
  static const String _storageKey = 'bill_splitter_v2_state';

  final TextEditingController _totalCtrl = TextEditingController();
  final TextEditingController _personCtrl = TextEditingController();

  final List<String> _people = <String>['You'];
  final double _taxPct = 18;

  double _tipPct = 10;
  bool _includeTax = false;
  bool _isLoading = true;

  double get _total => double.tryParse(_totalCtrl.text.trim()) ?? 0;
  double get _tip => _total * (_tipPct / 100);
  double get _tax => _includeTax ? _total * (_taxPct / 100) : 0;
  double get _grandTotal => _total + _tip + _tax;
  double get _perPerson => _people.isEmpty ? 0 : _grandTotal / _people.length;

  String get _commentaryMood {
    if (_total > 0 && _people.length >= 4) {
      return 'achievement';
    }
    if (_total > 0) {
      return 'motivated';
    }
    return 'neutral';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _totalCtrl.dispose();
    _personCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> data =
            jsonDecode(raw) as Map<String, dynamic>;
        _totalCtrl.text = (data['total'] as String?) ?? '';
        _tipPct = (data['tipPct'] as num?)?.toDouble() ?? _tipPct;
        _includeTax = data['includeTax'] as bool? ?? _includeTax;
        final List<dynamic> savedPeople =
            (data['people'] as List<dynamic>?) ?? <dynamic>['You'];
        _people
          ..clear()
          ..addAll(
            savedPeople
                .map((entry) => entry.toString().trim())
                .where((entry) => entry.isNotEmpty),
          );
        if (_people.isEmpty) {
          _people.add('You');
        }
      }
    } catch (_) {}

    if (!mounted) {
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(<String, dynamic>{
        'total': _totalCtrl.text.trim(),
        'tipPct': _tipPct,
        'includeTax': _includeTax,
        'people': _people,
      }),
    );
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    if (mounted) {
      setState(() {});
    }
  }

  String _currency(double value) => '₹${value.toStringAsFixed(2)}';

  void _addPerson() {
    final name = _personCtrl.text.trim();
    if (name.isEmpty) {
      return;
    }
    if (_people.any((person) => person.toLowerCase() == name.toLowerCase())) {
      showSuccessSnackbar(context, '$name is already in the split.');
      _personCtrl.clear();
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _people.add(name));
    _personCtrl.clear();
    _save();
    showSuccessSnackbar(context, '$name added to the split.');
  }

  void _removePerson(int index) {
    if (_people.length <= 1) {
      return;
    }
    final removed = _people[index];
    HapticFeedback.lightImpact();
    setState(() => _people.removeAt(index));
    _save();
    showUndoSnackbar(
      context,
      '$removed removed from this split.',
      () {
        final restoreIndex = index > _people.length ? _people.length : index;
        setState(() => _people.insert(restoreIndex, removed));
        _save();
      },
    );
  }

  void _shareResult() {
    if (_total <= 0) {
      return;
    }

    final StringBuffer buffer = StringBuffer('Bill Split Summary\n');
    buffer.writeln('-------------------');
    buffer.writeln('Subtotal: ${_currency(_total)}');
    if (_tipPct > 0) {
      buffer.writeln('Tip (${_tipPct.round()}%): ${_currency(_tip)}');
    }
    if (_includeTax) {
      buffer.writeln('Tax (${_taxPct.round()}%): ${_currency(_tax)}');
    }
    buffer.writeln('Total: ${_currency(_grandTotal)}');
    buffer.writeln('-------------------');
    buffer.writeln('Split between ${_people.length} people:');
    for (final String person in _people) {
      buffer.writeln('- $person: ${_currency(_perPerson)}');
    }

    Share.share(buffer.toString());
    HapticFeedback.mediumImpact();
    showSuccessSnackbar(context, 'Split summary ready to share.');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: V2Theme.surfaceDark,
        body: Center(
          child: CircularProgressIndicator(color: V2Theme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: V2Theme.primaryColor,
          backgroundColor: V2Theme.surfaceLight,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white70,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BILL SPLITTER',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Split bills with friends',
                          style: GoogleFonts.outfit(
                            color: Colors.amberAccent,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_total > 0)
                        IconButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _totalCtrl.clear();
                              _tipPct = 10;
                              _includeTax = false;
                              _people
                                ..clear()
                                ..add('You');
                            });
                            _save();
                            showSuccessSnackbar(context, 'Bill reset to fresh start.');
                          },
                          icon: Icon(
                            Icons.restart_alt_rounded,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          tooltip: 'Reset',
                        ),
                      FilledButton.icon(
                        onPressed: _total > 0 ? _shareResult : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.amberAccent.withValues(alpha: 0.2),
                          foregroundColor: Colors.amberAccent,
                        ),
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('Share'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedEntry(
                index: 0,
                child: GlassCard(
                  margin: EdgeInsets.zero,
                  glow: true,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tonight\'s split plan',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _total > 0
                                  ? '${_people.length} people sharing ${_currency(_grandTotal)}'
                                  : 'Add a subtotal to preview the split',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _total > 0
                                  ? 'Each person owes ${_currency(_perPerson)} with tip and tax choices already baked in.'
                                  : 'Pick a total, invite the group, and this page handles the math and sharing for you.',
                              style: GoogleFonts.outfit(
                                color: Colors.white60,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ProgressRing(
                        progress: (_people.length / 6).clamp(0, 1).toDouble(),
                        foreground: Colors.amberAccent,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people_alt_rounded,
                              color: Colors.amberAccent,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_people.length}',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Guests',
                              style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedEntry(
                index: 1,
                child: WaifuCommentary(mood: _commentaryMood),
              ),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Per Person',
                      value: _currency(_perPerson),
                      icon: Icons.payments_rounded,
                      color: Colors.amberAccent,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: 'Tip',
                      value: '${_tipPct.round()}%',
                      icon: Icons.tips_and_updates_rounded,
                      color: V2Theme.primaryColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Tax',
                      value: _includeTax ? '${_taxPct.round()}%' : 'Off',
                      icon: Icons.receipt_long_rounded,
                      color: V2Theme.secondaryColor,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: 'People',
                      value: '${_people.length}',
                      icon: Icons.groups_rounded,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GlassCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bill amount',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _totalCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) {
                        setState(() {});
                        _save();
                      },
                      style: GoogleFonts.outfit(
                        color: Colors.amberAccent,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                      cursorColor: Colors.amberAccent,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '₹ 0.00',
                        hintStyle: GoogleFonts.outfit(
                          color: Colors.white24,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                        filled: true,
                        fillColor: Colors.amberAccent.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Colors.amberAccent.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Colors.amberAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        prefixText: '₹ ',
                        prefixStyle: GoogleFonts.outfit(
                          color: Colors.amberAccent.withValues(alpha: 0.5),
                          fontSize: 28,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adjustments',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <double>[0, 5, 10, 15, 20].map((double value) {
                        final bool selected = _tipPct == value;
                        return ChoiceChip(
                          label: Text('${value.round()}%'),
                          selected: selected,
                          selectedColor:
                              Colors.amberAccent.withValues(alpha: 0.22),
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          labelStyle: GoogleFonts.outfit(
                            color:
                                selected ? Colors.amberAccent : Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() => _tipPct = value);
                            _save();
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Include tax',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        'Apply $_taxPct% tax before splitting the final total.',
                        style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      value: _includeTax,
                      activeColor: Colors.amberAccent,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        setState(() => _includeTax = value);
                        _save();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'People in this split',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _personCtrl,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            cursorColor: Colors.amberAccent,
                            decoration: InputDecoration(
                              hintText: 'Add person',
                              hintStyle: GoogleFonts.outfit(
                                color: Colors.white30,
                                fontSize: 12,
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.04),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _addPerson(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _addPerson,
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Colors.amberAccent.withValues(alpha: 0.2),
                            foregroundColor: Colors.amberAccent,
                          ),
                          child: const Icon(Icons.person_add_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Quick-add presets
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ['Partner', 'Friend', 'Roommate', 'Family']
                          .where((name) => !_people.any(
                              (p) => p.toLowerCase() == name.toLowerCase()))
                          .map((name) => GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _people.add(name));
                                  _save();
                                  showSuccessSnackbar(context, '$name joined the split.');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.amberAccent.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded, size: 13, color: Colors.amberAccent.withValues(alpha: 0.7)),
                                      const SizedBox(width: 4),
                                      Text(name, style: GoogleFonts.outfit(color: Colors.amberAccent.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    ..._people.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final String person = entry.value;
                      final Widget card = Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.amberAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.amberAccent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    person,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    _total > 0
                                        ? 'Owes ${_currency(_perPerson)}'
                                        : 'Waiting for the bill total',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_people.length > 1)
                              const Icon(
                                Icons.swipe_left_rounded,
                                color: Colors.white24,
                                size: 18,
                              ),
                          ],
                        ),
                      );

                      if (_people.length == 1) {
                        return card;
                      }

                      return SwipeToDismissItem(
                        dismissText: 'Remove',
                        dismissColor: Colors.redAccent,
                        onDismissed: () => _removePerson(index),
                        child: card,
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_total <= 0)
                const GlassCard(
                  margin: EdgeInsets.zero,
                  child: EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No bill added yet',
                    subtitle:
                        'Drop in the subtotal, adjust tip or tax, and this screen will instantly calculate everyone\'s share.',
                  ),
                )
              else
                GlassCard(
                  margin: EdgeInsets.zero,
                  glow: true,
                  child: Column(
                    children: [
                      _summaryRow(
                        'Subtotal',
                        _currency(_total),
                        Colors.white70,
                      ),
                      if (_tipPct > 0)
                        _summaryRow(
                          'Tip (${_tipPct.round()}%)',
                          _currency(_tip),
                          Colors.white70,
                        ),
                      if (_includeTax)
                        _summaryRow(
                          'Tax (${_taxPct.round()}%)',
                          _currency(_tax),
                          Colors.white70,
                        ),
                      const Divider(color: Colors.white12, height: 20),
                      _summaryRow(
                        'TOTAL',
                        _currency(_grandTotal),
                        Colors.amberAccent,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.amberAccent.withValues(alpha: 0.1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.people_rounded,
                              color: Colors.amberAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: _perPerson),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              builder: (_, val, __) => Text(
                                _currency(val),
                                style: GoogleFonts.outfit(
                                  color: Colors.amberAccent,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              ' / person',
                              style: GoogleFonts.outfit(
                                color: Colors.amberAccent.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(color: color, fontSize: 13),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}



