import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/foundation.dart';

class ContactsLookupService {
  /// Searches device contacts by name and returns a summary string.
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

      final lowerQuery = query.toLowerCase();
      final matches = contacts
          .where((c) => c.displayName.toLowerCase().contains(lowerQuery))
          .toList();

      if (matches.isEmpty) {
        return "I couldn't find anyone named '$query' in your contacts, darling!";
      }

      final contact = matches.first;
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
}
