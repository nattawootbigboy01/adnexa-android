import 'package:flutter_test/flutter_test.dart';
import 'package:adnexa/core/ai/ai_orchestrator.dart';
import 'package:adnexa/core/ai/ai_provider.dart';
import 'package:adnexa/core/ai/ai_request.dart';

class FakeAiProvider implements AiProvider {
  AiRequest? receivedRequest;

  @override
  Future<String> generate(AiRequest request) async {
    receivedRequest = request;
    return 'ผลลัพธ์ตัวอย่าง';
  }
}

void main() {
  test('orchestrator forwards the request to its provider and returns output',
      () async {
    final provider = FakeAiProvider();
    final orchestrator = AiOrchestrator(provider: provider);
    const request = AiRequest(
      task: 'copywriter',
      prompt: 'เขียนแคปชันสินค้า',
      languageCode: 'th',
      context: {'category': 'อาหาร'},
    );

    final result = await orchestrator.run(request);

    expect(result, 'ผลลัพธ์ตัวอย่าง');
    expect(provider.receivedRequest, same(request));
    expect(provider.receivedRequest?.task, 'copywriter');
    expect(provider.receivedRequest?.context['category'], 'อาหาร');
  });
}
