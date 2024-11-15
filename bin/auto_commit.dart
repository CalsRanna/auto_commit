import 'package:args/command_runner.dart';
import 'package:auto_commit/commit_command.dart';
import 'package:auto_commit/config_command.dart';

Future<void> main(List<String> arguments) async {
  var executable = 'auto commit';
  var description = 'AI-powered Conventional Commits Generator';
  var runner = CommandRunner(executable, description)
    ..addCommand(CommitCommand())
    ..addCommand(ConfigCommand());
  await runner.run(arguments);
}
