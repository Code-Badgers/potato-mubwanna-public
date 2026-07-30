package com.gamjamubwatna.mission.application;

import org.springframework.web.multipart.MultipartFile;

public interface MissionPhotoStorage {

    StoredMissionPhoto store(String uploadKey, String fileName, String contentType, MultipartFile file);
}
