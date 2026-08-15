import 'dart:async';
import 'dart:developer' as developer;

import 'package:signalr_core/signalr_core.dart' as signalr;

import '../models/todo.dart';

sealed class TodoEvent {
  const TodoEvent();
}

final class TodoAdded extends TodoEvent {
  const TodoAdded(this.todo);
  final Todo todo;
}

final class TodoUpdated extends TodoEvent {
  const TodoUpdated(this.todo);
  final Todo todo;
}

final class TodoDeleted extends TodoEvent {
  const TodoDeleted(this.id);
  final String id;
}

enum RealtimeStatus { connecting, connected, reconnecting, disconnected }

/// Exposes realtime notifications as typed Dart streams.
abstract interface class TodoRealtimeService {
  Stream<TodoEvent> get events;
  Stream<RealtimeStatus> get statuses;
  Future<void> start();
  Future<void> close();
}

/// Adapts SignalR callback APIs to typed streams and retries initial startup.
final class SignalRTodoRealtimeService implements TodoRealtimeService {
  SignalRTodoRealtimeService({required String baseUrl}) {
    final normalizedBaseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    _connection = signalr.HubConnectionBuilder()
        .withUrl('$normalizedBaseUrl/todoHub')
        .withAutomaticReconnect()
        .build();

    _connection.on('TodoAdded', _onTodoAdded);
    _connection.on('TodoUpdated', _onTodoUpdated);
    _connection.on('TodoDeleted', _onTodoDeleted);
    _connection.onreconnecting((error) {
      _emitStatus(RealtimeStatus.reconnecting);
    });
    _connection.onreconnected((connectionId) {
      _emitStatus(RealtimeStatus.connected);
    });
    _connection.onclose((error) {
      if (_closed) {
        return;
      }

      _emitStatus(RealtimeStatus.disconnected);
      if (error != null) {
        developer.log('SignalR connection closed.', error: error);
      }
      _scheduleStart();
    });
  }

  static const _retryDelay = Duration(seconds: 2);

  late final signalr.HubConnection _connection;
  final _eventController = StreamController<TodoEvent>.broadcast();
  final _statusController = StreamController<RealtimeStatus>.broadcast();
  Timer? _startTimer;
  bool _closed = false;

  @override
  Stream<TodoEvent> get events => _eventController.stream;

  @override
  Stream<RealtimeStatus> get statuses => _statusController.stream;

  @override
  Future<void> start() async {
    if (_closed ||
        _connection.state != signalr.HubConnectionState.disconnected) {
      return;
    }

    _emitStatus(RealtimeStatus.connecting);
    try {
      await _connection.start();
      if (!_closed) {
        _emitStatus(RealtimeStatus.connected);
      }
    } catch (error, stackTrace) {
      if (!_closed) {
        developer.log(
          'Unable to start SignalR; retrying.',
          error: error,
          stackTrace: stackTrace,
        );
        _emitStatus(RealtimeStatus.disconnected);
        _scheduleStart();
      }
    }
  }

  void _scheduleStart() {
    if (_closed) {
      return;
    }

    _startTimer?.cancel();
    _startTimer = Timer(_retryDelay, () => unawaited(start()));
  }

  void _onTodoAdded(List<dynamic>? arguments) {
    final todo = _parseTodo(arguments, 'TodoAdded');
    if (todo != null) {
      _eventController.add(TodoAdded(todo));
    }
  }

  void _onTodoUpdated(List<dynamic>? arguments) {
    final todo = _parseTodo(arguments, 'TodoUpdated');
    if (todo != null) {
      _eventController.add(TodoUpdated(todo));
    }
  }

  void _onTodoDeleted(List<dynamic>? arguments) {
    final value = _firstArgument(arguments);
    if (value is String) {
      _eventController.add(TodoDeleted(value));
    } else {
      developer.log('Ignored an invalid TodoDeleted event.');
    }
  }

  Todo? _parseTodo(List<dynamic>? arguments, String eventName) {
    try {
      return Todo.fromJson(_firstArgument(arguments));
    } on FormatException catch (error) {
      developer.log('Ignored an invalid $eventName event.', error: error);
      return null;
    }
  }

  Object? _firstArgument(List<dynamic>? arguments) {
    return arguments == null || arguments.isEmpty ? null : arguments.first;
  }

  void _emitStatus(RealtimeStatus status) {
    if (!_closed) {
      _statusController.add(status);
    }
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }

    _closed = true;
    _startTimer?.cancel();
    try {
      if (_connection.state != signalr.HubConnectionState.disconnected) {
        await _connection.stop();
      }
    } finally {
      await _eventController.close();
      await _statusController.close();
    }
  }
}
