import 'mission_challenge.dart';

enum MissionVerificationStatus {
  ready,
  blocked,
}

class MissionVerificationResult {
  const MissionVerificationResult._({
    required this.status,
    required this.message,
  });

  const MissionVerificationResult.ready()
      : this._(
          status: MissionVerificationStatus.ready,
          message: '',
        );

  const MissionVerificationResult.blocked(String message)
      : this._(
          status: MissionVerificationStatus.blocked,
          message: message,
        );

  final MissionVerificationStatus status;
  final String message;

  bool get canComplete => status == MissionVerificationStatus.ready;
}

class MissionVerificationService {
  const MissionVerificationService();

  MissionVerificationResult verifyQuizAnswer({
    required MissionChallenge mission,
    required String selectedAnswer,
  }) {
    if (selectedAnswer != quizCorrectAnswer(mission)) {
      return const MissionVerificationResult.blocked('정답이 틀렸습니다. 다시 풀어주세요.');
    }
    return const MissionVerificationResult.ready();
  }

  MissionVerificationResult verifyStepProgress(MissionChallenge mission) {
    if (mission.progress < mission.target) {
      return const MissionVerificationResult.blocked('걸음을 다 채우고 재시도해주세요.');
    }
    return const MissionVerificationResult.ready();
  }

  MissionVerificationResult verifyPhotoUpload({
    required MissionChallenge mission,
    required bool uploaded,
  }) {
    if (!uploaded) {
      return const MissionVerificationResult.blocked('이미지를 업로드한 뒤 다시 시도해주세요.');
    }
    return const MissionVerificationResult.ready();
  }

  List<String> quizOptions(MissionChallenge mission) {
    final answer = quizCorrectAnswer(mission);
    return [
      answer,
      '옥수수감자',
      '메밀감자',
    ]..shuffle();
  }

  String quizCorrectAnswer(MissionChallenge mission) {
    if (mission.title.contains('곤드레')) {
      return '곤드레감자';
    }
    return '감자';
  }
}
