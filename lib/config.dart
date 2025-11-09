import 'dart:async';

import 'config_store.dart';

class Config {
  Config({
    required Uri serverUrl,
    Duration connectTimeout = const Duration(seconds: 5),
    Duration receiveTimeout = const Duration(seconds: 15),
    Map<String, String>? defaultHeaders,
    String? accessToken,
    String? refreshToken,
    ConfigStore? store,
  }) : this._(
          store: store ?? ConfigStore(),
          serverUrl: serverUrl,
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
          defaultHeaders:
              Map<String, String>.from(defaultHeaders ?? const {'Content-Type': 'application/json'}),
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

  Config._({
    required ConfigStore store,
    required Uri serverUrl,
    required Duration connectTimeout,
    required Duration receiveTimeout,
    required Map<String, String> defaultHeaders,
    String? accessToken,
    String? refreshToken,
  })  : _store = store,
        _serverUrl = serverUrl,
        _connectTimeout = connectTimeout,
        _receiveTimeout = receiveTimeout,
        _defaultHeaders = Map<String, String>.from(defaultHeaders),
        _accessToken = accessToken,
        _refreshToken = refreshToken;

  final ConfigStore _store;
  Uri _serverUrl;
  Duration _connectTimeout;
  Duration _receiveTimeout;
  final Map<String, String> _defaultHeaders;
  String? _accessToken;
  String? _refreshToken;
  Future<void>? _pendingSave;

  Uri get serverUrl => _serverUrl;
  set serverUrl(Uri value) {
    if (_serverUrl == value) return;
    _serverUrl = value;
    _scheduleSave();
  }

  Duration get connectTimeout => _connectTimeout;
  set connectTimeout(Duration value) {
    if (_connectTimeout == value) return;
    _connectTimeout = value;
    _scheduleSave();
  }

  Duration get receiveTimeout => _receiveTimeout;
  set receiveTimeout(Duration value) {
    if (_receiveTimeout == value) return;
    _receiveTimeout = value;
    _scheduleSave();
  }

  Map<String, String> get defaultHeaders => Map.unmodifiable(_defaultHeaders);

  void setHeader(String key, String value) {
    final normalized = key.trim();
    if (normalized.isEmpty) {
      return;
    }
    if (_defaultHeaders[normalized] == value) {
      return;
    }
    _defaultHeaders[normalized] = value;
    _scheduleSave();
  }

  void removeHeader(String key) {
    if (_defaultHeaders.remove(key) != null) {
      _scheduleSave();
    }
  }

  String? get accessToken => _accessToken;
  set accessToken(String? value) {
    if (_accessToken == value) return;
    _accessToken = value;
    _scheduleSave();
  }

  String? get refreshToken => _refreshToken;
  set refreshToken(String? value) {
    if (_refreshToken == value) return;
    _refreshToken = value;
    _scheduleSave();
  }

  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl.toString(),
      'connectTimeoutMs': connectTimeout.inMilliseconds,
      'receiveTimeoutMs': receiveTimeout.inMilliseconds,
      'defaultHeaders': _defaultHeaders,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  Future<void> save() => _store.write(toJson());

  Future<void> flush() async {
    final pending = _pendingSave;
    if (pending != null) {
      await pending;
      return;
    }
    await save();
  }

  void _scheduleSave() {
    _pendingSave ??= Future.microtask(() async {
      try {
        await save();
      } finally {
        _pendingSave = null;
      }
    });
  }

  static Future<Config> load({
    ConfigStore? store,
    required Uri defaultServerUrl,
  }) async {
    final resolvedStore = store ?? ConfigStore();
    final json = await resolvedStore.read();
    if (json != null) {
      return Config._fromJson(json, resolvedStore);
    }
    return Config(serverUrl: defaultServerUrl, store: resolvedStore);
  }

  static Config _fromJson(Map<String, dynamic> json, ConfigStore store) {
    return Config._(
      store: store,
      serverUrl: Uri.parse(json['serverUrl'] as String),
      connectTimeout: Duration(milliseconds: (json['connectTimeoutMs'] as int?) ?? 5000),
      receiveTimeout: Duration(milliseconds: (json['receiveTimeoutMs'] as int?) ?? 15000),
      defaultHeaders: _decodeHeaders(json['defaultHeaders']),
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
    );
  }

  static Map<String, String> _decodeHeaders(Object? value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val.toString()));
    }
    return const {'Content-Type': 'application/json'};
  }
}
