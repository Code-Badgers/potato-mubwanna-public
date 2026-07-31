package com.gamjamubwatna.push.application;

import com.gamjamubwatna.push.domain.UserPushToken;
import com.gamjamubwatna.push.domain.UserPushTokenRepository;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class PushNotificationService {

    private final UserPushTokenRepository pushTokenRepository;
    private final PushMessageGateway pushMessageGateway;

    public PushNotificationService(
        UserPushTokenRepository pushTokenRepository,
        PushMessageGateway pushMessageGateway
    ) {
        this.pushTokenRepository = pushTokenRepository;
        this.pushMessageGateway = pushMessageGateway;
    }

    public PushSendResult sendToUser(
        Long userId,
        PushNotificationMessage message
    ) {
        if (!pushMessageGateway.isEnabled()) {
            return PushSendResult.disabled();
        }

        List<String> registrationTokens = pushTokenRepository.findAllByUserId(userId)
            .stream()
            .map(UserPushToken::getToken)
            .toList();
        if (registrationTokens.isEmpty()) {
            return new PushSendResult(true, 0, 0, 0, 0);
        }

        PushDeliveryResult delivery = pushMessageGateway.send(
            registrationTokens,
            message
        );
        int removedInvalidTokens = delivery.invalidTokens().isEmpty()
            ? 0
            : Math.toIntExact(pushTokenRepository.deleteByTokenIn(
                delivery.invalidTokens()
            ));
        return new PushSendResult(
            true,
            registrationTokens.size(),
            delivery.successfulCount(),
            delivery.failedCount(),
            removedInvalidTokens
        );
    }
}
