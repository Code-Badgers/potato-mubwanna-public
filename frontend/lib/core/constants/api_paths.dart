class ApiPaths {
  const ApiPaths._();

  static const authKakao = '/auth/kakao';
  static const authRefresh = '/auth/refresh';
  static const authLogout = '/auth/logout';
  static const myProfile = '/users/me';
  static const spots = '/spots';
  static String spotDetail(String spotId) => '/spots/$spotId';
  static String spotAudioGuide(String spotId) => '/audio-guides/spots/$spotId';
  static const favoriteSpots = '/me/favorite-spots';
  static const nearbySpots = '/spots/nearby';
  static const stampVerify = '/stamps/verify';
  static const myStamps = '/stamps/me';
  static const stampRewardCheck = '/stamps/rewards/check';
  static const stampRewardClaim = '/stamps/rewards/claim';
  static const missions = '/missions';
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
