package com.gamjamubwatna.user.application;

import com.gamjamubwatna.auth.domain.RefreshTokenRepository;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.mission.application.MissionPhotoStorage;
import com.gamjamubwatna.visit.domain.UserVisitRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserAccountService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final UserVisitRepository userVisitRepository;
    private final MissionPhotoStorage missionPhotoStorage;

    public UserAccountService(
        UserRepository userRepository,
        RefreshTokenRepository refreshTokenRepository,
        UserVisitRepository userVisitRepository,
        MissionPhotoStorage missionPhotoStorage
    ) {
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.userVisitRepository = userVisitRepository;
        this.missionPhotoStorage = missionPhotoStorage;
    }

    @Transactional
    public void withdraw(Long userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new UserProfileAuthenticationException("사용자를 찾을 수 없습니다."));

        // 사진 파기가 실패하면 DB 개인정보를 남겨 탈퇴 요청을 안전하게 재시도할 수 있게 한다.
        missionPhotoStorage.deleteAllByUserId(userId);
        // 두 테이블은 사용자 FK에 ON DELETE CASCADE가 없어 계정 삭제 전에 명시적으로 정리한다.
        refreshTokenRepository.deleteAllByUserId(userId);
        userVisitRepository.deleteAllByUserId(userId);
        userRepository.delete(user);
    }
}
