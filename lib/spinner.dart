import 'dart:async';
import 'dart:io';

class Spinner {
  final _frames = ['⣷', '⣯', '⣟', '⡿', '⢿', '⣻', '⣽', '⣾'];
  Timer? _timer;
  bool _running = false;
  String _message = '';
  int _i = 0;

  void start() {
    if (_running) return;
    _running = true;
    _i = 0;
    _timer = Timer.periodic(Duration(milliseconds: 80), (_) {
      _i = (_i + 1) % _frames.length;
      _updateSpinner();
    });
  }

  void next({bool success = true}) {
    stdout.write('\r\x1B[K'); // 清除当前行
    var indicator = success ? '✓' : '✗';
    stdout.writeln('$indicator $_message');
  }

  void stop({String? completedMessage}) {
    if (!_running) return;
    _running = false;
    _timer?.cancel();
    _timer = null;
    stdout.write('\r\x1B[K'); // 清除当前行
  }

  void update(String message) {
    if (!_running) return;
    _message = message;
  }

  void _updateSpinner() {
    if (!_running) return;
    stdout.write('\r\x1B[K'); // 清除当前行
    var message = _message.isEmpty ? '' : ' $_message';
    stdout.write('${_frames[_i]}$message');
  }
}
