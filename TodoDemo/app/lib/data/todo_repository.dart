import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/todo.dart';

/// Defines the reliable request/response operations used by the UI.
abstract interface class TodoRepository {
  Future<List<Todo>> getAll();
  Future<Todo> add(String title);
  Future<Todo> toggle(String id);
  Future<void> delete(String id);
  Future<void> close();
}

/// Implements [TodoRepository] with the ASP.NET Core REST API.
final class HttpTodoRepository implements TodoRepository {
  HttpTodoRepository({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  final String _baseUrl;
  final http.Client _client;
  final bool _ownsClient;
  final Duration requestTimeout;

  Uri _uri(String path) => Uri.parse(_baseUrl + path);

  @override
  Future<List<Todo>> getAll() async {
    final response = await _client
        .get(_uri('/api/todos'))
        .timeout(requestTimeout);
    _requireStatus(response, 200);

    final value = jsonDecode(response.body);
    if (value is! List<Object?>) {
      throw const FormatException('Todo list must be a JSON array.');
    }

    return value.map(Todo.fromJson).toList(growable: false);
  }

  @override
  Future<Todo> add(String title) async {
    final response = await _client
        .post(
          _uri('/api/todos'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({'title': title}),
        )
        .timeout(requestTimeout);
    _requireStatus(response, 201);
    return Todo.fromJson(jsonDecode(response.body));
  }

  @override
  Future<Todo> toggle(String id) async {
    final response = await _client
        .put(_uri('/api/todos/${Uri.encodeComponent(id)}/toggle'))
        .timeout(requestTimeout);
    _requireStatus(response, 200);
    return Todo.fromJson(jsonDecode(response.body));
  }

  @override
  Future<void> delete(String id) async {
    final response = await _client
        .delete(_uri('/api/todos/${Uri.encodeComponent(id)}'))
        .timeout(requestTimeout);
    _requireStatus(response, 204);
  }

  void _requireStatus(http.Response response, int expectedStatus) {
    if (response.statusCode == expectedStatus) {
      return;
    }

    throw TodoApiException(response.statusCode, _messageFromResponse(response));
  }

  String _messageFromResponse(http.Response response) {
    try {
      final value = jsonDecode(response.body);
      if (value is Map<Object?, Object?>) {
        final detail = value['detail'];
        final title = value['title'];
        if (detail is String) {
          return detail;
        }
        if (title is String) {
          return title;
        }
      }
    } on FormatException {
      // Failed responses are allowed to have an empty or non-JSON body.
    }

    return 'Request failed (${response.statusCode}).';
  }

  @override
  Future<void> close() {
    if (_ownsClient) {
      _client.close();
    }
    return Future<void>.value();
  }
}

/// Carries an HTTP status code without exposing transport details to widgets.
final class TodoApiException implements Exception {
  const TodoApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}
