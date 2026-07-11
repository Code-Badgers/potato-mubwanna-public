package com.gamjamubwatna.mission.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;

@Entity
@Table(
    name = "mission_verification_policies",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_mission_verification_policies_mission",
            columnNames = "mission_id"
        )
    }
)
public class MissionVerificationPolicy {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "mission_verification_policy_id")
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "mission_id", nullable = false)
    private Mission mission;

    @Enumerated(EnumType.STRING)
    @Column(name = "verification_type", nullable = false, length = 30)
    private MissionType verificationType;

    @Column(name = "expected_answer", length = 160)
    private String expectedAnswer;

    @Column(name = "expected_qr_code", length = 160)
    private String expectedQrCode;

    @Column(name = "required_upload", nullable = false)
    private boolean requiredUpload;

    @Column(name = "min_step_count")
    private Integer minStepCount;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected MissionVerificationPolicy() {
    }

    public MissionVerificationPolicy(
        Mission mission,
        MissionType verificationType,
        String expectedAnswer,
        String expectedQrCode,
        boolean requiredUpload,
        Integer minStepCount,
        Instant now
    ) {
        this.mission = mission;
        this.verificationType = verificationType;
        this.expectedAnswer = expectedAnswer;
        this.expectedQrCode = expectedQrCode;
        this.requiredUpload = requiredUpload;
        this.minStepCount = minStepCount;
        this.createdAt = now;
        this.updatedAt = now;
    }

    public MissionType getVerificationType() {
        return verificationType;
    }

    public String getExpectedAnswer() {
        return expectedAnswer;
    }

    public String getExpectedQrCode() {
        return expectedQrCode;
    }

    public boolean isRequiredUpload() {
        return requiredUpload;
    }

    public Integer getMinStepCount() {
        return minStepCount;
    }
}
