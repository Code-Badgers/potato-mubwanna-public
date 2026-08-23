package com.gamjamubwatna.push.infrastructure;

import static org.assertj.core.api.Assertions.assertThat;

import com.gamjamubwatna.push.application.PushMessageGateway;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;

class FirebaseAdminConfigurationTest {

    private final ApplicationContextRunner contextRunner =
        new ApplicationContextRunner()
            .withUserConfiguration(FirebaseAdminConfiguration.class);

    @Test
    void createsDisabledGatewayWhenFirebaseAdminIsDisabled() {
        contextRunner
            .withPropertyValues("push.firebase.enabled=false")
            .run(context -> assertThat(context.getBean(PushMessageGateway.class))
                .isInstanceOf(DisabledPushMessageGateway.class));
    }

    @Test
    void failsFastWhenFirebaseAdminIsEnabledWithoutProjectId() {
        contextRunner
            .withPropertyValues(
                "push.firebase.enabled=true",
                "push.firebase.project-id="
            )
            .run(context -> {
                assertThat(context).hasFailed();
                assertThat(context.getStartupFailure())
                    .hasRootCauseInstanceOf(IllegalStateException.class)
                    .hasRootCauseMessage(
                        "FIREBASE_PROJECT_ID is required when Firebase Admin is enabled"
                    );
            });
    }

    @Test
    void failsFastWhenServiceAccountBase64IsMalformed() {
        contextRunner
            .withPropertyValues(
                "push.firebase.enabled=true",
                "push.firebase.project-id=potato-mubwanna-prod",
                "push.firebase.service-account-base64=not-base64"
            )
            .run(context -> {
                assertThat(context).hasFailed();
                assertThat(context.getStartupFailure())
                    .hasMessageContaining(
                        "FIREBASE_SERVICE_ACCOUNT_BASE64 must be a valid base64 service account JSON"
                    );
            });
    }
}
