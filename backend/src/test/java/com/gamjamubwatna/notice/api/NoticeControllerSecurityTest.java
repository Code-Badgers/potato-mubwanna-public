package com.gamjamubwatna.notice.api;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.notice.application.NoticeService;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:notice_controller_security;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
@AutoConfigureMockMvc
class NoticeControllerSecurityTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private NoticeService noticeService;

    @Test
    void allowsNoticeRequestWithoutBearerToken() throws Exception {
        when(noticeService.getPublishedNotices()).thenReturn(
            new NoticeListResponse(List.of())
        );

        mockMvc.perform(get("/notices"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.items").isEmpty());
    }
}
