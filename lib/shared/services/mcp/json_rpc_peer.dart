import 'dart:async';

class JsonRpcException implements Exception {
  final int code;
  final String message;
  final Object? data;

  JsonRpcException(this.code, this.message, {this.data});

  @override
  String toString() => 'JsonRpcException($code): $message';
}

class JsonRpcPeer {
  final Future<void> Function(Map<String, dynamic> message) _send;
  final StreamSubscription<Map<String, dynamic>> _sub;

  int _nextId = 1;
  final Map<String, Completer<dynamic>> _pending = {};

  JsonRpcPeer({
    required Stream<Map<String, dynamic>> incoming,
    required Future<void> Function(Map<String, dynamic> message) send,
  })  : _send = send,
        _sub = incoming.listen((msg) {}) {
    _sub.onData(_onMessage);
  }

  Future<void> notify(String method, {Object? params}) {
    final payload = <String, dynamic>{
      'jsonrpc': '2.0',
      'method': method,
    };
    if (params != null) payload['params'] = params;
    return _send(payload);
  }

  Future<dynamic> request(
    String method, {
    Object? params,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final id = _nextId++;
    final idKey = id.toString();
    final completer = Completer<dynamic>();
    _pending[idKey] = completer;

    final payload = <String, dynamic>{
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
    };
    if (params != null) payload['params'] = params;

    await _send(payload);

    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      _pending.remove(idKey);
      if (method != 'initialize') {
        // Best-effort cancellation hint (server may ignore).
        unawaited(notify('notifications/cancelled', params: {
          'requestId': id,
          'reason': 'timeout',
        }));
      }
      rethrow;
    }
  }

  void _onMessage(Map<String, dynamic> msg) {
    final hasMethod = msg.containsKey('method');
    final hasId = msg.containsKey('id');

    if (hasMethod && hasId) {
      // Server -> client request. We don't implement any server-initiated
      // methods yet (sampling/roots/etc), but must reply with Method not found.
      final id = msg['id'];
      _replyError(
        id: id,
        code: -32601,
        message: 'Method not found',
      );
      return;
    }

    if (hasMethod && !hasId) {
      // Notification: ignore.
      return;
    }

    if (hasId) {
      final idKey = msg['id']?.toString();
      if (idKey == null) return;
      final completer = _pending.remove(idKey);
      if (completer == null) return;

      if (msg.containsKey('error')) {
        final err = msg['error'];
        if (err is Map) {
          final code = err['code'];
          final message = err['message'];
          completer.completeError(JsonRpcException(
            code is int ? code : -32000,
            message?.toString() ?? 'Unknown error',
            data: err['data'],
          ));
          return;
        }
        completer.completeError(JsonRpcException(-32000, 'Unknown error'));
        return;
      }

      completer.complete(msg['result']);
    }
  }

  Future<void> _replyError({
    required Object? id,
    required int code,
    required String message,
    Object? data,
  }) async {
    final error = <String, dynamic>{
      'code': code,
      'message': message,
    };
    if (data != null) error['data'] = data;

    await _send({
      'jsonrpc': '2.0',
      'id': id,
      'error': error,
    });
  }

  Future<void> close() async {
    try {
      await _sub.cancel();
    } catch (_) {}
    for (final c in _pending.values) {
      if (!c.isCompleted) {
        c.completeError(StateError('JSON-RPC peer closed'));
      }
    }
    _pending.clear();
  }
}

