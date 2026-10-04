import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tarefas_http/screens/home_page.dart';
import 'package:tarefas_http/services/task_service.dart';

void main() {
  testWidgets('Lista, formulário obrigatório e bloqueio de envios repetidos', (
    tester,
  ) async {
    var posts = 0;
    final gate = Completer<void>();
    final service = TaskService(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          posts++;
          await gate.future;
          return http.Response(
            jsonEncode({
              'id': 201,
              'userId': 1,
              'title': 'Nova tarefa de teste',
              'completed': false,
            }),
            201,
          );
        }
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'userId': 1,
              'title': 'Estudar Flutter',
              'completed': false,
            },
          ]),
          200,
        );
      }),
    );
    await tester.pumpWidget(MaterialApp(home: HomePage(service: service)));
    await tester.pumpAndSettle();
    expect(find.text('Minhas Tarefas'), findsOneWidget);
    expect(find.text('Estudar Flutter'), findsOneWidget);
    await tester.tap(find.text('Nova tarefa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cadastrar'));
    await tester.pump();
    expect(find.text('Digite o título da tarefa.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Nova tarefa de teste');
    await tester.tap(find.text('Cadastrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Nova tarefa'));
    await tester.pump();
    expect(find.byType(TaskForm), findsNothing);
    expect(posts, 1);
    gate.complete();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Nova tarefa de teste'), findsOneWidget);
    service.dispose();
  });
  testWidgets('Erro de conexão permite tentar novamente', (tester) async {
    final service = TaskService(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await tester.pumpWidget(MaterialApp(home: HomePage(service: service)));
    await tester.pumpAndSettle();
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.textContaining('Falha de conexão'), findsOneWidget);
    service.dispose();
  });
}
