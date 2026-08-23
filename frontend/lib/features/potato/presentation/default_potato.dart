import '../domain/potato_collection.dart';

/// 서버 기본 감자 카탈로그와 동일한 로컬 표시 정보다.
///
/// 정상 로그인 상태에서는 서버가 실제 소유 데이터와 함께 내려주며, 이 값은
/// 네트워크 응답 전의 이미지·문구 일관성을 위해서만 사용한다.
const defaultBeginnerPotato = PotatoCollectionItem(
  id: '0',
  code: 'POTATO_DEFAULT_BEGINNER',
  name: '새싹 감자',
  region: '강원 여행길',
  rarity: PotatoRarity.common,
  description: '강원 여행을 시작한 모든 사용자에게 지급되는 첫 감자예요. 돌봄과 걸음으로 함께 키워 보세요.',
  acquisitionHint: '회원가입 시 기본 지급',
  imageUrl: null,
  acquired: false,
  acquiredAt: null,
  level: 1,
  growthDistance: 0,
  growthGoalDistance: 3000,
  representative: false,
);
