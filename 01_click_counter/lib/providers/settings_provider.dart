import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _kIsDark = 'settings_is_dark';
  static const _kHaptics = 'settings_haptics';
  static const _kConfirmReset = 'settings_confirm_reset';
  static const _kUserName = 'settings_user_name';
  static const _kNamePrompted = 'settings_name_prompted';

  bool _isDarkMode = false;
  bool _hapticsEnabled = true;
  bool _confirmReset = true;
  String? _userName;
  bool _namePrompted = false;
  bool _initialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get confirmReset => _confirmReset;
  String? get userName => _userName;
  bool get namePrompted => _namePrompted;
  bool get isInitialized => _initialized;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_kIsDark) ?? false;
    _hapticsEnabled = prefs.getBool(_kHaptics) ?? true;
    _confirmReset = prefs.getBool(_kConfirmReset) ?? true;
    _userName = prefs.getString(_kUserName);
    _namePrompted = prefs.getBool(_kNamePrompted) ?? false;
    _initialized = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool v) async {
    _isDarkMode = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsDark, v);
  }

  // Backwards-compatible property setter used by UI: settings.isDarkMode = v
  set isDarkMode(bool v) {
    // fire-and-forget the async save
    setDarkMode(v);
  }

  Future<void> setHaptics(bool v) async {
    _hapticsEnabled = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHaptics, v);
  }

  set hapticsEnabled(bool v) {
    setHaptics(v);
  }

  Future<void> setConfirmReset(bool v) async {
    _confirmReset = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kConfirmReset, v);
  }

  set confirmReset(bool v) {
    setConfirmReset(v);
  }

  Future<void> setUserName(String? v) async {
    _userName = v?.trim().isEmpty == true ? null : v?.trim();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_userName == null) {
      await prefs.remove(_kUserName);
    } else {
      await prefs.setString(_kUserName, _userName!);
    }
  }

  // Backwards-compatible property setter used by UI: settings.userName = v
  set userName(String? v) {
    setUserName(v);
  }

  Future<void> setNamePrompted(bool v) async {
    _namePrompted = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNamePrompted, v);
  }

  set namePrompted(bool v) {
    setNamePrompted(v);
  }
}
