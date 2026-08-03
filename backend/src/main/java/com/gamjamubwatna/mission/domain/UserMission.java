package com.gamjamubwatna.mission.domain;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.spot.domain.TouristSpot;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;

@Entity
@Table(
    name = "user_missions",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_user_missions_user_mission",
            columnNames = {"user_id", "mission_id", "completion_period"}
        )
    }
)
public class UserMission {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_mission_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "mission_id", nullable = false)
    private Mission mission;

    @Column(name = "completed_at", nullable = false, updatable = false)
    private Instant completedAt;

    @Column(name = "completion_period", nullable = false, length = 40)
    private String completionPeriod;

    @Column(name = "evidence_upload_key", length = 500)
    private String evidenceUploadKey;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tourist_spot_id")
    private TouristSpot touristSpot;

    protected UserMission() {
    }

    public UserMission(User user, Mission mission, Instant completedAt) {
        this(user, mission, completedAt, MissionPeriod.ONE_TIME_KEY);
    }

    public UserMission(
        User user,
        Mission mission,
        Instant completedAt,
        String completionPeriod
    ) {
        this(user, mission, completedAt, completionPeriod, null, null);
    }

    public UserMission(
        User user,
        Mission mission,
        Instant completedAt,
        String completionPeriod,
        String evidenceUploadKey,
        TouristSpot touristSpot
    ) {
        this.user = user;
        this.mission = mission;
        this.completedAt = completedAt;
        this.completionPeriod = completionPeriod;
        this.evidenceUploadKey = evidenceUploadKey;
        this.touristSpot = touristSpot;
    }

    public Long getId() {
        return id;
    }

    public Mission getMission() {
        return mission;
    }

    public Instant getCompletedAt() {
        return completedAt;
    }

    public String getCompletionPeriod() {
        return completionPeriod;
    }

    public String getEvidenceUploadKey() {
        return evidenceUploadKey;
    }

    public TouristSpot getTouristSpot() {
        return touristSpot;
    }
}
