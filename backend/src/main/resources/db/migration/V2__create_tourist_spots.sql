CREATE TABLE tourist_spots (
    tourist_spot_id BIGSERIAL PRIMARY KEY,
    content_id VARCHAR(100) UNIQUE,
    content_type_id INTEGER NOT NULL,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(50) NOT NULL,
    latitude NUMERIC(10, 7) NOT NULL,
    longitude NUMERIC(10, 7) NOT NULL,
    address VARCHAR(500),
    city_name VARCHAR(100),
    image_url VARCHAR(500),
    source VARCHAR(30) NOT NULL DEFAULT 'TOUR_API',
    potato_tags VARCHAR(500),
    congestion_level VARCHAR(30) NOT NULL DEFAULT 'NORMAL',
    verification_radius_meter INTEGER NOT NULL DEFAULT 100,
    stamp_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_tourist_spots_category ON tourist_spots(category);
CREATE INDEX idx_tourist_spots_city_name ON tourist_spots(city_name);
CREATE INDEX idx_tourist_spots_latitude_longitude ON tourist_spots(latitude, longitude);
CREATE INDEX idx_tourist_spots_active ON tourist_spots(active);
