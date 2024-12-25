import 'dart:convert';

import 'package:auto_commit/config.dart';
import 'package:openai_dart/openai_dart.dart';

class Generator {
  static Future<String> generate(
    String difference, {
    required Config config,
  }) async {
    var client = OpenAIClient(apiKey: config.apiKey, baseUrl: config.baseUrl);
    var prompt = 'Generate a Conventional Commits style commit message for '
        'the following git diff. Only output the commit message, no other text.';
    var systemMessage = ChatCompletionMessage.system(content: prompt);
    var userMessage = ChatCompletionMessage.user(
      content: ChatCompletionUserMessageContent.string(difference),
    );
    var request = CreateChatCompletionRequest(
      model: ChatCompletionModel.modelId(config.model),
      messages: [systemMessage, userMessage],
      responseFormat: _getResponseFormat(),
    );
    try {
      var response = await client.createChatCompletion(request: request);
      return _formatResponseMessage(response.choices.first.message.content);
    } finally {
      client.endSession();
    }
  }

  static String _formatResponseMessage(String? content) {
    if (content == null) return '';
    try {
      var json = jsonDecode(content);
      var type = json['commitType'];
      var scope = json['scope'];
      var description = json['description'];
      var body = json['body'];
      var footer = json['footer'];
      var buffer = StringBuffer();
      buffer.write(type);
      if (scope != null) buffer.write('($scope)');
      buffer.write(': ');
      buffer.write(description);
      if (body != null) buffer.write('\n\n$body');
      if (footer != null) buffer.write('\n\n$footer');
      return buffer.toString();
    } catch (error) {
      return content;
    }
  }

  static ResponseFormat _getResponseFormat() {
    var properties = {
      'commitType': {'type': 'string'},
      'scope': {
        'type': ['string', 'null']
      },
      'description': {'type': 'string'},
      'body': {
        'type': ['string', 'null']
      },
      'footer': {
        'type': ['string', 'null']
      },
    };
    var schema = {
      'type': 'object',
      'properties': properties,
      'additionalProperties': false,
      'required': properties.keys.toList(),
    };
    var jsonSchemaObject = JsonSchemaObject(
      name: 'commit_message',
      description: 'Conventional Commits style commit message',
      strict: true,
      schema: schema,
    );
    return ResponseFormat.jsonSchema(jsonSchema: jsonSchemaObject);
  }
}
