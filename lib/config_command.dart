import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:auto_commit/config.dart';

class ConfigCommand extends Command {
  ConfigCommand() {
    argParser
      ..addOption('set-api-key', help: 'Set the API key')
      ..addOption('set-base-url', help: 'Set the API base url')
      ..addOption('set-model', help: 'Set the model')
      ..addFlag('show', help: 'Show current configuration');
  }

  @override
  String get description => 'Configure Auto Commit CLI';

  @override
  String get name => 'config';

  @override
  Future<void> run() async {
    var config = await Config.load();
    if (argResults?['set-api-key'] != null) return _setAPIKey(config);
    if (argResults?['set-base-url'] != null) return _setBaseUrl(config);
    if (argResults?['set-model'] != null) return _setModel(config);
    return _show(config);
  }

  void _setAPIKey(Config config) {
    config.apiKey = argResults!['set-api-key'].toString();
    config.save();
    stdout.writeln('\nAPI key set successfully');
    _show(config);
  }

  void _setBaseUrl(Config config) {
    config.baseUrl = argResults!['set-base-url'].toString();
    config.save();
    stdout.writeln('\nBase url set successfully');
    _show(config);
  }

  void _setModel(Config config) {
    config.model = argResults!['set-model'].toString();
    config.save();
    stdout.writeln('\nModel set successfully');
    _show(config);
  }

  void _show(Config config) {
    stdout.writeln('Auto Commit CLI Configuration\n');
    var apiKey = config.apiKey;
    var length = apiKey.length;
    if (length > 13) {
      var prefix = apiKey.substring(0, 7);
      var suffix = apiKey.substring(length - 6, length);
      var encrypted = List.generate(length - 13, (index) => '*');
      apiKey = prefix + encrypted.join() + suffix;
    }
    stdout.writeln('API Key: $apiKey');
    stdout.writeln('Base URL: ${config.baseUrl}');
    stdout.writeln('Model: ${config.model}\n');
  }
}
