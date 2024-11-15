import 'package:args/command_runner.dart';

class VersionCommand extends Command {
  @override
  String get description => 'Print the current version';

  @override
  bool get hidden => true;

  @override
  String get name => 'version';

  @override
  Future<void> run() async {
    print('Flit 1.0.0');
  }
}
