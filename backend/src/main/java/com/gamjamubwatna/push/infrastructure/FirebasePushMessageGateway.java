package com.gamjamubwatna.push.infrastructure;

import com.google.firebase.messaging.BatchResponse;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.MessagingErrorCode;
import com.google.firebase.messaging.MulticastMessage;
import com.google.firebase.messaging.Notification;
import com.google.firebase.messaging.SendResponse;
import com.gamjamubwatna.push.application.PushDeliveryException;
import com.gamjamubwatna.push.application.PushDeliveryResult;
import com.gamjamubwatna.push.application.PushMessageGateway;
import com.gamjamubwatna.push.application.PushNotificationMessage;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@SuppressWarnings("deprecation")
public class FirebasePushMessageGateway implements PushMessageGateway {

    private static final int MAX_BATCH_SIZE = 500;

    private final FirebaseMessaging firebaseMessaging;

    public FirebasePushMessageGateway(FirebaseMessaging firebaseMessaging) {
        this.firebaseMessaging = firebaseMessaging;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }

    @Override
    public PushDeliveryResult send(
        List<String> registrationTokens,
        PushNotificationMessage message
    ) {
        int successfulCount = 0;
        int failedCount = 0;
        Set<String> invalidTokens = new HashSet<>();

        for (int start = 0; start < registrationTokens.size(); start += MAX_BATCH_SIZE) {
            List<String> batchTokens = registrationTokens.subList(
                start,
                Math.min(start + MAX_BATCH_SIZE, registrationTokens.size())
            );
            BatchResponse response = sendBatch(batchTokens, message);
            successfulCount += response.getSuccessCount();
            failedCount += response.getFailureCount();
            collectInvalidTokens(batchTokens, response.getResponses(), invalidTokens);
        }

        return new PushDeliveryResult(successfulCount, failedCount, invalidTokens);
    }

    private BatchResponse sendBatch(
        List<String> registrationTokens,
        PushNotificationMessage message
    ) {
        MulticastMessage firebaseMessage = MulticastMessage.builder()
            .setNotification(Notification.builder()
                .setTitle(message.title())
                .setBody(message.body())
                .build())
            .putAllData(message.data())
            .addAllTokens(registrationTokens)
            .build();
        try {
            return firebaseMessaging.sendEachForMulticast(firebaseMessage);
        } catch (FirebaseMessagingException exception) {
            throw new PushDeliveryException("FCM 메시지 발송에 실패했습니다.", exception);
        }
    }

    private void collectInvalidTokens(
        List<String> registrationTokens,
        List<SendResponse> responses,
        Set<String> invalidTokens
    ) {
        for (int index = 0; index < responses.size(); index++) {
            SendResponse response = responses.get(index);
            if (response.isSuccessful() || response.getException() == null) {
                continue;
            }
            MessagingErrorCode errorCode = response.getException().getMessagingErrorCode();
            if (
                errorCode == MessagingErrorCode.UNREGISTERED
                    || errorCode == MessagingErrorCode.INVALID_ARGUMENT
            ) {
                invalidTokens.add(registrationTokens.get(index));
            }
        }
    }
}
