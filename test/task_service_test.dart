import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tarefas_http/models/task.dart';
import 'package:tarefas_http/services/task_service.dart';

const task = Task(id: 1, userId: 1, title: 'Estudar Flutter', completed: false);
void main() {
  test('GET, POST, PUT e DELETE enviam URL, headers e JSON corretos', () async {
    final methods = <String>[];
    final service = TaskService(
      client: MockClient((request) async {
        methods.add(request.method);
        expect(request.headers['accept'], 'application/json');
        expect(request.url.host, 'jsonplaceholder.typicode.com');
        if (request.method == 'GET') {
          expect(request.url.queryParameters['userId'], '1');
          return http.Response(jsonEncode([task.toJson()]), 200);
        }
        if (request.method == 'DELETE') {
          expect(request.url.path, '/todos/1');
          return http.Response('', 204);
        }
        expect(request.headers['content-type'], contains('application/json'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['title'], 'Estudar Flutter');
        expect(body['userId'], 1);
        return http.Response(
          jsonEncode({...body, 'id': 1}),
          request.method == 'POST' ? 201 : 200,
        );
      }),
    );
    expect((await service.fetchTasks()).single.title, task.title);
    expect((await service.createTask(' Estudar Flutter ')).title, task.title);
    expect((await service.updateTask(task)).id, 1);
    await service.deleteTask(1);
    expect(methods, ['GET', 'POST', 'PUT', 'DELETE']);
    service.dispose();
  });
  for (final status in [404, 500]) {
    test('HTTP $status é apresentado como erro', () async {
      final service = TaskService(
        client: MockClient((_) async => http.Response('{}', status)),
      );
      await expectLater(
        service.fetchTasks(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('$status'),
          ),
        ),
      );
      service.dispose();
    });
  }
  for (final body in [
    'invalid',
    '{}',
    '[{}]',
    '[{"id":1,"userId":1,"title":"x"}]',
  ]) {
    test('JSON inesperado ou incompleto: $body', () async {
      final service = TaskService(
        client: MockClient((_) async => http.Response(body, 200)),
      );
      await expectLater(service.fetchTasks(), throwsA(isA<ApiException>()));
      service.dispose();
    });
  }
  test('Sem conexão', () async {
    final service = TaskService(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(
      service.fetchTasks(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('conexão'),
        ),
      ),
    );
    service.dispose();
  });
  test('Timeout', () async {
    final service = TaskService(
      timeout: const Duration(milliseconds: 5),
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response('[]', 200);
      }),
    );
    await expectLater(
      service.fetchTasks(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('demorou'),
        ),
      ),
    );
    service.dispose();
  });
  test('URL incorreta', () async {
    final service = TaskService(
      baseUrl: 'http://[invalid',
      client: MockClient((_) async => http.Response('[]', 200)),
    );
    await expectLater(service.fetchTasks(), throwsA(isA<ApiException>()));
    service.dispose();
  });
}
