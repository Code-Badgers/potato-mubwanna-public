import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/mission/domain/mission_challenge.dart';
import 'package:potato_mubwanna/features/mission/data/mission_repository.dart';
import 'package:potato_mubwanna/features/mission/presentation/mission_jumsooni_dialogue.dart';

void main() {
  test('server completion and period timestamps are preserved in Korean time', () {
    final mission = MissionChallenge.fromJson({
      'completed': true, 'group': 'DAILY', 'type': 'STAMP',
      'completedAt': '2026-09-10T15:01:00Z',
      'periodStartsAt': '2026-09-10T15:00:00Z',
      'periodEndsAt': '2026-09-11T15:00:00Z',
    });
    expect(mission.completionTimeLabel, '완료 처리: 2026.09.11 00:01 (한국 시간)');
    expect(mission.completionEvidenceLabel, '완료 기준: 스탬프 획득 기록');
    expect(mission.evidencePeriodLabel, contains('2026.09.12 00:00 미만'));
    expect(mission.copyWith(progress: 1).completedAt, mission.completedAt);
    expect(mission.copyWith(progress: 1).periodEndsAt, mission.periodEndsAt);
  });

  test('missing timestamps are not replaced with the device clock', () {
    final mission = MissionChallenge.fromJson({'completed': true, 'type': 'PHOTO'});
    expect(mission.completionTimeLabel, isNull);
    expect(mission.evidencePeriodLabel, isNull);
    expect(mission.completionEvidenceLabel, '완료 기준: 사진 인증');
    expect(MissionChallenge.fromJson({'completed': false}).completionEvidenceLabel, isNull);
  });

  test('verification response supplies the server completion time', () {
    final result = MissionCompletionResult.fromJson({'completedAt': '2026-09-11T01:00:00Z'});
    expect(result.completedAt, DateTime.utc(2026, 9, 11, 1));
  });

  test('special mission uses the supplied local story', () {
    final mission = MissionChallenge.fromJson({'group': 'JUMSOONI', 'dialogue': '이 미술관에서 그림 속 마을을 찾아봐요.'});
    expect(MissionJumsooniDialogue.detail(mission), mission.dialogue);
  });
}
