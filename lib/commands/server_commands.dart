import 'dart:io';

import 'package:args/command_runner.dart';

import 'base.dart';

import '../config.dart';
import '../services/api_client.dart';

class ServerCommand extends Command<void> {
  ServerCommand({
    required ApiClient client,
    required Config config,
    IOSink? output,
  }) : _output = output ?? stdout {
    addSubcommand(
      ServerListCommand(client: client, config: config, output: _output),
    );
    addSubcommand(
      ServerCreateCommand(client: client, config: config, output: _output),
    );
    addSubcommand(
      ServerGetCommand(client: client, config: config, output: _output),
    );
    addSubcommand(
      ServerUpdateCommand(client: client, config: config, output: _output),
    );
    addSubcommand(
      ServerDeleteCommand(client: client, config: config, output: _output),
    );
  }

  final IOSink _output;

  @override
  String get description => '외부 서버 엔드포인트 모음.';

  @override
  String get name => 'server';

  @override
  Future<void> run() async {
    throw UsageException('Specify a server subcommand.', usage);
  }
}

class ServerListCommand extends SoriCommand {
  ServerListCommand({
    required super.client,
    required super.config,
    super.output,
  }) : super(enableDataOption: false) {
    argParser
      ..addOption('cursor', help: '페이지네이션 커서')
      ..addOption('limit', help: '가져올 개수 (1~100)')
      ..addOption('sort-by', defaultsTo: 'createdAt', help: '정렬 기준 필드')
      ..addOption(
        'order-by',
        defaultsTo: 'desc',
        allowed: const ['asc', 'desc'],
        help: '정렬 순서',
      );
  }

  @override
  final String name = 'list';

  @override
  final String description = '서버 목록을 조회합니다.';

  @override
  String get invocation => 'sori server list [--cursor <cursor>] [--limit 20]';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final query = <String, dynamic>{};
    void add(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        query[key] = value;
      }
    }

    add('cursor', context.option<String>('cursor'));
    add('sortBy', context.option<String>('sort-by'));
    add('orderBy', context.option<String>('order-by'));

    final limit = context.option<String>('limit');
    if (limit != null && limit.isNotEmpty) {
      query['limit'] = limit;
    }

    final response = await context.client.get(
      'server',
      query: query.isEmpty ? null : query,
    );
    final data = response.data;
    context.render(data, paginated: true);
  }
}

class ServerCreateCommand extends SoriCommand {
  ServerCreateCommand({
    required super.client,
    required super.config,
    super.output,
  });

  @override
  final String name = 'create';

  @override
  final String description = '서버를 생성합니다.';

  @override
  String get invocation => 'sori server create -d name=<name> -d url=<url>';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final name = context.require('name');
    final url = context.require('url');
    final payload = {'name': name, 'url': url, ...context.namedArgs};

    final response = await context.client.post('server', data: payload);
    context.success('서버 생성 완료.');
    context.render(response.data);
  }
}

class ServerGetCommand extends SoriCommand {
  ServerGetCommand({required super.client, required super.config, super.output})
    : super(enableDataOption: false);

  @override
  final String name = 'get';

  @override
  final String description = '서버 정보를 조회합니다.';

  @override
  String get invocation => 'sori server get <id>';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final serverId = context.argResults?.rest.isNotEmpty == true
        ? context.argResults!.rest.first
        : null;
    if (serverId == null || serverId.isEmpty) {
      throw CliUsageException('서버 ID를 위치 인자로 전달하세요. 예: sori server get abc123');
    }
    final response = await context.client.get('server/$serverId');
    context.render(response.data);
  }
}

class ServerUpdateCommand extends SoriCommand {
  ServerUpdateCommand({
    required super.client,
    required super.config,
    super.output,
  });

  @override
  final String name = 'update';

  @override
  final String description = '서버 정보를 수정합니다.';

  @override
  String get invocation => 'sori server update <id> -d url=<url>';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final serverId = context.argResults?.rest.isNotEmpty == true
        ? context.argResults!.rest.first
        : null;
    if (serverId == null || serverId.isEmpty) {
      throw CliUsageException(
        '서버 ID를 위치 인자로 전달하세요. 예: sori server update abc123 -d url=<url>',
      );
    }
    if (context.namedArgs.isEmpty) {
      throw CliUsageException('수정할 필드를 -d key=value 형태로 지정하세요.');
    }
    final response = await context.client.patch(
      'server/$serverId',
      data: context.namedArgs,
    );
    context.success('서버 수정 완료.');
    context.render(response.data);
  }
}

class ServerDeleteCommand extends SoriCommand {
  ServerDeleteCommand({
    required super.client,
    required super.config,
    super.output,
  }) : super(enableDataOption: false);

  @override
  final String name = 'delete';

  @override
  final String description = '서버를 삭제합니다.';

  @override
  String get invocation => 'sori server delete <id>';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final serverId = context.argResults?.rest.isNotEmpty == true
        ? context.argResults!.rest.first
        : null;
    if (serverId == null || serverId.isEmpty) {
      throw CliUsageException(
        '서버 ID를 위치 인자로 전달하세요. 예: sori server delete abc123',
      );
    }
    await context.client.delete('server/$serverId');
    context.success('서버 삭제 완료.');
  }
}
