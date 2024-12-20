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
    var difference = await _differentiate();
    if (difference.isEmpty) return _fail('Nothing to commit');
    _spinner.success();
    _spinner.start('Generating commit message');
    var config = await Config.load();
    try {
      var message = await Generator.generate(difference, config: config);
      _spinner.success();
      _spinner.stop();
      stdout.writeln('\n∙ ───────────────────────────────────────── ∙');
      stdout.writeln('∙ ${_getGeneratedTip()} ∙');
      stdout.writeln('∙ ───────────────────────────────────────── ∙\n');
      stdout.writeln('\x1B[32m$message\x1B[0m');
      if (argResults?['yes'] == true) return _commit(message);
      stdout.write('\n⟩ Do you want to use this message? [y/n] ');
      var answer = stdin.readLineSync();
      if (answer == 'y') return _commit(message);
      stdout.writeln('\n⭕ Commit cancelled.');
    } catch (error) {
      _fail('$error');
    }
  }

  Future<void> _commit(String message) async {
    var file = File('.commit');
    await file.writeAsString(message);
    var shell = Shell(verbose: false);
    await shell.run('git commit -F .commit');
    await file.delete();
    stdout.writeln('\n✨ Commit completed');
  }

  Future<String> _differentiate() async {
    var shell = Shell(verbose: false);
    var result = await shell.run('git diff --staged');
    var difference = result.first.stdout.toString();
    await Future.delayed(const Duration(milliseconds: 500));
    return difference;
  }

  void _fail(String message) {
    _spinner.fail();
    _spinner.stop();
    stdout.writeln('\n\x1B[31m• $message\x1B[0m');
  }

  String _getGeneratedTip() {
    final tip = 'Generated Commit Message';
    final totalWidth = 41; // Width of - characters
    final leadingPadding = (totalWidth - tip.length) ~/ 2;
    var leadingPaddingCharacters = ' ' * leadingPadding;
    var trailingPaddingCharacters = ' ' * (totalWidth - leadingPadding);
    return '$leadingPaddingCharacters$tip$trailingPaddingCharacters';
  }
}
