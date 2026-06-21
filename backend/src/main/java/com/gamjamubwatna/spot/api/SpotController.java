package com.gamjamubwatna.spot.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.spot.application.SpotService;
import com.gamjamubwatna.spot.domain.CongestionLevel;
import com.gamjamubwatna.spot.domain.SpotCategory;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/spots")
public class SpotController {

    private final SpotService spotService;

    public SpotController(SpotService spotService) {
        this.spotService = spotService;
    }

    // 지도 탭에서 강원도 감자 스팟 마커를 렌더링하기 위한 목록을 조회한다.
    @GetMapping
    public AuthApiResponse<List<SpotListResponse>> getSpots(
        @RequestParam(required = false) SpotCategory category,
        @RequestParam(required = false) String cityName,
        @RequestParam(required = false) CongestionLevel congestionLevel
    ) {
        return AuthApiResponse.success(spotService.getSpots(category, cityName, congestionLevel));
    }

    // 마커 또는 추천 카드 선택 시 하단 시트와 상세 화면에 필요한 스팟 정보를 조회한다.
    @GetMapping("/{spotId}")
    public AuthApiResponse<SpotDetailResponse> getSpot(
        @PathVariable Long spotId
    ) {
        return AuthApiResponse.success(spotService.getSpot(spotId));
    }
}
