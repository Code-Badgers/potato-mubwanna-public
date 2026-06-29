package com.gamjamubwatna.user.application;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.user.api.UserProfileResponse;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserProfileService {

    private final UserRepository userRepository;

    public UserProfileService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public UserProfileResponse getProfile(Long userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new UserProfileAuthenticationException("사용자를 찾을 수 없습니다."));

        return new UserProfileResponse(
            user.getId(),
            user.getNickname(),
            user.getEmail(),
            user.getProfileImage(),
            user.getCreatedAt()
        );
    }
}
