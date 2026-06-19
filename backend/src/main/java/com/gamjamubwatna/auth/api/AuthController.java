package com.gamjamubwatna.auth.api;

import com.gamjamubwatna.auth.application.AuthService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    // 앱에서 카카오 로그인을 마친 사용자를 검증하고 서비스 JWT 세션으로 교환한다.
    @PostMapping("/kakao")
    public AuthApiResponse<AuthLoginResponse> loginWithKakao(
        @Valid @RequestBody KakaoLoginRequest request
    ) {
        return AuthApiResponse.success(authService.loginWithKakao(request.accessToken()));
    }
}
