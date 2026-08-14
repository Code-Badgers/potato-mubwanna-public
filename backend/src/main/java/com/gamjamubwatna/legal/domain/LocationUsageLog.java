package com.gamjamubwatna.legal.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "location_usage_logs")
public class LocationUsageLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "location_usage_log_id")
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "used_at", nullable = false, updatable = false)
    private Instant usedAt;

    @Column(name = "acquisition_source", nullable = false, length = 40)
    private String acquisitionSource;

    @Column(name = "purpose", nullable = false, length = 60)
    private String purpose;

    @Column(name = "service_result", nullable = false, length = 40)
    private String serviceResult;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    protected LocationUsageLog() {
    }

    public LocationUsageLog(Long userId, Instant usedAt, String serviceResult, Instant expiresAt) {
        this.userId = userId;
        this.usedAt = usedAt;
        this.acquisitionSource = "DEVICE_GPS";
        this.purpose = "VISIT_VERIFICATION";
        this.serviceResult = serviceResult;
        this.expiresAt = expiresAt;
    }
}
