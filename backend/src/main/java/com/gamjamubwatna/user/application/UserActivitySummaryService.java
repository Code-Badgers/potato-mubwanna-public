package com.gamjamubwatna.user.application;

import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.potato.domain.UserDailyActivityRepository;
import com.gamjamubwatna.potato.domain.UserPotatoRepository;
import com.gamjamubwatna.stamp.domain.UserStampRepository;
import com.gamjamubwatna.user.api.UserActivitySummaryResponse;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserActivitySummaryService {

    private final UserRepository userRepository;
    private final UserDailyActivityRepository userDailyActivityRepository;
    private final UserStampRepository userStampRepository;
    private final UserPotatoRepository userPotatoRepository;

    public UserActivitySummaryService(
        UserRepository userRepository,
        UserDailyActivityRepository userDailyActivityRepository,
        UserStampRepository userStampRepository,
        UserPotatoRepository userPotatoRepository
    ) {
        this.userRepository = userRepository;
        this.userDailyActivityRepository = userDailyActivityRepository;
        this.userStampRepository = userStampRepository;
        this.userPotatoRepository = userPotatoRepository;
    }

    @Transactional(readOnly = true)
    public UserActivitySummaryResponse getActivitySummary(Long userId) {
        if (!userRepository.existsById(userId)) {
            throw new UserProfileAuthenticationException("사용자를 찾을 수 없습니다.");
        }

        return new UserActivitySummaryResponse(
            userDailyActivityRepository.sumStepsByUserId(userId),
            userStampRepository.countByUserId(userId),
            userPotatoRepository.countByUserId(userId)
        );
    }
}
