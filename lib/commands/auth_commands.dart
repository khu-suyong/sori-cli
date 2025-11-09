import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../config.dart';
import '../services/api_client.dart';
import 'base.dart';

class AuthCommand extends Command<void> {
  AuthCommand({
    required ApiClient client,
    required Config config,
    IOSink? output,
  }) : _output = output ?? stdout {
    addSubcommand(
      AuthRefreshCommand(client: client, config: config, output: _output),
    );
    addSubcommand(
      AuthStartCommand(client: client, config: config, output: _output),
    );
    addSubcommand(
      AuthCallbackCommand(client: client, config: config, output: _output),
    );
  }

  final IOSink _output;

  @override
  String get description => '인증 관련 엔드포인트 모음.';

  @override
  String get name => 'auth';

  @override
  Future<void> run() async {
    throw UsageException('Specify an auth subcommand.', usage);
  }
}

class AuthRefreshCommand extends SoriCommand {
  AuthRefreshCommand({
    required super.client,
    required super.config,
    super.output,
  }) : super(enableDataOption: false);

  @override
  final String name = 'refresh';

  @override
  final String description = '리프레시 토큰으로 새로운 토큰을 발급합니다.';

  @override
  String get invocation => 'sori auth refresh';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final response = await context.client.post('auth/refresh');
    context.success('토큰 재발급 완료 (HTTP ${response.statusCode ?? 'unknown'}).');
    context.render(response.data);
    _captureTokens(context, response.data);
  }
}

class AuthStartCommand extends SoriCommand {
  AuthStartCommand({required super.client, required super.config, super.output})
    : super(enableDataOption: false) {
    argParser.addOption(
      'provider',
      abbr: 'p',
      help: 'OAuth 제공자 이름',
      defaultsTo: 'google',
      allowed: const ['google'],
    );
  }

  @override
  final String name = 'login';

  @override
  final String description = 'OAuth 인증을 시작합니다.';

  @override
  String get invocation => 'sori auth login --provider google';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final provider = context.option<String>('provider') ?? 'google';

    final result = await authWithBrowser(provider, (url) {
      context.info('브라우저에서 로그인을 계속 진행합니다: $url');
    });

    config.accessToken = result.$1;
    config.refreshToken = result.$2;

    context.success('인증 완료. 토큰이 저장되었습니다.');
  }

  Future<(String, String)> authWithBrowser(
    String provider,
    void Function(String url)? onRedirect,
  ) async {
    Duration timeout = const Duration(minutes: 5);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final completer = Completer<(String, String)>();
    final url =
        '${config.serverUrl}/auth/$provider?redirect=http%3A%2F%2Flocalhost%3A${server.port}%2F';
    onRedirect?.call(url);

    final sub = server.listen((HttpRequest req) async {
      if (req.method == 'GET' &&
          req.uri.path == '/' &&
          !completer.isCompleted) {
        final query = req.uri.queryParameters;

        String? accessToken;
        String? refreshToken;
        query.forEach((key, value) {
          if (key == 'accessToken') {
            accessToken = value;
          } else if (key == 'refreshToken') {
            refreshToken = value;
          }
        });

        if (accessToken != null && refreshToken != null) {
          req.response
            ..statusCode = 200
            ..headers.contentType = ContentType.html
            ..write(
              '<html><body style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;">완료되었습니다. 이제 이 창을 닫아도 됩니다.</body></html>',
            );

          await req.response.close();
          completer.complete((accessToken!, refreshToken!));
        } else {
          req.response
            ..statusCode = 200
            ..headers.contentType = ContentType.html
            ..write(
              '<html><body style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;">인증에 실패하였습니다.</body></html>',
            );

          await req.response.close();
          completer.completeError(Exception('인증에 실패했습니다. 토큰이 제공되지 않았습니다.'));
        }

        await server.close(force: true);
      } else {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
      }
    });

    // 타임아웃 처리
    unawaited(
      Future.delayed(timeout, () async {
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException('callback timeout'));
          await sub.cancel();
          await server.close(force: true);
        }
      }),
    );

    return completer.future;
  }
}

class AuthCallbackCommand extends SoriCommand {
  AuthCallbackCommand({
    required super.client,
    required super.config,
    super.output,
  }) {
    argParser.addOption(
      'provider',
      abbr: 'p',
      help: 'OAuth 제공자 이름',
      defaultsTo: 'google',
      allowed: const ['google'],
    );
  }

  @override
  final String name = 'callback';

  @override
  final String description = 'OAuth 콜백을 수동으로 트리거합니다.';

  @override
  String get invocation =>
      'sori auth callback --provider google -d code=<value> -d state=<value>';

  @override
  Future<void> runWithContext(CommandContext context) async {
    final provider = context.option<String>('provider') ?? 'google';
    final response = await context.client.get(
      'auth/$provider/callback',
      query: context.namedArgs.isEmpty ? null : context.namedArgs,
    );

    context.success(
      'OAuth 콜백 처리 완료 (HTTP ${response.statusCode ?? 'unknown'}).',
    );
    context.render(response.data);
    _captureTokens(context, response.data);
  }
}

void _captureTokens(CommandContext context, Object? payload) {
  if (payload is! Map) {
    return;
  }
  final access = payload['accessToken'] as String?;
  final refresh = payload['refreshToken'] as String?;
  if (access == null && refresh == null) {
    return;
  }
  context.config.accessToken = access ?? context.config.accessToken;
  context.config.refreshToken = refresh ?? context.config.refreshToken;
}
