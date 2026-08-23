package com.gamjamubwatna.push.infrastructure;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.gamjamubwatna.push.application.PushMessageGateway;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.Base64;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class FirebaseAdminConfiguration {

    private static final String FIREBASE_APP_NAME = "push-notifications";

    @Bean
    @ConditionalOnProperty(
        name = "push.firebase.enabled",
        havingValue = "true"
    )
    public PushMessageGateway firebasePushMessageGateway(
        @Value("${push.firebase.project-id}") String projectId,
        @Value("${push.firebase.service-account-base64:}") String serviceAccountBase64
    ) throws IOException {
        if (projectId == null || projectId.isBlank()) {
            throw new IllegalStateException(
                "FIREBASE_PROJECT_ID is required when Firebase Admin is enabled"
            );
        }

        FirebaseApp firebaseApp;
        try {
            firebaseApp = FirebaseApp.getInstance(FIREBASE_APP_NAME);
        } catch (IllegalStateException ignored) {
            FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(firebaseCredentials(serviceAccountBase64))
                .setProjectId(projectId)
                .build();
            firebaseApp = FirebaseApp.initializeApp(
                options,
                FIREBASE_APP_NAME
            );
        }
        return new FirebasePushMessageGateway(FirebaseMessaging.getInstance(firebaseApp));
    }

    @Bean
    @ConditionalOnMissingBean(PushMessageGateway.class)
    public PushMessageGateway disabledPushMessageGateway() {
        return new DisabledPushMessageGateway();
    }

    private GoogleCredentials firebaseCredentials(
        String serviceAccountBase64
    ) throws IOException {
        if (serviceAccountBase64 == null || serviceAccountBase64.isBlank()) {
            return GoogleCredentials.getApplicationDefault();
        }

        try {
            byte[] serviceAccountJson = Base64.getDecoder()
                .decode(serviceAccountBase64);
            return GoogleCredentials.fromStream(
                new ByteArrayInputStream(serviceAccountJson)
            );
        } catch (IllegalArgumentException exception) {
            throw new IllegalStateException(
                "FIREBASE_SERVICE_ACCOUNT_BASE64 must be a valid base64 service account JSON",
                exception
            );
        }
    }
}
