UPDATE mission_verification_policies
SET
    expected_qr_code = CASE (
        SELECT missions.code
        FROM missions
        WHERE missions.mission_id = mission_verification_policies.mission_id
    )
        WHEN 'MISSION_PYEONGCHANG_QR' THEN 'gamjamubwatna://mission/qr/MISSION_PYEONGCHANG_QR'
        WHEN 'MISSION_SOKCHO_ONNURI_QR' THEN 'gamjamubwatna://mission/qr/MISSION_SOKCHO_ONNURI_QR'
        WHEN 'MISSION_CHEORWON_GOSEOKJEONG_QR' THEN 'gamjamubwatna://mission/qr/MISSION_CHEORWON_GOSEOKJEONG_QR'
        WHEN 'MISSION_HOENGSEONG_HANWOO_QR' THEN 'gamjamubwatna://mission/qr/MISSION_HOENGSEONG_HANWOO_QR'
        WHEN 'MISSION_HWACHEON_SANCHEONEO_QR' THEN 'gamjamubwatna://mission/qr/MISSION_HWACHEON_SANCHEONEO_QR'
        ELSE mission_verification_policies.expected_qr_code
    END,
    updated_at = CURRENT_TIMESTAMP
WHERE EXISTS (
    SELECT 1
    FROM missions
    WHERE missions.mission_id = mission_verification_policies.mission_id
      AND missions.mission_type = 'QR_SCAN'
);
