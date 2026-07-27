package com.gamjamubwatna.potato.application;

import com.gamjamubwatna.potato.domain.PotatoRarity;
import com.gamjamubwatna.spot.domain.CongestionLevel;
import java.util.List;
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

    public List<PotatoRarity> visitAcquisitionCandidates(CongestionLevel congestionLevel) {
        return switch (congestionLevel) {
            case LOW -> List.of(PotatoRarity.EPIC, PotatoRarity.RARE, PotatoRarity.COMMON);
            case NORMAL -> List.of(PotatoRarity.RARE, PotatoRarity.COMMON);
            case HIGH -> List.of(PotatoRarity.COMMON);
        };
    }
}
