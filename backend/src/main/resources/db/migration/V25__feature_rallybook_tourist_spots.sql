ALTER TABLE tourist_spots
    ADD COLUMN rallybook_featured BOOLEAN NOT NULL DEFAULT FALSE;

UPDATE tourist_spots
SET rallybook_featured = TRUE,
    updated_at = CURRENT_TIMESTAMP
WHERE content_id IN (
    '128019',
    '2396037',
    '2633832',
    '127722',
    '125790',
    '129176',
    '1223212',
    '125740',
    '1260275',
    '125779',
    '126729',
    '125711',
    '125764',
    '131301',
    '2774026',
    '125785',
    '125794',
    '129263',
    '130415',
    '132003',
    '2615225',
    '507599',
    '130493',
    '126603',
    '1818945',
    '128171',
    '125706',
    '2501905',
    '125773'
);

CREATE INDEX idx_tourist_spots_rallybook_featured
    ON tourist_spots(rallybook_featured, active, stamp_enabled);
