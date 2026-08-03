package com.gamjamubwatna.mission.api;

import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.mission.application.MissionPhotoNotFoundException;
import com.gamjamubwatna.mission.application.MissionPhotoQueryService;
import com.gamjamubwatna.mission.application.StoredMissionPhotoFile;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(MissionPhotoController.class)
class MissionPhotoControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private MissionPhotoQueryService missionPhotoQueryService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void returnsOwnedEvidenceBytesWithoutPublicCaching() throws Exception {
        when(missionPhotoQueryService.getCompletedMissionPhoto(1L, 31L))
            .thenReturn(new StoredMissionPhotoFile("mission-uploads/1/20/photo.jpg", new byte[] {1, 2, 3}));

        mockMvc.perform(get("/mission-uploads/completions/31/image").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(content().contentType(MediaType.APPLICATION_OCTET_STREAM))
            .andExpect(content().bytes(new byte[] {1, 2, 3}))
            .andExpect(header().string(HttpHeaders.CACHE_CONTROL, "no-store"));
    }

    @Test
    void hidesUnavailableEvidenceAsNotFound() throws Exception {
        when(missionPhotoQueryService.getCompletedMissionPhoto(2L, 31L))
            .thenThrow(new MissionPhotoNotFoundException());

        mockMvc.perform(get("/mission-uploads/completions/31/image").with(user("user:2")))
            .andExpect(status().isNotFound());
    }

    @Test
    void rejectsMalformedPrincipal() throws Exception {
        mockMvc.perform(get("/mission-uploads/completions/31/image").with(user("admin:1")))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void rejectsUnauthenticatedRequest() throws Exception {
        mockMvc.perform(get("/mission-uploads/completions/31/image"))
            .andExpect(status().isUnauthorized());
    }
}
