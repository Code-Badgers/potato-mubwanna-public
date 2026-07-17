package com.gamjamubwatna.potato.api;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.potato.application.PotatoCommandService;
import com.gamjamubwatna.potato.application.PotatoQueryService;
import com.gamjamubwatna.potato.application.PotatoRepresentativeException;
import com.gamjamubwatna.potato.domain.PotatoRarity;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(PotatoController.class)
class PotatoControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private PotatoQueryService potatoQueryService;

    @MockitoBean
    private PotatoCommandService potatoCommandService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void returnsPotatoCatalog() throws Exception {
        when(potatoQueryService.getPotatoes()).thenReturn(new PotatoCatalogResponse(
            1,
            List.of(catalogItem())
        ));

        mockMvc.perform(get("/potatoes").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.totalCount").value(1))
            .andExpect(jsonPath("$.data.items[0].potatoId").value(1))
            .andExpect(jsonPath("$.data.items[0].name").value("하지감자"))
            .andExpect(jsonPath("$.data.items[0].rarity").value("COMMON"));
    }

    @Test
    void returnsAuthenticatedUsersPotatoCollection() throws Exception {
        when(potatoQueryService.getMyPotatoes(eq(1L))).thenReturn(new UserPotatoCollectionResponse(
            1,
            1,
            List.of(collectionItem())
        ));

        mockMvc.perform(get("/potatoes/me").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.acquiredCount").value(1))
            .andExpect(jsonPath("$.data.items[0].acquired").value(true))
            .andExpect(jsonPath("$.data.items[0].level").value(2))
            .andExpect(jsonPath("$.data.items[0].representative").value(true));
    }

    @Test
    void rejectsMalformedUserPrincipal() throws Exception {
        mockMvc.perform(get("/potatoes/me").with(user("admin:1")))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("인증 정보를 확인할 수 없습니다."));
    }

    @Test
    void updatesRepresentativePotato() throws Exception {
        when(potatoCommandService.updateRepresentativePotato(eq(1L), eq(2L)))
            .thenReturn(new PotatoRepresentativeResponse(2L, true));

        mockMvc.perform(patch("/potatoes/me/representative")
                .with(user("user:1"))
                .with(csrf())
                .contentType("application/json")
                .content("{\"potatoId\":2}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.potatoId").value(2))
            .andExpect(jsonPath("$.data.representative").value(true));
    }

    @Test
    void rejectsUnacquiredRepresentativePotato() throws Exception {
        when(potatoCommandService.updateRepresentativePotato(eq(1L), eq(99L)))
            .thenThrow(new PotatoRepresentativeException("획득한 감자만 대표 감자로 설정할 수 있습니다."));

        mockMvc.perform(patch("/potatoes/me/representative")
                .with(user("user:1"))
                .with(csrf())
                .contentType("application/json")
                .content("{\"potatoId\":99}"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("획득한 감자만 대표 감자로 설정할 수 있습니다."));
    }

    private PotatoCatalogItemResponse catalogItem() {
        return new PotatoCatalogItemResponse(
            1L,
            "POTATO_HAJI_GANGNEUNG",
            "하지감자",
            "강릉시",
            PotatoRarity.COMMON,
            "강릉 여행길에서 처음 만나기 좋은 기본 감자입니다.",
            "강릉 감자 스팟 방문 인증",
            null,
            3000.0
        );
    }

    private UserPotatoCollectionItemResponse collectionItem() {
        return new UserPotatoCollectionItemResponse(
            1L,
            "POTATO_HAJI_GANGNEUNG",
            "하지감자",
            "강릉시",
            PotatoRarity.COMMON,
            "강릉 여행길에서 처음 만나기 좋은 기본 감자입니다.",
            "강릉 감자 스팟 방문 인증",
            null,
            true,
            Instant.parse("2026-07-01T00:00:00Z"),
            2,
            1500.0,
            3000.0,
            true
        );
    }
}
