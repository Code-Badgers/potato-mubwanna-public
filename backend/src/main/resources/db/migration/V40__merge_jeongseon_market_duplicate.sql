-- The curated Jeongseon Arirang Market row and TourAPI's Jeongseon 5-day
-- Market row describe the same place. Move existing relations to the official
-- TourAPI row before hiding the duplicate so user history remains reachable.
CREATE TEMPORARY TABLE jeongseon_market_spot_merge AS
SELECT
    duplicate_spot.tourist_spot_id AS duplicate_spot_id,
    official_spot.tourist_spot_id AS official_spot_id
FROM tourist_spots duplicate_spot
JOIN tourist_spots official_spot
  ON official_spot.content_id = '132003'
WHERE duplicate_spot.content_id = 'CURATED:NOTION:JEONGSEON_ARIRANG_MARKET';

-- Unique user/spot relations keep the already-existing official relation when
-- a user happened to interact with both duplicate map entries.
DELETE FROM favorite_spots
WHERE tourist_spot_id = (
        SELECT duplicate_spot_id FROM jeongseon_market_spot_merge
    )
  AND EXISTS (
      SELECT 1
      FROM favorite_spots official_favorite
      WHERE official_favorite.user_id = favorite_spots.user_id
        AND official_favorite.tourist_spot_id = (
            SELECT official_spot_id FROM jeongseon_market_spot_merge
        )
  );

UPDATE favorite_spots
SET tourist_spot_id = (
    SELECT official_spot_id FROM jeongseon_market_spot_merge
)
WHERE tourist_spot_id = (
    SELECT duplicate_spot_id FROM jeongseon_market_spot_merge
);

DELETE FROM user_visits
WHERE tourist_spot_id = (
        SELECT duplicate_spot_id FROM jeongseon_market_spot_merge
    )
  AND EXISTS (
      SELECT 1
      FROM user_visits official_visit
      WHERE official_visit.user_id = user_visits.user_id
        AND official_visit.tourist_spot_id = (
            SELECT official_spot_id FROM jeongseon_market_spot_merge
        )
  );

UPDATE user_visits
SET tourist_spot_id = (
    SELECT official_spot_id FROM jeongseon_market_spot_merge
)
WHERE tourist_spot_id = (
    SELECT duplicate_spot_id FROM jeongseon_market_spot_merge
);

DELETE FROM audio_guides
WHERE tourist_spot_id = (
        SELECT duplicate_spot_id FROM jeongseon_market_spot_merge
    )
  AND EXISTS (
      SELECT 1
      FROM audio_guides official_audio
      WHERE official_audio.language = audio_guides.language
        AND official_audio.tourist_spot_id = (
            SELECT official_spot_id FROM jeongseon_market_spot_merge
        )
  );

UPDATE audio_guides
SET tourist_spot_id = (
    SELECT official_spot_id FROM jeongseon_market_spot_merge
)
WHERE tourist_spot_id = (
    SELECT duplicate_spot_id FROM jeongseon_market_spot_merge
);

DELETE FROM spot_congestion_predictions
WHERE tourist_spot_id = (
        SELECT duplicate_spot_id FROM jeongseon_market_spot_merge
    )
  AND EXISTS (
      SELECT 1
      FROM spot_congestion_predictions official_prediction
      WHERE official_prediction.prediction_date = spot_congestion_predictions.prediction_date
        AND official_prediction.source = spot_congestion_predictions.source
        AND official_prediction.tourist_spot_id = (
            SELECT official_spot_id FROM jeongseon_market_spot_merge
        )
  );

UPDATE spot_congestion_predictions
SET tourist_spot_id = (
    SELECT official_spot_id FROM jeongseon_market_spot_merge
)
WHERE tourist_spot_id = (
    SELECT duplicate_spot_id FROM jeongseon_market_spot_merge
);

DELETE FROM tourist_spot_menu_items
WHERE tourist_spot_id = (
        SELECT duplicate_spot_id FROM jeongseon_market_spot_merge
    )
  AND EXISTS (
      SELECT 1
      FROM tourist_spot_menu_items official_menu
      WHERE official_menu.name = tourist_spot_menu_items.name
        AND official_menu.tourist_spot_id = (
            SELECT official_spot_id FROM jeongseon_market_spot_merge
        )
  );

UPDATE tourist_spot_menu_items
SET tourist_spot_id = (
    SELECT official_spot_id FROM jeongseon_market_spot_merge
)
WHERE tourist_spot_id = (
    SELECT duplicate_spot_id FROM jeongseon_market_spot_merge
);

UPDATE user_missions
SET tourist_spot_id = (
    SELECT official_spot_id FROM jeongseon_market_spot_merge
)
WHERE tourist_spot_id = (
    SELECT duplicate_spot_id FROM jeongseon_market_spot_merge
);

-- V38 should already have removed non-passport stamps. This defensive remap
-- preserves any anomalous legacy achievement without issuing a new stamp.
DELETE FROM user_stamps
WHERE tourist_spot_id = (
        SELECT duplicate_spot_id FROM jeongseon_market_spot_merge
    )
  AND EXISTS (
      SELECT 1
      FROM user_stamps official_user_stamp
      JOIN stamps official_stamp
        ON official_stamp.stamp_id = official_user_stamp.stamp_id
      WHERE official_user_stamp.user_id = user_stamps.user_id
        AND official_stamp.tourist_spot_id = (
            SELECT official_spot_id FROM jeongseon_market_spot_merge
        )
  );

UPDATE user_stamps
SET
    stamp_id = (
        SELECT stamp_id
        FROM stamps
        WHERE tourist_spot_id = (
            SELECT official_spot_id FROM jeongseon_market_spot_merge
        )
    ),
    tourist_spot_id = (
        SELECT official_spot_id FROM jeongseon_market_spot_merge
    )
WHERE tourist_spot_id = (
        SELECT duplicate_spot_id FROM jeongseon_market_spot_merge
    )
  AND EXISTS (
      SELECT 1
      FROM stamps
      WHERE tourist_spot_id = (
          SELECT official_spot_id FROM jeongseon_market_spot_merge
      )
  );

DELETE FROM stamps
WHERE tourist_spot_id = (
    SELECT duplicate_spot_id FROM jeongseon_market_spot_merge
);

UPDATE tourist_spots
SET
    stamp_enabled = FALSE,
    active = FALSE,
    rallybook_featured = FALSE,
    updated_at = CURRENT_TIMESTAMP
WHERE tourist_spot_id = (
    SELECT duplicate_spot_id FROM jeongseon_market_spot_merge
);

DROP TABLE jeongseon_market_spot_merge;
