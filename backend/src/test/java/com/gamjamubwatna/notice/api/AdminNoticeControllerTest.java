package com.gamjamubwatna.notice.api;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtAuthenticationFilter;
import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.global.config.SecurityConfig;
import com.gamjamubwatna.notice.application.AdminNoticeService;
import com.gamjamubwatna.notice.application.NoticeNotFoundException;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.UserRequestPostProcessor;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(AdminNoticeController.class)
@Import({SecurityConfig.class, JwtAuthenticationFilter.class})
class AdminNoticeControllerTest {

    private static final Instant NOW = Instant.parse("2026-08-23T07:30:00Z");

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminNoticeService adminNoticeService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void returnsAllNoticesToAdmin() throws Exception {
        when(adminNoticeService.getNotices()).thenReturn(
            new AdminNoticeListResponse(List.of(response(1L, true)))
        );

        mockMvc.perform(get("/admin/notices").with(admin()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.items[0].id").value(1))
            .andExpect(jsonPath("$.data.items[0].published").value(true))
            .andExpect(jsonPath("$.data.items[0].createdAt").value(NOW.toString()));
    }

    @Test
    void rejectsNonAdminUser() throws Exception {
        mockMvc.perform(get("/admin/notices").with(user("user:1").roles("USER")))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.message").value("관리자 권한이 필요합니다."));

        verifyNoInteractions(adminNoticeService);
    }

    @Test
    void createsNotice() throws Exception {
        when(adminNoticeService.create(eq("새 공지"), eq("새 내용"), eq(false)))
            .thenReturn(response(2L, false));

        mockMvc.perform(post("/admin/notices")
                .with(admin())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"title":"새 공지","content":"새 내용","published":false}
                    """))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.data.id").value(2))
            .andExpect(jsonPath("$.data.published").value(false));
    }

    @Test
    void rejectsInvalidCreateRequest() throws Exception {
        mockMvc.perform(post("/admin/notices")
                .with(admin())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"title":" ","content":"","published":null}
                    """))
            .andExpect(status().isBadRequest());

        verifyNoInteractions(adminNoticeService);
    }

    @Test
    void updatesNoticeContent() throws Exception {
        when(adminNoticeService.update(3L, "수정 제목", "수정 내용"))
            .thenReturn(response(3L, true));

        mockMvc.perform(put("/admin/notices/3")
                .with(admin())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"title":"수정 제목","content":"수정 내용"}
                    """))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.id").value(3));
    }

    @Test
    void changesPublicationState() throws Exception {
        when(adminNoticeService.changePublication(4L, true))
            .thenReturn(response(4L, true));

        mockMvc.perform(patch("/admin/notices/4/publication")
                .with(admin())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"published":true}
                    """))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.published").value(true));
    }

    @Test
    void returnsNotFoundForUnknownNotice() throws Exception {
        when(adminNoticeService.update(404L, "제목", "내용"))
            .thenThrow(new NoticeNotFoundException());

        mockMvc.perform(put("/admin/notices/404")
                .with(admin())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"title":"제목","content":"내용"}
                    """))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.message").value("공지를 찾을 수 없습니다."));
    }

    private UserRequestPostProcessor admin() {
        return user("user:99").roles("USER", "ADMIN");
    }

    private AdminNoticeResponse response(Long id, boolean published) {
        return new AdminNoticeResponse(
            id,
            "공지 제목",
            "공지 내용",
            published,
            NOW,
            NOW,
            NOW
        );
    }
}
