CREATE TABLE spot_congestion_predictions (
    spot_congestion_prediction_id BIGSERIAL PRIMARY KEY,
    tourist_spot_id BIGINT NOT NULL,
    prediction_date DATE NOT NULL,
    predicted_visitors INTEGER NOT NULL,
    baseline_visitors INTEGER NOT NULL,
    congestion_level VARCHAR(30) NOT NULL,
    source VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT fk_spot_congestion_predictions_tourist_spot
        FOREIGN KEY (tourist_spot_id)
        REFERENCES tourist_spots(tourist_spot_id),
    CONSTRAINT uk_spot_congestion_predictions_spot_date_source
        UNIQUE (tourist_spot_id, prediction_date, source),
    CONSTRAINT chk_spot_congestion_predictions_predicted_visitors
        CHECK (predicted_visitors >= 0),
    CONSTRAINT chk_spot_congestion_predictions_baseline_visitors
        CHECK (baseline_visitors > 0)
);

CREATE INDEX idx_spot_congestion_predictions_spot_date
    ON spot_congestion_predictions(tourist_spot_id, prediction_date);

CREATE INDEX idx_tourist_spots_congestion_level
    ON tourist_spots(congestion_level);
