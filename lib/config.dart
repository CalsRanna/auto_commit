import 'dart:io';

import 'package:yaml/yaml.dart';

class Config {
  static const String name = '.auto_commit.yaml';

  late String apiKey;
  late String endpoint;
  late String model;

  Config({
    this.apiKey = 'YOUR_API_KEY',
    this.endpoint = 'https://api.openai.com',
    this.model = 'gpt-4o',
  });

  Future<void> save() async {
    var currentDirectory = Directory.current;
    var homeDirectory = Platform.environment['HOME'];
    var profileDirectory = Platform.environment['USERPROFILE'];
    var directory = homeDirectory ?? profileDirectory;
    var path = directory ?? currentDirectory.path;
    var file = File('$path/$name');
    var parts = [
      '# Auto Commit CLI Configuration',
      'apiKey: $apiKey',
      'endpoint: $endpoint',
      'model: $model',
    ];
    await file.writeAsString(parts.join('\n'));
  }

  static Future<Config> load() async {
    var file = await _findConfigFile();
    if (file == null) return Config();
    var content = await file.readAsString();
    var yaml = loadYaml(content);
    return Config(
      apiKey: yaml['apiKey']?.toString() ?? 'YOUR_API_KEY',
      endpoint: yaml['endpoint']?.toString() ?? 'https://api.openai.com',
      model: yaml['model']?.toString() ?? 'gpt-4o',
    );
  }

  static Future<File?> _findConfigFile() async {
    var currentDirectory = Directory.current;
    var homeDirectory = Platform.environment['HOME'];
    var profileDirectory = Platform.environment['USERPROFILE'];
    var file = File('$currentDirectory/$name');
    if (await file.exists()) return file;
    var globalDirectory = homeDirectory ?? profileDirectory;
    if (globalDirectory == null) return null;
    file = File('$globalDirectory/$name');
    if (await file.exists()) return file;
    return null;
  }
}
