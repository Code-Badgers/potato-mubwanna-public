package com.gamjamubwatna.spot.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDate;

@Entity
@Table(name = "tourist_spot_menu_items")
public class SpotMenuItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "tourist_spot_menu_item_id")
    private Long id;

    @Column(name = "tourist_spot_id", nullable = false)
    private Long touristSpotId;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(name = "price_won")
    private Integer priceWon;

    @Column(name = "price_note", length = 50)
    private String priceNote;

    @Column(name = "display_order", nullable = false)
    private Integer displayOrder;

    @Column(name = "source_url", nullable = false, length = 500)
    private String sourceUrl;

    @Column(name = "verified_on", nullable = false)
    private LocalDate verifiedOn;

    @Column(name = "active", nullable = false)
    private Boolean active;

    protected SpotMenuItem() {
    }

    public SpotMenuItem(
        Long touristSpotId,
        String name,
        Integer priceWon,
        String priceNote,
        Integer displayOrder,
        String sourceUrl,
        LocalDate verifiedOn
    ) {
        this.touristSpotId = touristSpotId;
        this.name = name;
        this.priceWon = priceWon;
        this.priceNote = priceNote;
        this.displayOrder = displayOrder;
        this.sourceUrl = sourceUrl;
        this.verifiedOn = verifiedOn;
        this.active = true;
    }

    public Long getId() {
        return id;
    }

    public Long getTouristSpotId() {
        return touristSpotId;
    }

    public String getName() {
        return name;
    }

    public Integer getPriceWon() {
        return priceWon;
    }

    public String getPriceNote() {
        return priceNote;
    }

    public Integer getDisplayOrder() {
        return displayOrder;
    }

    public String getSourceUrl() {
        return sourceUrl;
    }

    public LocalDate getVerifiedOn() {
        return verifiedOn;
    }

    public Boolean getActive() {
        return active;
    }
}
