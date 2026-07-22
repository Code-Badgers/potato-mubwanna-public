import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potato_mubwanna/app/theme/app_theme.dart';
import 'package:potato_mubwanna/features/audio/application/audio_guide_controller.dart';
import 'package:potato_mubwanna/features/audio/application/audio_playback_controller.dart';
import 'package:potato_mubwanna/features/audio/domain/audio_guide.dart';
import 'package:potato_mubwanna/features/spot/application/spot_detail_controller.dart';
import 'package:potato_mubwanna/features/spot/domain/spot_detail.dart';
import 'package:potato_mubwanna/features/spot/presentation/screen/spot_detail_screen.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        spotDetailProvider('1').overrideWith((ref) async => _spot),
        audioGuideProvider('1').overrideWith((ref) async => _guide),
        audioPlaybackEngineFactoryProvider.overrideWithValue(
          _PreviewAudioPlaybackEngine.new,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SpotDetailScreen(spotId: '1'),
      ),
    ),
  );
}

const _spot = SpotDetail(
  id: '1',
  contentId: '1234567',
  name: '정선 5일장',
  category: 'POTATO_MARKET',
  latitude: 37.3801,
  longitude: 128.6609,
  address: '강원특별자치도 정선군 정선읍 5일장길 40',
  cityName: '정선군',
  imageUrl: null,
  potatoTags: ['감자', '곤드레', '전통시장'],
  congestionLevel: 'LOW',
  verificationRadiusMeter: 100,
  stampEnabled: true,
);

const _guide = AudioGuide(
  id: 7,
  title: '정선 5일장 이야기',
  audioUrl: 'https://example.com/jeongseon-market.mp3',
  script:
      '정선 5일장은 강원도의 산나물과 농산물이 모이는 전통시장입니다. '
      '끝자리가 2일과 7일인 날마다 장이 열리고, 곤드레밥과 수수부꾸미 같은 '
      '지역 먹거리를 만날 수 있습니다.',
  characterScript: '점순이: 정선의 맛과 이야기가 모이는 장터를 함께 걸어봐요!',
);

class _PreviewAudioPlaybackEngine implements AudioPlaybackEngine {
  @override
  Stream<Duration> get positionStream =>
      Stream.value(const Duration(seconds: 38));

  @override
  Stream<Duration?> get durationStream =>
      Stream.value(const Duration(minutes: 2, seconds: 5));

  @override
  Stream<AudioPlaybackEngineStatus> get statusStream =>
      Stream.value(AudioPlaybackEngineStatus.ready);

  @override
  Future<Duration?> setUrl(String url) async =>
      const Duration(minutes: 2, seconds: 5);

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> dispose() async {}
}
