import 'feature_tour_overlay.dart';
import 'feature_tour_targets.dart';

abstract final class FeatureTourIds {
  static const map = 'map-v9';
  static const stamp = 'stamp-v7';
  static const passport = 'passport-v6';
  static const potato = 'potato-v7';
  static const mission = 'mission-v5';
  static const spot = 'spot-v3';
  static const myPage = 'my-page-v4';
  static const travelRecord = 'travel-record-v3';
}

abstract final class FeatureTourDefinitions {
  static final map = <FeatureTourStep>[
    FeatureTourStep(
      targetKey: FeatureTourTargets.mapDiscovery,
      title: '강원도에서 오늘 갈 곳을 찾아보세요',
      description: '추천 장소와 여행 코스를 한눈에 볼 수 있어요.',
    ),
    FeatureTourStep(
      targetKey: FeatureTourTargets.mapCourseCard,
      title: '취향에 맞는 코스를 골라보세요',
      description: '카드를 눌러 오늘의 여행 이야기를 펼쳐볼 수 있어요.',
      advanceType: CoachMarkAdvanceType.targetTap,
      interactionHint: '코스 카드를 눌러보세요',
    ),
    FeatureTourStep(
      targetKey: FeatureTourTargets.mapGoodNowCard,
      title: '지금 가기 좋은 곳도 살펴보세요',
      description: '마음에 드는 장소를 누르면 지도에서 바로 확인할 수 있어요.',
      advanceType: CoachMarkAdvanceType.targetTap,
      interactionHint: '장소 카드를 눌러보세요',
    ),
    FeatureTourStep(
      targetKey: FeatureTourTargets.mapFullView,
      title: '지도를 크게 열어보세요',
      description: '장소 마커를 직접 눌러 자세히 살펴볼 수 있어요.',
      advanceType: CoachMarkAdvanceType.targetTap,
      interactionHint: '지도 크게 보기 버튼을 눌러보세요',
    ),
    FeatureTourStep(
      targetKey: FeatureTourTargets.mapMarker,
      title: '궁금한 장소를 눌러보세요',
      description: '장소를 고르면 방문 인증과 상세 정보를 확인할 수 있어요.',
      advanceType: CoachMarkAdvanceType.targetTap,
      interactionHint: '지도에서 마커를 눌러보세요',
      cardPlacement: FeatureTourCardPlacement.aboveFooter,
    ),
    FeatureTourStep(
      targetKey: FeatureTourTargets.spotSheetHandle,
      title: '카드를 위로 올려보세요',
      description: '사진과 운영 정보를 더 자세히 볼 수 있어요.',
      advanceType: CoachMarkAdvanceType.swipeUp,
      interactionHint: '카드를 위로 올려보세요',
    ),
    FeatureTourStep(
      targetKey: FeatureTourTargets.routeMode,
      title: '마음에 드는 곳은 내 동선에 담아보세요',
      description: '담은 장소만 모아보고 여행 순서도 확인할 수 있어요.',
      advanceType: CoachMarkAdvanceType.targetTap,
      interactionHint: '내 동선 버튼을 눌러보세요',
    ),
  ];

  static final stamp = <FeatureTourStep>[
    FeatureTourStep(
      targetKey: FeatureTourTargets.stampMap,
      title: '스탬프를 찍을 장소를 찾아보세요',
      description: '지도의 깃발을 누르면 방문 인증으로 이어져요.',
    ),
    FeatureTourStep(
      targetKey: FeatureTourTargets.passportButton,
      title: '패스포트를 열어보세요',
      description: '모은 여행 도장을 패스포트에서 한눈에 볼 수 있어요.',
      advanceType: CoachMarkAdvanceType.targetTap,
      interactionHint: '패스포트 버튼을 눌러보세요',
    ),
    FeatureTourStep(
      targetKey: FeatureTourTargets.stampMarker,
      title: '마음에 드는 명소를 눌러보세요',
      description: '명소를 선택해 방문 인증을 시작할 수 있어요.',
      advanceType: CoachMarkAdvanceType.targetTap,
      interactionHint: '지도에서 깃발을 눌러보세요',
    ),
    FeatureTourStep(
      targetKey: FeatureTourTargets.stampVisit,
      title: '방문 인증을 남겨보세요',
      description: '현장에서 인증하면 스탬프를 얻고, 명소의 관광 오디오 해설도 들을 수 있어요.',
      advanceType: CoachMarkAdvanceType.targetTap,
      interactionHint: '방문 인증하기를 눌러보세요',
    ),
  ];

