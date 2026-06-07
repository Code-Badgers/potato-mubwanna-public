import 'package:flutter/material.dart';

class KakaoMapView extends StatelessWidget {
  const KakaoMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFEAF5D5),
      child: Center(
        child: Text(
          '카카오맵은 Android/iOS 네이티브 지도 설정 후 표시됩니다.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
