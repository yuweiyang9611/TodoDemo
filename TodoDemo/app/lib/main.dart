import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 用别名，避免 ConnectionState 同名冲突
import 'package:signalr_core/signalr_core.dart' as signalr;

const apiBase = 'http://localhost:5200';
const hubUrl = '$apiBase/todoHub';

class Todo {
  final int id;
  final String title;
  final bool done;

  const Todo({required this.id, required this.title, required this.done});

  factory Todo.fromJson(Map<String, dynamic> j) =>
      Todo(id: j['id'], title: j['title'], done: j['isDone'] ?? false);
}

Future<List<Todo>> fetchTodos() async {
  final r = await http.get(Uri.parse('$apiBase/api/todos'));
  if (r.statusCode != 200) throw Exception('list failed');
  final arr = jsonDecode(r.body) as List;
  return arr.map((e) => Todo.fromJson(e as Map<String, dynamic>)).toList();
}

Future<void> addTodo(String title) async {
  final r = await http.post(
    Uri.parse('$apiBase/api/todos'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'title': title}),
  );
  if (r.statusCode >= 300) throw Exception('add failed');
}

Future<void> toggleTodo(int id) async {
  final url = Uri.parse('$apiBase/api/todos/$id/toggle');
  final r = await http.put(url);
  if (r.statusCode != 200) throw Exception('toggle failed');
}

Future<void> deleteTodo(int id) async {
  final r = await http.delete(Uri.parse('$apiBase/api/todos/$id'));
  if (r.statusCode != 204) throw Exception('delete failed');
}

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  // 仅用于首屏/刷新转圈控制
  late Future<List<Todo>> future;
  bool _loading = true;

  // 实际渲染的数据源（SignalR 事件增量更新它）
  List<Todo> _todos = [];

  final controller = TextEditingController();
  signalr.HubConnection? _hub;

  @override
  void initState() {
    super.initState();

    // 首次拉一次数据
    future = fetchTodos();
    (() async {
      try {
        final list = await future;
        if (!mounted) return;
        setState(() {
          _todos = list;
          _loading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
        });
      }
    })();

    // 建立 SignalR 连接
    _hub = signalr.HubConnectionBuilder()
        .withUrl(hubUrl) // 如 Android 模拟器，请改为 http://10.0.2.2:5200/todoHub
        .withAutomaticReconnect()
        .build();

    // 解析函数
    Todo? _toTodo(List<Object?>? args) {
      if (args == null || args.isEmpty || args[0] == null) return null;
      final obj = args[0];
      if (obj is Map) {
        final m = Map<String, dynamic>.from(obj as Map);
        return Todo.fromJson(m);
      }
      return null;
    }

    int? _toId(List<Object?>? args) {
      if (args == null || args.isEmpty || args[0] == null) return null;
      final v = args[0];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return null;
    }

    // 事件：增量更新 _todos（不再整表 refresh）
    _hub!.on('TodoAdded', (args) {
      final t = _toTodo(args);
      if (t == null) return;
      if (!mounted) return;
      setState(() {
        final i = _todos.indexWhere((x) => x.id == t.id);
        if (i < 0) _todos.add(t);
        // 可选：保持有序（如按 id 升序）
        // _todos.sort((a, b) => a.id.compareTo(b.id));
      });
    });

    _hub!.on('TodoUpdated', (args) {
      final t = _toTodo(args);
      if (t == null) return;
      if (!mounted) return;
      setState(() {
        final i = _todos.indexWhere((x) => x.id == t.id);
        if (i >= 0) _todos[i] = t;
      });
    });

    _hub!.on('TodoDeleted', (args) {
      final id = _toId(args);
      if (id == null) return;
      if (!mounted) return;
      setState(() {
        _todos.removeWhere((x) => x.id == id);
      });
    });

    // 启动连接
    (() async {
      try {
        await _hub!.start();
        debugPrint('SignalR started');
      } catch (e) {
        debugPrint('SignalR start error: $e');
      }
    })();
  }

  // 下拉刷新/兜底全量拉取：拉完写回 _todos，并让 future 完成
  Future<void> refresh() async {
    final list = await fetchTodos();
    if (!mounted) return;
    setState(() {
      _todos = list;
      _loading = false;
      future = Future.value(list); // 让 FutureBuilder 进入 done 状态
    });
  }

  @override
  void dispose() {
    _hub?.stop();
    _hub = null;
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Todo (Flutter)')),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(hintText: '新事项'),
                      onSubmitted: (_) async {
                        final t = controller.text.trim();
                        if (t.isEmpty) return;
                        await addTodo(t);
                        controller.clear();
                        // 依赖后端推送 TodoAdded，无需 refresh
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final t = controller.text.trim();
                      if (t.isEmpty) return;
                      await addTodo(t);
                      controller.clear();
                      // 依赖后端推送 TodoAdded，无需 refresh
                    },
                    child: const Text('添加'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 这里仍保留 FutureBuilder，只用于控制“首屏/刷新时的转圈 & 错误”
              Expanded(
                child: FutureBuilder<List<Todo>>(
                  future: future,
                  builder: (context, s) {
                    final waiting =
                        _loading || s.connectionState != ConnectionState.done;

                    if (waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (s.hasError) {
                      return Center(child: Text('错误: ${s.error}'));
                    }

                    // ⬅️ 用 _todos 作为渲染数据源（SignalR 事件会更新它）
                    final todos = _todos;

                    return RefreshIndicator(
                      onRefresh: refresh, // 手动下拉时可全量拉一次
                      child: ListView.separated(
                        itemCount: todos.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final t = todos[i];
                          return ListTile(
                            leading: Checkbox(
                              value: t.done,
                              onChanged: (_) async {
                                await toggleTodo(t.id);
                                // 依赖 TodoUpdated 推送，无需 refresh
                              },
                            ),
                            title: Text(
                              t.title,
                              style: TextStyle(
                                decoration: t.done
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await deleteTodo(t.id);
                                // 依赖 TodoDeleted 推送，无需 refresh
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
