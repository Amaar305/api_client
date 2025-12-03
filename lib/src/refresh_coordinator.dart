import 'dart:async';

class RefreshCoordinator {
  Future<void>? _inflight;
  final _waiters = <Completer<void>>[];

  bool get isRefreshing => _inflight != null;

  Future<void> runOnce(Future<void> Function() action) {
    if (_inflight != null) return _inflight!;

    final completer = Completer<void>();
    _inflight = action()
        .then((_) {
          completer.complete();
        })
        .catchError(completer.completeError)
        .whenComplete(() {
          _inflight = null;
          for (final w in _waiters) {
            w.complete();
          }
          _waiters.clear();
        });

    return _inflight!;
  }

  Future<void> wait() {
    if (_inflight == null) return Future.value();
    final c = Completer<void>();
    _waiters.add(c);
    return c.future;
  }

  void failAll(Object error, [StackTrace? st]) {
    for (final w in _waiters) {
      w.completeError(error, st);
    }
    _waiters.clear();
    _inflight = null;
  }
}
