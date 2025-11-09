import 'dart:io';

import 'package:args/command_runner.dart';

import '../config.dart';
import '../services/api_client.dart';
import '../utils/output.dart';
import 'base.dart';

class WorkspaceCommand extends Command<void> {
  WorkspaceCommand({
    required ApiClient client,
    required Config config,
    IOSink? output,
  }) : _output = output ?? stdout {
    addSubcommand(
      WorkspaceListCommand(client: client, config: config, output: _output),
    );
    addSubcommand(
      WorkspaceCreateCommand(client: client, config: config, output: _output),
    );
    addSubcommand(
      WorkspaceGetCommand(client: client, config: config, output: _output),
    );
    addSubcommand(
      WorkspaceFolderCreateCommand(
        client: client,
        config: config,
        output: _output,
      ),
    );
    addSubcommand(
      WorkspaceFolderUpdateCommand(
        client: client,
        config: config,
        output: _output,
      ),
    );
    addSubcommand(
      WorkspaceFolderDeleteCommand(
        client: client,
        config: config,
        output: _output,
      ),
    );
    addSubcommand(
      WorkspaceNoteCreateCommand(
        client: client,
        config: config,
        output: _output,
      ),
    );
    addSubcommand(
      WorkspaceNoteUpdateCommand(
        client: client,
        config: config,
        output: _output,
      ),
    );
    addSubcommand(
      WorkspaceNoteDeleteCommand(
        client: client,
        config: config,
        output: _output,
      ),
    );
    addSubcommand(
      WorkspaceNoteTranscribeCommand(
        client: client,
        config: config,
        output: _output,
      ),
    );
  }

  final IOSink _output;

  @override
  String get description => '워크스페이스 관련 모든 엔드포인트.';

  @override
  String get name => 'workspace';

  @override
  Future<void> run() async {
    printInfo('workspace 서브커맨드를 선택하세요.', sink: _output);
    throw UsageException('Workspace command requires a subcommand.', usage);
  }
}

class WorkspaceListCommand extends SoriCommand {
  WorkspaceListCommand({
    required super.client,
    required super.config,
    super.output,
  }) : super(enableDataOption: false) {
    argParser
      ..addOption('cursor', help: '페이지네이션 커서')
      ..addOption('limit', help: '가져올 워크스페이스 개수 (1~100)')
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
  final String description = '현재 유저의 워크스페이스를 모두 조회합니다.';

  @override
  String get invocation =>
      'sori workspace list [--cursor <cursor>] [--limit 20] [--sort-by createdAt] [--order-by desc]';

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
      'workspace',
      query: query.isEmpty ? null : query,
    );
    final data = response.data;
    context.render(data, paginated: true);
  }
}

class WorkspaceCreateCommand extends SoriCommand {
  WorkspaceCreateCommand({
    required super.client,
    required super.config,
    super.output,
  });

  @override
  final String name = 'create';

  @override
  final String description = '워크스페이스를 생성합니다.';

  @override
  String get invocation => 'sori workspace create -d name=<value>';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final payload = {'name': context.require('name'), ...context.namedArgs};

    final response = await context.client.post('workspace', data: payload);

    context.success('워크스페이스가 생성되었습니다.');
    context.render(response.data);
  }
}

class WorkspaceGetCommand extends SoriCommand {
  WorkspaceGetCommand({
    required super.client,
    required super.config,
    super.output,
  }) : super(enableDataOption: false) {
    argParser.addOption('workspace-id', mandatory: true, help: '조회할 워크스페이스 ID');
  }

  @override
  final String name = 'get';

  @override
  final String description = '특정 워크스페이스를 조회합니다.';

  @override
  String get invocation => 'sori workspace get --workspace-id <id>';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final workspaceId = _requireWorkspaceId(context);
    final response = await context.client.get('workspace/$workspaceId');
    context.render(response.data);
  }
}

class WorkspaceFolderCreateCommand extends SoriCommand {
  WorkspaceFolderCreateCommand({
    required super.client,
    required super.config,
    super.output,
  }) {
    argParser.addOption(
      'workspace-id',
      mandatory: true,
      help: '폴더를 생성할 워크스페이스 ID',
    );
  }

  @override
  final String name = 'folder-create';

  @override
  final String description = '폴더를 생성합니다.';

  @override
  String get invocation =>
      'sori workspace folder-create --workspace-id <id> -d name=<value>';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final workspaceId = _requireWorkspaceId(context);
    context.require('name');
    final response = await context.client.post(
      'workspace/$workspaceId/folder',
      data: context.namedArgs,
    );
    context.success('폴더 생성 완료.');
    context.render(response.data);
  }
}

class WorkspaceFolderUpdateCommand extends SoriCommand {
  WorkspaceFolderUpdateCommand({
    required super.client,
    required super.config,
    super.output,
  }) {
    argParser
      ..addOption('workspace-id', mandatory: true, help: '폴더가 속한 워크스페이스 ID')
      ..addOption('folder-id', mandatory: true, help: '수정할 폴더 ID');
  }

  @override
  final String name = 'folder-update';

  @override
  final String description = '폴더를 수정합니다.';

  @override
  String get invocation =>
      'sori workspace folder-update --workspace-id <id> --folder-id <id> -d name=<value>';

