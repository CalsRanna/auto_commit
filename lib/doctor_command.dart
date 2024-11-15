import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:auto_commit/config.dart';
import 'package:auto_commit/spinner.dart';
import 'package:http/http.dart';

class DoctorCommand extends Command {
  List<String> _errors = [];

  @override
  String get description => 'Show information about the flit configuration';

  @override
  String get name => 'doctor';

  @override
  Future<void> run() async {
    var config = await Config.load();
    var spinner = Spinner();
    spinner.start();
    _checkAPIKey(spinner, config);
    _checkEndpoint(spinner, config);
    _checkModel(spinner, config);
    await _checkNetwork(spinner, config);
    spinner.stop();
    if (_errors.isNotEmpty) {
      for (var error in _errors) {
        stdout.writeln('\n• $error');
      }
      return;
    }
    stdout.writeln('\n✨ No issues found');
  }

  void _checkAPIKey(Spinner spinner, Config config) {
    var apiKey = config.apiKey;
    if (apiKey.isEmpty) return _error(spinner, 'API Key not set');
    var length = apiKey.length;
    if (length > 13) {
      var prefix = apiKey.substring(0, 7);
      var suffix = apiKey.substring(length - 6, length);
      var encrypted = List.generate(length - 13, (index) => '*');
      apiKey = prefix + encrypted.join() + suffix;
    }
    spinner.update('API Key: $apiKey');
    spinner.next();
  }

  void _checkEndpoint(Spinner spinner, Config config) {
    if (config.endpoint.isEmpty) return _error(spinner, 'Endpoint not set');
    spinner.update('Endpoint: ${config.endpoint}');
    spinner.next();
  }

  void _checkModel(Spinner spinner, Config config) {
    if (config.model.isEmpty) return _error(spinner, 'Model not set');
    spinner.update('Model: ${config.model}');
    spinner.next();
  }

  Future<void> _checkNetwork(Spinner spinner, Config config) async {
    spinner.update('');
    var response = await _connect(config);
    if (response.statusCode != 200) {
      var json = jsonDecode(response.body);
      var error = json['error']['message'];
      _error(spinner, 'Network connectivity failed', error: error);
      return;
    }
    spinner.update('Network connectivity');
    spinner.next();
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

  void _error(Spinner spinner, String message, {String? error}) {
    spinner.update(message);
    spinner.next(success: false);
    _errors.add(error ?? message);
  }
}
