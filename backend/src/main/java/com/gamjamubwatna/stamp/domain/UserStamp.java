package com.gamjamubwatna.stamp.domain;

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
    name = "user_stamps",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_user_stamps_user_stamp",
            columnNames = {"user_id", "stamp_id"}
        )
    }
)
public class UserStamp {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_stamp_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "stamp_id", nullable = false)
    private Stamp stamp;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tourist_spot_id", nullable = false)
    private TouristSpot touristSpot;

    @Column(name = "acquired_at", nullable = false, updatable = false)
    private Instant acquiredAt;

    protected UserStamp() {
    }

    public UserStamp(User user, Stamp stamp, TouristSpot touristSpot, Instant acquiredAt) {
        this.user = user;
        this.stamp = stamp;
        this.touristSpot = touristSpot;
        this.acquiredAt = acquiredAt;
    }

    public Stamp getStamp() {
        return stamp;
    }

    public Instant getAcquiredAt() {
        return acquiredAt;
    }
}
