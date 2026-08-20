UPDATE missions
SET title = CASE code
        WHEN 'MISSION_GANGNEUNG_ANMOK_PHOTO_OCR' THEN '안목 해변 현장 인증샷'
        WHEN 'MISSION_WONJU_MUSEUM_SAN_PHOTO_OCR' THEN '뮤지엄 산 물의 정원 인증샷'
        WHEN 'MISSION_GOSEONG_DMZ_PHOTO_OCR' THEN '통일전망대 평화감자 여행 인증'
        ELSE title
    END,
    description = CASE code
        WHEN 'MISSION_GANGNEUNG_ANMOK_PHOTO_OCR'
            THEN '안목 커피거리 현장에서 현재 위치를 확인하고 여행 사진을 촬영하여 업로드하세요.'
        WHEN 'MISSION_WONJU_MUSEUM_SAN_PHOTO_OCR'
            THEN '뮤지엄 산 현장에서 현재 위치를 확인하고 물의 정원 주변 사진을 촬영하여 업로드하세요.'
        WHEN 'MISSION_GOSEONG_DMZ_PHOTO_OCR'
            THEN '통일전망대 현장에서 현재 위치를 확인하고 여행 사진을 촬영하여 업로드하세요.'
        ELSE description
    END,
    condition_label = '현장 위치 및 사진 인증',
    updated_at = CURRENT_TIMESTAMP
WHERE code IN (
    'MISSION_GANGNEUNG_ANMOK_PHOTO_OCR',
    'MISSION_WONJU_MUSEUM_SAN_PHOTO_OCR',
    'MISSION_GOSEONG_DMZ_PHOTO_OCR'
);

UPDATE mission_verification_policies
SET expected_answer = NULL,
    updated_at = CURRENT_TIMESTAMP
WHERE mission_id IN (
    SELECT mission_id
    FROM missions
    WHERE code IN (
        'MISSION_GANGNEUNG_ANMOK_PHOTO_OCR',
        'MISSION_WONJU_MUSEUM_SAN_PHOTO_OCR',
        'MISSION_GOSEONG_DMZ_PHOTO_OCR'
    )
);
