package com.gamjamubwatna.visit.application;

import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.mission.domain.UserMission;
import com.gamjamubwatna.mission.domain.UserMissionRepository;
import com.gamjamubwatna.visit.api.VisitHistoryResponse;
import com.gamjamubwatna.visit.domain.UserVisit;
import com.gamjamubwatna.visit.domain.UserVisitRepository;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class VisitHistoryService {

    private final UserRepository userRepository;
    private final UserVisitRepository userVisitRepository;
    private final UserMissionRepository userMissionRepository;

    public VisitHistoryService(
        UserRepository userRepository,
        UserVisitRepository userVisitRepository,
        UserMissionRepository userMissionRepository
    ) {
        this.userRepository = userRepository;
        this.userVisitRepository = userVisitRepository;
        this.userMissionRepository = userMissionRepository;
    }

    public List<VisitHistoryResponse> getMyVisits(Long userId) {
        if (!userRepository.existsById(userId)) {
            throw new VisitAuthenticationException("인증 정보를 확인할 수 없습니다.");
        }

        List<UserVisit> visits = userVisitRepository.findByUserIdOrderByVisitedAtDesc(userId);
        Map<Long, String> uploadedImages = uploadedImages(userId, visits);
        return visits
            .stream()
            .map(visit -> VisitHistoryResponse.from(
                visit,
                uploadedImages.get(visit.getTouristSpot().getId())
            ))
            .toList();
    }

    private Map<Long, String> uploadedImages(Long userId, List<UserVisit> visits) {
        List<Long> spotIds = visits.stream()
            .map(visit -> visit.getTouristSpot().getId())
            .distinct()
            .toList();
        if (spotIds.isEmpty()) {
            return Map.of();
        }

        Map<Long, String> imageUrls = new HashMap<>();
        for (UserMission completion : userMissionRepository.findTravelEvidence(userId, spotIds)) {
            Long spotId = completion.getTouristSpot().getId();
            // 저장소가 최신순을 보장하므로 장소별 첫 행만 대표 사진으로 유지한다.
            imageUrls.putIfAbsent(
                spotId,
                "/mission-uploads/completions/%d/image".formatted(completion.getId())
            );
        }
        return imageUrls;
    }
}
