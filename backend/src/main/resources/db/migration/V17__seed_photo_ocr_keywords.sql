UPDATE mission_verification_policies
SET expected_answer = (
    SELECT CASE missions.code
        WHEN 'MISSION_GANGNEUNG_ANMOK_PHOTO_OCR' THEN '하지감자'
        WHEN 'MISSION_WONJU_MUSEUM_SAN_PHOTO_OCR' THEN '물의 정원'
        WHEN 'MISSION_GOSEONG_DMZ_PHOTO_OCR' THEN '평화의 종'
        ELSE mission_verification_policies.expected_answer
    END
    FROM missions
    WHERE missions.mission_id = mission_verification_policies.mission_id
)
WHERE mission_id IN (
    SELECT mission_id
    FROM missions
    WHERE code IN (
        'MISSION_GANGNEUNG_ANMOK_PHOTO_OCR',
        'MISSION_WONJU_MUSEUM_SAN_PHOTO_OCR',
        'MISSION_GOSEONG_DMZ_PHOTO_OCR'
    )
);
