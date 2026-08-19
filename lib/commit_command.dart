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
        stdout.writeln('\n\x1B[32m$message\x1B[0m');
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
    var hash = await _getShortHash();
    stdout.writeln('✨ Commit completed ($hash)');
    var branch = await _getCurrentBranch();
    if (branch != null && !await _hasUpstreamBranch(branch)) {
      stdout.writeln(
        "\n💡 Tip: Run 'git push -u origin $branch' to publish and track this branch",
      );
      return;
    }
    var count = await _getLocalCommitsLength();
    if (count > 3) {
      stdout.writeln(
          '\n💡 Tip: Run \'git push\' to share your changes with the remote repository');
    }
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

  Future<String> _generateMessage(String difference, Config config) async {
    _spinner.start('Generating commit message');
    var message = await Generator.generate(difference, config: config);
    _spinner.success();
    _spinner.stop();
    return message;
  }

  Future<String?> _getCurrentBranch() async {
    var shell = Shell(verbose: false);
    try {
      var result = await shell.run('git branch --show-current');
      var branch = result.first.stdout.toString().trim();
      return branch.isEmpty ? null : branch;
    } catch (_) {
      return null;
    }
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
          '\x1B[32m${parts[2]}\x1B[0m \x1B[32m+${parts[0]}\x1B[0m \x1B[31m-${parts[1]}\x1B[0m';
      buffer.write('$changes\n');
    }
    await Future.delayed(const Duration(milliseconds: 500));
    return buffer.toString();
  }

  Future<int> _getLocalCommitsLength() async {
    var shell = Shell(verbose: false);
    try {
      var result = await shell.run('git rev-list --count @{u}...HEAD');
      return int.parse(result.first.stdout.toString());
    } catch (e) {
      // If upstream branch is not set, try counting commits from the beginning
      try {
        var result = await shell.run('git rev-list --count HEAD');
        return int.parse(result.first.stdout.toString());
      } catch (e) {
        // If all else fails, return a safe default
        return 0;
      }
    }
  }

  Future<String> _getShortHash() async {
    var shell = Shell(verbose: false);
    var result = await shell.run('git rev-parse --short HEAD');
    return result.first.stdout.toString().trim();
  }

  Future<bool> _hasUpstreamBranch(String branch) async {
    var shell = Shell(verbose: false);
    try {
      var result = await shell.run(
        'git for-each-ref --format="%(upstream:short)" refs/heads/$branch',
      );
      return result.first.stdout.toString().trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String> _promptForAction() async {
    var prompt = 'Press Y to commit, N to cancel, any other key to try another';
    stdout.write('\n⟩ $prompt: ');

    // Handle Windows console input properly
    try {
      stdin.echoMode = false;
      stdin.lineMode = false;
      int byte = stdin.readByteSync();
      var char = String.fromCharCode(byte).toUpperCase();
      stdout.writeln('$char\n');
      return char;
    } catch (e) {
      // Fallback for Windows console issues
      var input = stdin.readLineSync();
      return (input?.isNotEmpty == true) ? input![0].toUpperCase() : '';
    } finally {
      // Always restore console state
      try {
        stdin.echoMode = true;
        stdin.lineMode = true;
      } catch (_) {
        // Ignore restoration errors
      }
    }
  }

}
