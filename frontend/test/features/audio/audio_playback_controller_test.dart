import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/audio/application/audio_playback_controller.dart';

void main() {
  test('loads, plays, seeks, pauses, and disposes audio', () async {
    final engine = _FakeAudioPlaybackEngine();
    final controller = AudioPlaybackController(
      engine: engine,
      audioUrl: 'https://example.com/audio.mp3',
    );

    await Future<void>.delayed(Duration.zero);
    expect(engine.loadedUrl, 'https://example.com/audio.mp3');
    expect(controller.state.status, AudioPlaybackStatus.ready);
    expect(controller.state.duration, const Duration(seconds: 90));

    await controller.togglePlayback();
    expect(engine.playCount, 1);
    expect(controller.state.isPlaying, isTrue);

    await controller.seek(const Duration(seconds: 35));
    expect(engine.lastSeek, const Duration(seconds: 35));
    expect(controller.state.position, const Duration(seconds: 35));

    await controller.togglePlayback();
    expect(engine.pauseCount, 1);
    expect(controller.state.status, AudioPlaybackStatus.ready);

    controller.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(engine.disposed, isTrue);
  });

  test('shows a retryable failure when audio loading fails', () async {
    final engine = _FakeAudioPlaybackEngine(failLoadCount: 1);
    final controller = AudioPlaybackController(
      engine: engine,
      audioUrl: 'https://example.com/audio.mp3',
    );

    await Future<void>.delayed(Duration.zero);
    expect(controller.state.status, AudioPlaybackStatus.failure);

    await controller.retry();
    expect(controller.state.status, AudioPlaybackStatus.ready);
    expect(engine.loadCount, 2);

    controller.dispose();
  });
}

class _FakeAudioPlaybackEngine implements AudioPlaybackEngine {
  _FakeAudioPlaybackEngine({this.failLoadCount = 0});

  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _statusController =
      StreamController<AudioPlaybackEngineStatus>.broadcast();
  int failLoadCount;
  int loadCount = 0;
  int playCount = 0;
  int pauseCount = 0;
  String? loadedUrl;
  Duration? lastSeek;
  bool disposed = false;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Stream<AudioPlaybackEngineStatus> get statusStream =>
      _statusController.stream;

  @override
  Future<Duration?> setUrl(String url) async {
    loadCount++;
    loadedUrl = url;
    if (loadCount <= failLoadCount) {
      throw StateError('load failed');
    }
    return const Duration(seconds: 90);
  }

  @override
  Future<void> play() async {
    playCount++;
  }

  @override
  Future<void> pause() async {
    pauseCount++;
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeek = position;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _positionController.close();
    await _durationController.close();
    await _statusController.close();
  }
}
