import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potato_mubwanna/features/mypage/application/user_profile_controller.dart';
import 'package:potato_mubwanna/features/mypage/domain/user_profile.dart';
import 'package:potato_mubwanna/features/mypage/presentation/screen/my_page_screen.dart';

void main() {
  runApp(const MyPageProfilePreviewApp());
}

class MyPageProfilePreviewApp extends StatelessWidget {
  const MyPageProfilePreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(
            userId: 1,
            nickname: '실제 사용자',
            email: 'user@example.com',
            profileImage: '',
            createdAt: null,
          ),
        ),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MyPageScreen(),
      ),
    );
  }
}
