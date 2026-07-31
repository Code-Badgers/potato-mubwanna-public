package com.gamjamubwatna.mission.infrastructure;

import com.gamjamubwatna.mission.application.MissionPhotoTextReader;
import com.gamjamubwatna.mission.application.StoredMissionPhotoFile;
import java.nio.charset.StandardCharsets;
import org.springframework.stereotype.Component;

@Component
public class EmbeddedTextMissionPhotoTextReader implements MissionPhotoTextReader {

    @Override
    public String readText(StoredMissionPhotoFile photoFile) {
        // 운영 OCR 연결 전까지는 테스트/로컬 검증을 위해 파일 바이트에 포함된 텍스트를 판독 결과로 사용한다.
        return new String(photoFile.bytes(), StandardCharsets.UTF_8);
    }
}
