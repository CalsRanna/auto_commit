import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:auto_commit/config.dart';
import 'package:auto_commit/generator.dart';
import 'package:auto_commit/spinner.dart';
import 'package:process_run/process_run.dart';

class CommitCommand extends Command {
  @override
  String get description => 'Generate Conventional Commits by AI';

  @override
  String get name => 'commit';

  CommitCommand() {
    argParser.addFlag(
      'yes',
      abbr: 'y',
      help: 'Skip confirmation',
      negatable: false,
    );
  }

  @override
  Future<void> run() async {
    stdout.writeln('\n✧ ────────────── AUTO COMMIT ────────────── ✧\n');
    var spinner = Spinner();
    spinner.start();
    spinner.update('Analyzing changes...');
    var difference = await _differentiate();
    if (difference.isEmpty) return _terminate(spinner);
    spinner.update('Generating commit message...');
    var config = await Config.load();
    try {
      var message = await Generator.generate(difference, config: config);
      spinner.stop();
      stdout.writeln('\n∙ ───────────────────────────────────────── ∙');
      stdout.writeln('\tGenerated Commit Message\t');
      stdout.writeln('∙ ───────────────────────────────────────── ∙\n');
      stdout.writeln('\x1B[32m$message\x1B[0m');
      if (argResults?['yes'] == true) return _commit(message);
      stdout.write('\n⟩ Do you want to use this message? [y/n] ');
      var answer = stdin.readLineSync();
      if (answer == 'y') return _commit(message);
      stdout.writeln('\n⭕ Commit cancelled.');
    } on GeneratorException catch (error) {
      spinner.stop();
      stdout.writeln('\n🚫 Operation failed: [${error.code}] ${error.message}');
    } catch (error) {
      spinner.stop();
      stdout.writeln('\n🚫 Operation failed: $error');
    }
  }

  Future<String> _differentiate() async {
    var shell = Shell(verbose: false);
    var result = await shell.run('git diff --staged');
    var difference = result.first.stdout.toString();
    await Future.delayed(const Duration(milliseconds: 500));
    return difference;
  }

  Future<void> _commit(String message) async {
    var file = File('.commit');
    await file.writeAsString(message);
    var shell = Shell(verbose: false);
    await shell.run('git commit -F .commit');
    await file.delete();
    stdout.writeln('\n✨ Commit completed');
  }

  void _terminate(Spinner spinner) {
    spinner.stop();
    stdout.writeln('🔍 Nothing to commit');
  }
}
