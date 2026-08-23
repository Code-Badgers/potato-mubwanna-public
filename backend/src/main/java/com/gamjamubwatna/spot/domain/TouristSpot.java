package com.gamjamubwatna.spot.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "tourist_spots")
public class TouristSpot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "tourist_spot_id")
    private Long id;

    @Column(name = "content_id", length = 100, unique = true)
    private String contentId;

    @Column(name = "content_type_id", nullable = false)
    private Integer contentTypeId;

    @Column(name = "name", nullable = false, length = 255)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(name = "category", nullable = false, length = 50)
    private SpotCategory category;

    @Column(name = "latitude", nullable = false, precision = 10, scale = 7)
    private BigDecimal latitude;

    @Column(name = "longitude", nullable = false, precision = 10, scale = 7)
    private BigDecimal longitude;

    @Column(name = "address", length = 500)
    private String address;

    @Column(name = "city_name", length = 100)
    private String cityName;

    @Column(name = "image_url", length = 500)
    private String imageUrl;

    @Column(name = "source", nullable = false, length = 30)
    private String source;

    @Column(name = "potato_tags", length = 500)
    private String potatoTags;

    @Enumerated(EnumType.STRING)
    @Column(name = "congestion_level", nullable = false, length = 30)
    private CongestionLevel congestionLevel;

    @Column(name = "verification_radius_meter", nullable = false)
    private Integer verificationRadiusMeter;

    @Column(name = "stamp_enabled", nullable = false)
    private Boolean stampEnabled;

    @Column(name = "rallybook_featured", nullable = false)
    private Boolean rallybookFeatured;

    @Column(name = "active", nullable = false)
    private Boolean active;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected TouristSpot() {
    }

    public TouristSpot(
        String contentId,
        Integer contentTypeId,
        String name,
        SpotCategory category,
        BigDecimal latitude,
        BigDecimal longitude,
        String address,
        String cityName,
        String imageUrl,
        String potatoTags,
        Instant now
    ) {
        this(
            contentId,
            contentTypeId,
            name,
            category,
            latitude,
            longitude,
            address,
            cityName,
            imageUrl,
            "TOUR_API",
            potatoTags,
            now
        );
    }

    public TouristSpot(
        String contentId,
        Integer contentTypeId,
        String name,
        SpotCategory category,
        BigDecimal latitude,
        BigDecimal longitude,
        String address,
        String cityName,
        String imageUrl,
        String source,
        String potatoTags,
        Instant now
    ) {
        this.contentId = contentId;
        this.contentTypeId = contentTypeId;
        this.name = name;
        this.category = category;
        this.latitude = latitude;
        this.longitude = longitude;
        this.address = address;
        this.cityName = cityName;
        this.imageUrl = imageUrl;
        this.source = source;
        this.potatoTags = potatoTags;
        this.congestionLevel = CongestionLevel.NORMAL;
        this.verificationRadiusMeter = 100;
        this.stampEnabled = true;
        this.rallybookFeatured = false;
        this.active = true;
        this.createdAt = now;
        this.updatedAt = now;
    }

    public void updateFromTourApi(
        String name,
        SpotCategory category,
        BigDecimal latitude,
        BigDecimal longitude,
        String address,
        String cityName,
        String imageUrl,
        String potatoTags,
        Instant now
    ) {
        updateFromSource(name, category, latitude, longitude, address, cityName, imageUrl, "TOUR_API", potatoTags, now);
    }

    public void updateFromSource(
        String name,
        SpotCategory category,
        BigDecimal latitude,
        BigDecimal longitude,
        String address,
        String cityName,
        String imageUrl,
        String source,
        String potatoTags,
        Instant now
    ) {
        this.name = name;
        this.category = category;
        this.latitude = latitude;
        this.longitude = longitude;
        this.address = address;
        this.cityName = cityName;
        this.imageUrl = imageUrl;
        this.source = source;
        this.potatoTags = potatoTags;
        this.active = true;
        this.updatedAt = now;
    }

    public void updateCongestionLevel(CongestionLevel congestionLevel, Instant now) {
        if (congestionLevel == null) {
            return;
        }
        this.congestionLevel = congestionLevel;
        this.updatedAt = now;
    }

    public void cacheImageUrl(String imageUrl, Instant now) {
        if (imageUrl == null || imageUrl.isBlank() || (this.imageUrl != null && !this.imageUrl.isBlank())) {
            return;
        }
        this.imageUrl = imageUrl;
        this.updatedAt = now;
    }

    public Long getId() {
        return id;
    }

    public String getContentId() {
        return contentId;
    }

    public Integer getContentTypeId() {
        return contentTypeId;
    }

    public String getName() {
        return name;
    }

    public SpotCategory getCategory() {
        return category;
    }

    public BigDecimal getLatitude() {
        return latitude;
    }

    public BigDecimal getLongitude() {
        return longitude;
    }

    public String getAddress() {
        return address;
    }

    public String getCityName() {
        return cityName;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public String getPotatoTags() {
        return potatoTags;
    }

    public CongestionLevel getCongestionLevel() {
        return congestionLevel;
    }

    public Integer getVerificationRadiusMeter() {
        return verificationRadiusMeter;
    }

    public Boolean getStampEnabled() {
        return stampEnabled;
    }

    public Boolean getRallybookFeatured() {
        return rallybookFeatured;
    }
}
