package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.spot.api.FavoriteSpotResponse;
import com.gamjamubwatna.spot.api.FavoriteSpotToggleResponse;
import com.gamjamubwatna.spot.domain.FavoriteSpot;
import com.gamjamubwatna.spot.domain.FavoriteSpotRepository;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import java.time.Instant;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class FavoriteSpotService {

    private final UserRepository userRepository;
    private final TouristSpotRepository touristSpotRepository;
    private final FavoriteSpotRepository favoriteSpotRepository;

    public FavoriteSpotService(
        UserRepository userRepository,
        TouristSpotRepository touristSpotRepository,
        FavoriteSpotRepository favoriteSpotRepository
    ) {
        this.userRepository = userRepository;
        this.touristSpotRepository = touristSpotRepository;
        this.favoriteSpotRepository = favoriteSpotRepository;
    }

    @Transactional(readOnly = true)
    public List<FavoriteSpotResponse> getFavoriteSpots(Long userId) {
        return favoriteSpotRepository.findByUserIdWithTouristSpot(userId)
            .stream()
            .map(FavoriteSpotResponse::from)
            .toList();
    }

    @Transactional
    public FavoriteSpotToggleResponse addFavoriteSpot(Long userId, Long spotId) {
        if (favoriteSpotRepository.existsByUserIdAndTouristSpotId(userId, spotId)) {
            return new FavoriteSpotToggleResponse(spotId, true);
        }

        User user = userRepository.findById(userId)
            .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        TouristSpot spot = touristSpotRepository.findByIdAndActiveTrue(spotId)
            .orElseThrow(() -> new IllegalArgumentException("감자 스팟을 찾을 수 없습니다."));

        // 같은 사용자가 같은 스팟을 중복 저장하지 않도록 DB unique key와 서비스 idempotency를 함께 둔다.
        favoriteSpotRepository.save(new FavoriteSpot(user, spot, Instant.now()));
        return new FavoriteSpotToggleResponse(spotId, true);
    }

    @Transactional
    public FavoriteSpotToggleResponse removeFavoriteSpot(Long userId, Long spotId) {
        favoriteSpotRepository.findByUserIdAndTouristSpotId(userId, spotId)
            .ifPresent(favoriteSpotRepository::delete);
        return new FavoriteSpotToggleResponse(spotId, false);
    }
}
