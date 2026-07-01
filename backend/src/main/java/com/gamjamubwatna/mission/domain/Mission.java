package com.gamjamubwatna.mission.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
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
}
