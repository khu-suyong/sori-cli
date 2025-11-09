import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../config.dart';
import '../services/api_client.dart';
import '../utils/output.dart';

class CommandContext {
  CommandContext({
    required this.client,
    required this.config,
    required this.namedArgs,
    required this.rawArguments,
    this.argResults,
    IOSink? output,
  }) : output = output ?? stdout;

  final ApiClient client;
  final Config config;
  final Map<String, String> namedArgs;
  final List<String> rawArguments;
  final ArgResults? argResults;
  final IOSink output;

  String require(String key) {
    final value = namedArgs[key];
    if (value == null || value.isEmpty) {
      throw CliUsageException('Missing required argument "$key".');
    }
    return value;
  }

  T? option<T>(String name) {
    final results = argResults;
    if (results == null) {
      return null;
    }
    final value = results[name];
    if (value == null) {
      return null;
    }
    return value as T;
  }

  String requireOption(String name) {
    final value = option<String>(name);
    if (value == null || value.isEmpty) {
      throw CliUsageException('Missing option "--$name".');
    }
    return value;
  }

  void info(String message) => printInfo(message, sink: output);
  void success(String message) => printSuccess(message, sink: output);
  void error(String message) => printError(message, sink: output);
  void render(Object? message, {bool paginated = false}) {
    if (message is Map<String, dynamic>) {
      if (paginated) {
        printPaginatedResponse(message, sink: output);
      } else {
        printTable([message], sink: output);
      }
    } else {
      printObject(message, sink: output);
      return;
    }
  }
}

abstract class SoriCommand extends Command<void> {
  SoriCommand({
    required this.client,
    required this.config,
    IOSink? output,
    bool enableDataOption = true,
  }) : output = output ?? stdout,
       _hasDataOption = enableDataOption {
    if (enableDataOption) {
      argParser.addMultiOption(
        'data',
        abbr: 'd',
        valueHelp: 'key=value',
        help: 'Attach body/query parameters (repeatable).',
        defaultsTo: const <String>[],
        splitCommas: false,
      );
    }
  }

  final ApiClient client;
  final Config config;
  final IOSink output;
  final bool _hasDataOption;

  @override
  Future<void> run() async {
    final context = CommandContext(
      client: client,
      config: config,
      namedArgs: dataArgs,
      rawArguments: argResults?.rest ?? const [],
      argResults: argResults,
      output: output,
    );
    await runWithContext(context);
  }

  Map<String, String> get dataArgs {
    if (!_hasDataOption) {
      return const {};
    }
    final results = argResults;
    if (results == null || !results.wasParsed('data')) {
      return const {};
    }
    final values = results['data'];
    if (values is List) {
      return _namedArgsFrom(List<String>.from(values));
    }
    return const {};
  }

  Future<void> runWithContext(CommandContext context);

  Map<String, String> _namedArgsFrom(List<String> entries) {
    final named = <String, String>{};

    for (final entry in entries) {
      final separatorIndex = entry.indexOf('=');
      if (separatorIndex <= 0) {
        continue;
      }

      final key = entry.substring(0, separatorIndex).trim();
      final value = entry.substring(separatorIndex + 1).trim();
      if (key.isEmpty) {
        continue;
      }
      named[key] = _stripQuotes(value);
    }

    return named;
  }

  String _stripQuotes(String value) {
    if (value.length >= 2) {
      final start = value[0];
      final end = value[value.length - 1];
      if ((start == '"' && end == '"') || (start == '\'' && end == '\'')) {
        return value.substring(1, value.length - 1);
      }
    }
    return value;
  }
}

class CliUsageException implements Exception {
  CliUsageException(this.message);

  final String message;

  @override
  String toString() => 'CliUsageException: $message';
}
