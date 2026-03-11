import 'package:aurora/shared/utils/stats_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StatsCalculator.calculateTPS', () {
    test('treats buffered single-packet streaming like non-streaming', () {
      final tps = StatsCalculator.calculateTPS(
        completionTokens: 88,
        reasoningTokens: 26,
        durationMs: 5000,
        firstTokenMs: 4980,
      );

      expect(tps, closeTo(22.8, 0.1));
    });

    test('smooths tiny sample windows for small outputs', () {
      final tps = StatsCalculator.calculateTPS(
        completionTokens: 20,
        reasoningTokens: 0,
        durationMs: 10,
        firstTokenMs: 0,
      );

      expect(tps, closeTo(80.0, 0.1));
    });

    test('applies the same smoothing to aggregated small-sample stats', () {
      final tps = StatsCalculator.calculateTPS(
        completionTokens: 2000,
        reasoningTokens: 0,
        durationMs: 2000,
        firstTokenMs: 1000,
        sampleCount: 100,
      );

      expect(tps, closeTo(80.0, 0.1));
    });

    test('keeps normal streaming outputs close to the raw generation rate', () {
      final tps = StatsCalculator.calculateTPS(
        completionTokens: 240,
        reasoningTokens: 0,
        durationMs: 1500,
        firstTokenMs: 300,
      );

      expect(tps, closeTo(200.0, 0.1));
    });
  });
}
