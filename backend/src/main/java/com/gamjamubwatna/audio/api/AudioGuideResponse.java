package com.gamjamubwatna.audio.api;

import com.gamjamubwatna.audio.domain.AudioGuide;

public record AudioGuideResponse(
    Long id,
    String title,
    String audioUrl,
    String script,
    String characterScript
) {

    public static AudioGuideResponse from(AudioGuide audioGuide) {
        return new AudioGuideResponse(
            audioGuide.getId(),
            audioGuide.getTitle(),
            audioGuide.getAudioUrl(),
            audioGuide.getScript(),
            audioGuide.getCharacterScript()
        );
    }
}
