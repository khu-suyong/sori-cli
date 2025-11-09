import 'dart:io';

import 'package:args/command_runner.dart';

import '../config.dart';
import '../services/api_client.dart';
import 'base.dart';

class UserCommand extends Command<void> {
  UserCommand({
    required ApiClient client,
    required Config config,
    IOSink? output,
  }) : _output = output ?? stdout {
    addSubcommand(
      UserGetCommand(client: client, config: config, output: _output),
    );
    addSubcommand(
      UserUpdateCommand(client: client, config: config, output: _output),
    );
  }

  final IOSink _output;

  @override
  String get description => '사용자 엔드포인트 모음.';

  @override
  String get name => 'user';

  @override
  Future<void> run() async {
    throw UsageException('Specify a user subcommand.', usage);
  }
}

class UserGetCommand extends SoriCommand {
  UserGetCommand({required super.client, required super.config, super.output})
    : super(enableDataOption: false);

  @override
  final String name = 'get';

  @override
  final String description = '인증된 유저 정보를 조회합니다.';

  @override
  String get invocation => 'sori user get';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final response = await context.client.get('user');
    context.render(response.data);
  }
}

class UserUpdateCommand extends SoriCommand {
  UserUpdateCommand({
    required super.client,
    required super.config,
    super.output,
  });

  @override
  final String name = 'update';

  @override
  final String description = '유저 프로필을 수정합니다.';

  @override
  String get invocation => 'sori user update -d name=<value> [-d image=<url>]';

  @override
  Future<void> runWithContext(CommandContext context) async {
    if (context.namedArgs.isEmpty) {
      throw CliUsageException('전송할 필드를 -d key=value 형태로 지정하세요.');
    }
    final response = await context.client.patch(
      'user',
      data: context.namedArgs,
    );
    context.success('유저 정보 수정 완료.');
    context.render(response.data);
  }
}
