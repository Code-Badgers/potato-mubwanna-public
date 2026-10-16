import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/app/theme/app_theme.dart';
import 'package:potato_mubwanna/core/network/api_exception.dart';
import 'package:potato_mubwanna/features/audio/application/audio_guide_controller.dart';
import 'package:potato_mubwanna/features/spot/application/spot_detail_controller.dart';
import 'package:potato_mubwanna/features/spot/data/spot_detail_repository.dart';
import 'package:potato_mubwanna/features/spot/presentation/screen/spot_detail_screen.dart';

void main() {
  testWidgets(
      'basic name and directions work before external information arrives',
      (tester) async {
    final full = Completer<Map<String, dynamic>>();
    final repository = _Repository(full.future);
    Uri? launched;
    await tester.pumpWidget(_app(repository, launch: (uri) async {
      launched = uri;
      return true;
    }));
    await tester.pumpAndSettle();
    expect(find.text('기본 장소'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('spot-enrichment-status')), findsOneWidget);
    final directions = find.byKey(const ValueKey('spot-directions-button'));
    await tester.ensureVisible(directions);
    await tester.pumpAndSettle();
    await tester.tap(directions);
    expect(launched?.host, 'map.kakao.com');
    expect(launched.toString(), contains('37.9,127.7'));
    full.complete({..._basic, 'description': '보강된 관광 안내'});
    await tester.pumpAndSettle();
    expect(find.text('보강된 관광 안내'), findsOneWidget);
    expect(find.byKey(const ValueKey('spot-enrichment-status')), findsNothing);
    expect(repository.fullCalls, 1);
    expect(repository.basicCalls, 1);
  });

  testWidgets('keeps basic information and retries enrichment after failure',
      (tester) async {
    final full = Completer<Map<String, dynamic>>();
    final repository = _Repository(full.future);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    full.completeError(
        const ApiException(message: 'unavailable', statusCode: 503));
    await tester.pumpAndSettle();
    expect(find.text('기본 장소'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('spot-directions-button')), findsOneWidget);
    repository.full = Future.value({..._basic, 'description': '복구된 안내'});
    final retry = find.text('추가 정보 다시 시도');
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.text('복구된 안내'), findsOneWidget);
    expect(repository.fullCalls, 2);
    expect(repository.basicCalls, 1);
  });

  testWidgets('a warm full response skips the basic request', (tester) async {
    final repository = _Repository(Future.value(_basic));
    final container = ProviderContainer(overrides: [
      spotDetailRepositoryProvider.overrideWithValue(repository),
      audioGuideProvider.overrideWith(
          (ref, id) async => throw const ApiException(message: 'no audio')),
    ]);
    await container.read(spotDetailResponseProvider('7').future);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            theme: AppTheme.light, home: const SpotDetailScreen(spotId: '7'))));
    await tester.pumpAndSettle();
    expect(find.text('기본 장소'), findsOneWidget);
    expect(repository.fullCalls, 1);
    expect(repository.basicCalls, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('visit verification waits for a stable full-detail model',
      (tester) async {
    final full = Completer<Map<String, dynamic>>();
    final repository = _Repository(full.future,
        basicPayload: {..._basic, 'stampEnabled': true});
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    expect(find.text('기본 장소'), findsOneWidget);
    expect(find.byKey(const ValueKey('visit-verify-button')), findsNothing);
    full.complete({..._basic, 'stampEnabled': true});
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('visit-verify-button')), findsOneWidget);
  });

  testWidgets('older server without basic route can still show full detail',
      (tester) async {
    final full = Completer<Map<String, dynamic>>();
    final repository = _Repository(full.future, missingBasic: true);
    await tester.pumpWidget(_app(repository));
    await tester.pump();
    full.complete(_basic);
    await tester.pumpAndSettle();
    expect(find.text('기본 장소'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('spot-directions-button')), findsOneWidget);
  });

  testWidgets('basic view remains scrollable on a small screen with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(
        _Repository(Completer<Map<String, dynamic>>().future),
        largeText: true));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const ValueKey('spot-directions-button')));
    expect(tester.takeException(), isNull);
  });
}

const _basic = <String, dynamic>{
  'id': 7,
  'name': '기본 장소',
  'category': 'POTATO_TOUR',
  'cityName': '춘천시',
  'address': '강원특별자치도 춘천시 테스트로 1',
  'latitude': 37.9,
  'longitude': 127.7,
  'stampEnabled': false
};

Widget _app(_Repository repository,
        {Future<bool> Function(Uri)? launch, bool largeText = false}) =>
    ProviderScope(
      overrides: [
        spotDetailRepositoryProvider.overrideWithValue(repository),
        audioGuideProvider.overrideWith(
            (ref, id) async => throw const ApiException(message: 'no audio'))
      ],
      child: MaterialApp(
          theme: AppTheme.light,
          builder: largeText
              ? (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!)
              : null,
          home: SpotDetailScreen(
              spotId: '7', mapUriLauncher: launch ?? (_) async => true)),
    );

class _Repository extends SpotDetailRepository {
  _Repository(this.full,
      {this.missingBasic = false, this.basicPayload = _basic})
      : super(dio: Dio());
  Future<Map<String, dynamic>> full;
  final bool missingBasic;
  final Map<String, dynamic> basicPayload;
  int fullCalls = 0;
  int basicCalls = 0;
  @override
  Future<Map<String, dynamic>> fetchSpotDetailPayload(String id,
      {bool basic = false}) async {
    if (basic) {
      basicCalls++;
      if (missingBasic) {
        throw const ApiException(message: 'not found', statusCode: 404);
      }
      return basicPayload;
    }
    fullCalls++;
    return full;
  }
}
