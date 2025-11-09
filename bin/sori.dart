import 'dart:io';

import 'package:sori_cli/config.dart';
import 'package:sori_cli/services/api_client.dart';
import 'package:sori_cli/sori_cli.dart';

Future<void> main(List<String> arguments) async {
  final overrideBase = Platform.environment['SORI_BASE_URL'];
  final defaultBase = overrideBase ?? 'http://localhost:3000/api/v1';

  final config = await Config.load(defaultServerUrl: Uri.parse(defaultBase));

  if (overrideBase != null && overrideBase.isNotEmpty) {
    config.serverUrl = Uri.parse(overrideBase);
  }
  final client = ApiClient(config);
  final cli = SoriCli(client: client, config: config);

  final code = await cli.execute(arguments);
  await config.flush();
  exit(code);
}
