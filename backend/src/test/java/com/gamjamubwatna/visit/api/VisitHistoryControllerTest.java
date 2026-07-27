package com.gamjamubwatna.visit.api;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.visit.application.VisitAuthenticationException;
import com.gamjamubwatna.visit.application.VisitHistoryService;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(VisitHistoryController.class)
class VisitHistoryControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private VisitHistoryService visitHistoryService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void returnsAuthenticatedUsersVisitHistory() throws Exception {
        when(visitHistoryService.getMyVisits(eq(1L))).thenReturn(List.of(
            new VisitHistoryResponse(
                2L,
                20L,
                "감자 카페",
                "POTATO_CAFE",
                "정선군",
                "강원특별자치도 정선군",
                "https://example.com/spot.png",
                Instant.parse("2026-07-27T12:00:00Z")
            )
        ));

        mockMvc.perform(get("/users/me/visits").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data[0].visitId").value(2))
            .andExpect(jsonPath("$.data[0].spotId").value(20))
            .andExpect(jsonPath("$.data[0].spotName").value("감자 카페"))
            .andExpect(jsonPath("$.data[0].category").value("POTATO_CAFE"))
            .andExpect(jsonPath("$.data[0].cityName").value("정선군"))
            .andExpect(jsonPath("$.data[0].visitedAt").value("2026-07-27T12:00:00Z"));
    }

    @Test
    void rejectsMalformedPrincipal() throws Exception {
        mockMvc.perform(get("/users/me/visits").with(user("admin:1")))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void rejectsDeletedUser() throws Exception {
        when(visitHistoryService.getMyVisits(1L))
            .thenThrow(new VisitAuthenticationException("인증 정보를 확인할 수 없습니다."));

        mockMvc.perform(get("/users/me/visits").with(user("user:1")))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("인증 정보를 확인할 수 없습니다."));
    }
}
