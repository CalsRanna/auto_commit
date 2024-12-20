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
    );
    try {
      var response = await client.createChatCompletion(request: request);
      return response.choices.first.message.content ?? '';
    } finally {
      client.endSession();
    }
  }
}
