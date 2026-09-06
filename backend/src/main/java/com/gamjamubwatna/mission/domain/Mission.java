package com.gamjamubwatna.mission.domain;

import com.gamjamubwatna.spot.domain.TouristSpot;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "missions")
public class Mission {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "mission_id")
    private Long id;

    @Column(name = "code", nullable = false, unique = true, length = 80)
    private String code;

    @Enumerated(EnumType.STRING)
    @Column(name = "mission_group", nullable = false, length = 30)
    private MissionGroup group;

    @Enumerated(EnumType.STRING)
    @Column(name = "mission_type", nullable = false, length = 30)
    private MissionType type;

    @Enumerated(EnumType.STRING)
    @Column(name = "default_status", nullable = false, length = 30)
    private MissionStatus defaultStatus;

    @Column(name = "title", nullable = false, length = 120)
    private String title;

    @Column(name = "spot_name", nullable = false, length = 120)
    private String spotName;

    @Column(name = "city_name", nullable = false, length = 80)
    private String cityName;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "target_spot_id")
    private TouristSpot targetSpot;

    @Column(name = "description", nullable = false, length = 500)
    private String description;

    @Column(name = "dialogue", nullable = false, length = 500)
    private String dialogue;

    @Column(name = "condition_label", nullable = false, length = 160)
    private String conditionLabel;

    @Enumerated(EnumType.STRING)
    @Column(name = "reward_type", nullable = false, length = 30)
    private MissionRewardType rewardType;

    @Column(name = "reward_label", nullable = false, length = 120)
    private String rewardLabel;

    @Column(name = "reward_coupon_id")
    private Long rewardCouponId;

    @Column(name = "progress", nullable = false)
    private Integer progress;

    @Column(name = "target", nullable = false)
    private Integer target;

    @Column(name = "is_new", nullable = false)
    private Boolean newMission;

    @Column(name = "active", nullable = false)
    private Boolean active;

    @Column(name = "display_order", nullable = false, unique = true)
    private Integer displayOrder;

    @Column(name = "starts_at")
    private Instant startsAt;

    @Column(name = "ends_at")
    private Instant endsAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Mission() {
    }

    public Mission(
        String code,
        MissionGroup group,
        MissionType type,
        MissionStatus defaultStatus,
        String title,
        String spotName,
        String cityName,
        String description,
        String dialogue,
        String conditionLabel,
        MissionRewardType rewardType,
        String rewardLabel,
        Integer progress,
        Integer target,
        Boolean newMission,
        Boolean active,
        Integer displayOrder,
        Instant now
    ) {
        this(
            code,
            group,
            type,
            defaultStatus,
            title,
            spotName,
            cityName,
            description,
            dialogue,
            conditionLabel,
            rewardType,
            rewardLabel,
            progress,
            target,
            newMission,
            active,
            displayOrder,
            null,
            null,
            now
        );
    }

    public Mission(
        String code,
        MissionGroup group,
        MissionType type,
        MissionStatus defaultStatus,
        String title,
        String spotName,
        String cityName,
        String description,
        String dialogue,
        String conditionLabel,
        MissionRewardType rewardType,
        String rewardLabel,
        Integer progress,
        Integer target,
        Boolean newMission,
        Boolean active,
        Integer displayOrder,
        Instant startsAt,
        Instant endsAt,
        Instant now
    ) {
        this.code = code;
        this.group = group;
        this.type = type;
        this.defaultStatus = defaultStatus;
        this.title = title;
        this.spotName = spotName;
        this.cityName = cityName;
        this.description = description;
        this.dialogue = dialogue;
        this.conditionLabel = conditionLabel;
        this.rewardType = rewardType;
        this.rewardLabel = rewardLabel;
        this.progress = progress;
        this.target = target;
        this.newMission = newMission;
        this.active = active;
        this.displayOrder = displayOrder;
        this.startsAt = startsAt;
        this.endsAt = endsAt;
        this.createdAt = now;
        this.updatedAt = now;
    }

    public Long getId() {
        return id;
    }

    public String getCode() {
        return code;
    }

    public MissionGroup getGroup() {
        return group;
    }

    public MissionType getType() {
        return type;
    }

    public MissionStatus getDefaultStatus() {
        return defaultStatus;
    }

    public String getTitle() {
        return title;
    }

    public String getSpotName() {
        return spotName;
    }

    public String getCityName() {
        return cityName;
    }

    public TouristSpot getTargetSpot() {
        return targetSpot;
    }

    public boolean requiresPhotoTarget() {
        return type == MissionType.PHOTO || type == MissionType.PHOTO_OCR;
    }

    public boolean hasAvailablePhotoTarget() {
        return !requiresPhotoTarget() || (targetSpot != null && Boolean.TRUE.equals(targetSpot.isActive()));
    }

    public void assignTargetSpot(TouristSpot spot) {
        if (spot == null || !Boolean.TRUE.equals(spot.isActive())) {
            throw new IllegalArgumentException("활성 관광지를 선택해주세요.");
        }
        this.targetSpot = spot;
    }

    public String getDescription() {
        return description;
    }

    public String getDialogue() {
        return dialogue;
    }

    public String getConditionLabel() {
        return conditionLabel;
    }

    public MissionRewardType getRewardType() {
        return rewardType;
    }

    public String getRewardLabel() {
        return rewardLabel;
    }

    public Long getRewardCouponId() {
        return rewardCouponId;
    }

    public Integer getProgress() {
        return progress;
    }

    public Integer getTarget() {
        return target;
    }

    public Boolean isNewMission() {
        return newMission;
    }

    public Boolean isActive() {
        return active;
    }

    public Instant getStartsAt() {
        return startsAt;
    }

    public Instant getEndsAt() {
        return endsAt;
    }
}
