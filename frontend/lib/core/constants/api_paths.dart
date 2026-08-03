class ApiPaths {
  const ApiPaths._();

  static const authKakao = '/auth/kakao';
  static const authKakaoCode = '/auth/kakao/code';
  static const authRefresh = '/auth/refresh';
  static const authLogout = '/auth/logout';
  static const myProfile = '/users/me';
  static const myActivitySummary = '/users/me/activity-summary';
  static const myVisits = '/users/me/visits';
  static const myPushTokens = '/users/me/push-tokens';
  static const spots = '/spots';
  static String spotDetail(String spotId) => '/spots/$spotId';
  static String spotRecommendations(String spotId) =>
      '/spots/$spotId/recommendations';
  static String spotAudioGuide(String spotId) => '/audio-guides/spots/$spotId';
  static const favoriteSpots = '/me/favorite-spots';
  static const favoriteSpotRoute = '/me/favorite-spots/route';
  static const nearbySpots = '/spots/nearby';
  static const visitVerify = '/visits/verify';
  static const stampVerify = '/stamps/verify';
  static const myStamps = '/stamps/me';
  static const stampNextTargets = '/stamps/me/next-targets';
  static const stampRallybookSpots = '/stamps/rallybook-spots';
  static const stampRewardCheck = '/stamps/rewards/check';
  static const stampRewardClaim = '/stamps/rewards/claim';
  static const missions = '/missions';
  static const missionUploads = '/mission-uploads';
  static const potatoes = '/potatoes';
  static const myPotatoes = '/potatoes/me';
  static const potatoGrowthSummary = '/potatoes/me/growth-summary';
  static const potatoDailyActivity = '/potatoes/me/activity/daily';
  static const representativePotato = '/potatoes/me/representative';
  static const myCoupons = '/coupons/me';
  static String couponDetail(int userCouponId) => '/coupons/$userCouponId';
  static String couponQr(int userCouponId) => '/coupons/$userCouponId/qr';
  static String couponUse(int userCouponId) => '/coupons/$userCouponId/use';
  static const rewardHistory = '/rewards/history';
}
