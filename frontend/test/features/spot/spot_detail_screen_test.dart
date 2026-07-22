import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/app/theme/app_theme.dart';
import 'package:potato_mubwanna/features/audio/application/audio_guide_controller.dart';
import 'package:potato_mubwanna/features/audio/application/audio_playback_controller.dart';
import 'package:potato_mubwanna/features/audio/data/audio_guide_repository.dart';
import 'package:potato_mubwanna/features/audio/domain/audio_guide.dart';
import 'package:potato_mubwanna/features/spot/application/spot_detail_controller.dart';
import 'package:potato_mubwanna/features/spot/domain/spot_detail.dart';
import 'package:potato_mubwanna/features/spot/presentation/screen/spot_detail_screen.dart';

void main() {
  testWidgets('renders real spot detail and controls audio playback',
      (tester) async {
    await _setMobileViewport(tester);
    final engine = _FakeAudioPlaybackEngine();

    await tester.pumpWidget(
      _app(
        engine: engine,
        spotOverride: (ref) async => _spot,
        audioOverride: (ref) async => _guide,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('정선 5일장'), findsOneWidget);
    expect(find.text('시장'), findsOneWidget);
    expect(find.text('여유'), findsOneWidget);
    expect(find.text('#감자전'), findsOneWidget);
    expect(find.text('정선 5일장 이야기'), findsOneWidget);
    expect(find.byKey(const ValueKey('audio-player-card')), findsOneWidget);

    final playButton = find.byKey(const ValueKey('audio-play-toggle'));
    await tester.ensureVisible(playButton);
    await tester.tap(playButton);
    await tester.pump();

    expect(engine.playCount, 1);
  });

  testWidgets('keeps spot detail visible when audio guide is unavailable',
      (tester) async {
    await _setMobileViewport(tester);

    await tester.pumpWidget(
      _app(
        engine: _FakeAudioPlaybackEngine(),
        spotOverride: (ref) async => _spot,
        audioOverride: (ref) => Future<AudioGuide>.error(
          const AudioGuideException(
            type: AudioGuideFailureType.unavailable,
            message: '이 관광지의 오디오 가이드를 찾을 수 없습니다.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('정선 5일장'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('audio-guide-unavailable')),
      findsOneWidget,
    );
    expect(find.text('관광지 정보는 계속 확인할 수 있습니다.'), findsOneWidget);
  });

  testWidgets('shows a retry action when audio service fails', (tester) async {
    await _setMobileViewport(tester);

    await tester.pumpWidget(
      _app(
        engine: _FakeAudioPlaybackEngine(),
        spotOverride: (ref) async => _spot,
        audioOverride: (ref) => Future<AudioGuide>.error(
          const AudioGuideException(
            type: AudioGuideFailureType.serviceUnavailable,
            message: '오디오 가이드 제공 서비스에 연결할 수 없습니다.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('audio-guide-error')), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('shows loading and error states for spot detail', (tester) async {
    await _setMobileViewport(tester);
    final completer = Completer<SpotDetail>();

    await tester.pumpWidget(
      _app(
        engine: _FakeAudioPlaybackEngine(),
        spotOverride: (ref) => completer.future,
        audioOverride: (ref) async => _guide,
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('spot-detail-loading')), findsOneWidget);

    completer.completeError(StateError('network failed'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('spot-detail-error')), findsOneWidget);
  });

  testWidgets('keeps audio controls stable with large text scaling',
      (tester) async {
    await _setMobileViewport(tester);

    await tester.pumpWidget(
      _app(
        engine: _FakeAudioPlaybackEngine(),
        spotOverride: (ref) async => _spot,
        audioOverride: (ref) async => _guide,
        textScaler: const TextScaler.linear(1.4),
      ),
    );
    await tester.pumpAndSettle();

    final playerCard = find.byKey(const ValueKey('audio-player-card'));
    await tester.ensureVisible(playerCard);
    await tester.pump();

    expect(playerCard, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app({
  required _FakeAudioPlaybackEngine engine,
  required Future<SpotDetail> Function(Ref ref) spotOverride,
  required Future<AudioGuide> Function(Ref ref) audioOverride,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return ProviderScope(
    overrides: [
      spotDetailProvider('1').overrideWith(spotOverride),
      audioGuideProvider('1').overrideWith(audioOverride),
      audioPlaybackEngineFactoryProvider.overrideWithValue(() => engine),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: const SpotDetailScreen(spotId: '1'),
    ),
  );
}

Future<void> _setMobileViewport(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 932);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

const _spot = SpotDetail(
  id: '1',
  contentId: '1234567',
  name: '정선 5일장',
  category: 'POTATO_MARKET',
  latitude: 37.3801,
  longitude: 128.6609,
  address: '강원특별자치도 정선군 정선읍',
  cityName: '정선군',
  imageUrl: null,
  potatoTags: ['감자', '감자전'],
  congestionLevel: 'LOW',
  verificationRadiusMeter: 100,
  stampEnabled: true,
);

const _guide = AudioGuide(
  id: 7,
  title: '정선 5일장 이야기',
  audioUrl: 'https://example.com/audio.mp3',
  script: '정선 5일장은 오랜 역사를 지닌 전통시장입니다.',
  characterScript: '점순이: 정선 5일장 이야기를 들어봐요!',
);

class _FakeAudioPlaybackEngine implements AudioPlaybackEngine {
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _statusController =
      StreamController<AudioPlaybackEngineStatus>.broadcast();
  int playCount = 0;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Stream<AudioPlaybackEngineStatus> get statusStream =>
      _statusController.stream;

  @override
  Future<Duration?> setUrl(String url) async => const Duration(seconds: 90);

  @override
  Future<void> play() async {
    playCount++;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> dispose() async {
    await _positionController.close();
    await _durationController.close();
    await _statusController.close();
  }
}