  @override
  Future<void> runWithContext(CommandContext context) async {
    if (context.namedArgs.isEmpty) {
      throw CliUsageException('수정할 필드를 -d key=value 형태로 전달하세요.');
    }
    final workspaceId = _requireWorkspaceId(context);
    final folderId = context.requireOption('folder-id');
    final response = await context.client.patch(
      'workspace/$workspaceId/folder/$folderId',
      data: context.namedArgs,
    );
    context.success('폴더 수정 완료.');
    context.render(response.data);
  }
}

class WorkspaceFolderDeleteCommand extends SoriCommand {
  WorkspaceFolderDeleteCommand({
    required super.client,
    required super.config,
    super.output,
  }) : super(enableDataOption: false) {
    argParser
      ..addOption('workspace-id', mandatory: true, help: '폴더가 속한 워크스페이스 ID')
      ..addOption('folder-id', mandatory: true, help: '삭제할 폴더 ID');
  }

  @override
  final String name = 'folder-delete';

  @override
  final String description = '폴더를 삭제합니다.';

  @override
  String get invocation =>
      'sori workspace folder-delete --workspace-id <id> --folder-id <id>';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final workspaceId = _requireWorkspaceId(context);
    final folderId = context.requireOption('folder-id');
    await context.client.delete('workspace/$workspaceId/folder/$folderId');
    context.success('폴더 삭제 완료.');
  }
}

class WorkspaceNoteCreateCommand extends SoriCommand {
  WorkspaceNoteCreateCommand({
    required super.client,
    required super.config,
    super.output,
  }) {
    argParser.addOption(
      'workspace-id',
      mandatory: true,
      help: '노트를 생성할 워크스페이스 ID',
    );
  }

  @override
  final String name = 'note-create';

  @override
  final String description = '노트를 생성합니다.';

  @override
  String get invocation =>
      'sori workspace note-create --workspace-id <id> -d name=<value>';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final workspaceId = _requireWorkspaceId(context);
    context.require('name');
    final response = await context.client.post(
      'workspace/$workspaceId/note',
      data: context.namedArgs,
    );
    context.success('노트 생성 완료.');
    context.render(response.data);
  }
}

class WorkspaceNoteUpdateCommand extends SoriCommand {
  WorkspaceNoteUpdateCommand({
    required super.client,
    required super.config,
    super.output,
  }) {
    argParser
      ..addOption('workspace-id', mandatory: true, help: '노트가 속한 워크스페이스 ID')
      ..addOption('note-id', mandatory: true, help: '수정할 노트 ID');
  }

  @override
  final String name = 'note-update';

  @override
  final String description = '노트를 수정합니다.';

  @override
  String get invocation =>
      'sori workspace note-update --workspace-id <id> --note-id <id> -d name=<value>';

  @override
  Future<void> runWithContext(CommandContext context) async {
    if (context.namedArgs.isEmpty) {
      throw CliUsageException('수정할 필드를 -d key=value 형태로 전달하세요.');
    }
    final workspaceId = _requireWorkspaceId(context);
    final noteId = context.requireOption('note-id');
    final response = await context.client.patch(
      'workspace/$workspaceId/note/$noteId',
      data: context.namedArgs,
    );
    context.success('노트 수정 완료.');
    context.render(response.data);
  }
}

class WorkspaceNoteDeleteCommand extends SoriCommand {
  WorkspaceNoteDeleteCommand({
    required super.client,
    required super.config,
    super.output,
  }) : super(enableDataOption: false) {
    argParser
      ..addOption('workspace-id', mandatory: true, help: '노트가 속한 워크스페이스 ID')
      ..addOption('note-id', mandatory: true, help: '삭제할 노트 ID');
  }

  @override
  final String name = 'note-delete';

  @override
  final String description = '노트를 삭제합니다.';

  @override
  String get invocation =>
      'sori workspace note-delete --workspace-id <id> --note-id <id>';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final workspaceId = _requireWorkspaceId(context);
    final noteId = context.requireOption('note-id');
    await context.client.delete('workspace/$workspaceId/note/$noteId');
    context.success('노트 삭제 완료.');
  }
}

class WorkspaceNoteTranscribeCommand extends SoriCommand {
  WorkspaceNoteTranscribeCommand({
    required super.client,
    required super.config,
    super.output,
  }) : super(enableDataOption: false) {
    argParser
      ..addOption('workspace-id', mandatory: true, help: '노트가 속한 워크스페이스 ID')
      ..addOption('note-id', mandatory: true, help: '음성 필기를 진행할 노트 ID');
  }

  @override
  final String name = 'note-transcribe';

  @override
  final String description = '노트 음성 필기(WebSocket) 엔드포인트 정보를 제공합니다.';

  @override
  String get invocation =>
      'sori workspace note-transcribe --workspace-id <id> --note-id <id>';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final workspaceId = _requireWorkspaceId(context);
    final noteId = context.requireOption('note-id');
    final base = context.client.config.serverUrl;
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    final httpUrl = base.resolve(
      'workspace/$workspaceId/note/$noteId/transcribe',
    );
    final wsUrl = httpUrl.replace(scheme: scheme);

    context.info('이 엔드포인트는 WebSocket 전용입니다.');
    context.info('예: wscat -c $wsUrl');
  }
}

String _requireWorkspaceId(CommandContext context) =>
    context.requireOption('workspace-id');
