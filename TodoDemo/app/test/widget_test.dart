import 'dart:async';

import 'package:app/data/todo_repository.dart';
import 'package:app/main.dart';
import 'package:app/models/todo.dart';
import 'package:app/realtime/todo_realtime_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loads, adds, toggles, and deletes todos', (tester) async {
    const initialId = '00000000-0000-0000-0000-000000000001';
    final repository = FakeTodoRepository([
      const Todo(id: initialId, title: '学习 Dart', isDone: false),
    ]);
    final realtime = FakeTodoRealtimeService();

    await tester.pumpWidget(
      TodoApp(repository: repository, realtime: realtime),
    );
    await tester.pumpAndSettle();

    expect(find.text('学习 Dart'), findsOneWidget);
    expect(find.text('实时同步已连接'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('new-todo')), '理解 SignalR');
    await tester.tap(find.byKey(const Key('add-todo')));
    await tester.pumpAndSettle();
    expect(find.text('理解 SignalR'), findsOneWidget);

    await tester.tap(find.byKey(const Key('todo-checkbox-$initialId')));
    await tester.pumpAndSettle();
    expect(repository.todos.first.isDone, isTrue);

    await tester.tap(find.byKey(const Key('delete-todo-$initialId')));
    await tester.pumpAndSettle();
    expect(find.text('学习 Dart'), findsNothing);
  });

  test('Todo.fromJson rejects a numeric id', () {
    expect(
      () => Todo.fromJson({'id': 1, 'title': 'Invalid', 'isDone': false}),
      throwsFormatException,
    );
  });
}

final class FakeTodoRepository implements TodoRepository {
  FakeTodoRepository(List<Todo> initial) : todos = [...initial];

  final List<Todo> todos;
  var _nextId = 2;

  @override
  Future<List<Todo>> getAll() async => List.unmodifiable(todos);

  @override
  Future<Todo> add(String title) async {
    final todo = Todo(
      id: '00000000-0000-0000-0000-${_nextId.toString().padLeft(12, '0')}',
      title: title,
      isDone: false,
    );
    _nextId += 1;
    todos.add(todo);
    return todo;
  }

  @override
  Future<Todo> toggle(String id) async {
    final index = todos.indexWhere((todo) => todo.id == id);
    if (index < 0) {
      throw StateError('Todo not found.');
    }

    final current = todos[index];
    final updated = Todo(
      id: current.id,
      title: current.title,
      isDone: !current.isDone,
    );
    todos[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    todos.removeWhere((todo) => todo.id == id);
  }

  @override
  Future<void> close() async {}
}

final class FakeTodoRealtimeService implements TodoRealtimeService {
  final _events = StreamController<TodoEvent>.broadcast();
  final _statuses = StreamController<RealtimeStatus>.broadcast();

  @override
  Stream<TodoEvent> get events => _events.stream;

  @override
  Stream<RealtimeStatus> get statuses => _statuses.stream;

  @override
  Future<void> start() async {
    _statuses.add(RealtimeStatus.connected);
  }

  @override
  Future<void> close() async {
    if (!_events.isClosed) {
      await _events.close();
    }
    if (!_statuses.isClosed) {
      await _statuses.close();
    }
  }
}
