import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppMode { offline, online }

const _key = 'app_mode';

class AppModeState {
  final AppMode? mode;
  final bool isLoaded;

  const AppModeState({this.mode, this.isLoaded = false});
}

class AppModeNotifier extends StateNotifier<AppModeState> {
  AppModeNotifier() : super(const AppModeState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    AppMode? mode;
    if (value == 'offline') {
      mode = AppMode.offline;
    } else if (value == 'online') {
      mode = AppMode.online;
    }
    if (mounted) {
      state = AppModeState(mode: mode, isLoaded: true);
    }
  }

  Future<void> setMode(AppMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
    state = AppModeState(mode: mode, isLoaded: true);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = const AppModeState(mode: null, isLoaded: true);
  }
}

final appModeProvider =
    StateNotifierProvider<AppModeNotifier, AppModeState>((ref) {
  return AppModeNotifier();
});
