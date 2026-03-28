import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppMode { offline, online }

const _key = 'app_mode';

class AppModeNotifier extends StateNotifier<AppMode?> {
  AppModeNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == 'offline') {
      state = AppMode.offline;
    } else if (value == 'online') {
      state = AppMode.online;
    }
    // null = not set yet (first launch)
  }

  Future<void> setMode(AppMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
    state = mode;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = null;
  }
}

final appModeProvider = StateNotifierProvider<AppModeNotifier, AppMode?>((ref) {
  return AppModeNotifier();
});
