package com.gamjamubwatna.mission.application;

public class MissionPhotoNotFoundException extends RuntimeException {

    public MissionPhotoNotFoundException() {
        super("미션 증빙 이미지를 찾을 수 없습니다.");
    }
}
