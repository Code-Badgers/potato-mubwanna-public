package com.gamjamubwatna.visit.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.mission.domain.MissionPeriod;
import com.gamjamubwatna.mission.domain.UserMission;
import com.gamjamubwatna.mission.domain.UserMissionRepository;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.visit.api.VisitHistoryResponse;
import com.gamjamubwatna.visit.domain.UserVisit;
import com.gamjamubwatna.visit.domain.UserVisitRepository;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

class VisitHistoryServiceTest {

    private UserRepository userRepository;
    private UserVisitRepository userVisitRepository;
    private UserMissionRepository userMissionRepository;
    private VisitHistoryService visitHistoryService;

    @BeforeEach
    void setUp() {
        userRepository = mock(UserRepository.class);
        userVisitRepository = mock(UserVisitRepository.class);
        userMissionRepository = mock(UserMissionRepository.class);
        visitHistoryService = new VisitHistoryService(
            userRepository,
            userVisitRepository,
            userMissionRepository
        );
    }

    @Test
    void returnsVisitsWithSpotInformationInRepositoryOrder() {
        TouristSpot latestSpot = spot(20L, "감자 카페", SpotCategory.POTATO_CAFE);
        UserVisit latest = visit(
            2L,
            latestSpot,
            "2026-07-27T12:00:00Z"
        );
        UserVisit previous = visit(
            1L,
            spot(10L, "정선 5일장", SpotCategory.POTATO_MARKET),
            "2026-07-26T09:00:00Z"
        );
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userVisitRepository.findByUserIdOrderByVisitedAtDesc(1L))
            .thenReturn(List.of(latest, previous));
        when(userMissionRepository.findTravelEvidence(1L, List.of(20L, 10L)))
            .thenReturn(List.of(
                completion(31L, latestSpot, "2026-07-27T11:00:00Z"),
                completion(30L, latestSpot, "2026-07-26T11:00:00Z")
            ));

        List<VisitHistoryResponse> result = visitHistoryService.getMyVisits(1L);

        assertThat(result).hasSize(2);
        assertThat(result.getFirst().visitId()).isEqualTo(2L);
        assertThat(result.getFirst().spotId()).isEqualTo(20L);
        assertThat(result.getFirst().spotName()).isEqualTo("감자 카페");
        assertThat(result.getFirst().category()).isEqualTo("POTATO_CAFE");
        assertThat(result.getFirst().uploadedImageUrl())
            .isEqualTo("/mission-uploads/completions/31/image");
        assertThat(result.getFirst().visitedAt())
            .isEqualTo(Instant.parse("2026-07-27T12:00:00Z"));
        assertThat(result.get(1).visitId()).isEqualTo(1L);
        assertThat(result.get(1).uploadedImageUrl()).isNull();
    }

    @Test
    void returnsEmptyListWithoutVisits() {
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userVisitRepository.findByUserIdOrderByVisitedAtDesc(1L))
            .thenReturn(List.of());

        assertThat(visitHistoryService.getMyVisits(1L)).isEmpty();
    }

    @Test
    void rejectsDeletedUser() {
        when(userRepository.existsById(99L)).thenReturn(false);

        assertThatThrownBy(() -> visitHistoryService.getMyVisits(99L))
            .isInstanceOf(VisitAuthenticationException.class)
            .hasMessage("인증 정보를 확인할 수 없습니다.");
    }

    private UserVisit visit(Long id, TouristSpot spot, String visitedAt) {
        UserVisit visit = new UserVisit(
            null,
            spot,
            new BigDecimal("12.50"),
            Instant.parse(visitedAt)
        );
        ReflectionTestUtils.setField(visit, "id", id);
        return visit;
    }

    private TouristSpot spot(Long id, String name, SpotCategory category) {
        TouristSpot spot = new TouristSpot(
            "spot-" + id,
            12,
            name,
            category,
            new BigDecimal("37.3801000"),
            new BigDecimal("128.6609000"),
            "강원특별자치도 정선군",
            "정선군",
            "https://example.com/spot.png",
            "감자",
            Instant.parse("2026-07-01T00:00:00Z")
        );
        ReflectionTestUtils.setField(spot, "id", id);
        return spot;
    }

    private UserMission completion(Long id, TouristSpot spot, String completedAt) {
        UserMission completion = new UserMission(
            null,
            null,
            Instant.parse(completedAt),
            MissionPeriod.ONE_TIME_KEY,
            "mission-uploads/1/20/photo-" + id + ".jpg",
            spot
        );
        ReflectionTestUtils.setField(completion, "id", id);
        return completion;
    }
}