  static final passport = <FeatureTourStep>[
    FeatureTourStep(
      targetKey: FeatureTourTargets.passportBook,
      title: '방문 인증한 도장이 여기에 채워져요',
      description: '스탬프를 찍으면 이 패스포트에 여행 도장이 하나씩 표시돼요.',
    ),
  ];

  static final potato = <FeatureTourStep>[
    FeatureTourStep(
      targetKey: FeatureTourTargets.potatoGrowth,
      title: '감자밭에서 감자를 키워보세요',
      description: '대표 감자의 현재 상태를 한눈에 확인할 수 있어요.',
    ),
    FeatureTourStep(
      targetKey: FeatureTourTargets.potatoCareActions,
      title: '감자를 돌봐보세요',
      description: '돌봄 버튼을 누르면 감자의 상태가 달라져요.',
      advanceType: CoachMarkAdvanceType.targetTap,
      interactionHint: '돌봄 버튼을 눌러보세요',
    ),
    FeatureTourStep(
      targetKey: FeatureTourTargets.potatoInfo,
      title: '감자 정보를 확인해보세요',
      description: '현재 감자의 이야기와 성장 정보를 자세히 볼 수 있어요.',
      advanceType: CoachMarkAdvanceType.navigationResult,
      interactionHint: '정보 보기를 눌러보세요',
    ),
    FeatureTourStep(
      targetKey: FeatureTourTargets.representativePotato,
      title: '대표 감자를 바꿔보세요',
      description: '도감에서 원하는 감자를 대표로 설정할 수 있어요.',
      advanceType: CoachMarkAdvanceType.navigationResult,
      interactionHint: '대표 감자 변경을 눌러보세요',
    ),
  ];

  static final mission = <FeatureTourStep>[
    FeatureTourStep(
      targetKey: FeatureTourTargets.missionFeatured,
      fallbackTargetKey: FeatureTourTargets.missionDaily,
      title: '오늘의 미션을 골라보세요',
      description: '하나를 눌러 미션 방법과 인증 흐름을 확인해보세요.',
      advanceType: CoachMarkAdvanceType.targetTap,
      interactionHint: '미션 카드를 눌러보세요',
    ),
    FeatureTourStep(
      targetKey: FeatureTourTargets.missionDetailAction,
      title: '하단 버튼으로 미션을 시작해요',
      description: '미션 유형에 맞는 인증을 마치면 오늘의 기록에 남아요.',
    ),
  ];

  static final spot = <FeatureTourStep>[
    FeatureTourStep(
      targetKey: FeatureTourTargets.audioPlay,
      title: '관광 해설을 들어보세요',
      description: '명소 이야기를 들은 뒤 방문 인증을 마치면 스탬프가 패스포트에 기록돼요.',
      advanceType: CoachMarkAdvanceType.targetTap,
      interactionHint: '재생 버튼을 눌러보세요',
    ),
    FeatureTourStep(
      targetKey: FeatureTourTargets.visitVerify,
      title: '방문 인증을 남겨보세요',
      description: '현장에서 인증하면 이 명소의 스탬프를 얻고 패스포트에 기록돼요.',
      advanceType: CoachMarkAdvanceType.targetTap,
      interactionHint: '방문 인증하기를 눌러보세요',
    ),
  ];

  static final myPage = <FeatureTourStep>[
    FeatureTourStep(
      targetKey: FeatureTourTargets.myPageTravelRecord,
      title: '여행 기록을 모아보세요',
      description: '스탬프와 미션으로 남긴 사진을 여행 기록에서 다시 볼 수 있어요.',
      advanceType: CoachMarkAdvanceType.targetTap,
      interactionHint: '여행 기록을 눌러보세요',
    ),
  ];

  static final travelRecord = <FeatureTourStep>[
    FeatureTourStep(
      targetKey: FeatureTourTargets.travelRecordGallery,
      title: '여행 사진을 한곳에 모아보세요',
      description: '스탬프와 미션으로 남긴 사진이 여행 기록에 차곡차곡 쌓여요.',
    ),
  ];
}
