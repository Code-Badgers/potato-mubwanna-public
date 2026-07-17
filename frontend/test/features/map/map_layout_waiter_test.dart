import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/map/presentation/widget/map_layout_waiter.dart';

void main() {
  test('retries until the map receives a positive layout size', () async {
    var layoutChecks = 0;

    final result = await waitForMapLayout(
      hasLayout: () {
        layoutChecks += 1;
        return layoutChecks >= 3;
      },
      shouldContinue: () => true,
      retryInterval: Duration.zero,
      maxAttempts: 5,
    );

    expect(result, isTrue);
    expect(layoutChecks, 3);
  });

  test('stops waiting after the map widget is disposed', () async {
    var mountedChecks = 0;

    final result = await waitForMapLayout(
      hasLayout: () => false,
      shouldContinue: () {
        mountedChecks += 1;
        return mountedChecks == 1;
      },
      retryInterval: Duration.zero,
      maxAttempts: 5,
    );

    expect(result, isFalse);
    expect(mountedChecks, 2);
  });
}
