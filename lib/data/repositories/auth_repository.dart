import 'package:shared_preferences/shared_preferences.dart';

/// A minimal local "session" so the Settings screen's "تسجيل الخروج" and the
/// login screen in the mockups have something real to do, without requiring
/// a backend. Swap the implementation for Firebase/Supabase auth later —
/// nothing outside this class needs to change.
class AuthRepository {
  static const _keyLoggedIn = 'auth_logged_in';
  static const _keyDisplayName = 'auth_display_name';

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  Future<String?> displayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDisplayName);
  }

  Future<void> signIn(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyDisplayName, name);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, false);
  }
}
