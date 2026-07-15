package com.gamjamubwatna.audio.api;

import com.gamjamubwatna.audio.application.AudioGuideExternalException;
import com.gamjamubwatna.audio.application.AudioGuideNotFoundException;
import com.gamjamubwatna.audio.application.AudioGuideService;
import com.gamjamubwatna.auth.api.AuthApiResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/audio-guides")
public class AudioGuideController {

    private final AudioGuideService audioGuideService;

    public AudioGuideController(AudioGuideService audioGuideService) {
        this.audioGuideService = audioGuideService;
    }

    @GetMapping("/spots/{spotId}")
    public ResponseEntity<AuthApiResponse<AudioGuideResponse>> getAudioGuide(
        @PathVariable Long spotId
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(audioGuideService.getAudioGuide(spotId)));
        } catch (AudioGuideNotFoundException exception) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(AuthApiResponse.failure(exception.getMessage()));
        } catch (AudioGuideExternalException exception) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(AuthApiResponse.failure(exception.getMessage()));
        }
    }
}
