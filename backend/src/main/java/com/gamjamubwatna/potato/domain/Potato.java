package com.gamjamubwatna.potato.domain;

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
@Table(name = "potatoes")
public class Potato {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "potato_id")
    private Long id;

    @Column(name = "code", nullable = false, unique = true, length = 80)
    private String code;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(name = "region", nullable = false, length = 80)
    private String region;

    @Enumerated(EnumType.STRING)
    @Column(name = "rarity", nullable = false, length = 30)
    private PotatoRarity rarity;

    @Column(name = "description", nullable = false, length = 500)
    private String description;

    @Column(name = "acquisition_hint", nullable = false, length = 255)
    private String acquisitionHint;

    @Column(name = "image_url", length = 500)
    private String imageUrl;

    @Column(name = "growth_goal_distance", nullable = false)
    private Double growthGoalDistance;

    @Column(name = "display_order", nullable = false, unique = true)
    private Integer displayOrder;

    @Column(name = "active", nullable = false)
    private Boolean active;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Potato() {
    }

    public Potato(
        String code,
        String name,
        String region,
        PotatoRarity rarity,
        String description,
        String acquisitionHint,
        String imageUrl,
        Double growthGoalDistance,
        Integer displayOrder,
        Boolean active,
        Instant now
    ) {
        this.code = code;
        this.name = name;
        this.region = region;
        this.rarity = rarity;
        this.description = description;
        this.acquisitionHint = acquisitionHint;
        this.imageUrl = imageUrl;
        this.growthGoalDistance = growthGoalDistance;
        this.displayOrder = displayOrder;
        this.active = active;
        this.createdAt = now;
        this.updatedAt = now;
    }

    public Long getId() {
        return id;
    }

    public String getCode() {
        return code;
    }

    public String getName() {
        return name;
    }

    public String getRegion() {
        return region;
    }

    public PotatoRarity getRarity() {
        return rarity;
    }

    public String getDescription() {
        return description;
    }

    public String getAcquisitionHint() {
        return acquisitionHint;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public Double getGrowthGoalDistance() {
        return growthGoalDistance;
    }

    public Integer getDisplayOrder() {
        return displayOrder;
    }

    public Boolean isActive() {
        return active;
    }
}
