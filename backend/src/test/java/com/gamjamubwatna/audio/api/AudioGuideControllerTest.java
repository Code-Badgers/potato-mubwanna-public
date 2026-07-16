package com.gamjamubwatna.audio.api;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.audio.application.AudioGuideExternalException;
import com.gamjamubwatna.audio.application.AudioGuideNotFoundException;
import com.gamjamubwatna.audio.application.AudioGuideService;
import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(AudioGuideController.class)
@AutoConfigureMockMvc(addFilters = false)
class AudioGuideControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AudioGuideService audioGuideService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void returnsAudioGuideForSpot() throws Exception {
        when(audioGuideService.getAudioGuide(1L)).thenReturn(new AudioGuideResponse(
            7L,
            "정선 5일장 이야기",
            "https://example.com/audio.mp3",
            "정선 5일장은...",
            null
        ));

        mockMvc.perform(get("/audio-guides/spots/1"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.message").value("요청이 성공했습니다."))
            .andExpect(jsonPath("$.data.id").value(7))
            .andExpect(jsonPath("$.data.title").value("정선 5일장 이야기"))
            .andExpect(jsonPath("$.data.audioUrl").value("https://example.com/audio.mp3"))
            .andExpect(jsonPath("$.data.script").value("정선 5일장은..."))
            .andExpect(jsonPath("$.data.characterScript").isEmpty());
    }

    @Test
    void returnsNotFoundWhenGuideDoesNotExist() throws Exception {
        when(audioGuideService.getAudioGuide(1L))
            .thenThrow(new AudioGuideNotFoundException("이 관광지의 오디오 가이드를 찾을 수 없습니다."));

        mockMvc.perform(get("/audio-guides/spots/1"))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("이 관광지의 오디오 가이드를 찾을 수 없습니다."))
            .andExpect(jsonPath("$.data").isEmpty());
    }

    @Test
    void returnsServiceUnavailableWhenExternalApiFails() throws Exception {
        when(audioGuideService.getAudioGuide(1L))
            .thenThrow(new AudioGuideExternalException("오디오 가이드 제공 서비스에 연결할 수 없습니다."));

        mockMvc.perform(get("/audio-guides/spots/1"))
            .andExpect(status().isServiceUnavailable())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("오디오 가이드 제공 서비스에 연결할 수 없습니다."));
    }
}
