# Minhas Tarefas — tarefas_http

Aplicativo Flutter de uma atividade prática de "Implementação do Protocolo HTTP no Flutter".

É um único aplicativo de tarefas. Os exemplos de álbuns nas seções 6–13 explicam HTTP; o Catálogo de Jogos começa na seção 18 e não integra esta entrega.

## Entregas
- Código-fonte neste repositório público.
- APK Android instalável na release v1.0.0.

## Funcionalidades
- Tela "Minhas Tarefas", lista, filtros e contagem de pendentes/concluídas.
- GET /todos?userId=1 ao iniciar; recarregamento manual.
- POST /todos pelo formulário com título obrigatório.
- PUT /todos/{id} para editar título e marcar conclusão.
- DELETE /todos/{id} com confirmação.
- Loading, mensagens de sucesso, erro HTTP, conexão, timeout e JSON inesperado.
- Botões bloqueados durante operações para evitar envio repetido.
- Model Task com fromJson/toJson; TaskService com pacote http; interface separada.
- Headers Content-Type e Accept; INTERNET no manifesto Android.
- Status, URL, headers e body registrados apenas no modo debug.

## API didática
Usa https://jsonplaceholder.typicode.com, a API pública indicada na apostila, sem autenticação.
As alterações são simuladas no servidor; o aplicativo atualiza a lista em memória após respostas bem-sucedidas. Recarregar ou reiniciar restaura os dados originais.

Uma tarefa criada recebe ID 201, que não existe no servidor. Sua edição/conclusão fica desabilitada para evitar um PUT que o servidor não suporta; edite ou conclua as tarefas originais para demonstrar PUT. Não há persistência local nem backend próprio.

A seção 16 apresenta autenticação como introdução: esta API não exige token. Nenhum segredo é necessário no código.

## Executar e compilar
Requisitos usados: Flutter 3.41.9 / Dart 3.11.5, Android SDK e Java 21.
~~~sh
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
~~~
APK: build/app/outputs/flutter-apk/app-release.apk.
APK universal para ARM32, ARM64 e x86_64. A configuração Flutter usa assinatura de desenvolvimento para instalação direta; a entrega não é destinada à Play Store.

## Roteiro de demonstração
1. Abrir o app com internet e conferir a lista obtida por GET.
2. Cadastrar um título pelo botão Nova tarefa (POST / HTTP 201).
3. Editar uma tarefa original pelo menu de opções (PUT / HTTP 200).
4. Marcar uma tarefa original como concluída (PUT).
5. Excluir uma tarefa e confirmar (DELETE).
6. Desligar a internet e recarregar para ver o erro; ligar e tentar novamente.
7. Executar flutter run para conferir status/body/headers no console.

## Testes
Os testes de serviço verificam os quatro métodos, URL, headers, corpo JSON, erros 404/500, JSON inválido/incompleto, ausência de conexão, timeout e URL inválida.
Os testes de interface verificam listagem, validação de título, bloqueio durante envio e recuperação de erro.
Não há aparelho/emulador conectado neste ambiente; testes de interface são automatizados com flutter test.

## Referências
- https://docs.flutter.dev/cookbook/networking/fetch-data
- https://pub.dev/packages/http
- https://jsonplaceholder.typicode.com/
