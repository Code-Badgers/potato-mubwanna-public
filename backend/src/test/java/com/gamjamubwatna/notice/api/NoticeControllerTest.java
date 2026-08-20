package com.gamjamubwatna.notice.api;

import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.notice.application.NoticeService;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(NoticeController.class)
class NoticeControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private NoticeService noticeService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void getNoticesReturnsPublishedNoticeList() throws Exception {
        when(noticeService.getPublishedNotices()).thenReturn(
            new NoticeListResponse(List.of(
                new NoticeResponse(
                    1L,
                    "서비스 이용 안내",
                    "공지 내용",
                    Instant.parse("2026-08-20T00:00:00Z")
                )
            ))
        );

        mockMvc.perform(get("/notices").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.items[0].id").value(1))
            .andExpect(jsonPath("$.data.items[0].title").value("서비스 이용 안내"))
            .andExpect(jsonPath("$.data.items[0].content").value("공지 내용"))
            .andExpect(jsonPath("$.data.items[0].publishedAt")
                .value("2026-08-20T00:00:00Z"));
    }

}
