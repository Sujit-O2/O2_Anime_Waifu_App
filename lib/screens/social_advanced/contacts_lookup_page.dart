import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/integrations/contacts_lookup_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsLookupPage extends StatefulWidget {
  const ContactsLookupPage({super.key});

  @override
  State<ContactsLookupPage> createState() => _ContactsLookupPageState();
}

class _ContactsLookupPageState extends State<ContactsLookupPage> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  String _result = '';
  String? _phone;
  String? _email;
  String? _name;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _result = '';
        _phone = null;
        _email = null;
        _name = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(value));
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    setState(() => _loading = true);
    final raw = await ContactsLookupService.findContact(query);
    final phone = await ContactsLookupService.resolvePhoneNumber(query);
    if (!mounted) return;

    // Parse name/phone/email from result string
    String? parsedName;
    String? parsedPhone;
    String? parsedEmail;
    final lines = raw.split('\n');
    if (lines.isNotEmpty) parsedName = lines[0];
    for (final line in lines) {
      if (line.startsWith('📞')) parsedPhone = line.replaceFirst('📞 ', '');
      if (line.startsWith('📧')) parsedEmail = line.replaceFirst('📧 ', '');
    }

    setState(() {
      _loading = false;
      _result = raw;
      _name = parsedName;
      _phone = phone ?? parsedPhone;
      _email = parsedEmail;
    });
  }

  Future<void> _call() async {
    if (_phone == null) return;
    final uri = Uri(scheme: 'tel', path: _phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _message() async {
    if (_phone == null) return;
    final uri = Uri(scheme: 'sms', path: _phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _mailTo() async {
    if (_email == null) return;
    final uri = Uri(scheme: 'mailto', path: _email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  bool get _hasResult =>
      _result.isNotEmpty &&
      !_result.startsWith("I couldn't") &&
      !_result.startsWith("I don't") &&
      !_result.startsWith('Something');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Contacts Lookup',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF2E7D32), cs.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  TextField(
                    controller: _ctrl,
                    onChanged: _onChanged,
                    style: GoogleFonts.outfit(),
                    decoration: InputDecoration(
                      hintText: 'Search by name…',
                      hintStyle: GoogleFonts.outfit(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _ctrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _ctrl.clear();
                                _onChanged('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: cs.surfaceContainerLow,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_loading)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ))
                  else if (_ctrl.text.isEmpty)
                    _SearchHint(cs: cs)
                  else if (_hasResult)
                    _ContactCard(
                      name: _name ?? 'Contact',
                      phone: _phone,
                      email: _email,
                      cs: cs,
                      onCall: _phone != null ? _call : null,
                      onMessage: _phone != null ? _message : null,
                      onEmail: _email != null ? _mailTo : null,
                    )
                  else
                    _NoResult(query: _ctrl.text, cs: cs),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contact Card ───────────────────────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.name,
    required this.phone,
    required this.email,
    required this.cs,
    required this.onCall,
    required this.onMessage,
    required this.onEmail,
  });
  final String name;
  final String? phone;
  final String? email;
  final ColorScheme cs;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final VoidCallback? onEmail;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: cs.primaryContainer,
              child: Text(
                _initials,
                style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: cs.primary),
              ),
            ),
            const SizedBox(height: 12),
            Text(name,
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            if (phone != null) ...[
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: phone!,
                cs: cs,
                onCopy: () => _copy(context, phone!),
              ),
              const SizedBox(height: 8),
            ],
            if (email != null) ...[
              _InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: email!,
                cs: cs,
                onCopy: () => _copy(context, email!),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (onCall != null)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onCall,
                      icon: const Icon(Icons.call, size: 18),
                      label: Text('Call', style: GoogleFonts.outfit()),
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.green),
                    ),
                  ),
                if (onCall != null && onMessage != null)
                  const SizedBox(width: 8),
                if (onMessage != null)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onMessage,
                      icon: const Icon(Icons.message, size: 18),
                      label: Text('Message', style: GoogleFonts.outfit()),
                      style: FilledButton.styleFrom(
                          backgroundColor: cs.primary),
                    ),
                  ),
                if (onEmail != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEmail,
                      icon: const Icon(Icons.mail_outline, size: 18),
                      label: Text('Email', style: GoogleFonts.outfit()),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Copied to clipboard', style: GoogleFonts.outfit()),
          duration: const Duration(seconds: 2)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
    required this.onCopy,
  });
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: cs.onSurfaceVariant)),
                Text(value,
                    style: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: onCopy,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ── Search Hint ────────────────────────────────────────────────────────────
class _SearchHint extends StatelessWidget {
  const _SearchHint({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.contacts_outlined,
                size: 72, color: cs.onSurfaceVariant.withAlpha(80)),
            const SizedBox(height: 16),
            Text('Search your contacts',
                style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Type a name to find contact details,\nphone numbers and emails.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ── No Result ──────────────────────────────────────────────────────────────
class _NoResult extends StatelessWidget {
  const _NoResult({required this.query, required this.cs});
  final String query;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.person_search_outlined,
                size: 64, color: cs.onSurfaceVariant.withAlpha(80)),
            const SizedBox(height: 16),
            Text('No contact found for "$query"',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 15, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
