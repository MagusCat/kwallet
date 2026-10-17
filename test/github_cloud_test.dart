import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kwall/core/contracts/app_repositories.dart';
import 'package:kwall/core/models/recovery_copy.dart';
import 'package:kwall/core/services/device_files.dart';
import 'package:kwall/core/services/github_cloud_service.dart';
import 'package:kwall/features/settings/view_models/settings_view_model.dart';

class MockHttpClient implements HttpClient {
  final Map<String, dynamic> Function(String method, Uri uri, String? body) handler;
  MockHttpClient(this.handler);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return MockHttpClientRequest(method, url, handler);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => openUrl('GET', url);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpClientRequest implements HttpClientRequest {
  @override
  final String method;
  @override
  final Uri uri;
  final Map<String, dynamic> Function(String method, Uri uri, String? body) handler;
  final List<int> _bodyBytes = [];
  @override
  final HttpHeaders headers = MockHttpHeaders();

  MockHttpClientRequest(this.method, this.uri, this.handler);

  @override
  void add(List<int> data) {
    _bodyBytes.addAll(data);
  }

  @override
  int contentLength = 0;

  @override
  Future<HttpClientResponse> close() async {
    final bodyStr = _bodyBytes.isNotEmpty ? utf8.decode(_bodyBytes) : null;
    final result = handler(method, uri, bodyStr);
    final status = result['status'] as int? ?? 200;
    final respBody = jsonEncode(result['body'] ?? {});
    return MockHttpClientResponse(status, respBody);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  final int statusCode;
  final String responseBody;

  MockHttpClientResponse(this.statusCode, this.responseBody);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(utf8.encode(responseBody)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpHeaders implements HttpHeaders {
  @override
  ContentType? contentType;
  @override
  int contentLength = 0;
  final Map<String, Object> _headers = {};
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name.toLowerCase()] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSettingsRepo implements SettingsRepository {
  Map<String, String> data = {};
  @override
  final changes = ValueNotifier<int>(0);

  @override
  Future<Map<String, String>> getSettings() async => Map.from(data);

  @override
  Future<void> saveSettings(Map<String, String> values) async {
    data.addAll(values);
  }

  @override
  Future<String> exportFullDataAsJson() async => '{"version": 1, "accounts": []}';

  @override
  Future<Map<String, int>> inspectBackup(String content) async => {
        'accounts': 2,
        'movements': 10,
        'notes': 3,
        'habits': 1,
      };

  @override
  Future<void> importFullDataFromJson(String content) async {}

  @override
  Future<List<RecoveryCopy>> getRecoveryCopies() async => [];

  @override
  Future<String> readRecoveryCopy(String id) async => '{}';
}

class FakeDeviceFiles implements DeviceFiles {
  @override
  Future<String?> pickBackup() async => null;
  @override
  Future<String?> pickPetImage() async => null;
  @override
  Future<bool> saveBackup(String content, String suggestedName) async => true;
}

void main() {
  group('GitHubCloudService and Settings Cloud Backup Tests', () {
    test('GitHubUser models deserialization handles full and minimal profiles', () {
      final user = GitHubUser.fromJson({
        'login': 'MagusCat',
        'name': 'Magus',
        'avatar_url': 'https://avatars.githubusercontent.com/u/1234',
        'html_url': 'https://github.com/MagusCat',
      });
      expect(user.login, 'MagusCat');
      expect(user.name, 'Magus');
      expect(user.avatarUrl, contains('1234'));

      final fallbackUser = GitHubUser.fromJson({'login': 'octo'});
      expect(fallbackUser.name, 'octo');
    });

    test('GitHubCloudService verifies token and finds existing backup gist', () async {
      final service = GitHubCloudService(
        clientFactory: () => MockHttpClient((method, uri, body) {
          if (uri.path == '/user') {
            return {
              'status': 200,
              'body': {'login': 'kwalluser', 'name': 'Kwall Tester'},
            };
          }
          if (uri.path == '/gists') {
            return {
              'status': 200,
              'body': [
                {
                  'id': 'gist123',
                  'files': {
                    'kwall-backup.json': {'filename': 'kwall-backup.json'},
                  },
                }
              ],
            };
          }
          return {'status': 404, 'body': {}};
        }),
      );

      final user = await service.verifyToken('ghp_valid_token');
      expect(user.login, 'kwalluser');

      final gistId = await service.findBackupGist('ghp_valid_token');
      expect(gistId, 'gist123');
    });

    test('GitHubCloudService syncs and fetches backup JSON', () async {
      final service = GitHubCloudService(
        clientFactory: () => MockHttpClient((method, uri, body) {
          if (method == 'POST' && uri.path == '/gists') {
            return {
              'status': 201,
              'body': {
                'id': 'new_gist_456',
                'html_url': 'https://gist.github.com/new_gist_456',
                'updated_at': '2026-10-17T12:00:00Z',
              },
            };
          }
          if (method == 'GET' && uri.path == '/gists/new_gist_456') {
            return {
              'status': 200,
              'body': {
                'files': {
                  'kwall-backup.json': {
                    'content': '{"version":1,"accounts":[{"id":"acc1"}]}',
                  },
                },
              },
            };
          }
          return {'status': 404, 'body': {}};
        }),
      );

      final syncResult = await service.syncBackup(
        token: 'ghp_token',
        backupJson: '{"version":1,"accounts":[{"id":"acc1"}]}',
      );
      expect(syncResult.gistId, 'new_gist_456');

      final content = await service.fetchBackup(
        token: 'ghp_token',
        gistId: 'new_gist_456',
      );
      expect(content, contains('acc1'));
    });

    test('SettingsViewModel connects to GitHub, syncs and prepares restore', () async {
      final repo = FakeSettingsRepo();
      final files = FakeDeviceFiles();
      final cloud = GitHubCloudService(
        clientFactory: () => MockHttpClient((method, uri, body) {
          if (uri.path == '/user') {
            return {'status': 200, 'body': {'login': 'tester'}};
          }
          if (method == 'POST' && uri.path == '/gists') {
            return {
              'status': 201,
              'body': {
                'id': 'gist_live_789',
                'html_url': 'https://gist.github.com/gist_live_789',
                'updated_at': '2026-10-17T14:00:00Z',
              },
            };
          }
          if (method == 'GET' && uri.path == '/gists/gist_live_789') {
            return {
              'status': 200,
              'body': {
                'files': {
                  'kwall-backup.json': {
                    'content': '{"version":1,"accounts":[]}',
                  },
                },
              },
            };
          }
          return {'status': 200, 'body': []};
        }),
      );

      final vm = SettingsViewModel(repo, files, cloud);
      await vm.load();

      expect(vm.isGitHubConnected, false);

      final connected = await vm.connectGitHub('ghp_sample_token');
      expect(connected, true);
      expect(vm.isGitHubConnected, true);
      expect(vm.githubUsername, 'tester');

      final synced = await vm.syncToGitHub();
      expect(synced, true);
      expect(vm.githubGistId, 'gist_live_789');
      expect(vm.githubLastSync.isNotEmpty, true);

      final preview = await vm.prepareGitHubRestore();
      expect(preview, isNotNull);
      expect(preview!.accounts, 2);

      final disconnected = await vm.disconnectGitHub();
      expect(disconnected, true);
      expect(vm.isGitHubConnected, false);
      expect(vm.githubUsername, '');
    });
  });
}
