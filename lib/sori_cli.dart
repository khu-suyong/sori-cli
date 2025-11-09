library;

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';

import 'commands/auth_commands.dart';
import 'commands/base.dart';
import 'commands/server_commands.dart';
import 'commands/status_commands.dart';
import 'commands/user_commands.dart';
import 'commands/workspace_commands.dart';
import 'config.dart';
import 'services/api_client.dart';
import 'utils/output.dart';

export 'commands/base.dart';

class SoriCli extends CommandRunner<void> {
  SoriCli({
    required ApiClient client,
    required Config config,
    IOSink? output,
    Iterable<Command<void>> extraCommands = const [],
  }) : _output = output ?? stdout,
       super('sori', 'A CLI application for Sori') {
    addCommand(StatusCommand(client: client, config: config, output: _output));
    addCommand(AuthCommand(client: client, config: config, output: _output));
    addCommand(UserCommand(client: client, config: config, output: _output));
    addCommand(
      WorkspaceCommand(client: client, config: config, output: _output),
    );
    addCommand(ServerCommand(client: client, config: config, output: _output));
    for (final command in extraCommands) {
      addCommand(command);
    }
  }

  final IOSink _output;

  Future<int> execute(List<String> arguments) async {
    try {
      await run(arguments);
      return 0;
    } on UsageException catch (error) {
      printError(error.message, sink: _output);
      if (error.usage.isNotEmpty) {
        printInfo(error.usage, sink: _output);
      }
      return 64;
    } on CliUsageException catch (error) {
      printError('Input error: ${error.message}', sink: _output);
      return 64;
    } on DioException catch (error) {
      final status = error.response?.statusCode ?? error.message;
      printError('HTTP error: $status', sink: _output);
      final data = error.response?.data;
      if (data != null) {
        printObject(data, sink: _output);
      }
      return 1;
    }
  }
}
