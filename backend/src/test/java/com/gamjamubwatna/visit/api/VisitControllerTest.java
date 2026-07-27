package com.gamjamubwatna.visit.api;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.potato.api.PotatoAcquisitionResponse;
import com.gamjamubwatna.potato.domain.PotatoRarity;
import com.gamjamubwatna.visit.application.VisitDuplicateException;
import com.gamjamubwatna.visit.application.VisitVerificationException;
import com.gamjamubwatna.visit.application.VisitVerificationService;
import java.math.BigDecimal;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(VisitController.class)
@AutoConfigureMockMvc(addFilters = false)
class VisitControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockitoBean
    private VisitVerificationService visitVerificationService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void verifyVisitReturnsSuccessResponse() throws Exception {
        when(visitVerificationService.verifyVisit(eq(1L), any(VisitVerifyRequest.class)))
            .thenReturn(new VisitVerifyResponse(
                10L,
                true,
                new BigDecimal("23.50"),
                100,
                true,
                true,
                new PotatoAcquisitionResponse(
                    3L,
                    "POTATO_GOLDEN_GANGWON",
                    "황금감자",
                    "강원특별자치도",
                    PotatoRarity.EPIC,
                    false
                ),
                false
            ));

        mockMvc.perform(post("/visits/verify")
                .principal(authentication())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(new VisitVerifyRequest(
                    10L,
                    new BigDecimal("37.3801000"),
                    new BigDecimal("128.6609000")
                ))))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.spotId").value(10))
            .andExpect(jsonPath("$.data.verified").value(true))
            .andExpect(jsonPath("$.data.distanceMeters").value(23.50))
            .andExpect(jsonPath("$.data.verificationRadiusMeter").value(100))
            .andExpect(jsonPath("$.data.stampIssued").value(true))
            .andExpect(jsonPath("$.data.potatoAcquired").value(true))
            .andExpect(jsonPath("$.data.acquiredPotato.name").value("황금감자"))
            .andExpect(jsonPath("$.data.acquiredPotato.rarity").value("EPIC"))
            .andExpect(jsonPath("$.data.acquiredPotato.alreadyOwned").value(false))
            .andExpect(jsonPath("$.data.missionAvailable").value(false));
    }

    @Test
    void verifyVisitReturnsBadRequestWhenOutsideRadius() throws Exception {
        when(visitVerificationService.verifyVisit(eq(1L), any(VisitVerifyRequest.class)))
            .thenThrow(new VisitVerificationException("방문 인증 가능 범위를 벗어났습니다."));

        mockMvc.perform(post("/visits/verify")
                .principal(authentication())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(new VisitVerifyRequest(
                    10L,
                    new BigDecimal("37.3901000"),
                    new BigDecimal("128.6609000")
                ))))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("방문 인증 가능 범위를 벗어났습니다."));
    }

    @Test
    void verifyVisitReturnsConflictForDuplicateVisit() throws Exception {
        when(visitVerificationService.verifyVisit(eq(1L), any(VisitVerifyRequest.class)))
            .thenThrow(new VisitDuplicateException("이미 방문 인증한 감자 스팟입니다."));

        mockMvc.perform(post("/visits/verify")
                .principal(authentication())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(new VisitVerifyRequest(
                    10L,
                    new BigDecimal("37.3801000"),
                    new BigDecimal("128.6609000")
                ))))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("이미 방문 인증한 감자 스팟입니다."));
    }

    private Authentication authentication() {
        TestingAuthenticationToken authentication = new TestingAuthenticationToken("user:1", null);
        authentication.setAuthenticated(true);
        return authentication;
    }
}
