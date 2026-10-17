import 'package:flutter/foundation.dart';

abstract class ViewModel extends ChangeNotifier {
  bool busy = false;
  String? error;
  bool _disposed = false;
  int _request = 0;
  final _subscriptions = <VoidCallback>[];
  bool get disposed => _disposed;
  int beginRequest() => ++_request;
  bool isCurrent(int request) => !_disposed && request == _request;
  void changed() {
    if (!_disposed) notifyListeners();
  }

  void observe(Listenable source, VoidCallback listener) {
    source.addListener(listener);
    _subscriptions.add(() => source.removeListener(listener));
  }

  bool fail(String message) {
    error = message;
    changed();
    return false;
  }

  Future<bool> perform(
    Future<void> Function() action, {
    String failure = 'No se pudo guardar. Inténtalo otra vez.',
  }) async {
    if (busy || _disposed) return false;
    busy = true;
    error = null;
    changed();
    try {
      await action();
      return true;
    } catch (e) {
      if (!_disposed) error = e is StateError ? e.message.toString() : failure;
      return false;
    } finally {
      busy = false;
      changed();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    for (final unsubscribe in _subscriptions) {
      unsubscribe();
    }
    super.dispose();
  }
}
