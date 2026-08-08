import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_source_code/chat/data/services/socket_service.dart';
import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this._path);

  final String _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;

  @override
  Future<String?> getApplicationSupportPath() async => _path;

  @override
  Future<String?> getTemporaryPath() async => _path;

  @override
  Future<String?> getApplicationCachePath() async => _path;
}

const _base = 'https://backendforwehelp.onrender.com';

Future<Map<String, dynamic>> _api(
  String method,
  String path, {
  Map<String, dynamic>? body,
  String? token,
}) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl(method, Uri.parse('$_base/$path'));
    req.headers.contentType = ContentType.json;
    if (token != null) {
      req.headers.set('Authorization', 'Bearer $token');
    }
    if (body != null) {
      req.write(jsonEncode(body));
    }
    final res = await req.close();
    final text = await res.transform(utf8.decoder).join();
    final decoded =
        text.isEmpty ? <String, dynamic>{} : jsonDecode(text) as Map<String, dynamic>;
    return {'status': res.statusCode, 'body': decoded};
  } finally {
    client.close(force: true);
  }
}

Future<Map<String, dynamic>> _login(String email, String password) async {
  final res = await _api(
    'POST',
    'authentication/login',
    body: {'email': email, 'password': password},
  );
  if (res['status'] != 200 && res['status'] != 201) {
    throw StateError('login failed: ${res['status']} ${res['body']}');
  }
  final body = res['body'] as Map<String, dynamic>;
  final user = body['user'] as Map<String, dynamic>;
  return {
    'token': body['access_token'] ?? body['accessToken'],
    'id': (user['id'] ?? user['_id']).toString(),
    'role': user['role'],
  };
}

Future<Map<String, dynamic>> _createRequest(String token, String title) async {
  final res = await _api(
    'POST',
    'help-requests',
    token: token,
    body: {
      'title': title,
      'category': 'Medical',
      'subCategory': 'E2E Test',
      'description': 'Automated client E2E',
      'locationName': 'Abbottabad',
      'latitude': 34.1999,
      'longitude': 73.2416,
    },
  );
  if (res['status'] != 200 && res['status'] != 201) {
    throw StateError('create request failed: ${res['status']} ${res['body']}');
  }
  return res['body'] as Map<String, dynamic>;
}

Future<void> _waitForConnected(
  SocketService service,
  bool expected, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (service.isConnected == expected) return;
    await Future.delayed(const Duration(milliseconds: 250));
  }
  throw StateError(
    'socket isConnected did not become $expected (was ${service.isConnected})',
  );
}

/// Waits until an event for [requestId] is seen, then waits a grace window
/// to detect duplicate deliveries for the same request.
Future<void> _expectEvent(
  String requestId,
  List<String> events, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (events.contains(requestId)) {
      await Future.delayed(const Duration(seconds: 3));
      return;
    }
    await Future.delayed(const Duration(milliseconds: 250));
  }
  throw StateError('did not receive new_help_request for $requestId; seen: $events');
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // flutter_test replaces HttpClient with a 400-returning mock; this test
    // needs the real network (plain test(), so this is the only override).
    HttpOverrides.global = null;
    final dir = await Directory.systemTemp.createTemp('getstorage_e2e');
    PathProviderPlatform.instance = _FakePathProviderPlatform(dir.path);
    await GetStorage.init();
  });

  test(
    'FE E2E: register, receive new_help_request, reconnect, no duplicate events',
    () async {
      const volEmail = String.fromEnvironment('VOL_EMAIL');
      const reqEmail = String.fromEnvironment('REQ_EMAIL');
      const password = String.fromEnvironment('PASSWORD');
      expect(volEmail, isNotEmpty);
      expect(reqEmail, isNotEmpty);
      expect(password, isNotEmpty);

      // Same storage keys the real login flow writes (auth_contrl.dart).
      final storage = StorageHelper();
      final vol = await _login(volEmail, password);
      expect(vol['role'], 'volunteer');
      storage.saveData('token', vol['token']);
      storage.saveData('userId', vol['id']);
      storage.saveData('role', 'volunteer');

      final req = await _login(reqEmail, password);

      final service = SocketService();
      // A: fresh connect with a valid token (exact client code path)
      service.connect(vol['token'] as String);
      await _waitForConnected(service, true);

      // G: duplicate connect with the same token must be a no-op
      service.connect(vol['token'] as String);
      await Future.delayed(const Duration(seconds: 1));
      expect(service.isConnected, isTrue);

      final events = <String>[];
      final sub = service.flowEventStream.listen((e) {
        final d = e['data'];
        if (e['event'] == 'new_help_request' && d is Map && d['_id'] != null) {
          print('[TEST] flow event: ${e['event']} id=${d['_id']} isSos=${d['isSos']}');
          events.add(d['_id'] as String);
        }
      });

      // create request -> volunteer must receive exactly one event
      final created = await _createRequest(req['token'] as String, 'E2E FE TEST 1');
      final reqId = ((created['data'] as Map<String, dynamic>)['request']
          as Map<String, dynamic>)['_id'] as String;
      print('[TEST] created request 1: $reqId');
      await _expectEvent(reqId, events);

      // D: disconnect then reconnect with the same token
      service.disconnect();
      await _waitForConnected(service, false);
      print('[TEST] disconnected - reconnecting with same token');
      service.connect(vol['token'] as String);
      await _waitForConnected(service, true);

      final created2 = await _createRequest(req['token'] as String, 'E2E FE TEST 2');
      final reqId2 = ((created2['data'] as Map<String, dynamic>)['request']
          as Map<String, dynamic>)['_id'] as String;
      print('[TEST] created request 2: $reqId2');
      await _expectEvent(reqId2, events);

      expect(events.where((id) => id == reqId).length, 1);
      expect(events.where((id) => id == reqId2).length, 1);
      print('[TEST] FE E2E PASS: registered, received, reconnected, no duplicates');

      await sub.cancel();
      service.disconnect();
    },
    timeout: Timeout(const Duration(minutes: 4)),
  );
}
