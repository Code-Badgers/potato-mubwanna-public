import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

typedef AudioPlaybackEngineFactory = AudioPlaybackEngine Function();

final audioPlaybackEngineFactoryProvider = Provider<AudioPlaybackEngineFactory>(
  (ref) => JustAudioPlaybackEngine.new,
);

final audioPlaybackControllerProvider = StateNotifierProvider.autoDispose
    .family<AudioPlaybackController, AudioPlaybackState, String>(
  (ref, audioUrl) => AudioPlaybackController(
    engine: ref.watch(audioPlaybackEngineFactoryProvider)(),
    audioUrl: audioUrl,
  ),
);

class AudioPlaybackController extends StateNotifier<AudioPlaybackState> {
  AudioPlaybackController({
    required AudioPlaybackEngine engine,
    required String audioUrl,
  })  : _engine = engine,
        _audioUrl = audioUrl,
        super(const AudioPlaybackState()) {
    _positionSubscription = _engine.positionStream.listen(_onPositionChanged);
    _durationSubscription = _engine.durationStream.listen(_onDurationChanged);
    _statusSubscription = _engine.statusStream.listen(_onStatusChanged);
    unawaited(_load());
  }

  final AudioPlaybackEngine _engine;
  final String _audioUrl;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration?> _durationSubscription;
  late final StreamSubscription<AudioPlaybackEngineStatus> _statusSubscription;
  bool _disposed = false;

  Future<void> retry() => _load();

  Future<void> togglePlayback() async {
    if (!state.canPlay) {
      return;
    }
    try {
      if (state.isPlaying) {
        await _engine.pause();
        _setState(state.copyWith(status: AudioPlaybackStatus.ready));
        return;
      }
      if (state.status == AudioPlaybackStatus.completed) {
        await _engine.seek(Duration.zero);
      }
      _setState(state.copyWith(status: AudioPlaybackStatus.playing));
      unawaited(
        _engine.play().catchError((Object error, StackTrace stackTrace) {
          _setFailure();
        }),
      );
    } catch (_) {
      _setFailure();
    }
  }

  Future<void> seek(Duration position) async {
    if (!state.canPlay) {
      return;
    }
    final maxMilliseconds = state.duration.inMilliseconds;
    final milliseconds = position.inMilliseconds.clamp(0, maxMilliseconds);
    try {
      await _engine.seek(Duration(milliseconds: milliseconds));
      _setState(
        state.copyWith(
          position: Duration(milliseconds: milliseconds),
          status: state.status == AudioPlaybackStatus.completed
              ? AudioPlaybackStatus.ready
              : state.status,
        ),
      );
    } catch (_) {
      _setFailure();
    }
  }

  Future<void> _load() async {
    _setState(
      state.copyWith(
        status: AudioPlaybackStatus.loading,
        position: Duration.zero,
        clearError: true,
      ),
    );
    try {
      final duration = await _engine.setUrl(_audioUrl);
      _setState(
        state.copyWith(
          status: AudioPlaybackStatus.ready,
          duration: duration ?? state.duration,
          clearError: true,
        ),
      );
    } catch (_) {
      _setFailure();
    }
  }

  void _onPositionChanged(Duration position) {
    final duration = state.duration;
    final safePosition =
        duration > Duration.zero && position > duration ? duration : position;
    _setState(state.copyWith(position: safePosition));
  }

  void _onDurationChanged(Duration? duration) {
    if (duration != null) {
      _setState(state.copyWith(duration: duration));
    }
  }

  void _onStatusChanged(AudioPlaybackEngineStatus status) {
    final nextStatus = switch (status) {
      AudioPlaybackEngineStatus.loading => AudioPlaybackStatus.loading,
      AudioPlaybackEngineStatus.ready => AudioPlaybackStatus.ready,
      AudioPlaybackEngineStatus.playing => AudioPlaybackStatus.playing,
      AudioPlaybackEngineStatus.completed => AudioPlaybackStatus.completed,
    };
    _setState(
      state.copyWith(
        status: nextStatus,
        position: nextStatus == AudioPlaybackStatus.completed
            ? state.duration
            : state.position,
      ),
    );
  }

  void _setFailure() {
    _setState(
      state.copyWith(
        status: AudioPlaybackStatus.failure,
        errorMessage: '오디오를 재생하지 못했습니다.',
      ),
    );
  }

  void _setState(AudioPlaybackState next) {
    if (!_disposed) {
      state = next;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_positionSubscription.cancel());
    unawaited(_durationSubscription.cancel());
    unawaited(_statusSubscription.cancel());
    unawaited(_engine.dispose());
    super.dispose();
  }
}

enum AudioPlaybackStatus { loading, ready, playing, completed, failure }

class AudioPlaybackState {
  const AudioPlaybackState({
    this.status = AudioPlaybackStatus.loading,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
  });

  final AudioPlaybackStatus status;
  final Duration position;
  final Duration duration;
  final String? errorMessage;

  bool get isPlaying => status == AudioPlaybackStatus.playing;

  bool get canPlay =>
      status == AudioPlaybackStatus.ready ||
      status == AudioPlaybackStatus.playing ||
      status == AudioPlaybackStatus.completed;

  AudioPlaybackState copyWith({
    AudioPlaybackStatus? status,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AudioPlaybackState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

enum AudioPlaybackEngineStatus { loading, ready, playing, completed }

abstract interface class AudioPlaybackEngine {
  Stream<Duration> get positionStream;

  Stream<Duration?> get durationStream;

  Stream<AudioPlaybackEngineStatus> get statusStream;

  Future<Duration?> setUrl(String url);

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> dispose();
}

class JustAudioPlaybackEngine implements AudioPlaybackEngine {
  JustAudioPlaybackEngine() : _player = AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Stream<AudioPlaybackEngineStatus> get statusStream =>
      _player.playerStateStream.map((state) {
        if (state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering) {
          return AudioPlaybackEngineStatus.loading;
        }
        if (state.processingState == ProcessingState.completed) {
          return AudioPlaybackEngineStatus.completed;
        }
        if (state.playing) {
          return AudioPlaybackEngineStatus.playing;
        }
        return AudioPlaybackEngineStatus.ready;
      });

  @override
  Future<Duration?> setUrl(String url) => _player.setUrl(url);

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> dispose() => _player.dispose();
}
