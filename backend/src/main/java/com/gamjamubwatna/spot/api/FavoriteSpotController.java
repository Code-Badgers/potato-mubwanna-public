package com.gamjamubwatna.spot.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.spot.application.FavoriteSpotService;
import java.util.List;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
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
