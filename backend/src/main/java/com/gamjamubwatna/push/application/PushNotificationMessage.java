package com.gamjamubwatna.push.application;

import com.gamjamubwatna.push.domain.PushDestination;
import java.util.LinkedHashMap;
import java.util.Map;

public record PushNotificationMessage(
    String title,
    String body,
    PushDestination destination,
    Long destinationId
) {

    private static final int MAX_TITLE_LENGTH = 120;
    private static final int MAX_BODY_LENGTH = 500;

    public PushNotificationMessage {
        validateText(title, MAX_TITLE_LENGTH, "Push title");
        validateText(body, MAX_BODY_LENGTH, "Push body");
        if (destination == null) {
            throw new IllegalArgumentException("Push destination is required");
        }
        if (destination == PushDestination.SPOT) {
            if (destinationId == null || destinationId < 1) {
                throw new IllegalArgumentException("Spot destination requires a positive id");
            }
        } else if (destinationId != null) {
            throw new IllegalArgumentException("Only spot destination accepts an id");
        }
    }

    public Map<String, String> data() {
        Map<String, String> data = new LinkedHashMap<>();
        data.put("destination", destination.name());
        if (destinationId != null) {
            data.put("destinationId", destinationId.toString());
        }
        return Map.copyOf(data);
    }

    private static void validateText(String value, int maxLength, String label) {
        if (value == null || value.isBlank() || value.length() > maxLength) {
            throw new IllegalArgumentException(label + " is invalid");
        }
    }
}
