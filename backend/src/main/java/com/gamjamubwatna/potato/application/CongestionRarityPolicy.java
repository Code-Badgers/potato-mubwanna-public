package com.gamjamubwatna.potato.application;

import com.gamjamubwatna.spot.domain.CongestionLevel;
import org.springframework.stereotype.Component;

@Component
public class CongestionRarityPolicy {

    public double rarePotatoMultiplier(CongestionLevel congestionLevel) {
        return switch (congestionLevel) {
            case LOW -> 1.5;
            case NORMAL -> 1.0;
            case HIGH -> 0.7;
        };
    }
}
