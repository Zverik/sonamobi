import 'dart:async';

class DebounceDelayer {
  Timer? _timer;

  DebounceDelayer();

  void delayed(Duration duration, Function() computation) {
    if (_timer?.isActive ?? false) _timer?.cancel();
    _timer = Timer(duration, () {
      _timer = null;
      computation();
    });
  }

  void cancel() {
    if (_timer?.isActive ?? false) _timer?.cancel();
    _timer = null;
  }
}