import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/shared/widgets/loading/potato_loading_view.dart';

void main() {
  testWidgets('cycles potato loading frames with semantics', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: PotatoLoadingView.fullScreen(
          frameInterval: Duration(milliseconds: 700),
        ),
      ),
    );

    expect(find.text('감자가 길을 찾는 중이에요'), findsOneWidget);
    expect(find.bySemanticsLabel('콘텐츠를 불러오는 중'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assets/loading/potato_loading_01.png')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 700));

    expect(
      find.byKey(const ValueKey('assets/loading/potato_loading_02.png')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  test('uses all eight source frames in a ping-pong playback order', () {
    expect(PotatoLoadingView.frameAssets, hasLength(8));
    expect(
      PotatoLoadingView.playbackFrameIndexes.toSet(),
      equals({0, 1, 2, 3, 4, 5, 6, 7}),
    );
    expect(PotatoLoadingView.playbackFrameIndexes.first, 0);
    expect(PotatoLoadingView.playbackFrameIndexes[7], 7);
    expect(PotatoLoadingView.playbackFrameIndexes.last, 1);
  });
}
