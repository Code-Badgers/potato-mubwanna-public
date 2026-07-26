package com.gamjamubwatna.auth.api;

import jakarta.validation.constraints.NotBlank;

public record KakaoAuthorizationCodeRequest(
    @NotBlank String authorizationCode,
    @NotBlank String redirectUri
) {
}
