package com.gamjamubwatna.spot.domain;

import com.gamjamubwatna.auth.domain.User;
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
    name = "favorite_spots",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_favorite_spots_user_spot",
            columnNames = {"user_id", "tourist_spot_id"}
        )
    }
)
public class FavoriteSpot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "favorite_spot_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tourist_spot_id", nullable = false)
    private TouristSpot touristSpot;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "route_order", nullable = false)
    private int routeOrder;

    protected FavoriteSpot() {
    }

    public FavoriteSpot(User user, TouristSpot touristSpot, Instant createdAt) {
        this(user, touristSpot, createdAt, 1);
    }

    public FavoriteSpot(User user, TouristSpot touristSpot, Instant createdAt, int routeOrder) {
        this.user = user;
        this.touristSpot = touristSpot;
        this.createdAt = createdAt;
        this.routeOrder = routeOrder;
    }

    public TouristSpot getTouristSpot() {
        return touristSpot;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public int getRouteOrder() {
        return routeOrder;
    }

    public void updateRouteOrder(int routeOrder) {
        this.routeOrder = routeOrder;
    }
}
