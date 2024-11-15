import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:auto_commit/config.dart';

class ConfigCommand extends Command {
  @override
  String get description => 'Configure Auto Commit CLI';

  @override
  String get name => 'config';

  ConfigCommand() {
    argParser
      ..addOption('set-api-key', help: 'Set the API key')
      ..addOption('set-endpoint', help: 'Set the API endpoint')
      ..addOption('set-model', help: 'Set the model')
      ..addFlag('show', help: 'Show current configuration')
      ..addFlag('init', help: 'Create a new configuration file');
  }

  @override
  Future<void> run() async {
    var config = await Config.load();
    if (argResults?['set-api-key'] != null) return _setAPIKey(config);
    if (argResults?['set-endpoint'] != null) return _setEndpoint(config);
    if (argResults?['set-model'] != null) return _setModel(config);
    if (argResults?['show'] == true) return _show(config);
    if (argResults?['init'] == true) return _init(config);
  }

  void _setAPIKey(Config config) {
    config.apiKey = argResults!['set-api-key'].toString();
    config.save();
    stdout.writeln('\nAPI Key set successfully');
    _show(config);
  }

  void _setEndpoint(Config config) {
    config.endpoint = argResults!['set-endpoint'].toString();
    config.save();
    stdout.writeln('\nAPI Endpoint set successfully');
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
    stdout.writeln('Endpoint: ${config.endpoint}');
    stdout.writeln('Model: ${config.model}\n');
  }

  Future<void> _init(Config config) async {
    var currentDirectory = Directory.current;
    var homeDirectory = Platform.environment['HOME'];
    var profileDirectory = Platform.environment['USERPROFILE'];
    var directory = homeDirectory ?? profileDirectory;
    var path = directory ?? currentDirectory.path;
    var file = File('$path/${Config.name}');
    var parts = [
      '# Auto Commit CLI Configuration',
      'apiKey: ${config.apiKey}',
      'endpoint: ${config.endpoint}',
      'model: ${config.model}',
    ];
    await file.writeAsString(parts.join('\n'));
    stdout.writeln('\nConfiguration file created successfully\n');
  }
}