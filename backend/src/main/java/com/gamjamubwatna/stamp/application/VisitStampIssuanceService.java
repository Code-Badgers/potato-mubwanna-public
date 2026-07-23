package com.gamjamubwatna.stamp.application;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.stamp.domain.Stamp;
import com.gamjamubwatna.stamp.domain.StampRepository;
import com.gamjamubwatna.stamp.domain.UserStamp;
import com.gamjamubwatna.stamp.domain.UserStampRepository;
import java.time.Instant;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class VisitStampIssuanceService {

    private final StampRepository stampRepository;
    private final UserStampRepository userStampRepository;

    public VisitStampIssuanceService(
        StampRepository stampRepository,
        UserStampRepository userStampRepository
    ) {
        this.stampRepository = stampRepository;
        this.userStampRepository = userStampRepository;
    }

    @Transactional
    public boolean issueStamp(User user, TouristSpot touristSpot, Instant acquiredAt) {
        if (!Boolean.TRUE.equals(touristSpot.getStampEnabled())) {
            return false;
        }
        String cityName = touristSpot.getCityName();
        if (cityName == null || cityName.isBlank()) {
            return false;
        }

        Stamp stamp = stampRepository.findByCityNameForUpdate(cityName).orElse(null);
        if (stamp == null || userStampRepository.existsByUserIdAndStampId(
            user.getId(),
            stamp.getId()
        )) {
            return false;
        }

        userStampRepository.save(new UserStamp(user, stamp, touristSpot, acquiredAt));
        return true;
    }
}
