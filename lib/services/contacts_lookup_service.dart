import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/foundation.dart';

class ContactsLookupService {
  /// Searches device contacts by name (case-insensitive) and returns the best
  /// match ranked: exact → starts-with → contains.
  static Future<String> findContact(String query) async {
    try {
      final hasPermission =
          await FlutterContacts.requestPermission(readonly: true);
      if (!hasPermission) {
        return "I don't have permission to access your contacts. Please grant Contacts permission in Settings.";
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      final q = query.toLowerCase().trim();

      // Rank: exact → exact word → starts-with → contains (all case-insensitive)
      final exact =
          contacts.where((c) => c.displayName.toLowerCase().trim() == q);
      final exactWord = contacts.where((c) {
        final d = c.displayName.toLowerCase().trim();
        if (d == q) return false;
        return d.split(RegExp(r'\s+')).contains(q);
      });
      final startsWith = contacts.where((c) {
        final d = c.displayName.toLowerCase().trim();
        return d.startsWith(q) &&
            d != q &&
            !d.split(RegExp(r'\s+')).contains(q);
      });
      final contains = contacts.where((c) {
        final d = c.displayName.toLowerCase().trim();
        return d.contains(q) &&
            !d.startsWith(q) &&
            !d.split(RegExp(r'\s+')).contains(q);
      });

      final ranked = [...exact, ...exactWord, ...startsWith, ...contains];

      if (ranked.isEmpty) {
        return "I couldn't find anyone named '$query' in your contacts, darling!";
      }

      final contact = ranked.first;
      final phones = contact.phones.map((p) => p.number).join(', ');
      final emails = contact.emails.map((e) => e.address).join(', ');

      final parts = <String>[contact.displayName];
      if (phones.isNotEmpty) parts.add('📞 $phones');
      if (emails.isNotEmpty) parts.add('📧 $emails');

      return parts.join('\n');
    } catch (e) {
      debugPrint('ContactsLookup error: $e');
      return "Something went wrong looking up contacts, sorry!";
    }
  }

  /// Resolves a contact name to its best phone number (case-insensitive,
  /// ranked: exact → starts-with → contains). Returns null if not found.
  static Future<String?> resolvePhoneNumber(String query) async {
    try {
      final hasPermission =
          await FlutterContacts.requestPermission(readonly: true);
      if (!hasPermission) return null;

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      final q = query.toLowerCase().trim();

      final exact =
          contacts.where((c) => c.displayName.toLowerCase().trim() == q);
      final exactWord = contacts.where((c) {
        final d = c.displayName.toLowerCase().trim();
        if (d == q) return false;
        return d.split(RegExp(r'\s+')).contains(q);
      });
      final startsWith = contacts.where((c) {
        final d = c.displayName.toLowerCase().trim();
        return d.startsWith(q) &&
            d != q &&
            !d.split(RegExp(r'\s+')).contains(q);
      });
      final contains = contacts.where((c) {
        final d = c.displayName.toLowerCase().trim();
        return d.contains(q) &&
            !d.startsWith(q) &&
            !d.split(RegExp(r'\s+')).contains(q);
      });

      final ranked = [...exact, ...exactWord, ...startsWith, ...contains];
      if (ranked.isEmpty) return null;

      final phone = ranked.first.phones.firstOrNull?.number;
      return phone?.replaceAll(RegExp(r'\s'), ''); // strip spaces
    } catch (e) {
      debugPrint('ContactsLookup resolvePhone error: $e');
      return null;
    }
  }
}
