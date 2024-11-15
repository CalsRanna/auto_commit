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
    var spinner = Spinner();
    spinner.start();
    spinner.update('Analyzing changes...');
    var shell = Shell(verbose: false);
    var result = await shell.run('git diff --staged');
    var difference = result.first.stdout.toString();
    await Future.delayed(const Duration(seconds: 1));
    if (difference.isEmpty) return _terminate(spinner);
    spinner.update('Generating commit message...');
    var config = await Config.load();
    try {
      var message = await Generator.generate(difference, config: config);
      spinner.stop();
      stdout.writeln('\nCommit message:\n');
      stdout.writeln(message);
      if (argResults?['yes'] == true) return _commit(message);
      stdout.write('Do you want to use this message? [y/n] ');
      var answer = stdin.readLineSync();
      if (answer == 'y') return _commit(message);
    } on GeneratorException catch (error) {
      spinner.stop();
      stdout.writeln('\n[${error.code}] ${error.message}');
    } catch (error) {
      spinner.stop();
      stdout.writeln('\nAn error occurred: $error');
    }
  }

  Future<void> _commit(String message) async {
    var file = File('.commit');
    await file.writeAsString(message);
    var shell = Shell(verbose: false);
    await shell.run('git commit -F .commit');
    await file.delete();
    stdout.writeln('\nCommit successful.');
  }

  void _terminate(Spinner spinner) {
    spinner.stop();
    stdout.writeln('No changes detected.');
  }
}
