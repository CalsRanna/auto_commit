import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:yaml/yaml.dart';

class VersionCommand extends Command {
  @override
  String get description => 'Print the current version';

  @override
  bool get hidden => true;

  @override
  String get name => 'version';

  @override
  Future<void> run() async {
    print('Flit ${_resolveVersion()}');
  }

  String _resolveVersion() {
    const env = String.fromEnvironment('APP_VERSION');
    if (env.isNotEmpty) return env;
    try {
      final yaml = loadYaml(File('pubspec.yaml').readAsStringSync());
      final version = yaml['version']?.toString();
      if (version != null && version.isNotEmpty) return version;
    } catch (_) {}
    return '0.0.0';
  }
}
