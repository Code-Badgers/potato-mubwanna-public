package com.gamjamubwatna.spot.api;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.spot.application.FavoriteSpotService;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(FavoriteSpotController.class)
@AutoConfigureMockMvc(addFilters = false)
class FavoriteSpotControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private FavoriteSpotService favoriteSpotService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void addFavoriteSpotAcceptsJwtSubjectUserPrefix() throws Exception {
        when(favoriteSpotService.addFavoriteSpot(eq(1L), eq(10L)))
            .thenReturn(new FavoriteSpotToggleResponse(10L, true));

        mockMvc.perform(post("/me/favorite-spots/10")
                .principal(new UsernamePasswordAuthenticationToken("user:1", null)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.spotId").value(10))
            .andExpect(jsonPath("$.data.favorite").value(true));

        verify(favoriteSpotService).addFavoriteSpot(1L, 10L);
    }

    @Test
    void getFavoriteSpotRouteAcceptsJwtSubjectUserPrefix() throws Exception {
        when(favoriteSpotService.getFavoriteSpotRoute(eq(1L)))
            .thenReturn(new FavoriteSpotRouteResponse(
                "나만의 감자 동선",
                18.4,
                45,
                List.of(),
                List.of()
            ));

        mockMvc.perform(get("/me/favorite-spots/route")
                .principal(new UsernamePasswordAuthenticationToken("user:1", null)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.routeName").value("나만의 감자 동선"))
            .andExpect(jsonPath("$.data.totalDistanceKm").value(18.4))
            .andExpect(jsonPath("$.data.estimatedMinutes").value(45));

        verify(favoriteSpotService).getFavoriteSpotRoute(1L);
    }
}
