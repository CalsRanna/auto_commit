import 'dart:convert';

import 'package:auto_commit/config.dart';
import 'package:openai_dart/openai_dart.dart';

class Generator {
  static const _headers = {
    'HTTP-Referer': 'https://github.com/CalsRanna/auto_commit',
    'X-Title': 'Flit',
  };

  static const _prompt = '''
You are a commit message generator. Analyze the git diff and output a Conventional Commits message as a JSON object.

Output exactly: {"message": "<commit message>"}

Commit message format: type[(scope)]: subject
  [blank line]
  [body]

Rules:
- Subject: imperative mood, ≤72 chars
- Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore
- Do NOT fabricate issue numbers, PR numbers, ticket IDs, or external references
- Include a concise body if the changes need explanation
''';

  static const _maxAttempts = 3;

  static Future<String> generate(
    String difference, {
    required Config config,
  }) async {
    var client = OpenAIClient(
      apiKey: config.apiKey,
      baseUrl: config.baseUrl,
      headers: _headers,
    );
    var systemMessage = ChatCompletionMessage.system(content: _prompt);
    var userMessage = ChatCompletionMessage.user(
      content: ChatCompletionUserMessageContent.string(difference),
    );
    var request = CreateChatCompletionRequest(
      model: ChatCompletionModel.modelId(config.model),
      messages: [systemMessage, userMessage],
      temperature: 0.2,
      responseFormat: ResponseFormat.jsonObject(),
    );
    try {
      var finishReason = '';
      for (var attempt = 0; attempt < _maxAttempts; attempt++) {
        var response = await client.createChatCompletion(request: request);
        var choice = response.choices.first;
        finishReason = choice.finishReason?.name ?? 'unknown';
        var message = _parseMessage(choice.message.content ?? '');
        if (message.isNotEmpty) return message;
      }
      throw Exception(
        'AI returned an empty commit message '
        '($_maxAttempts attempts, last finish_reason: $finishReason)',
      );
    } finally {
      client.endSession();
    }
  }

  static String _cleanText(String raw) {
    var text = raw.trim();

    // Strip markdown code fences
    if (text.startsWith('```')) {
      var end = text.indexOf('\n');
      text = end != -1 ? text.substring(end + 1) : '';
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.lastIndexOf('```'));
    }

    // Strip common prefix on first line
    text = text.replaceFirst(
      RegExp(r"^(?:here(?:'s| is) )?(?:the )?(?:commit )?message[:：]\s*",
          caseSensitive: false),
      '',
    );

    return text.trim();
  }

  static String _parseMessage(String raw) {
    try {
      var json = jsonDecode(raw) as Map<String, dynamic>;
      var message = (json['message'] as String?)?.trim() ?? '';
      return message;
    } catch (_) {
      return _cleanText(raw);
    }
  }
}
