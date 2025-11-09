import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../config.dart';
import '../services/api_client.dart';
import 'base.dart';

class StatusCommand extends Command<void> {
  StatusCommand({
    required ApiClient client,
    required Config config,
    IOSink? output,
  }) : _output = output ?? stdout {
    addSubcommand(
      AuthStatusCommand(client: client, config: config, output: _output),
    );
    addSubcommand(
      MicStatusCommand(client: client, config: config, output: _output),
    );
  }

  final IOSink _output;

  @override
  String get description => 'Sori 사용을 위한 상태 확인 명령어 모음.';

  @override
  String get name => 'status';

  @override
  Future<void> run() async {
    throw UsageException('Specify a status subcommand.', usage);
  }
}

class AuthStatusCommand extends SoriCommand {
  AuthStatusCommand({
    required super.client,
    required super.config,
    super.output,
  }) : super(enableDataOption: false);

  @override
  final String name = 'auth';

  @override
  final String description = '인증 상태를 조회합니다.';

  @override
  String get invocation => 'sori status auth';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final isAuthenticated = config.accessToken != null;

    if (isAuthenticated) {
      context.success('로그인된 상태입니다.');
    } else {
      context.info('인증되지 않은 상태입니다. "sori auth login" 명령어를 사용하여 로그인하세요.');
    }
  }
}

class MicStatusCommand extends SoriCommand {
  MicStatusCommand({required super.client, required super.config, super.output})
    : super(enableDataOption: false);

  @override
  final String name = 'mic';

  @override
  final String description = '사용 가능한 마이크 장치를 조회합니다.';

  @override
  String get invocation => 'sori status mic';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final command = Platform.isWindows
        ? ['ffmpeg', '-list_devices', 'true', '-f', 'dshow', '-i', 'dummy']
        : ['ffmpeg', '-f', 'avfoundation', '-list_devices', 'true', '-i', ''];

    final micList = await _listAllAudioInput(context);
    context.info('사용 가능한 마이크 장치 목록:');
    for (final line in micList) {
      context.info(' - "${line.trim()}"');
    }
  }

  Future<List<String>> _listAllAudioInput(CommandContext context) async {
    final p = await Process.start('ffmpeg', [
      '-hide_banner',
      '-f',
      'dshow',
      '-list_devices',
      'true',
      '-i',
      'dummy',
    ]);
    final lines = await p.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .toList();
    final out = <String>[];
    final reQuoted = RegExp(r'^\[dshow.*\]\s+"([^"]+)"'); // "장치명"
    for (final l in lines) {
      if (l.contains('(audio)')) {
        final m = reQuoted.firstMatch(l);
        if (m != null) out.add(m.group(1)!);
      }
    }
    await p.exitCode;
    return out;
  }
}
