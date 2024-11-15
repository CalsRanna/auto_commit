import 'dart:convert';

import 'package:auto_commit/config.dart';
import 'package:http/http.dart';

class Generator {
  static Future<String> generate(
    String difference, {
    required Config config,
  }) async {
    var url = '${config.endpoint}/v1/chat/completions';
    var headers = {
      'Authorization': 'Bearer ${config.apiKey}',
      'Content-Type': 'application/json'
    };
    var prompt = 'Generate a Conventional Commits style commit message for '
        'the following git diff.';
    var schema = {
      "description": 'Conventional commit message',
      'name': 'commit',
      'strict': true,
      'schema': {
        'type': 'object',
        'properties': {
          'commit': {
            'description': 'commit message',
            'type': 'string',
          }
        }
      }
    };
    var body = {
      'messages': [
        {'role': 'system', 'content': prompt},
        {'role': 'user', 'content': difference}
      ],
      'model': config.model,
      'response_format': {'type': 'json_schema', 'json_schema': schema}
    };
    var response = await post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
    var json = jsonDecode(response.body);
    var code = response.statusCode;
    if (code == 200) return _getContent(json);
    throw _getException(json);
  }

  static String _getContent(Map<String, dynamic> json) {
    var content = json['choices'][0]['message']['content'];
    try {
      var formattedContent = jsonDecode(content);
      return formattedContent['commit'];
    } catch (error) {
      return content;
    }
  }

  static GeneratorException _getException(Map<String, dynamic> json) {
    return GeneratorException(json['error']['code'], json['error']['message']);
  }
}

class GeneratorException implements Exception {
  final String code;
  final String message;
  GeneratorException(this.code, this.message);
}
