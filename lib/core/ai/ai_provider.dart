import 'ai_request.dart';

/// Contract implemented by each approved AI execution route.
///
/// Future implementations may include a server-side Gemini API provider and
/// a manual prompt-export route. Secrets must never be stored in this app.
abstract interface class AiProvider {
  Future<String> generate(AiRequest request);
}
