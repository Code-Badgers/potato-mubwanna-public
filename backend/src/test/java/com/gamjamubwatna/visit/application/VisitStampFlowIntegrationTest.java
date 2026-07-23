package com.gamjamubwatna.visit.application;

import static org.assertj.core.api.Assertions.assertThat;

import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import com.gamjamubwatna.stamp.api.StampBookResponse;
import com.gamjamubwatna.stamp.api.StampRewardStatusResponse;
import com.gamjamubwatna.stamp.application.StampQueryService;
import com.gamjamubwatna.stamp.domain.UserStampRepository;
import com.gamjamubwatna.visit.api.VisitVerifyRequest;
import com.gamjamubwatna.visit.api.VisitVerifyResponse;
import com.gamjamubwatna.visit.domain.UserVisitRepository;
import java.math.BigDecimal;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:visit_stamp_flow;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
class VisitStampFlowIntegrationTest {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TouristSpotRepository touristSpotRepository;

    @Autowired
    private UserVisitRepository userVisitRepository;

    @Autowired
    private UserStampRepository userStampRepository;

    @Autowired
    private VisitVerificationService visitVerificationService;

    @Autowired
    private StampQueryService stampQueryService;

    @Test
    void issuesOneRegionalStampAcrossMultipleVerifiedSpots() {
        Instant now = Instant.parse("2026-07-23T00:00:00Z");
        User user = userRepository.save(new User(
            AuthProvider.KAKAO,
            "visit-stamp-flow-user",
            null,
            "스탬프 통합 사용자",
            null,
            now
        ));
        TouristSpot firstSpot = saveSpot("visit-stamp-flow-1", "정선 감자마을", now);
        TouristSpot secondSpot = saveSpot("visit-stamp-flow-2", "정선 5일장", now);

        VisitVerifyResponse first = verify(user, firstSpot);
        StampBookResponse stampBook = stampQueryService.getStampBook(user.getId());
        StampRewardStatusResponse rewardStatus = stampQueryService.getRewardStatus(user.getId());
        VisitVerifyResponse second = verify(user, secondSpot);

        assertThat(first.stampIssued()).isTrue();
        assertThat(stampBook.acquiredCount()).isEqualTo(1);
        assertThat(rewardStatus.acquiredCount()).isEqualTo(1);
        assertThat(second.stampIssued()).isFalse();
        assertThat(userVisitRepository.count()).isEqualTo(2);
        assertThat(userStampRepository.countByUserId(user.getId())).isEqualTo(1);
    }

    private VisitVerifyResponse verify(User user, TouristSpot spot) {
        return visitVerificationService.verifyVisit(
            user.getId(),
            new VisitVerifyRequest(spot.getId(), spot.getLatitude(), spot.getLongitude())
        );
    }

    private TouristSpot saveSpot(String contentId, String name, Instant now) {
        return touristSpotRepository.save(new TouristSpot(
            contentId,
            12,
            name,
            SpotCategory.POTATO_TOUR,
            new BigDecimal("37.3801000"),
            new BigDecimal("128.6609000"),
            "강원특별자치도 정선군",
            "정선군",
            null,
            "감자,시장",
            now
        ));
    }
}
