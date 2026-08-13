import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();
  SharedPreferences? _prefs;

  StorageService._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? getAuthToken() {
    return _prefs?.getString('auth_token');
  }

  Future<bool> saveAuthToken(String token) async {
    return await _prefs?.setString('auth_token', token) ?? false;
  }

  Future<bool> clearAuthToken() async {
    return await _prefs?.remove('auth_token') ?? false;
  }
}
