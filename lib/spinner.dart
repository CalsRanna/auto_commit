import 'dart:async';
import 'dart:io';

class Spinner {
  final _frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
  Timer? _timer;
  bool _running = false;
  String _message = '';
  int _i = 0;

  void start() {
    if (_running) return;
    _running = true;
    _i = 0;
    stdout.write('\x1B[?25l'); // 隐藏光标
    _timer = Timer.periodic(Duration(milliseconds: 80), (_) {
      _i = (_i + 1) % _frames.length;
      _updateSpinner();
    });
  }

  void stop({String? completedMessage}) {
    if (!_running) return;
    _running = false;
    _timer?.cancel();
    _timer = null;

    if (_message.isNotEmpty) {
      stdout.write('\r\x1B[K'); // 清除当前行
      stdout.writeln('✓ $_message'); // 将最后的消息转换为完成状态
    }
    if (completedMessage != null) {
      stdout.writeln('✓ $completedMessage');
    }

    stdout.write('\x1B[?25h'); // 显示光标
  }

  void update(String newMessage) {
    if (_running && _message != newMessage) {
      stdout.write('\r\x1B[K'); // 清除当前行的 loading 状态
      if (_message.isNotEmpty) stdout.writeln('✓ $_message'); // 打印完成状态
      _message = newMessage;
      _updateSpinner(); // 显示新消息的 loading 状态
    }
  }

  void _updateSpinner() {
    if (!_running) return;
    stdout.write('\r\x1B[K'); // 清除当前行
    final frame = _frames[_i];
    stdout.write('$frame $_message');
  }
}
