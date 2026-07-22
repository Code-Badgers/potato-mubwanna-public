package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.spot.domain.CongestionLevel;
import org.springframework.stereotype.Component;

@Component
public class CongestionLevelPolicy {

    private static final double LOW_THRESHOLD_RATIO = 0.8;
    private static final double HIGH_THRESHOLD_RATIO = 1.2;

    public CongestionLevel resolve(Integer predictedVisitors, Integer baselineVisitors) {
        if (predictedVisitors == null || predictedVisitors < 0 || baselineVisitors == null || baselineVisitors <= 0) {
            return CongestionLevel.NORMAL;
        }

        double ratio = predictedVisitors.doubleValue() / baselineVisitors.doubleValue();
        if (ratio < LOW_THRESHOLD_RATIO) {
            return CongestionLevel.LOW;
        }
        if (ratio > HIGH_THRESHOLD_RATIO) {
            return CongestionLevel.HIGH;
        }
        return CongestionLevel.NORMAL;
    }
}
