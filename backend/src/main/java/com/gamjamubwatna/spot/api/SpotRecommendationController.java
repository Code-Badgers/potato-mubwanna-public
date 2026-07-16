package com.gamjamubwatna.spot.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.spot.application.SpotRecommendationExternalException;
import com.gamjamubwatna.spot.application.SpotRecommendationNotFoundException;
import com.gamjamubwatna.spot.application.SpotRecommendationService;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/spots")
public class SpotRecommendationController {

    private final SpotRecommendationService spotRecommendationService;

    public SpotRecommendationController(SpotRecommendationService spotRecommendationService) {
        this.spotRecommendationService = spotRecommendationService;
    }

    // 관광지 상세와 방문 인증 결과에서 다음 목적지 후보로 사용할 연관 관광지를 조회한다.
    @GetMapping("/{spotId}/recommendations")
    public ResponseEntity<AuthApiResponse<List<SpotRecommendationResponse>>> getRecommendations(
        @PathVariable Long spotId
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                spotRecommendationService.getRecommendations(spotId)
            ));
        } catch (SpotRecommendationNotFoundException exception) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(AuthApiResponse.failure(exception.getMessage()));
        } catch (SpotRecommendationExternalException exception) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(AuthApiResponse.failure(exception.getMessage()));
        }
    }
}
