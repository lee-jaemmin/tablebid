import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupRefStore {
  static const _key = 'signup_ref';
  static final _preferences = SharedPreferencesAsync();
  static final _validRef = RegExp(r'^[a-zA-Z0-9_-]{1,100}$');

  static Future<void> capture(Uri uri) async {
    final ref = uri.queryParameters['ref'];
    if (ref == null || !_validRef.hasMatch(ref)) return;
    try {
      await _preferences.setString(_key, ref);
    } catch (e) {
      debugPrint('가입 출처 저장 실패: $e');
    }
  }

  static Future<String?> read() async {
    try {
      return await _preferences.getString(_key);
    } catch (e) {
      debugPrint('가입 출처 읽기 실패: $e');
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      await _preferences.remove(_key);
    } catch (e) {
      debugPrint('가입 출처 삭제 실패: $e');
    }
  }
}
