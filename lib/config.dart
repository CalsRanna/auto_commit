import 'dart:io';

import 'package:yaml/yaml.dart';

class Config {
  static const String name = '.auto_commit.yaml';

  late String apiKey;
  late String baseUrl;
  late String model;

  Config({
    this.apiKey = 'YOUR_API_KEY',
    this.baseUrl = 'https://api.openai.com',
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
      'api_key: $apiKey',
      'base_url: $baseUrl',
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
      apiKey: yaml['api_key']?.toString() ?? '',
      baseUrl: yaml['base_url']?.toString() ?? 'https://api.openai.com/v1',
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
