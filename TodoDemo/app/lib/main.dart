import 'dart:async';

import 'package:flutter/material.dart';

import 'data/todo_repository.dart';
import 'models/todo.dart';
import 'realtime/todo_realtime_service.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5200',
);

void main() {
  runApp(
    TodoApp(
      repository: HttpTodoRepository(baseUrl: apiBaseUrl),
      realtime: SignalRTodoRealtimeService(baseUrl: apiBaseUrl),
    ),
  );
}

class TodoApp extends StatelessWidget {
  const TodoApp({required this.repository, required this.realtime, super.key});

  final TodoRepository repository;
  final TodoRealtimeService realtime;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo 学习项目',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff2563eb)),
        useMaterial3: true,
      ),
      home: TodoPage(repository: repository, realtime: realtime),
    );
  }
}

class TodoPage extends StatefulWidget {
  const TodoPage({required this.repository, required this.realtime, super.key});

  final TodoRepository repository;
  final TodoRealtimeService realtime;

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final _titleController = TextEditingController();
  final _pendingIds = <String>{};
  late final StreamSubscription<TodoEvent> _eventSubscription;
  late final StreamSubscription<RealtimeStatus> _statusSubscription;

  List<Todo> _todos = const [];
  RealtimeStatus _realtimeStatus = RealtimeStatus.connecting;
  String? _error;
  bool _loading = true;
  bool _adding = false;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _eventSubscription = widget.realtime.events.listen(_handleRealtimeEvent);
    _statusSubscription = widget.realtime.statuses.listen(_handleStatus);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    unawaited(widget.realtime.start());
    await _refresh();
  }

  Future<void> _refresh() async {
    try {
      final todos = await widget.repository.getAll();
      if (!mounted) {
        return;
      }
      setState(() {
        _todos = todos;
        _error = null;
        _loading = false;
        _hasLoaded = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _messageFromError(error);
        _loading = false;
        _hasLoaded = true;
      });
    }
  }

  void _handleStatus(RealtimeStatus status) {
    if (!mounted) {
      return;
    }

    final shouldRefresh =
        _hasLoaded &&
        status == RealtimeStatus.connected &&
        _realtimeStatus != RealtimeStatus.connected;

    setState(() {
      _realtimeStatus = status;
    });

    if (shouldRefresh) {
      unawaited(_refresh());
    }
  }

  void _handleRealtimeEvent(TodoEvent event) {
    if (!mounted) {
      return;
    }

    setState(() {
      switch (event) {
        case TodoAdded(:final todo):
        case TodoUpdated(:final todo):
          _todos = _upsert(_todos, todo);
        case TodoDeleted(:final id):
          _todos = _todos.where((todo) => todo.id != id).toList();
      }
    });
  }

  List<Todo> _upsert(List<Todo> current, Todo updated) {
    final index = current.indexWhere((todo) => todo.id == updated.id);
    if (index < 0) {
      return [...current, updated];
    }

    return [
      for (final todo in current)
        if (todo.id == updated.id) updated else todo,
    ];
  }

  Future<void> _addTodo() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _adding) {
      return;
    }

    setState(() {
      _adding = true;
    });

    try {
      final todo = await widget.repository.add(title);
      if (!mounted) {
        return;
      }
      setState(() {
        _todos = _upsert(_todos, todo);
        _error = null;
        _titleController.clear();
      });
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _adding = false;
        });
      }
    }
  }

  Future<void> _toggleTodo(String id) async {
    _setPending(id, pending: true);
    try {
      final todo = await widget.repository.toggle(id);
      if (!mounted) {
        return;
      }
      setState(() {
        _todos = _upsert(_todos, todo);
        _error = null;
      });
    } catch (error) {
      _showError(error);
    } finally {
      _setPending(id, pending: false);
    }
  }

  Future<void> _deleteTodo(String id) async {
    _setPending(id, pending: true);
    try {
      await widget.repository.delete(id);
      if (!mounted) {
        return;
      }
      setState(() {
        _todos = _todos.where((todo) => todo.id != id).toList();
        _error = null;
      });
    } catch (error) {
      _showError(error);
    } finally {
      _setPending(id, pending: false);
    }
  }

  void _setPending(String id, {required bool pending}) {
    if (!mounted) {
      return;
    }

    setState(() {
      if (pending) {
        _pendingIds.add(id);
      } else {
        _pendingIds.remove(id);
      }
    });
  }

  void _showError(Object error) {
    if (!mounted) {
      return;
    }

    setState(() {
      _error = _messageFromError(error);
    });
  }

  String _messageFromError(Object error) {
    return error is TodoApiException ? error.message : error.toString();
  }

  @override
  void dispose() {
    unawaited(_eventSubscription.cancel());
    unawaited(_statusSubscription.cancel());
    unawaited(widget.realtime.close());
    unawaited(widget.repository.close());
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todo 学习项目')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _StatusCard(status: _realtimeStatus),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('new-todo'),
                          controller: _titleController,
                          maxLength: 200,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            counterText: '',
                            labelText: '新事项',
                          ),
                          onSubmitted: (_) => unawaited(_addTodo()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        key: const Key('add-todo'),
                        onPressed: _adding ? null : _addTodo,
                        child: Text(_adding ? '添加中…' : '添加'),
                      ),
                    ],
                  ),
                  if (_error case final error?)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: MaterialBanner(
                        content: Text(error),
                        actions: [
                          TextButton(
                            onPressed: _refresh,
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Expanded(child: _buildTodoList()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodoList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_todos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('暂无事项，添加一条开始学习。')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        itemCount: _todos.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final todo = _todos[index];
          final pending = _pendingIds.contains(todo.id);
          return ListTile(
            leading: Checkbox(
              key: Key('todo-checkbox-${todo.id}'),
              value: todo.isDone,
              onChanged: pending
                  ? null
                  : (_) => unawaited(_toggleTodo(todo.id)),
            ),
            title: Text(
              todo.title,
              style: TextStyle(
                decoration: todo.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            trailing: IconButton(
              key: Key('delete-todo-${todo.id}'),
              tooltip: '删除',
              onPressed: pending ? null : () => unawaited(_deleteTodo(todo.id)),
              icon: const Icon(Icons.delete_outline),
            ),
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});

  final RealtimeStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      RealtimeStatus.connecting => ('正在连接实时服务', Colors.orange),
      RealtimeStatus.connected => ('实时同步已连接', Colors.green),
      RealtimeStatus.reconnecting => ('实时服务正在重连', Colors.orange),
      RealtimeStatus.disconnected => ('实时服务已断开', Colors.red),
    };

    return Card(
      child: ListTile(
        dense: true,
        leading: Icon(Icons.circle, color: color, size: 12),
        title: Text(label),
        subtitle: const Text('REST 负责可靠读写，SignalR 负责实时通知。'),
      ),
    );
  }
}
