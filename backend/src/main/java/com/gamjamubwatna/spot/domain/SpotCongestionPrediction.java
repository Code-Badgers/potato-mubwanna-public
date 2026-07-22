package com.gamjamubwatna.spot.domain;

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
import java.time.LocalDate;

@Entity
@Table(name = "spot_congestion_predictions")
public class SpotCongestionPrediction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "spot_congestion_prediction_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "tourist_spot_id", nullable = false)
    private TouristSpot touristSpot;

    @Column(name = "prediction_date", nullable = false)
    private LocalDate predictionDate;

    @Column(name = "predicted_visitors", nullable = false)
    private Integer predictedVisitors;

    @Column(name = "baseline_visitors", nullable = false)
    private Integer baselineVisitors;

    @Enumerated(EnumType.STRING)
    @Column(name = "congestion_level", nullable = false, length = 30)
    private CongestionLevel congestionLevel;

    @Column(name = "source", nullable = false, length = 50)
    private String source;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected SpotCongestionPrediction() {
    }

    public SpotCongestionPrediction(
        TouristSpot touristSpot,
        LocalDate predictionDate,
        Integer predictedVisitors,
        Integer baselineVisitors,
        CongestionLevel congestionLevel,
        String source,
        Instant createdAt
    ) {
        this.touristSpot = touristSpot;
        this.predictionDate = predictionDate;
        this.predictedVisitors = predictedVisitors;
        this.baselineVisitors = baselineVisitors;
        this.congestionLevel = congestionLevel;
        this.source = source;
        this.createdAt = createdAt;
    }

    public void update(
        Integer predictedVisitors,
        Integer baselineVisitors,
        CongestionLevel congestionLevel
    ) {
        this.predictedVisitors = predictedVisitors;
        this.baselineVisitors = baselineVisitors;
        this.congestionLevel = congestionLevel;
    }

    public Long getId() {
        return id;
    }

    public TouristSpot getTouristSpot() {
        return touristSpot;
    }

    public LocalDate getPredictionDate() {
        return predictionDate;
    }

    public Integer getPredictedVisitors() {
        return predictedVisitors;
    }

    public Integer getBaselineVisitors() {
        return baselineVisitors;
    }

    public CongestionLevel getCongestionLevel() {
        return congestionLevel;
    }

    public String getSource() {
        return source;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
