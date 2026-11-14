import 'ai_provider.dart';
import 'ai_request.dart';

/// Application-level entry point for AI features.
///
/// The orchestrator depends on an abstract provider so UI and feature modules
/// do not depend directly on Gemini, HTTP clients, or API credentials.
class AiOrchestrator {
  const AiOrchestrator({required AiProvider provider}) : _provider = provider;

  final AiProvider _provider;

  Future<String> run(AiRequest request) => _provider.generate(request);
}
