import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/mission/application/mission_controller.dart';
import 'package:potato_mubwanna/features/mission/data/mission_repository.dart';
import 'package:potato_mubwanna/features/mission/domain/mission_challenge.dart';

void main() {
  test('미션 조회 전에 최신 걸음 동기화를 실행한다', () async {
    final operations = <String>[];
    final controller = MissionController(
      _FakeMissionRepository(
        _itemMission,
        onFetch: () => operations.add('fetch'),
      ),
      beforeLoad: () async => operations.add('sync'),
    );

    await controller.load();

    expect(operations, ['sync', 'fetch']);
  });

  test('쿠폰 보상 미션 완료 후 쿠폰 목록 갱신을 요청한다', () async {
    var refreshCount = 0;
    final controller = MissionController(
      _FakeMissionRepository(_couponMission),
      onCouponReward: () => refreshCount += 1,
    );
    await controller.load();

    final completed = await controller.complete(
      _couponMission.id,
      const MissionVerificationPayload(type: MissionType.visit),
    );

    expect(completed.status, MissionStatus.completed);
    expect(refreshCount, 1);
  });

  test('쿠폰이 아닌 보상은 쿠폰 목록 갱신을 요청하지 않는다', () async {
    var refreshCount = 0;
    final controller = MissionController(
      _FakeMissionRepository(_itemMission),
      onCouponReward: () => refreshCount += 1,
    );
    await controller.load();

    await controller.complete(
      _itemMission.id,
      const MissionVerificationPayload(type: MissionType.visit),
    );

    expect(refreshCount, 0);
  });
}

class _FakeMissionRepository extends MissionRepository {
  _FakeMissionRepository(this.mission, {this.onFetch}) : super(dio: Dio());

  final MissionChallenge mission;
  final void Function()? onFetch;

  @override
  Future<List<MissionChallenge>> fetchMissions() async {
    onFetch?.call();
    return [mission];
  }

  @override
  Future<MissionCompletionResult> verifyMission(
    String missionId,
    MissionVerificationPayload payload,
  ) async {
    return MissionCompletionResult(
      id: missionId,
      rewardType: mission.rewardType,
      rewardLabel: mission.rewardLabel,
    );
  }
}

const _couponMission = MissionChallenge(
  id: '8',
  group: MissionGroup.event,
  type: MissionType.visit,
  status: MissionStatus.ready,
  title: '화천 감자 축제 방문',
  spotName: '화천 감자 축제',
  cityName: '화천군',
  description: '축제 현장을 방문하세요.',
  dialogue: '축제날 감자는 그냥 지나치면 섭섭하지.',
  conditionLabel: '방문 인증 1회',
  rewardType: MissionRewardType.coupon,
  rewardLabel: '지역 쿠폰 1장',
  progress: 0,
  target: 1,
);

const _itemMission = MissionChallenge(
  id: '1',
  group: MissionGroup.jumsooni,
  type: MissionType.visit,
  status: MissionStatus.ready,
  title: '감자 미션',
  spotName: '감자밭',
  cityName: '강원도',
  description: '감자밭을 방문하세요.',
  dialogue: '어서 오게.',
  conditionLabel: '방문 인증 1회',
  rewardType: MissionRewardType.item,
  rewardLabel: '황금감자 성장 아이템',
  progress: 0,
  target: 1,
);
