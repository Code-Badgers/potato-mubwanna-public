package com.gamjamubwatna.user.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.user.application.UserProfileService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/users")
public class UserController {

    private static final String USER_SUBJECT_PREFIX = "user:";

    private final UserProfileService userProfileService;

    public UserController(UserProfileService userProfileService) {
        this.userProfileService = userProfileService;
    }

    // 로그인 세션을 복원한 사용자가 마이페이지에서 자신의 저장된 계정 정보를 조회한다.
    @GetMapping("/me")
    public AuthApiResponse<UserProfileResponse> getMyProfile(Authentication authentication) {
        return AuthApiResponse.success(userProfileService.getProfile(userId(authentication)));
    }

    private Long userId(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            throw new IllegalArgumentException("인증 정보가 없습니다.");
        }

        String subject = authentication.getName();
        if (!subject.startsWith(USER_SUBJECT_PREFIX)) {
            throw new IllegalArgumentException("인증 주체 형식이 올바르지 않습니다.");
        }

        return Long.parseLong(subject.substring(USER_SUBJECT_PREFIX.length()));
    }
}
