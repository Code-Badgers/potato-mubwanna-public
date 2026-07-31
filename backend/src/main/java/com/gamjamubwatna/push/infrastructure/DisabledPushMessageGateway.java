package com.gamjamubwatna.push.infrastructure;

import com.gamjamubwatna.push.application.PushDeliveryResult;
import com.gamjamubwatna.push.application.PushMessageGateway;
import com.gamjamubwatna.push.application.PushNotificationMessage;
import java.util.List;
import java.util.Set;

public class DisabledPushMessageGateway implements PushMessageGateway {

    @Override
    public boolean isEnabled() {
        return false;
    }

    @Override
    public PushDeliveryResult send(
        List<String> registrationTokens,
        PushNotificationMessage message
    ) {
        return new PushDeliveryResult(0, 0, Set.of());
    }
}
