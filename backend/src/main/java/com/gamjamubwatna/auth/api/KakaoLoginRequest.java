package com.gamjamubwatna.auth.api;

import jakarta.validation.constraints.NotBlank;

public record KakaoLoginRequest(
    @NotBlank(message = "카카오 accessToken은 필수입니다.")
    String accessToken
) {
}
