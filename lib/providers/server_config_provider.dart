import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/server_config.dart';

const _serversKey = 'servers';
const _activeServerKey = 'active_server_id';

class ServerConfigState {
  final List<ServerConfig> servers;
  final String? activeServerId;

  const ServerConfigState({
    this.servers = const [],
    this.activeServerId,
  });

  ServerConfig? get activeServer {
    if (activeServerId == null) return null;
    try {
      return servers.firstWhere((s) => s.id == activeServerId);
    } catch (_) {
      return servers.isNotEmpty ? servers.first : null;
    }
  }

  ServerConfigState copyWith({
    List<ServerConfig>? servers,
    String? activeServerId,
  }) {
    return ServerConfigState(
      servers: servers ?? this.servers,
      activeServerId: activeServerId ?? this.activeServerId,
    );
  }
}

class ServerConfigNotifier extends StateNotifier<ServerConfigState> {
  ServerConfigNotifier() : super(const ServerConfigState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final serversJson = prefs.getString(_serversKey);
    var activeId = prefs.getString(_activeServerKey);

    var servers = <ServerConfig>[];
    if (serversJson != null) {
      final list = jsonDecode(serversJson) as List<dynamic>;
      servers = list
          .map((e) => ServerConfig.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Remove stale auto-added preset from previous versions
    final hadPreset = servers.any((s) => s.id == 'preset_digitlock');
    if (hadPreset) {
      servers = servers.where((s) => s.id != 'preset_digitlock').toList();
      if (activeId == 'preset_digitlock') {
        activeId = servers.isNotEmpty ? servers.first.id : null;
      }
      await _save(servers, activeId);
    }

    state = ServerConfigState(
      servers: servers,
      activeServerId: activeId,
    );
  }

  Future<void> addServer(ServerConfig server) async {
    final servers = [...state.servers, server];
    final activeId = state.activeServerId ?? server.id;
    await _save(servers, activeId);
    state = ServerConfigState(servers: servers, activeServerId: activeId);
  }

  Future<void> removeServer(String id) async {
    final servers = state.servers.where((s) => s.id != id).toList();
    var activeId = state.activeServerId;
    if (activeId == id) {
      activeId = servers.isNotEmpty ? servers.first.id : null;
    }
    await _save(servers, activeId);
    state = ServerConfigState(servers: servers, activeServerId: activeId);
  }

  Future<void> setActive(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeServerKey, id);
    state = state.copyWith(activeServerId: id);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_serversKey);
    await prefs.remove(_activeServerKey);
    state = const ServerConfigState();
  }

  Future<void> _save(List<ServerConfig> servers, String? activeId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(servers.map((s) => s.toJson()).toList());
    await prefs.setString(_serversKey, json);
    if (activeId != null) {
      await prefs.setString(_activeServerKey, activeId);
    } else {
      await prefs.remove(_activeServerKey);
    }
  }
}

final serverConfigProvider =
    StateNotifierProvider<ServerConfigNotifier, ServerConfigState>((ref) {
  return ServerConfigNotifier();
});
