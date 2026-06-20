import 'package:flutter/material.dart';
import 'package:potato_mubwanna/features/mypage/presentation/screen/my_page_screen.dart';

void main() {
  runApp(const MyPagePreviewApp());
}

class MyPagePreviewApp extends StatelessWidget {
  const MyPagePreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyPageScreen(),
    );
  }
}
