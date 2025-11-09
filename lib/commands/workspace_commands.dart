import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dart_console/dart_console.dart';
import 'package:web_socket_channel/io.dart';

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
      WorkspaceNoteGetCommand(client: client, config: config, output: _output),
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

class WorkspaceNoteGetCommand extends SoriCommand {
  WorkspaceNoteGetCommand({
    required super.client,
    required super.config,
    super.output,
  }) {
    argParser
      ..addOption('workspace-id', mandatory: true, help: '노트가 속한 워크스페이스 ID')
      ..addOption('note-id', mandatory: true, help: '조회할 노트 ID');
  }

  @override
  final String name = 'note-get';

  @override
  final String description = '특정 노트를 조회합니다.';

  @override
  String get invocation =>
      'sori workspace note-get --workspace-id <id> --note-id <id>';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final workspaceId = _requireWorkspaceId(context);
    final noteId = context.requireOption('note-id');
    final response = await context.client.get(
      'workspace/$workspaceId/note/$noteId',
    );
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
  static const sampleRate = 48000;
  static const channels = 1;
  static const bytesPerSample = 2;
  static const frameMs = 20;
  static const frameBytes =
      sampleRate * channels * bytesPerSample * frameMs ~/ 1000;

  WorkspaceNoteTranscribeCommand({
    required super.client,
    required super.config,
    super.output,
  }) : super(enableDataOption: false) {
    argParser
      ..addOption('workspace-id', mandatory: true, help: '노트가 속한 워크스페이스 ID')
      ..addOption('note-id', mandatory: true, help: '음성 필기를 진행할 노트 ID')
      ..addOption('mic', help: '사용할 마이크 장치 이름');
  }

  @override
  final String name = 'note-transcribe';

  @override
  final String description = '노트 음성 필기(WebSocket) 엔드포인트 정보를 제공합니다.';

  @override
  String get invocation =>
      'sori workspace note-transcribe --workspace-id <id> --note-id <id> --mic <mic_name>';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final workspaceId = _requireWorkspaceId(context);
    final noteId = context.requireOption('note-id');
    final micName = context.option<String>('mic');

    if (micName == null) {
      context.info(
        "설정된 마이크가 없습니다. `sori status mic` 명령어로 사용 가능한 마이크 장치를 확인할 수 있습니다.",
      );
      return;
    }

    final base = context.client.config.serverUrl;
    final httpUrl = '$base/workspace/$workspaceId/note/$noteId/transcribe';
    final wsUrl = httpUrl
        .replaceFirst('http', 'ws')
        .replaceFirst('https', 'wss')
        .toString();
    context.info('WebSocket URL: $wsUrl');

    // final test = "ws://localhost:8000/asr";
    await startTranscribe(wsUrl, mic: micName);
  }

  Future<List<String>> _ffArgs({String mic = 'default'}) async {
    if (Platform.isMacOS) {
      return [
        '-f',
        'avfoundation',
        '-i',
        ':0',
        '-c:a',
        'libopus',
        '-ac',
        '1',
        '-ar',
        sampleRate.toString(),
        '-f',
        'webm',
        '-',
      ];
    } else if (Platform.isLinux) {
      return [
        '-f',
        'alsa',
        '-i',
        'default',
        '-c:a',
        'libopus',
        '-ac',
        '1',
        '-ar',
        sampleRate.toString(),
        '-f',
        'webm',
        '-',
      ];
    } else if (Platform.isWindows) {
      final device = Platform.environment['MIC_DEVICE'] ?? mic;
      return [
        '-f',
        'dshow',
        '-i',
        'audio=$device',
        '-c:a',
        'libopus',
        '-ac',
        '1',
        '-ar',
        sampleRate.toString(),
        '-f',
        'webm',
        '-',
      ];
    }
    throw UnsupportedError('OS not supported');
  }

  Future<void> startTranscribe(String url, {String mic = 'default'}) async {
    final ch = IOWebSocketChannel.connect(
      url,
      headers: {'Authorization': 'Bearer ${config.accessToken}'},
    );
    final sink = ch.sink;

    final ff = await Process.start(
      'ffmpeg',
      await _ffArgs(mic: mic),
      mode: ProcessStartMode.normal,
    );

    ff.stderr.transform(utf8.decoder).listen((s) {
      stderr.write(s);
    });

    ProcessSignal.sigint.watch().listen((_) async {
      sink.close();
      ff.kill(ProcessSignal.sigterm);
      await ff.exitCode;
      exit(0);
    });

    var endFlag = false;
    final buffer = BytesBuilder();
    final console = Console();
    final sub = ff.stdout.listen((List<int> chunk) {
      buffer.add(chunk);

      while (buffer.length >= frameBytes) {
        final bytes = buffer.toBytes();
        final frame = Uint8List.view(bytes.buffer, 0, frameBytes);
        sink.add(frame);

        final remaining = bytes.length - frameBytes;
        if (remaining > 0) {
          final rest = Uint8List.view(bytes.buffer, frameBytes, remaining);
          buffer.clear();
          buffer.add(rest);
        } else {
          buffer.clear();
        }
      }
    });

    console.clearScreen();
    console.resetCursorPosition();
    console.writeLine('음성 필기 중... Ctrl+C를 눌러 종료합니다.');
    console.writeLine('');

    ch.stream.listen(
      (message) {
        console.clearScreen();
        console.resetCursorPosition();
        console.writeLine('음성 필기 중... Ctrl+C를 눌러 종료합니다.');
        console.writeLine('check: ${DateTime.now().toIso8601String()}');
        final data = jsonDecode(message);

        if (data is! Map<String, dynamic>) {
          console.writeLine('Invalid message format.');
          return;
        }

        data['lines']?.forEach((line) {
          final speaker = line['speaker'];
          final text = line['text'];
          final start = line['start'];
          final end = line['end'];
          console.writeLine("$start ~ $end");
          console.writeLine('[$speaker]: $text');
          console.writeLine('');
        });
      },
      onDone: () {
        console.writeLine('WebSocket closed.');
        endFlag = true;
        ff.kill(ProcessSignal.sigterm);
      },
      onError: (error) {
        console.writeLine('WebSocket error: $error');
        endFlag = true;
        ff.kill(ProcessSignal.sigterm);
      },
    );

    ff.exitCode.then((code) async {
      await sub.cancel();
      await sink.close();
      endFlag = true;
      if (code != 0) console.writeLine('ffmpeg exited with $code');
    });

    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 5000));
      return !endFlag;
    });
  }
}

String _requireWorkspaceId(CommandContext context) =>
    context.requireOption('workspace-id');
