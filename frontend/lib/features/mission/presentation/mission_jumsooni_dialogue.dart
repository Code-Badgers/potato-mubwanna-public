import '../domain/mission_challenge.dart';

class MissionJumsooniDialogue {
  const MissionJumsooniDialogue._();

  static const featured = [
    '이건 내가 특별히 고른 거예요\n한번 해봐요',
    '그냥 지나가긴 아깝죠\n내가 골라뒀어요',
    '이 정도 미션은 할 만하죠?\n한번 가봐요',
  ];

  static const quizSuccess = [
    '흥, 제법인데요?\n약속대로 감자 줄게요',
    '맞혔네요\n이 정도는 알아야죠',
    '생각보다 잘하네요\n감자 하나 챙겨요',
  ];

  static const complete = [
    '흥, 제법인데요?\n약속대로 감자 줄게요',
    '오늘 건 잘했어요\n감자 하나 챙겨요',
    '이 정도면 봐줄 만하네요\n수고했어요',
  ];

  static String dailyLine(MissionChallenge mission) {
    return switch (mission.type) {
      MissionType.visitAndStep => '벌써 쉬려고요?\n감자가 기다리는데요',
      MissionType.photo || MissionType.photoOcr => '보고만 가면 아깝잖아요\n사진 한 장 남겨요',
      MissionType.qrScan => '내가 숨겨둔 표식이에요\n찾아볼래요?',
      MissionType.quiz => '강원도 왔으면\n이 정도는 알아야죠',
      _ => '내가 골라둔 곳이에요\n한번 가봐요',
    };
  }

  static String detail(MissionChallenge mission) {
    return switch (mission.type) {
      MissionType.photo || MissionType.photoOcr => '보고만 가면 아깝잖아요\n사진 한 장 남겨요',
      MissionType.quiz => '강원도 구경 왔으면\n이 정도는 알아야죠',
      MissionType.visitAndStep => '벌써 쉬려고요?\n감자가 기다리는데요',
      MissionType.qrScan => '내가 숨겨둔 표식이에요\n찾아볼래요?',
      MissionType.visit || MissionType.stamp => '여기까지 왔는데\n그냥 갈 건가요?',
      _ => '내가 골라둔 곳이에요\n한번 가봐요',
    };
  }

  static String pick(List<String> values, String seed) {
    if (values.isEmpty) {
      return '';
    }
    final index = seed.codeUnits.fold<int>(0, (sum, code) => sum + code);
    return values[index % values.length];
  }
}
