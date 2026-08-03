package com.gamjamubwatna.stamp.api;

import static org.mockito.Mockito.verifyNoInteractions;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.stamp.application.StampQueryService;
import com.gamjamubwatna.stamp.application.StampRewardService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:stamp_controller_security;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
@AutoConfigureMockMvc
class StampControllerSecurityTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private StampQueryService stampQueryService;

    @MockitoBean
    private StampRewardService stampRewardService;

    @Test
    void rejectsStampBookRequestWithoutBearerToken() throws Exception {
        mockMvc.perform(get("/stamps/me"))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("인증이 필요합니다."));

        verifyNoInteractions(stampQueryService);
    }

    @Test
    void rejectsRewardStatusRequestWithoutBearerToken() throws Exception {
        mockMvc.perform(get("/stamps/rewards/check"))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("인증이 필요합니다."));

        verifyNoInteractions(stampQueryService);
    }

    @Test
    void rejectsRallybookSpotRequestWithoutBearerToken() throws Exception {
        mockMvc.perform(get("/stamps/rallybook-spots"))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("인증이 필요합니다."));

        verifyNoInteractions(stampQueryService);
    }

    @Test
    void rejectsRewardClaimRequestWithoutBearerToken() throws Exception {
        mockMvc.perform(post("/stamps/rewards/claim")
                .contentType("application/json")
                .content("""
                    {"targetCount": 6}
                    """))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("인증이 필요합니다."));

        verifyNoInteractions(stampRewardService);
    }
}
