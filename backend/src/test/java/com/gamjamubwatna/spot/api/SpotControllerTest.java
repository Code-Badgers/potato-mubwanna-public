package com.gamjamubwatna.spot.api;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.spot.application.SpotService;
import com.gamjamubwatna.spot.domain.CongestionLevel;
import com.gamjamubwatna.spot.domain.SpotCategory;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(SpotController.class)
@AutoConfigureMockMvc(addFilters = false)
class SpotControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private SpotService spotService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void getSpotsReturnsPotatoSpotMarkers() throws Exception {
        when(spotService.getSpots(
                eq(SpotCategory.POTATO_RESTAURANT),
                eq("정선군"),
                eq(CongestionLevel.NORMAL)
            ))
            .thenReturn(List.of(new SpotListResponse(
                1L,
                "정선 감자옹심이",
                SpotCategory.POTATO_RESTAURANT,
                new BigDecimal("37.3801000"),
                new BigDecimal("128.6609000"),
                "강원특별자치도 정선군",
                "정선군",
                "https://example.com/jeongseon.jpg",
                List.of("https://example.com/jeongseon.jpg"),
                CongestionLevel.NORMAL,
                true,
                "033-000-0000",
                "https://example.com",
                4.2,
                new PlaceOpeningHoursResponse(
                    true,
                    "월요일: 오전 10:00~오후 8:00",
                    List.of("월요일: 오전 10:00~오후 8:00")
                ),
                List.of(new SpotMenuItemResponse(
                    "감자옹심이",
                    10000,
                    null,
                    LocalDate.of(2026, 8, 3)
                ))
            )));

        mockMvc.perform(get("/spots")
                .param("category", "POTATO_RESTAURANT")
                .param("cityName", "정선군")
                .param("congestionLevel", "NORMAL"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data[0].id").value(1))
            .andExpect(jsonPath("$.data[0].name").value("정선 감자옹심이"))
            .andExpect(jsonPath("$.data[0].category").value("POTATO_RESTAURANT"))
            .andExpect(jsonPath("$.data[0].cityName").value("정선군"))
            .andExpect(jsonPath("$.data[0].imageUrl").value("https://example.com/jeongseon.jpg"))
            .andExpect(jsonPath("$.data[0].imageUrls[0]").value("https://example.com/jeongseon.jpg"))
            .andExpect(jsonPath("$.data[0].phone").value("033-000-0000"))
            .andExpect(jsonPath("$.data[0].rating").value(4.2))
            .andExpect(jsonPath("$.data[0].businessOpeningHours.openNow").value(true))
            .andExpect(jsonPath("$.data[0].menuItems[0].name").value("감자옹심이"))
            .andExpect(jsonPath("$.data[0].menuItems[0].priceWon").value(10000))
            .andExpect(jsonPath("$.data[0].menuItems[0].priceNote").isEmpty())
            .andExpect(jsonPath("$.data[0].menuItems[0].verifiedOn").value("2026-08-03"));
    }
}
