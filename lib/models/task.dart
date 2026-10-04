class Task {
  final int id;
  final int userId;
  final String title;
  final bool completed;
  const Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.completed,
  });
  factory Task.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! int ||
        json['userId'] is! int ||
        json['title'] is! String ||
        json['completed'] is! bool) {
      throw const FormatException(
        'A API retornou uma tarefa incompleta ou inválida.',
      );
    }
    return Task(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
      completed: json['completed'] as bool,
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'completed': completed,
  };
  Task copyWith({String? title, bool? completed}) => Task(
    id: id,
    userId: userId,
    title: title ?? this.title,
    completed: completed ?? this.completed,
  );
}
