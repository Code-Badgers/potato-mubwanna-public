import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/mission/domain/mission_challenge.dart';
import 'package:potato_mubwanna/features/mission/domain/mission_verification.dart';

void main() {
  const service = MissionVerificationService();

  test('blocks quiz completion when answer is wrong', () {
    final result = service.verifyQuizAnswer(
      mission: _quizMission,
      selectedAnswer: '옥수수감자',
    );

    expect(result.canComplete, isFalse);
    expect(result.message, '정답이 틀렸습니다. 다시 풀어주세요.');
  });

  test('allows quiz completion when answer is correct', () {
    final result = service.verifyQuizAnswer(
      mission: _quizMission,
      selectedAnswer: '곤드레감자',
    );

    expect(result.canComplete, isTrue);
  });

  test('blocks step mission until target progress is reached', () {
    final result = service.verifyStepProgress(_stepMission);

    expect(result.canComplete, isFalse);
    expect(result.message, '걸음을 다 채우고 재시도해주세요.');
  });

  test('allows step mission when target progress is reached', () {
    final result = service.verifyStepProgress(
      _stepMission.copyWith(progress: 10000),
    );

    expect(result.canComplete, isTrue);
  });

  test('blocks photo mission without uploaded image', () {
    final result = service.verifyPhotoUpload(
      mission: _photoMission,
      uploaded: false,
    );

    expect(result.canComplete, isFalse);
    expect(result.message, '이미지를 업로드한 뒤 다시 시도해주세요.');
  });
}

const _quizMission = MissionChallenge(
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
);

const _stepMission = MissionChallenge(
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
);

const _photoMission = MissionChallenge(
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
);
