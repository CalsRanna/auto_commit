import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:auto_commit/config.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:http/http.dart';

class DoctorCommand extends Command {
  final List<String> _errors = [];
  final _spinner = CliSpin(spinner: CliSpinners.dots5);

  @override
  String get description => 'Show information about the flit configuration';

  @override
  String get name => 'doctor';

  @override
  Future<void> run() async {
    _spinner.start();
    var config = await Config.load();
    _checkAPIKey(config);
    _checkEndpoint(config);
    _checkModel(config);
    await _checkNetwork(config);
    _spinner.stop();
    if (_errors.isNotEmpty) {
      for (var error in _errors) {
        stdout.writeln('\n\x1B[31m• $error\x1B[0m');
      }
      return;
    }
    stdout.writeln('\n✨ No issues found');
  }

  void _checkAPIKey(Config config) {
    var apiKey = config.apiKey;
    if (apiKey.isEmpty) return _fail('API Key not set');
    var length = apiKey.length;
    if (length > 13) {
      var prefix = apiKey.substring(0, 7);
      var suffix = apiKey.substring(length - 6, length);
      var encrypted = List.generate(length - 13, (index) => '*');
      apiKey = prefix + encrypted.join() + suffix;
    }
    _spinner.success('API Key: $apiKey');
    _spinner.start();
  }

  void _checkEndpoint(Config config) {
    if (config.endpoint.isEmpty) return _fail('Endpoint not set');
    _spinner.success('Endpoint: ${config.endpoint}');
    _spinner.start();
  }

  void _checkModel(Config config) {
    if (config.model.isEmpty) return _fail('Model not set');
    _spinner.success('Model: ${config.model}');
    _spinner.start();
  }

  Future<void> _checkNetwork(Config config) async {
    _spinner.text = '';
    var response = await _connect(config);
    if (response.statusCode != 200) {
      var json = jsonDecode(response.body);
      var error = json['error']['message'];
      _fail('Network connectivity failed', error: error);
      return;
    }
    _spinner.success('Network connectivity');
  }

  Future<Response> _connect(Config config) async {
    var url = '${config.endpoint}/v1/chat/completions';
    var headers = {
      'Authorization': 'Bearer ${config.apiKey}',
      'Content-Type': 'application/json'
    };
    var body = {
      'messages': [
        {'role': 'user', 'content': 'hi'}
      ],
      'model': config.model,
    };
    return await post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  void _fail(String message, {String? error}) {
    _spinner.fail(message);
    _errors.add(error ?? message);
  }
}
