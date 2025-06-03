import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:auto_commit/config.dart';
import 'package:auto_commit/generator.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:process_run/process_run.dart';

class CommitCommand extends Command {
  final _spinner = CliSpin(spinner: CliSpinners.dots5);

  CommitCommand() {
    argParser.addFlag(
      'yes',
      abbr: 'y',
      help: 'Skip confirmation',
      negatable: false,
    );
  }

  @override
  String get description => 'Generate Conventional Commits by AI';

  @override
  String get name => 'commit';

  @override
  Future<void> run() async {
    stdout.writeln('\n✧ ────────────── AUTO COMMIT ────────────── ✧\n');
    _spinner.start('Analyzing changes');
    var stat = await _getDifferentStat();
    _spinner.success();
    stdout.writeln(stat);
    var difference = await _differentiate();
    if (difference.isEmpty) return _fail('Nothing to commit');

    var config = await Config.load();
    try {
      var message = await _generateMessage(difference, config);
      if (argResults?['yes'] == true) return _commit(message);
      while (true) {
        _displayMessage(message);
        switch (await _promptForAction()) {
          case 'Y':
            return _commit(message);
          case 'N':
            return _cancel();
          default:
            message = await _generateMessage(difference, config);
            continue;
        }
      }
    } catch (error) {
      _fail('$error');
    }
  }

  void _cancel() {
    stdout.writeln('⭕ Commit cancelled.');
  }

  Future<void> _commit(String message) async {
    var file = File('.commit');
    await file.writeAsString(message);
    var shell = Shell(verbose: false);
    await shell.run('git commit -F .commit');
    await file.delete();
    stdout.writeln('✨ Commit completed');
  }

  Future<String> _differentiate() async {
    var shell = Shell(verbose: false);
    var result = await shell.run('git diff --staged');
    var difference = result.first.stdout.toString();
    await Future.delayed(const Duration(milliseconds: 500));
    return difference;
  }

  void _displayMessage(String message) {
    stdout.writeln('\n∙ ───────────────────────────────────────── ∙');
    stdout.writeln('∙ ${_getGeneratedTip()} ∙');
    stdout.writeln('∙ ───────────────────────────────────────── ∙\n');
    stdout.writeln('\x1B[32m$message\x1B[0m');
  }

  void _fail(String message) {
    _spinner.fail();
    _spinner.stop();
    stdout.writeln('\n\x1B[31m• $message\x1B[0m');
  }

  Future<String> _generateMessage(String difference, Config config) async {
    _spinner.start('Generating commit message');
    var message = await Generator.generate(difference, config: config);
    _spinner.success();
    _spinner.stop();
    return message;
  }

  Future<String> _getDifferentStat() async {
    var buffer = StringBuffer();
    buffer.write('\n');
    var shell = Shell(verbose: false);
    var result = await shell.run('git diff --staged --numstat');
    var stat = result.first.stdout.toString();
    var lines = stat.split('\n');
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      var parts = line.split('\t');
      if (parts.length < 3) continue;
      var changes =
          '  ${parts[2]} \t \x1B[32m+${parts[0]}\x1B[0m \x1B[31m-${parts[1]}\x1B[0m';
      buffer.write('$changes\n');
    }
    await Future.delayed(const Duration(milliseconds: 500));
    return buffer.toString();
  }

  String _getGeneratedTip() {
    final tip = 'Generated Commit Message';
    final totalWidth = 41; // Width of - characters
    final leadingPadding = (totalWidth - tip.length) ~/ 2;
    var leadingPaddingCharacters = ' ' * leadingPadding;
    var trailingPaddingCharacters = ' ' * (totalWidth - leadingPadding);
    return '$leadingPaddingCharacters$tip$trailingPaddingCharacters';
  }

  Future<String> _promptForAction() async {
    var prompt = 'Press Y to commit, N to cancel, any other key to try another';
    stdout.write('\n⟩ $prompt: ');
    stdin.echoMode = false;
    stdin.lineMode = false;
    int byte = stdin.readByteSync();
    stdin.echoMode = true;
    stdin.lineMode = true;
    var char = String.fromCharCode(byte).toUpperCase();
    stdout.writeln('$char\n');
    return char;
  }
}
