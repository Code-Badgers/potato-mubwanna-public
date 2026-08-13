import '../domain/mission_challenge.dart';

class MissionJumsooniDialogue {
  const MissionJumsooniDialogue._();

  static const featured = [
    '오늘 가볍게 다녀오기 좋은 곳이에요',
    '내가 괜찮은 곳으로 골라뒀어요',
    '천천히 둘러보고 오면 딱 좋아요',
  ];

  static const quizSuccess = [
    '맞혔네요\n감자 하나 챙겨둘게요',
    '좋아요\n오늘 감자 지식이 늘었네요',
    '잘 골랐어요\n보상도 챙겨가요',
  ];

  static const complete = [
    '오늘도 잘 다녀왔네요\n감자 하나 챙겨요',
    '좋아요\n여행 기록에 남겨둘게요',
    '수고했어요\n다음 길도 같이 가봐요',
  ];

  static String dailyLine(MissionChallenge mission) {
    return switch (mission.type) {
      MissionType.visitAndStep => '천천히 걸으면\n감자도 같이 자라요',
      MissionType.photo || MissionType.photoOcr => '지금 풍경은\n사진으로 남겨도 좋겠어요',
      MissionType.qrScan => '근처에 작은 표식이 있어요\n찾아볼래요?',
      MissionType.quiz => '강원도 이야기를\n하나만 풀어볼까요?',
      _ => '내가 골라둔 곳이에요\n가볍게 들러봐요',
    };
  }

  static String detail(MissionChallenge mission) {
    return switch (mission.type) {
      MissionType.photo || MissionType.photoOcr => '이 장면은\n사진으로 남겨도 좋겠어요',
      MissionType.quiz => '강원도 이야기를\n짧게 풀어볼까요?',
      MissionType.visitAndStep => '조금 걸어보면\n여행길이 더 선명해져요',
      MissionType.qrScan => '근처 표식을\n천천히 찾아봐요',
      MissionType.visit || MissionType.stamp => '여기까지 왔으니\n기록 하나 남겨봐요',
      _ => '내가 골라둔 곳이에요\n가볍게 들러봐요',
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
