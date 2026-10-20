import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_design_tokens.dart';

class PotatoLoadingView extends StatefulWidget {
  const PotatoLoadingView({
    super.key,
    this.message = '감자가 길을 찾는 중이에요',
    this.subtitle,
    this.fullScreen = false,
    this.frameInterval = const Duration(milliseconds: 700),
    this.backgroundColor,
  });

  const PotatoLoadingView.fullScreen({
    super.key,
    this.message = '감자가 길을 찾는 중이에요',
    this.subtitle,
    this.frameInterval = const Duration(milliseconds: 700),
    this.backgroundColor = AppColors.background,
  }) : fullScreen = true;

  const PotatoLoadingView.compact({
    super.key,
    this.message = '감자가 길을 찾는 중이에요',
    this.subtitle,
    this.frameInterval = const Duration(milliseconds: 700),
    this.backgroundColor,
  }) : fullScreen = false;

  static const frameAssets = [
    'assets/loading/potato_loading_01.png',
    'assets/loading/potato_loading_02.png',
    'assets/loading/potato_loading_03.png',
    'assets/loading/potato_loading_04.png',
    'assets/loading/potato_loading_05.png',
    'assets/loading/potato_loading_06.png',
    'assets/loading/potato_loading_07.png',
    'assets/loading/potato_loading_08.png',
  ];

  @visibleForTesting
  static const playbackFrameIndexes = [
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    6,
    5,
    4,
    3,
    2,
    1,
  ];

  final String message;
  final String? subtitle;
  final bool fullScreen;
  final Duration frameInterval;
  final Color? backgroundColor;

  @override
  State<PotatoLoadingView> createState() => _PotatoLoadingViewState();
}

class _PotatoLoadingViewState extends State<PotatoLoadingView> {
  Timer? _timer;
  int _playbackIndex = 0;
  bool _didSchedulePrecache = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didSchedulePrecache) {
      _didSchedulePrecache = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_precacheFramesInOrder());
        }
      });
    }
  }

  Future<void> _precacheFramesInOrder() async {
    for (final asset in PotatoLoadingView.frameAssets.skip(1)) {
      if (!mounted) {
        return;
      }
      await precacheImage(AssetImage(asset), context);
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  @override
  void didUpdateWidget(covariant PotatoLoadingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frameInterval != widget.frameInterval) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAnimation() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.frameInterval, (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _playbackIndex = (_playbackIndex + 1) %
            PotatoLoadingView.playbackFrameIndexes.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final frameWidth = widget.fullScreen
        ? math.min(math.max(screenWidth * 0.42, 132), 180).toDouble()
        : math.min(math.max(screenWidth * 0.32, 92), 132).toDouble();
    final frameAsset = PotatoLoadingView
        .frameAssets[PotatoLoadingView.playbackFrameIndexes[_playbackIndex]];
    final content = Semantics(
      label: '콘텐츠를 불러오는 중',
      value: [widget.message, if (widget.subtitle != null) widget.subtitle!]
          .join('. '),
      container: true,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  frameAsset,
                  key: ValueKey(frameAsset),
                  width: frameWidth,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
                const SizedBox(height: 18),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.stateTitle,
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ),
                ],
                const SizedBox(height: 16),
                const _LoadingDots(),
              ],
            ),
          ),
        ),
      ),
    );

    // compact는 SliverFillRemaining의 intrinsic 측정 안에서도 사용된다.
    // 전체 화면에서만 별도 스크롤을 만들어 그 측정 경로를 보존한다.
    if (!widget.fullScreen) return content;
    final scrollableContent = LayoutBuilder(builder: (context, constraints) {
      if (!constraints.hasBoundedHeight) return content;
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: content,
        ),
      );
    });
    return ColoredBox(
      color: widget.backgroundColor ?? AppColors.background,
      child: scrollableContent,
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.38 + index * 0.18),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
