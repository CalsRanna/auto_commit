import 'package:auto_commit/config.dart';
import 'package:openai_dart/openai_dart.dart';

class Generator {
  static Future<String> generate(
    String difference, {
    required Config config,
  }) async {
    var headers = {
      'HTTP-Referer': 'https://github.com/CalsRanna/auto_commit',
      'X-Title': 'Flit',
    };
    var client = OpenAIClient(
      apiKey: config.apiKey,
      baseUrl: config.baseUrl,
      headers: headers,
    );
    var prompt = '''
You are an expert AI assistant specialized in analyzing git diffs and generating Conventional Commits style commit messages.
Your task is to create a concise and informative commit message based *solely* on the provided git diff.

**Instructions:**

1.  **Analyze the Diff:** Carefully examine the provided git diff to understand the primary purpose, nature, and impact of the changes. Identify the most significant modifications.
2.  **Determine Conventional Commit Type:** Based on your analysis, choose the most appropriate type from the following:
    *   `feat`: A new feature.
    *   `fix`: A bug fix.
    *   `docs`: Documentation only changes.
    *   `style`: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc).
    *   `refactor`: A code change that neither fixes a bug nor adds a feature.
    *   `perf`: A code change that improves performance.
    *   `test`: Adding missing tests or correcting existing tests.
    *   `build`: Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm).
    *   `ci`: Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs).
    *   `chore`: Other changes that don't modify src or test files (e.g., updating dependencies, project configuration).
3.  **Identify Scope (Optional):** If the changes are clearly localized to a specific part or module of the codebase, provide a short, descriptive scope in parentheses, e.g., `(api)`, `(ui)`. If no specific scope is obvious or applicable, omit it.
4.  **Write Subject:** Craft a concise subject line (max 50-72 characters) in the imperative mood, describing *what* the commit does. Start with a lowercase letter. Example: `fix: correct minor typos in documentation`.
5.  **Write Body (Optional):** If the changes are complex or require more explanation than the subject line allows, provide a brief body. Explain the 'what' and 'why' of the changes. Keep it concise. Separate the subject from the body with a blank line.
6.  **Indicate Breaking Changes (If Any):** If the commit introduces breaking changes, start a new paragraph in the footer with `BREAKING CHANGE:`, followed by a description of the breaking change.

**CRITICAL CONSTRAINT - NO FABRICATED REFERENCES:**
*   **ABSOLUTELY DO NOT invent, fabricate, or include *any* issue numbers, pull request numbers, ticket IDs, or any form of external references (e.g., `closes #123`, `refs #456`, `fixes PROJ-789`) in the commit message.**
*   You must only derive information from the provided git diff. Since the diff itself will not contain these future references, you must not generate them.
*   Violation of this rule will render the output unusable.

**Output Format:**
*   Your response MUST be *only* the generated commit message itself.
*   Do not include any other text, explanations, apologies, greetings, or markdown formatting (like backticks around the commit message).
*   The commit message should strictly follow the Conventional Commits format:
    `type(scope): subject`
    `\n\n[optional body]`
    `\n\n[optional BREAKING CHANGE footer]`

Please generate the commit message and the git diff is below:
''';
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
