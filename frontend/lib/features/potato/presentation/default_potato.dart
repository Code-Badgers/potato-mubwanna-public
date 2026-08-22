import '../domain/potato_collection.dart';

/// 서버에서 획득한 대표 감자가 없을 때 두 화면이 함께 사용하는 입문 감자다.
///
/// 실제 도감 아이템으로 오인되지 않도록 서버 ID 대신 카드 번호 000에 대응하는
/// 로컬 식별자를 사용한다.
const defaultBeginnerPotato = PotatoCollectionItem(
  id: '0',
  code: 'POTATO_DEFAULT_BEGINNER',
  name: '새싹 감자',
  region: '강원 여행길',
  rarity: PotatoRarity.common,
  description: '아직 여행을 시작하지 않은 작은 감자예요. 첫 스탬프를 찍으면 도감 이야기가 하나씩 열립니다.',
  acquisitionHint: '첫 감자 스팟 방문 전',
  imageUrl: null,
  acquired: false,
  acquiredAt: null,
  level: 1,
  growthDistance: 0,
  growthGoalDistance: 3000,
  representative: false,
);
