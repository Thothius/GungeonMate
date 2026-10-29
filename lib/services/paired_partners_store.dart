import 'package:shared_preferences/shared_preferences.dart';

/// Stores the user's multiplayer nickname.
class PairedPartnersStore {
  static const _kNickname = 'mp.nickname';

  static Future<void> saveNickname(String nickname) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kNickname, nickname);
    } catch (_) {}
  }

  static Future<String?> loadNickname() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kNickname);
    } catch (_) {
      return null;
    }
  }
}
