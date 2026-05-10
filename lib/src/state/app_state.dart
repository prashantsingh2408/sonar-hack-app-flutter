import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide settings (API origin, theme). Auth can extend this later.
class AppState extends ChangeNotifier {
  static const _kApiKey = 'api_origin';
  static const _kTheme = 'theme_mode';

  String apiOrigin;
  ThemeMode _themeMode = ThemeMode.system;

  AppState()
      : apiOrigin = const String.fromEnvironment(
          'API_ORIGIN',
          defaultValue: 'https://hacklens.vercel.app',
        );

  ThemeMode get themeMode => _themeMode;

  Future<void> loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    final savedApi = p.getString(_kApiKey);
    if (savedApi != null && savedApi.trim().isNotEmpty) {
      apiOrigin = savedApi.trim().replaceAll(RegExp(r'/$'), '');
    }
    final t = p.getString(_kTheme);
    if (t == 'light') _themeMode = ThemeMode.light;
    if (t == 'dark') _themeMode = ThemeMode.dark;
    if (t == 'system' || t == null) _themeMode = ThemeMode.system;
    notifyListeners();
  }

  Future<void> setApiOrigin(String value) async {
    final v = value.trim().replaceAll(RegExp(r'/$'), '');
    if (v.isEmpty) return;
    apiOrigin = v;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kApiKey, v);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final p = await SharedPreferences.getInstance();
    final s = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await p.setString(_kTheme, s);
    notifyListeners();
  }
}
