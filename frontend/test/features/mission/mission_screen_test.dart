import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/network/api_exception.dart';
import 'package:potato_mubwanna/features/mission/application/mission_controller.dart';
import 'package:potato_mubwanna/features/mission/data/mission_repository.dart';
import 'package:potato_mubwanna/features/mission/domain/mission_challenge.dart';
import 'package:potato_mubwanna/features/mission/presentation/screen/mission_screen.dart';

void main() {
  testWidgets('renders mission list and category filters', (tester) async {
    await _pumpMissionScreen(tester);

    expect(find.text('미션'), findsOneWidget);
    expect(find.text('점순이와 함께 도전해요'), findsOneWidget);
    expect(find.text('안목 해변에서 하지감자 찾기'), findsOneWidget);
    expect(find.text('점순이'), findsNothing);
    expect(find.text('일일'), findsOneWidget);
    expect(find.text('주간'), findsOneWidget);
    expect(find.text('이벤트'), findsOneWidget);

    await tester.tap(find.text('일일').first);
    await tester.pumpAndSettle();

    expect(find.text('정선 5일장 곤드레 퀴즈'), findsNothing);
    expect(find.text('10,000걸음 걷기'), findsOneWidget);

    await tester.tap(find.text('전체').first);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('10,000걸음 걷기'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('10,000걸음 걷기'), findsOneWidget);
  });

  testWidgets('opens mission detail and updates completion state',
      (tester) async {
    await _pumpMissionScreen(tester);

    await _openMission(tester, '정선 5일장 곤드레 퀴즈');

    expect(find.text('점순이의 미션'), findsOneWidget);
    expect(find.text('퀴즈 풀기'), findsOneWidget);
    expect(find.textContaining('황금감자 성장 아이템'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '퀴즈 풀기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('곤드레감자'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '정답 제출하기'));
    await tester.pumpAndSettle();

    expect(find.text('미션 완료!'), findsOneWidget);
    expect(find.text('황금감자 성장 아이템을 획득했어요.'), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    final completedButton = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, '완료된 미션'));
    expect(completedButton.onPressed, isNull);
  });

  testWidgets('does not complete quiz mission when selected answer is wrong',
      (tester) async {
    final repository = _FakeMissionRepository();
    await _pumpMissionScreen(tester, repository: repository);

    await _openMission(tester, '정선 5일장 곤드레 퀴즈');

    await tester.tap(find.widgetWithText(FilledButton, '퀴즈 풀기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('옥수수감자'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '정답 제출하기'));
    await tester.pumpAndSettle();

    expect(find.text('정답이 틀렸습니다. 다시 풀어주세요.'), findsOneWidget);
    expect(find.text('미션 완료!'), findsNothing);
    expect(repository.completeCallCount, 1);
  });

  testWidgets('does not complete step mission before target progress',
      (tester) async {
    final repository = _FakeMissionRepository();
    await _pumpMissionScreen(tester, repository: repository);

    await tester.tap(find.text('일일').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('10,000걸음 걷기'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '걸음 인증하기'));
    await tester.pumpAndSettle();

    expect(find.text('걸음을 다 채우고 재시도해주세요.'), findsOneWidget);
    expect(find.text('미션 완료!'), findsNothing);
    expect(repository.completeCallCount, 1);
  });

  testWidgets('completes photo mission after selecting upload source',
      (tester) async {
    final repository = _FakeMissionRepository();
    await _pumpMissionScreen(tester, repository: repository);

    await _openMission(tester, '안목 해변에서 하지감자 찾기');

    await tester.tap(find.widgetWithText(FilledButton, '촬영 인증하기'));
    await tester.pumpAndSettle();
    expect(find.text('카메라로 촬영하기'), findsOneWidget);
    expect(find.text('갤러리에서 선택하기'), findsOneWidget);

    await tester.tap(find.text('갤러리에서 선택하기'));
    await tester.pumpAndSettle();
    expect(find.text('갤러리 선택 이미지'), findsOneWidget);
    expect(find.text('업로드 준비 완료'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '인증 완료하기'));
    await tester.pumpAndSettle();

    expect(find.text('미션 완료!'), findsOneWidget);
    expect(repository.completeCallCount, 1);
  });

  testWidgets('shows failure message when completion API rejects',
      (tester) async {
    await _pumpMissionScreen(
      tester,
      repository: _FakeMissionRepository(
        completeError: const ApiException(
          message: '이미 완료한 미션입니다.',
          statusCode: 409,
        ),
      ),
    );

    await _openMission(tester, '정선 5일장 곤드레 퀴즈');

    await tester.tap(find.widgetWithText(FilledButton, '퀴즈 풀기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('곤드레감자'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '정답 제출하기'));
    await tester.pumpAndSettle();

    expect(find.text('이미 완료한 미션입니다.'), findsOneWidget);
    expect(find.text('미션 완료!'), findsNothing);
  });

  testWidgets('prevents duplicate completion requests while submitting',
      (tester) async {
    final repository = _FakeMissionRepository(
      completeDelay: const Duration(milliseconds: 120),
    );
    await _pumpMissionScreen(tester, repository: repository);

    await _openMission(tester, '시군 2곳 방문하기');

    await tester.tap(find.widgetWithText(FilledButton, '미션 인증하기'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '미션 인증하기'));
    await tester.pumpAndSettle();

    expect(repository.completeCallCount, 1);
    expect(find.text('미션 완료!'), findsOneWidget);
  });

  testWidgets('disables completion action for completed missions',
      (tester) async {
    await _pumpMissionScreen(tester);

    await tester.tap(find.text('일일').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('스탬프 1개 획득하기'));
    await tester.pumpAndSettle();

    final completedButton = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, '완료된 미션'));
    expect(completedButton.onPressed, isNull);

    await tester.tap(find.widgetWithText(FilledButton, '완료된 미션'));
    await tester.pumpAndSettle();

    expect(find.text('미션 완료!'), findsNothing);
  });

  testWidgets('sorts completed missions below actionable missions',
      (tester) async {
    await _pumpMissionScreen(tester);

    await tester.tap(find.text('일일').first);
    await tester.pumpAndSettle();

    final stepTop = tester.getTopLeft(find.text('10,000걸음 걷기')).dy;
    final completedTop = tester.getTopLeft(find.text('스탬프 1개 획득하기')).dy;
    expect(stepTop, lessThan(completedTop));
  });
}

Future<void> _pumpMissionScreen(
  WidgetTester tester, {
  MissionRepository? repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        missionRepositoryProvider.overrideWithValue(
          repository ?? _FakeMissionRepository(),
        ),
      ],
      child: const MaterialApp(home: MissionScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openMission(WidgetTester tester, String title) async {
  await tester.scrollUntilVisible(
    find.text(title),
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.text(title));
  await tester.pumpAndSettle();
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

class _FakeMissionRepository extends MissionRepository {
  _FakeMissionRepository({
    this.completeError,
    this.completeDelay = Duration.zero,
  }) : super(dio: Dio());

  final Object? completeError;
  final Duration completeDelay;
  int completeCallCount = 0;

  @override
  Future<List<MissionChallenge>> fetchMissions() async => _missions;

  @override
  Future<MissionCompletionResult> verifyMission(
    String missionId,
    MissionVerificationPayload payload,
  ) async {
    completeCallCount += 1;
    if (completeDelay > Duration.zero) {
      await Future<void>.delayed(completeDelay);
    }
    final error = completeError;
    if (error != null) {
      throw error;
    }
    final mission = _missions.firstWhere((mission) => mission.id == missionId);
    if (mission.type == MissionType.quiz && payload.answer != '곤드레감자') {
      throw const ApiException(message: '정답이 틀렸습니다. 다시 풀어주세요.');
    }
    if (mission.type == MissionType.visitAndStep &&
        (payload.stepCount ?? 0) < mission.target) {
      throw const ApiException(message: '걸음을 다 채우고 재시도해주세요.');
    }
    return MissionCompletionResult(
      id: mission.id,
      rewardType: mission.rewardType,
      rewardLabel: mission.rewardLabel,
    );
  }
}

const _missions = [
  MissionChallenge(
    id: '1004',
    group: MissionGroup.jumsooni,
    type: MissionType.quiz,
    status: MissionStatus.ready,
    title: '정선 5일장 곤드레 퀴즈',
    spotName: '정선 5일장',
    cityName: '정선군',
    description: '정선 장터에서 점순이가 내는 향토 음식 퀴즈를 풀어보세요.',
    dialogue: '곤드레감자가 뭔지도 모르는 눈치네?',
    conditionLabel: '정선 5일장 방문 후 퀴즈 정답 맞히기',
    rewardType: MissionRewardType.item,
    rewardLabel: '황금감자 성장 아이템',
    progress: 0,
    target: 1,
    isNew: true,
  ),
  MissionChallenge(
    id: '1002',
    group: MissionGroup.jumsooni,
    type: MissionType.photoOcr,
    status: MissionStatus.ready,
    title: '안목 해변에서 하지감자 찾기',
    spotName: '안목 커피거리',
    cityName: '강릉시',
    description: '안목 커피거리 가맹점 매장 영수증 또는 간판을 촬영하세요.',
    dialogue: '여가 그 유명한 안목 커피거리다 얘!',
    conditionLabel: '영수증 또는 간판 사진 인증',
    rewardType: MissionRewardType.potato,
    rewardLabel: '하지감자 씨앗',
    progress: 0,
    target: 1,
  ),
  MissionChallenge(
    id: 'daily-steps',
    group: MissionGroup.daily,
    type: MissionType.visitAndStep,
    status: MissionStatus.inProgress,
    title: '10,000걸음 걷기',
    spotName: '강원도 전역',
    cityName: '오늘의 감자걸음',
    description: '오늘 하루 동안 10,000걸음을 채워 감자 코인을 받아보세요.',
    dialogue: '오늘도 발바닥에 흙 좀 묻혀야 감자맛 나는 여행이지 않겠나 얘!',
    conditionLabel: '오늘 10,000걸음 달성',
    rewardType: MissionRewardType.coin,
    rewardLabel: '감자 코인 x2',
    progress: 7642,
    target: 10000,
  ),
  MissionChallenge(
    id: 'daily-stamp',
    group: MissionGroup.daily,
    type: MissionType.stamp,
    status: MissionStatus.completed,
    title: '스탬프 1개 획득하기',
    spotName: '방문 인증',
    cityName: '일일 미션',
    description: '오늘 방문 인증으로 스탬프를 1개 획득했습니다.',
    dialogue: '도장 하나 콕 찍었으니 오늘 여행은 벌써 반은 성공이다 마!',
    conditionLabel: '하루 스탬프 1개 획득',
    rewardType: MissionRewardType.coin,
    rewardLabel: '감자 코인 x1',
    progress: 1,
    target: 1,
  ),
  MissionChallenge(
    id: 'weekly-cities',
    group: MissionGroup.weekly,
    type: MissionType.visit,
    status: MissionStatus.inProgress,
    title: '시군 2곳 방문하기',
    spotName: '강원도 시군',
    cityName: '주간 미션',
    description: '이번 주 서로 다른 시군 2곳을 방문해보세요.',
    dialogue: '이번 주엔 두 군데 찍고 오자!',
    conditionLabel: '서로 다른 시군 2곳 방문',
    rewardType: MissionRewardType.coin,
    rewardLabel: '감자 코인 x5',
    progress: 1,
    target: 2,
  ),
  MissionChallenge(
    id: 'event-hwacheon',
    group: MissionGroup.event,
    type: MissionType.qrScan,
    status: MissionStatus.locked,
    title: '[시즌 한정] 얼음나라 산천어 미션',
    spotName: '화천천 산천어 축제장',
    cityName: '화천군',
    description: '겨울 축제 기간에만 열리는 QR 스캔 미션입니다.',
    dialogue: '축제장 한가운데 종합 안내소에 QR 판넬을 세워뒀다 마!',
    conditionLabel: '1월 축제 시즌 QR 코드 스캔',
    rewardType: MissionRewardType.coupon,
    rewardLabel: '산천어 구이 교환권',
    progress: 0,
    target: 1,
    active: false,
  ),
];
