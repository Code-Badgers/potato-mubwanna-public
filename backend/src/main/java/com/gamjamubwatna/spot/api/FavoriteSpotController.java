package com.gamjamubwatna.spot.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.spot.application.FavoriteSpotService;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/me/favorite-spots")
public class FavoriteSpotController {

    private final FavoriteSpotService favoriteSpotService;

    public FavoriteSpotController(FavoriteSpotService favoriteSpotService) {
        this.favoriteSpotService = favoriteSpotService;
    }

    // 지도 탭 진입 시 로그인 사용자의 저장된 감자 동선을 복원한다.
    @GetMapping
    public AuthApiResponse<List<FavoriteSpotResponse>> getFavoriteSpots(Authentication authentication) {
        return AuthApiResponse.success(favoriteSpotService.getFavoriteSpots(currentUserId(authentication)));
    }

    // 저장된 감자 스팟을 지도 Polyline과 내 동선 바텀시트에서 사용할 순서형 경로로 변환한다.
    @GetMapping("/route")
    public AuthApiResponse<FavoriteSpotRouteResponse> getFavoriteSpotRoute(Authentication authentication) {
        return AuthApiResponse.success(favoriteSpotService.getFavoriteSpotRoute(currentUserId(authentication)));
    }

    // 내 동선 화면에서 사용자가 드래그로 바꾼 장소 순서를 저장한다.
    @PutMapping("/order")
    public ResponseEntity<AuthApiResponse<FavoriteSpotRouteResponse>> updateFavoriteSpotOrder(
        Authentication authentication,
        @RequestBody FavoriteSpotOrderRequest request
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                favoriteSpotService.updateFavoriteSpotOrder(currentUserId(authentication), request.spotIds())
            ));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(AuthApiResponse.failure(exception.getMessage()));
        }
    }

    // 지도 하단 카드에서 선택한 감자 스팟을 내 동선에 저장한다.
    @PostMapping("/{spotId}")
    public AuthApiResponse<FavoriteSpotToggleResponse> addFavoriteSpot(
        Authentication authentication,
        @PathVariable Long spotId
    ) {
        return AuthApiResponse.success(
            favoriteSpotService.addFavoriteSpot(currentUserId(authentication), spotId)
        );
    }

    // 이미 저장한 감자 스팟을 내 동선에서 제거한다.
    @DeleteMapping("/{spotId}")
    public AuthApiResponse<FavoriteSpotToggleResponse> removeFavoriteSpot(
        Authentication authentication,
        @PathVariable Long spotId
    ) {
        return AuthApiResponse.success(
            favoriteSpotService.removeFavoriteSpot(currentUserId(authentication), spotId)
        );
    }

    private Long currentUserId(Authentication authentication) {
        String principal = authentication.getName();
        if (principal.startsWith("user:")) {
            return Long.parseLong(principal.substring("user:".length()));
        }
        return Long.parseLong(principal);
    }
}
