package com.gamjamubwatna.global.config;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:admin_access_control;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough",
    "auth.admin.user-ids=42, 99"
})
@AutoConfigureMockMvc
class AdminAccessControlTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void rejectsAdminRequestWithoutBearerToken() throws Exception {
        mockMvc.perform(get("/admin/ping"))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("인증이 필요합니다."));
    }

    @Test
    void rejectsAuthenticatedUserOutsideAdminAllowlist() throws Exception {
        mockMvc.perform(get("/admin/ping")
                .header("Authorization", "Bearer " + jwtTokenProvider.createAccessToken("1")))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("관리자 권한이 필요합니다."));
    }

    @Test
    void allowsConfiguredAdminUser() throws Exception {
        mockMvc.perform(get("/admin/ping")
                .header("Authorization", "Bearer " + jwtTokenProvider.createAccessToken("99")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("ok"));
    }

    @TestConfiguration
    static class AdminTestConfiguration {

        @Bean
        AdminTestController adminTestController() {
            return new AdminTestController();
        }
    }

    @RestController
    @RequestMapping("/admin")
    static class AdminTestController {

        // 실제 Admin API가 추가되기 전에도 공통 접근 제어 계약을 독립적으로 검증한다.
        @GetMapping("/ping")
        AdminPingResponse ping() {
            return new AdminPingResponse("ok");
        }
    }

    record AdminPingResponse(String status) {
    }
}
