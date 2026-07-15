class ApiPaths {
  const ApiPaths._();

  static const authKakao = '/auth/kakao';
  static const authRefresh = '/auth/refresh';
  static const authLogout = '/auth/logout';
  static const myProfile = '/users/me';
  static const spots = '/spots';
  static const favoriteSpots = '/me/favorite-spots';
  static const nearbySpots = '/spots/nearby';
  static const stampVerify = '/stamps/verify';
  static const myStamps = '/stamps/me';
  static const stampRewardCheck = '/stamps/rewards/check';
  static const missions = '/missions';
  static const potatoes = '/potatoes';
  static const myPotatoes = '/potatoes/me';
  static const myCoupons = '/coupons/me';
  static String couponDetail(int userCouponId) => '/coupons/$userCouponId';
}
