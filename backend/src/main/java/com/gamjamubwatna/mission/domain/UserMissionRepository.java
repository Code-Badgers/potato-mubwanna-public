package com.gamjamubwatna.mission.domain;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserMissionRepository extends JpaRepository<UserMission, Long> {

    @EntityGraph(attributePaths = "mission")
    List<UserMission> findByUserIdAndCompletionPeriodIn(
        Long userId,
        Collection<String> completionPeriods
    );

    boolean existsByUserIdAndMissionId(Long userId, Long missionId);

    Optional<UserMission> findByUserIdAndMissionId(Long userId, Long missionId);

    boolean existsByUserIdAndMissionIdAndCompletionPeriod(
        Long userId,
        Long missionId,
        String completionPeriod
    );

    Optional<UserMission> findByUserIdAndMissionIdAndCompletionPeriod(
        Long userId,
        Long missionId,
        String completionPeriod
    );

    @Query("""
        SELECT completion
        FROM UserMission completion
        WHERE completion.id = :completionId
          AND completion.user.id = :userId
          AND completion.evidenceUploadKey IS NOT NULL
        """)
    Optional<UserMission> findOwnedEvidenceCompletion(
        @Param("completionId") Long completionId,
        @Param("userId") Long userId
    );

    @EntityGraph(attributePaths = "touristSpot")
    @Query("""
        SELECT completion
        FROM UserMission completion
        WHERE completion.user.id = :userId
          AND completion.touristSpot.id IN :touristSpotIds
          AND completion.evidenceUploadKey IS NOT NULL
        ORDER BY completion.completedAt DESC, completion.id DESC
        """)
    List<UserMission> findTravelEvidence(
        @Param("userId") Long userId,
        @Param("touristSpotIds") Collection<Long> touristSpotIds
    );
}
