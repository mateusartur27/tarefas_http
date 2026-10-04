import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class HomePage extends StatefulWidget {
  final TaskService? service;
  const HomePage({super.key, this.service});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TaskService _service;
  List<Task> _tasks = [];
  bool _loading = true, _busy = false;
  String? _error;
  int _filter = 0;
  @override
  void initState() {
    super.initState();
    _service = widget.service ?? TaskService();
    _load();
  }

  @override
  void dispose() {
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tasks = await _service.fetchTasks();
      if (mounted) setState(() => _tasks = tasks);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _operation(
    Future<void> Function() action,
    String success,
  ) async {
    if (_busy || _loading) return;
    setState(() => _busy = true);
    try {
      await action();
      _message(success);
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([Task? task]) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => TaskForm(task: task),
    );
    if (title == null || !mounted) return;
    await _operation(
      () async {
        if (task == null) {
          final created = await _service.createTask(title);
          if (mounted) setState(() => _tasks.insert(0, created));
        } else {
          final updated = await _service.updateTask(
            task.copyWith(title: title),
          );
          if (mounted) setState(() => _tasks[_tasks.indexOf(task)] = updated);
        }
      },
      task == null
          ? 'Tarefa cadastrada com sucesso • HTTP 201'
          : 'Tarefa atualizada com sucesso • HTTP 200',
    );
  }

  Future<void> _delete(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir tarefa?'),
        content: Text(task.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _operation(() async {
      await _service.deleteTask(task.id);
      if (mounted) setState(() => _tasks.remove(task));
    }, 'Tarefa excluída com sucesso');
  }

  @override
  Widget build(BuildContext context) {
    final done = _tasks.where((t) => t.completed).length;
    final visible = _tasks
        .where(
          (t) => _filter == 0 || (_filter == 1 ? !t.completed : t.completed),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        actions: [
          IconButton(
            tooltip: 'Recarregar da API',
            onPressed: _loading || _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading || _busy || _error != null ? null : () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Nova tarefa'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                if (_busy) const LinearProgressIndicator(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Organize o seu dia',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_tasks.length - done} pendentes • $done concluídas',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ambiente de aula: a API simula alterações. Recarregar restaura os dados do servidor.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final (index, label) in [
                            'Todas',
                            'Pendentes',
                            'Concluídas',
                          ].indexed)
                            ChoiceChip(
                              label: Text(label),
                              selected: _filter == index,
                              onSelected: (_) =>
                                  setState(() => _filter = index),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Carregando tarefas…'),
                            ],
                          ),
                        )
                      : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cloud_off, size: 48),
                                const SizedBox(height: 16),
                                Text(_error!, textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: _load,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Tentar novamente'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : visible.isEmpty
                      ? const Center(child: Text('Nenhuma tarefa nesta lista.'))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: visible.length,
                            itemBuilder: (context, index) {
                              final task = visible[index];
                              final simulated = task.id > 200;
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    leading: Checkbox(
                                      value: task.completed,
                                      onChanged: _busy || simulated
                                          ? null
                                          : (value) => _operation(
                                              () async {
                                                final updated = await _service
                                                    .updateTask(
                                                      task.copyWith(
                                                        completed: value,
                                                      ),
                                                    );
                                                if (mounted) {
                                                  setState(
                                                    () =>
                                                        _tasks[_tasks.indexOf(
                                                              task,
                                                            )] =
                                                            updated,
                                                  );
                                                }
                                              },
                                              'Status atualizado com sucesso • HTTP 200',
                                            ),
                                    ),
                                    title: Text(
                                      task.title,
                                      style: TextStyle(
                                        decoration: task.completed
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    subtitle: Text(
                                      simulated
                                          ? 'Criada nesta sessão • API não persiste o cadastro'
                                          : 'Tarefa #${task.id} • ${task.completed ? 'Concluída' : 'Pendente'}',
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      enabled: !_busy,
                                      tooltip: 'Opções da tarefa',
                                      onSelected: (value) => value == 'edit'
                                          ? _edit(task)
                                          : _delete(task),
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          enabled: !simulated,
                                          child: const Text('Editar'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Excluir'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TaskForm extends StatefulWidget {
  final Task? task;
  const TaskForm({super.key, this.task});
  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task?.title);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState!.validate()) {
      Navigator.pop(context, _title.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.task == null ? 'Nova tarefa' : 'Editar tarefa'),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _title,
        autofocus: true,
        maxLength: 120,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Título',
          hintText: 'O que você precisa fazer?',
        ),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Digite o título da tarefa.'
            : null,
        onFieldSubmitted: (_) => _submit(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(widget.task == null ? 'Cadastrar' : 'Salvar'),
      ),
    ],
  );
}
