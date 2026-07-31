package com.gamjamubwatna.push.application;

import java.util.List;

public interface PushMessageGateway {

    boolean isEnabled();

    PushDeliveryResult send(
        List<String> registrationTokens,
        PushNotificationMessage message
    );
}
