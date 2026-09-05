package com.gamjamubwatna.visit.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import com.gamjamubwatna.stamp.api.StampBookResponse;
import com.gamjamubwatna.stamp.api.StampRewardStatusResponse;
import com.gamjamubwatna.stamp.application.StampQueryService;
import com.gamjamubwatna.stamp.domain.Stamp;
import com.gamjamubwatna.stamp.domain.StampRepository;
import com.gamjamubwatna.stamp.domain.UserStampRepository;
import com.gamjamubwatna.visit.api.VisitVerifyRequest;
import com.gamjamubwatna.visit.api.VisitVerifyResponse;
import com.gamjamubwatna.visit.domain.UserVisitRepository;
import com.gamjamubwatna.visit.domain.UserVisit;
import com.gamjamubwatna.potato.domain.UserPotatoRepository;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
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
    private StampRepository stampRepository;

    @Autowired
    private UserPotatoRepository userPotatoRepository;

    @Autowired
    private VisitVerificationService visitVerificationService;

    @Autowired
    private StampQueryService stampQueryService;

    @Test
    void issuesSeparatePassportStampsForMultipleSpotsInSameCity() {
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
        stampRepository.save(new Stamp(
            "PASSPORT_SPOT_visit-stamp-flow-1",
            firstSpot,
            null,
            101,
            now
        ));
        stampRepository.save(new Stamp(
            "PASSPORT_SPOT_visit-stamp-flow-2",
            secondSpot,
            null,
            102,
            now
        ));

        VisitVerifyResponse first = verify(user, firstSpot);
        StampBookResponse stampBook = stampQueryService.getStampBook(user.getId());
        StampRewardStatusResponse rewardStatus = stampQueryService.getRewardStatus(user.getId());
        VisitVerifyResponse second = verify(user, secondSpot);

        assertThat(first.stampIssued()).isTrue();
        assertThat(first.potatoAcquired()).isTrue();
        assertThat(first.acquiredPotato()).isNotNull();
        assertThat(stampBook.acquiredCount()).isEqualTo(1);
        assertThat(rewardStatus.acquiredCount()).isEqualTo(1);
        assertThat(second.stampIssued()).isTrue();
        assertThat(second.potatoAcquired()).isFalse();
        assertThat(second.acquiredPotato().alreadyOwned()).isTrue();
        assertThat(userVisitRepository.findByUserIdOrderByVisitedAtDesc(user.getId())).hasSize(2);
        assertThat(userStampRepository.countByUserId(user.getId())).isEqualTo(2);
        assertThat(userPotatoRepository.countByUserId(user.getId())).isEqualTo(1);
    }

    @Test
    void photoTravelRecordCanAcquireRewardsOnlyOnceEvenWithConcurrentRequests() throws Exception {
        Instant now = Instant.parse("2026-09-05T00:00:00Z");
        User user = userRepository.save(new User(AuthProvider.KAKAO, "photo-visit-rewards",
            null, "사진 방문 사용자", null, now));
        TouristSpot spot = saveSpot("photo-visit-rewards", "사진 보상 스팟", now);
        stampRepository.save(new Stamp("PHOTO_VISIT_REWARDS", spot, null, 103, now));
        UserVisit photoVisit = userVisitRepository.save(UserVisit.fromPhotoEvidence(user, spot, BigDecimal.ZERO, now));

        CountDownLatch start = new CountDownLatch(1);
        try (var executor = Executors.newFixedThreadPool(2)) {
            java.util.concurrent.Callable<Boolean> attempt = () -> {
                start.await(5, TimeUnit.SECONDS);
                try {
                    verify(user, spot);
                    return true;
                } catch (VisitDuplicateException expected) {
                    return false;
                }
            };
            var first = executor.submit(attempt);
            var second = executor.submit(attempt);
            start.countDown();
            assertThat(java.util.List.of(first.get(20, TimeUnit.SECONDS), second.get(20, TimeUnit.SECONDS)))
                .containsExactlyInAnyOrder(true, false);
        }
        assertThat(userVisitRepository.findById(photoVisit.getId()).orElseThrow().isVisitRewardsProcessed()).isTrue();
        assertThat(userVisitRepository.findByUserIdOrderByVisitedAtDesc(user.getId())).hasSize(1);
        assertThat(userStampRepository.countByUserId(user.getId())).isEqualTo(1);
        assertThat(userPotatoRepository.countByUserId(user.getId())).isEqualTo(1);
        assertThatThrownBy(() -> verify(user, spot)).isInstanceOf(VisitDuplicateException.class);
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
