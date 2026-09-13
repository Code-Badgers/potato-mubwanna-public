package com.gamjamubwatna.spot.api;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.spot.application.SpotRouteEstimateExternalException;
import com.gamjamubwatna.spot.application.SpotRouteEstimateService;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(SpotRouteEstimateController.class)
@AutoConfigureMockMvc(addFilters = false)
class SpotRouteEstimateControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private SpotRouteEstimateService routeEstimateService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void returnsRoadDistanceAndDuration() throws Exception {
        when(routeEstimateService.estimate(List.of(1L, 2L, 3L)))
            .thenReturn(new SpotRouteEstimateResponse(18400, 2760, "KAKAO_MOBILITY"));

        mockMvc.perform(post("/spots/route-estimate")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"spotIds\":[1,2,3]}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.distanceMeters").value(18400))
            .andExpect(jsonPath("$.data.durationSeconds").value(2760))
            .andExpect(jsonPath("$.data.source").value("KAKAO_MOBILITY"));
    }

    @Test
    void returnsBadRequestForInvalidRoute() throws Exception {
        when(routeEstimateService.estimate(List.of(1L, 2L)))
            .thenThrow(new IllegalArgumentException("활성 감자 스팟을 모두 찾을 수 없습니다."));

        mockMvc.perform(post("/spots/route-estimate")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"spotIds\":[1,2]}"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void returnsServiceUnavailableWhenDirectionsApiFails() throws Exception {
        when(routeEstimateService.estimate(List.of(1L, 2L)))
            .thenThrow(new SpotRouteEstimateExternalException("차량 경로 정보를 불러오지 못했습니다."));

        mockMvc.perform(post("/spots/route-estimate")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"spotIds\":[1,2]}"))
            .andExpect(status().isServiceUnavailable())
            .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void validatesMinimumSpotCount() throws Exception {
        mockMvc.perform(post("/spots/route-estimate")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"spotIds\":[1]}"))
            .andExpect(status().isBadRequest());
    }
}
