import 'package:args/command_runner.dart';
import 'package:auto_commit/commit_command.dart';
import 'package:auto_commit/config_command.dart';
import 'package:auto_commit/version_command.dart';

Future<void> main(List<String> arguments) async {
  var executable = 'flit';
  var description = 'AI-powered Conventional Commits Generator';
  var runner = CommandRunner(executable, description)
    ..addCommand(CommitCommand())
    ..addCommand(ConfigCommand())
    ..addCommand(VersionCommand());
  runner.argParser.addFlag(
    'version',
    abbr: 'v',
    negatable: false,
    help: 'Print the current version.',
  );
  var args = _filterVersionArgument(arguments);
  await runner.run(args);
}

List<String> _filterVersionArgument(List<String> arguments) {
  if (arguments.length != 1) return arguments;
  var argument = arguments.first;
  if (argument == '--version' || argument == '-v') return ['version'];
  return arguments;
}
