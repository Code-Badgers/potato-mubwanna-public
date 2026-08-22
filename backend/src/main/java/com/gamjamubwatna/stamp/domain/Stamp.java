package com.gamjamubwatna.stamp.domain;

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
import java.time.Instant;

@Entity
@Table(name = "stamps")
public class Stamp {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "stamp_id")
    private Long id;

    @Column(name = "stamp_key", nullable = false, unique = true, length = 100)
    private String stampKey;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tourist_spot_id", nullable = false, unique = true)
    private TouristSpot touristSpot;

    @Column(name = "city_name", nullable = false, length = 100)
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
        String stampKey,
        TouristSpot touristSpot,
        String stampImage,
        Integer displayOrder,
        Instant now
    ) {
        this.stampKey = stampKey;
        this.touristSpot = touristSpot;
        this.cityName = touristSpot.getCityName();
        this.stampName = touristSpot.getName();
        this.stampImage = stampImage;
        this.displayOrder = displayOrder;
        this.createdAt = now;
        this.updatedAt = now;
    }

    public Long getId() {
        return id;
    }

    public String getStampKey() {
        return stampKey;
    }

    public TouristSpot getTouristSpot() {
        return touristSpot;
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
