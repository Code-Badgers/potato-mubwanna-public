package com.gamjamubwatna.stamp.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "stamps")
public class Stamp {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "stamp_id")
    private Long id;

    @Column(name = "city_name", nullable = false, unique = true, length = 100)
    private String cityName;

    @Column(name = "stamp_name", nullable = false, length = 100)
    private String stampName;

    @Column(name = "stamp_image", length = 500)
    private String stampImage;

    @Column(name = "display_order", nullable = false, unique = true)
    private Integer displayOrder;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Stamp() {
    }

    public Stamp(
        String cityName,
        String stampName,
        String stampImage,
        Integer displayOrder,
        Instant now
    ) {
        this.cityName = cityName;
        this.stampName = stampName;
        this.stampImage = stampImage;
        this.displayOrder = displayOrder;
        this.createdAt = now;
        this.updatedAt = now;
    }

    public Long getId() {
        return id;
    }

    public String getCityName() {
        return cityName;
    }

    public String getStampName() {
        return stampName;
    }

    public String getStampImage() {
        return stampImage;
    }

    public Integer getDisplayOrder() {
        return displayOrder;
    }
}
