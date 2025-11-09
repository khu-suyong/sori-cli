import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class ConfigStore {
  ConfigStore({String? filePath}) : _filePath = filePath ?? _defaultPath();

  final String _filePath;

  File get _file => File(_filePath);

  Future<Map<String, dynamic>?> read() async {
    final file = _file;
    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return null;
      }
      final json = jsonDecode(content);
      if (json is Map<String, dynamic>) {
        return json;
      }
    } catch (_) {}
    return null;
  }

  Future<void> write(Map<String, dynamic> json) async {
    final file = _file;
    await file.parent.create(recursive: true);
    await file.writeAsString('${jsonEncode(json)}\n');
  }

  static String _defaultPath() {
    final env = Platform.environment;
    final override = env['SORI_CONFIG_PATH'];
    if (override != null && override.isNotEmpty) {
      return override;
    }

    final homeOverride = env['SORI_CONFIG_HOME'];
    if (homeOverride != null && homeOverride.isNotEmpty) {
      return p.join(homeOverride, 'config.json');
    }

    final baseDir = _resolveConfigDir(env);
    return p.join(baseDir, 'sori', 'config.json');
  }

  static String _resolveConfigDir(Map<String, String> env) {
    if (Platform.isWindows) {
      return env['APPDATA'] ?? env['USERPROFILE'] ?? Directory.current.path;
    }
    final xdg = env['XDG_CONFIG_HOME'];
    if (xdg != null && xdg.isNotEmpty) {
      return xdg;
    }
    final home = env['HOME'];
    if (home != null && home.isNotEmpty) {
      return p.join(home, '.config');
    }
    return Directory.current.path;
  }
}
