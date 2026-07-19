import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/potato/application/potato_collection_controller.dart';
import 'package:potato_mubwanna/features/potato/data/potato_repository.dart';
import 'package:potato_mubwanna/features/potato/domain/potato_collection.dart';
import 'package:potato_mubwanna/features/potato/presentation/screen/potato_collection_screen.dart';

void main() {
  testWidgets('renders potato collection summary and grid', (tester) async {
    await _pumpScreen(
      tester,
      overrides: [
        potatoCollectionProvider.overrideWith((ref) async => _collection()),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('감자'), findsOneWidget);
    expect(find.text('대표 감자'), findsOneWidget);
    expect(find.text('곤드레감자'), findsWidgets);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('오늘의 감자걸음'), findsOneWidget);
    expect(find.text('7,842 / 10,000보'), findsOneWidget);
    expect(find.text('나의 감자 도감'), findsOneWidget);
    expect(find.text('미획득'), findsOneWidget);
  });

  testWidgets('opens potato detail sheet from an acquired potato', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      overrides: [
        potatoCollectionProvider.overrideWith((ref) async => _collection()),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('하지감자').last);
    await tester.pumpAndSettle();

    expect(find.text('감자 소개'), findsOneWidget);
    expect(find.text('획득 방법'), findsOneWidget);
    expect(find.text('대표 감자로 설정'), findsOneWidget);
  });

  testWidgets('shows a signed out state for guests', (tester) async {
    await _pumpScreen(
      tester,
      overrides: [
        potatoCollectionProvider.overrideWith((ref) async => null),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('로그인 후 수집한 감자를 확인할 수 있습니다.'), findsOneWidget);
  });

  testWidgets('updates representative potato from the picker', (tester) async {
    final repository = _FakePotatoRepository();

    await _pumpScreen(
      tester,
      overrides: [
        potatoCollectionProvider.overrideWith((ref) async => _collection()),
        potatoRepositoryProvider.overrideWithValue(repository),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('대표 감자 변경'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('하지감자').last);
    await tester.pumpAndSettle();

    expect(repository.updatedPotatoId, '1');
    expect(find.text('대표 감자를 하지감자로 변경했어요.'), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required List<Override> overrides,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: PotatoCollectionScreen()),
    ),
  );
}

class _FakePotatoRepository extends PotatoRepository {
  _FakePotatoRepository() : super(dio: Dio());

  String? updatedPotatoId;

  @override
  Future<PotatoRepresentativeResult> updateRepresentativePotato(
    String potatoId,
  ) async {
    updatedPotatoId = potatoId;
    return PotatoRepresentativeResult(
      potatoId: potatoId,
      representative: true,
    );
  }
}

PotatoCollection _collection() {
  return PotatoCollection(
    totalCount: 3,
    acquiredCount: 2,
    items: [
      PotatoCollectionItem(
        id: '1',
        code: 'POTATO_HAJI_GANGNEUNG',
        name: '하지감자',
        region: '강릉시',
        rarity: PotatoRarity.common,
        description: '강릉 여행길에서 처음 만나기 좋은 기본 감자입니다.',
        acquisitionHint: '강릉 감자 스팟 방문 인증',
        imageUrl: null,
        acquired: true,
        acquiredAt: DateTime.parse('2026-07-01T00:00:00Z'),
        level: 2,
        growthDistance: 1500,
        growthGoalDistance: 3000,
        representative: false,
      ),
      PotatoCollectionItem(
        id: '2',
        code: 'POTATO_GONDRE_JEONGSEON',
        name: '곤드레감자',
        region: '정선군',
        rarity: PotatoRarity.rare,
        description: '정선 장터와 곤드레 향토 음식 이야기를 품은 희귀 감자입니다.',
        acquisitionHint: '정선 5일장 미션 완료',
        imageUrl: null,
        acquired: true,
        acquiredAt: DateTime.parse('2026-07-02T00:00:00Z'),
        level: 3,
        growthDistance: 4200,
        growthGoalDistance: 4200,
        representative: true,
      ),
      const PotatoCollectionItem(
        id: '3',
        code: 'POTATO_LEGEND_PYEONGCHANG',
        name: '전설감자',
        region: '평창군',
        rarity: PotatoRarity.legendary,
        description: '강원 고랭지 여행을 오래 이어간 사용자에게 열리는 감자입니다.',
        acquisitionHint: '평창 희귀 미션 완료',
        imageUrl: null,
        acquired: false,
        acquiredAt: null,
        level: 0,
        growthDistance: 0,
        growthGoalDistance: 10000,
        representative: false,
      ),
    ],
  );
}
