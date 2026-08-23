import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/network/api_exception.dart';
import 'package:potato_mubwanna/features/admin_notice/application/admin_notice_controller.dart';
import 'package:potato_mubwanna/features/admin_notice/data/admin_notice_repository.dart';
import 'package:potato_mubwanna/features/admin_notice/domain/admin_notice.dart';
import 'package:potato_mubwanna/features/admin_notice/presentation/screen/admin_notice_screen.dart';

void main() {
  testWidgets('renders notice summary and publication state', (tester) async {
    await _pumpScreen(tester, repository: _FakeAdminNoticeRepository());

    expect(find.text('공지 관리'), findsOneWidget);
    expect(find.text('ADMIN'), findsOneWidget);
    expect(find.text('전체 공지'), findsOneWidget);
    expect(find.text('게시 중'), findsNWidgets(2));
    expect(find.text('숨김'), findsNWidgets(2));
    expect(find.text('서비스 점검 안내'), findsOneWidget);
    expect(find.text('여행 스탬프 안내'), findsOneWidget);
  });

  testWidgets('shows an access denied state for a non-admin', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminNoticesProvider.overrideWith(
            (ref) => Future<List<AdminNotice>>.error(
              const ApiException(message: '접근 권한이 없습니다.', statusCode: 403),
            ),
          ),
        ],
        child: const MaterialApp(home: AdminNoticeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('관리자 전용 화면입니다'), findsOneWidget);
    expect(find.text('새 공지'), findsNothing);
  });

  testWidgets('creates a hidden notice from the editor', (tester) async {
    final repository = _FakeAdminNoticeRepository();
    await _pumpScreen(tester, repository: repository);

    await tester.tap(find.byKey(const ValueKey('admin-notice-create-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('admin-notice-title-field')),
      '여름 여행 안내',
    );
    await tester.enterText(
      find.byKey(const ValueKey('admin-notice-content-field')),
      '폭염 시간대를 피해 여행해 주세요.',
    );
    await tester.tap(find.byKey(const ValueKey('admin-notice-save-button')));
    await tester.pumpAndSettle();

    expect(repository.createdTitle, '여름 여행 안내');
    expect(repository.createdPublished, isFalse);
    expect(find.text('여름 여행 안내'), findsOneWidget);
  });

  testWidgets('changes publication through the server repository',
      (tester) async {
    final repository = _FakeAdminNoticeRepository();
    await _pumpScreen(tester, repository: repository);

    await tester.tap(
      find.byKey(const ValueKey('admin-notice-publication-2')),
    );
    await tester.pumpAndSettle();

    expect(repository.changedNoticeId, 2);
    expect(repository.changedPublished, isTrue);
  });

  testWidgets('edits an existing notice from the editor', (tester) async {
    final repository = _FakeAdminNoticeRepository();
    await _pumpScreen(tester, repository: repository);

    await tester.tap(find.byKey(const ValueKey('admin-notice-edit-2')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('admin-notice-title-field')),
      '서비스 점검 시간 변경',
    );
    await tester.tap(find.byKey(const ValueKey('admin-notice-save-button')));
    await tester.pumpAndSettle();

    expect(repository.updatedNoticeId, 2);
    expect(repository.updatedTitle, '서비스 점검 시간 변경');
    expect(find.text('서비스 점검 시간 변경'), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeAdminNoticeRepository repository,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminNoticeRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: AdminNoticeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeAdminNoticeRepository extends AdminNoticeRepository {
  _FakeAdminNoticeRepository() : super(dio: Dio());

  final notices = <AdminNotice>[
    AdminNotice(
      id: 2,
      title: '서비스 점검 안내',
      content: '8월 25일 새벽에 서비스 점검이 진행됩니다.',
      published: false,
      publishedAt: null,
      createdAt: DateTime.utc(2026, 8, 23),
      updatedAt: DateTime.utc(2026, 8, 23),
    ),
    AdminNotice(
      id: 1,
      title: '여행 스탬프 안내',
      content: '관광지 방문 인증 후 패스포트 스탬프를 확인해 주세요.',
      published: true,
      publishedAt: DateTime.utc(2026, 8, 22),
      createdAt: DateTime.utc(2026, 8, 22),
      updatedAt: DateTime.utc(2026, 8, 22),
    ),
  ];

  String? createdTitle;
  bool? createdPublished;
  int? changedNoticeId;
  bool? changedPublished;
  int? updatedNoticeId;
  String? updatedTitle;

  @override
  Future<List<AdminNotice>> fetchNotices() async =>
      List<AdminNotice>.unmodifiable(notices);

  @override
  Future<AdminNotice> createNotice({
    required String title,
    required String content,
    required bool published,
  }) async {
    createdTitle = title;
    createdPublished = published;
    final notice = AdminNotice(
      id: 3,
      title: title,
      content: content,
      published: published,
      publishedAt: published ? DateTime.utc(2026, 8, 23) : null,
      createdAt: DateTime.utc(2026, 8, 23),
      updatedAt: DateTime.utc(2026, 8, 23),
    );
    notices.insert(0, notice);
    return notice;
  }

  @override
  Future<AdminNotice> changePublication({
    required int noticeId,
    required bool published,
  }) async {
    changedNoticeId = noticeId;
    changedPublished = published;
    final index = notices.indexWhere((notice) => notice.id == noticeId);
    final previous = notices[index];
    final updated = AdminNotice(
      id: previous.id,
      title: previous.title,
      content: previous.content,
      published: published,
      publishedAt: published ? DateTime.utc(2026, 8, 23) : null,
      createdAt: previous.createdAt,
      updatedAt: DateTime.utc(2026, 8, 23),
    );
    notices[index] = updated;
    return updated;
  }

  @override
  Future<AdminNotice> updateNotice({
    required int noticeId,
    required String title,
    required String content,
  }) async {
    updatedNoticeId = noticeId;
    updatedTitle = title;
    final index = notices.indexWhere((notice) => notice.id == noticeId);
    final previous = notices[index];
    final updated = AdminNotice(
      id: previous.id,
      title: title,
      content: content,
      published: previous.published,
      publishedAt: previous.publishedAt,
      createdAt: previous.createdAt,
      updatedAt: DateTime.utc(2026, 8, 23),
    );
    notices[index] = updated;
    return updated;
  }
}
