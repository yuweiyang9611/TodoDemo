/// An immutable todo received from the server.
final class Todo {
  const Todo({required this.id, required this.title, required this.isDone});

  final String id;
  final String title;
  final bool isDone;

  /// Parses untrusted JSON and rejects values that do not match the API contract.
  factory Todo.fromJson(Object? value) {
    if (value is! Map<Object?, Object?>) {
      throw const FormatException('Todo must be a JSON object.');
    }

    final id = value['id'];
    final title = value['title'];
    final isDone = value['isDone'];
    if (id is! String || title is! String || isDone is! bool) {
      throw const FormatException('Todo fields have invalid types.');
    }

    return Todo(id: id, title: title, isDone: isDone);
  }
}
