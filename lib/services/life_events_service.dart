import 'package:shared_preferences/shared_preferences.dart';

/// Anniversary and day milestone detection.
class LifeEventsService {
  DateTime? _installDate;
  DateTime? _userBirthday;
  final List<int> _milestones = [1, 7, 14, 30, 50, 100, 200, 365, 500, 1000];

  int get daysSinceInstall =>
      _installDate != null
          ? DateTime.now().difference(_installDate!).inDays
          : 0;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final installStr = prefs.getString('install_date');
    if (installStr != null) {
      _installDate = DateTime.parse(installStr);
    } else {
      _installDate = DateTime.now();
      await prefs.setString(
          'install_date', _installDate!.toIso8601String());
    }
    final bdayStr = prefs.getString('user_birthday');
    if (bdayStr != null) _userBirthday = DateTime.parse(bdayStr);
  }

  Future<void> setUserBirthday(DateTime birthday) async {
    _userBirthday = birthday;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_birthday', birthday.toIso8601String());
  }

  String? checkForEvent() {
    final days = daysSinceInstall;

    // Check milestones
    for (final milestone in _milestones) {
      if (days == milestone) {
        return 'milestone_$milestone';
      }
    }

    // Check anniversary
    if (_installDate != null) {
      final now = DateTime.now();
      if (now.month == _installDate!.month &&
          now.day == _installDate!.day &&
          days >= 365) {
        return 'anniversary_${days ~/ 365}';
      }
    }

    // Check birthday
    if (_userBirthday != null) {
      final now = DateTime.now();
      if (now.month == _userBirthday!.month &&
          now.day == _userBirthday!.day) {
        return 'birthday';
      }
    }

    return null;
  }

  String toContextString() =>
      '[Life Events] Day $daysSinceInstall since first meeting';
}
