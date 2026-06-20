import 'package:flutter/material.dart';
import 'package:potato_mubwanna/features/coupon/presentation/screen/coupon_screen.dart';

void main() {
  runApp(const CouponPreviewApp());
}

class CouponPreviewApp extends StatelessWidget {
  const CouponPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CouponScreen(),
    );
  }
}
