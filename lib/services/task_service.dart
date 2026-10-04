import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

class TaskService {
  final http.Client _client;
  final String baseUrl;
  final Duration timeout;
  TaskService({
    http.Client? client,
    this.baseUrl = 'https://jsonplaceholder.typicode.com',
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();
  static const headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };
  Future<http.Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'));
      request.headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final response = await (() async => http.Response.fromStream(
        await _client.send(request),
      ))().timeout(timeout);
      if (kDebugMode) {
        debugPrint(
          '$method ${request.url} | headers: $headers | HTTP ${response.statusCode}',
        );
        debugPrint(response.body);
      }
      final expected = method == 'POST'
          ? [201]
          : method == 'DELETE'
          ? [200, 204]
          : [200];
      if (!expected.contains(response.statusCode)) {
        throw ApiException(
          'Erro HTTP ${response.statusCode}. ${response.statusCode == 404
              ? 'Recurso não encontrado.'
              : response.statusCode >= 500
              ? 'O servidor está indisponível.'
              : 'A operação não foi aceita.'}',
        );
      }
      return response;
    } on TimeoutException {
      throw const ApiException(
        'O servidor demorou para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Falha de conexão. Confira sua internet e tente novamente.',
      );
    } on FormatException {
      throw const ApiException('Endereço da API inválido.');
    }
  }

  dynamic _decode(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const ApiException('A API retornou JSON inválido.');
    }
  }

  Task _task(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const ApiException('Formato de tarefa inesperado.');
    }
    try {
      return Task.fromJson(value);
    } on FormatException catch (e) {
      throw ApiException(e.message);
    }
  }

  Future<List<Task>> fetchTasks() async {
    final data = _decode(await _request('GET', '/todos?userId=1'));
    if (data is! List) {
      throw const ApiException('A API não retornou uma lista de tarefas.');
    }
    return data.map(_task).toList();
  }

  Future<Task> createTask(String title) async => _task(
    _decode(
      await _request(
        'POST',
        '/todos',
        body: {'userId': 1, 'title': title.trim(), 'completed': false},
      ),
    ),
  );
  Future<Task> updateTask(Task task) async => _task(
    _decode(await _request('PUT', '/todos/${task.id}', body: task.toJson())),
  );
  Future<void> deleteTask(int id) async {
    await _request('DELETE', '/todos/$id');
  }

  void dispose() => _client.close();
}
