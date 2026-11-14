/// A provider-neutral request for CONTENTNEX AI features.
///
/// This type intentionally contains no API keys, network code, or vendor SDKs.
class AiRequest {
  const AiRequest({
    required this.task,
    required this.prompt,
    this.languageCode = 'th',
    this.context = const <String, String>{},
  });

  /// Stable feature identifier, e.g. "copywriter" or "council_strategy".
  final String task;

  /// User-approved instruction and input for the selected AI task.
  final String prompt;

  final String languageCode;
  final Map<String, String> context;
}
