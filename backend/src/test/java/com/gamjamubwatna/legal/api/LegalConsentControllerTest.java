package com.gamjamubwatna.legal.api;

import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.legal.application.LegalConsentService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(LegalConsentController.class)
class LegalConsentControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private LegalConsentService legalConsentService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void returnsAuthenticatedUsersLatestConsentSnapshot() throws Exception {
        when(legalConsentService.getSnapshot(1L)).thenReturn(
            new LegalConsentSnapshotResponse(
                "2026-08-15-v2",
                "2026-08-14-v1",
                null
            )
        );

        mockMvc.perform(get("/users/me/legal-consents").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.requiredDocumentsVersion").value("2026-08-15-v2"))
            .andExpect(jsonPath("$.data.personalLocationConsentVersion").value("2026-08-14-v1"))
            .andExpect(jsonPath("$.data.healthDataConsentVersion").isEmpty());

        verify(legalConsentService).getSnapshot(1L);
    }

    @Test
    void synchronizesAuthenticatedUsersConsentSnapshot() throws Exception {
        mockMvc.perform(put("/users/me/legal-consents")
                .with(user("user:1"))
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "requiredDocumentsVersion": "2026-08-14-v1",
                      "personalLocationConsentVersion": "2026-08-14-v1",
                      "healthDataConsentVersion": null
                    }
                    """))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true));

        verify(legalConsentService).synchronize(
            org.mockito.ArgumentMatchers.eq(1L),
            argThat(request -> request.requiredDocumentsVersion().equals("2026-08-14-v1")
                && request.personalLocationConsentVersion().equals("2026-08-14-v1")
                && request.healthDataConsentVersion() == null)
        );
    }

    @Test
    void rejectsInvalidConsentSnapshot() throws Exception {
        doThrow(new IllegalArgumentException("필수 약관 버전을 확인해주세요."))
            .when(legalConsentService)
            .synchronize(org.mockito.ArgumentMatchers.eq(1L), org.mockito.ArgumentMatchers.any());

        mockMvc.perform(put("/users/me/legal-consents")
                .with(user("user:1"))
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void rejectsConsentSnapshotLookupWithoutAuthenticatedPrincipal() throws Exception {
        mockMvc.perform(get("/users/me/legal-consents"))
            .andExpect(status().isUnauthorized());
    }
}
