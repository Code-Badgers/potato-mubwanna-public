package com.gamjamubwatna.mission.api;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.mission.application.MissionUploadException;
import com.gamjamubwatna.mission.application.MissionUploadService;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.multipart.MultipartFile;

@WebMvcTest(MissionUploadController.class)
class MissionUploadControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private MissionUploadService missionUploadService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void uploadsMissionPhotoAndReturnsUploadKey() throws Exception {
        when(missionUploadService.issueUploadKey(eq(1L), eq(1002L), any(MultipartFile.class)))
            .thenReturn(new MissionUploadResponse(
                "mission-uploads/1/1002/20260729T073000Z-abcd1234-receipt.jpg",
                "receipt.jpg",
                "image/jpeg",
                1024,
                Instant.parse("2026-07-29T08:30:00Z")
            ));

        mockMvc.perform(multipart("/mission-uploads")
                .file(image("receipt.jpg", "image/jpeg"))
                .param("missionId", "1002")
                .with(user("user:1"))
                .with(csrf()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.uploadKey")
                .value("mission-uploads/1/1002/20260729T073000Z-abcd1234-receipt.jpg"))
            .andExpect(jsonPath("$.data.fileName").value("receipt.jpg"))
            .andExpect(jsonPath("$.data.contentType").value("image/jpeg"))
            .andExpect(jsonPath("$.data.size").value(1024));
    }

    @Test
    void rejectsInvalidImageUpload() throws Exception {
        when(missionUploadService.issueUploadKey(eq(1L), eq(1002L), any(MultipartFile.class)))
            .thenThrow(new MissionUploadException("이미지 파일만 업로드할 수 있습니다."));

        mockMvc.perform(multipart("/mission-uploads")
                .file(image("memo.txt", "text/plain"))
                .param("missionId", "1002")
                .with(user("user:1"))
                .with(csrf()))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("이미지 파일만 업로드할 수 있습니다."));
    }

    @Test
    void rejectsMalformedUserPrincipal() throws Exception {
        mockMvc.perform(multipart("/mission-uploads")
                .file(image("receipt.jpg", "image/jpeg"))
                .param("missionId", "1002")
                .with(user("admin:1"))
                .with(csrf()))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("인증 정보를 확인할 수 없습니다."));
    }

    private MockMultipartFile image(String name, String contentType) {
        return new MockMultipartFile(
            "file",
            name,
            contentType,
            "image".getBytes()
        );
    }
}
