// lib/utils/mutex.dart
import 'dart:async'; // 🔥 IMPORTANTE: Agregar este import

class Mutex {
  Future<void>? _lock;
  final Set<Completer<void>> _waiters = {};

  Future<void> acquire() async {
    while (_lock != null) {
      final completer = Completer<void>();
      _waiters.add(completer);
      await completer.future;
    }
    _lock = Completer<void>().future;
  }

  void release() {
    _lock = null;
    if (_waiters.isNotEmpty) {
      final next = _waiters.first;
      _waiters.remove(next);
      next.complete();
    }
  }

  Future<T> protect<T>(Future<T> Function() fn) async {
    await acquire();
    try {
      return await fn();
    } finally {
      release();
    }
  }
}
