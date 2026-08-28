package com.gamjamubwatna.push.infrastructure;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.gamjamubwatna.push.application.PushMessageGateway;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.Base64;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class FirebaseAdminConfiguration {

    private static final Logger log = LoggerFactory.getLogger(FirebaseAdminConfiguration.class);
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
            log.error("Firebase Admin configuration invalid: FIREBASE_PROJECT_ID is required");
            throw new IllegalStateException(
                "FIREBASE_PROJECT_ID is required when Firebase Admin is enabled"
            );
        }

        try {
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
        } catch (IOException | RuntimeException exception) {
            log.error("Firebase Admin initialization failed: {}", safeFailureReason(exception));
            throw exception;
        }
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
            try {
                return GoogleCredentials.getApplicationDefault();
            } catch (IOException exception) {
                throw new IllegalStateException(
                    "FIREBASE_SERVICE_ACCOUNT_BASE64 or GOOGLE_APPLICATION_CREDENTIALS " +
                        "is required when Firebase Admin is enabled",
                    exception
                );
            }
        }

        byte[] serviceAccountJson;
        try {
            serviceAccountJson = Base64.getDecoder().decode(serviceAccountBase64);
        } catch (IllegalArgumentException exception) {
            throw new IllegalStateException(
                "FIREBASE_SERVICE_ACCOUNT_BASE64 must be a valid base64 service account JSON",
                exception
            );
        }

        try {
            return GoogleCredentials.fromStream(
                new ByteArrayInputStream(serviceAccountJson)
            );
        } catch (IOException exception) {
            throw new IllegalStateException(
                "FIREBASE_SERVICE_ACCOUNT_BASE64 must contain a valid service account JSON",
                exception
            );
        }
    }

    private String safeFailureReason(Throwable exception) {
        String message = exception.getMessage();
        if (message != null && (
            message.startsWith("FIREBASE_PROJECT_ID")
                || message.startsWith("FIREBASE_SERVICE_ACCOUNT_BASE64")
                || message.startsWith("Firebase Admin")
        )) {
            return message;
        }
        return "Firebase Admin SDK rejected the configured credentials (" +
            exception.getClass().getSimpleName() + ")";
    }
}
