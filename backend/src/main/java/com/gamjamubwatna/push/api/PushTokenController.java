package com.gamjamubwatna.push.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.push.application.PushTokenAuthenticationException;
import com.gamjamubwatna.push.application.PushTokenService;
import com.gamjamubwatna.push.application.PushTokenValidationException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/users/me/push-tokens")
public class PushTokenController {

    private static final Pattern USER_PRINCIPAL_PATTERN = Pattern.compile("^user:([1-9]\\d*)$");

    private final PushTokenService pushTokenService;

    public PushTokenController(PushTokenService pushTokenService) {
        this.pushTokenService = pushTokenService;
    }

    // 로그인한 사용자의 현재 기기 token을 등록하거나 refresh된 token으로 교체한다.
    @PostMapping
    public ResponseEntity<AuthApiResponse<PushTokenResponse>> register(
        Authentication authentication,
        @RequestBody PushTokenRegisterRequest request
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(PushTokenResponse.from(
                pushTokenService.register(
                    userId(authentication),
                    request == null ? null : request.token(),
                    request == null ? null : request.platform(),
                    request == null ? null : request.previousToken()
                )
            )));
        } catch (PushTokenAuthenticationException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(AuthApiResponse.failure("인증 정보를 확인할 수 없습니다."));
        } catch (PushTokenValidationException exception) {
            return ResponseEntity.badRequest()
                .body(AuthApiResponse.failure(exception.getMessage()));
        } catch (DataIntegrityViolationException exception) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(AuthApiResponse.failure("푸시 토큰을 다시 등록해주세요."));
        }
    }

    // 로그아웃과 알림 철회 전에 현재 사용자 소유 token만 idempotent하게 삭제한다.
    @DeleteMapping
    public ResponseEntity<AuthApiResponse<Void>> delete(
        Authentication authentication,
        @RequestBody PushTokenDeleteRequest request
    ) {
        try {
            pushTokenService.delete(
                userId(authentication),
                request == null ? null : request.token()
            );
            return ResponseEntity.ok(AuthApiResponse.success(null));
        } catch (PushTokenAuthenticationException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(AuthApiResponse.failure("인증 정보를 확인할 수 없습니다."));
        } catch (PushTokenValidationException exception) {
            return ResponseEntity.badRequest()
                .body(AuthApiResponse.failure(exception.getMessage()));
        }
    }

    private Long userId(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            throw invalidPrincipal();
        }

        Matcher matcher = USER_PRINCIPAL_PATTERN.matcher(authentication.getName());
        if (!matcher.matches()) {
            throw invalidPrincipal();
        }

        try {
            return Long.parseLong(matcher.group(1));
        } catch (NumberFormatException exception) {
            throw invalidPrincipal();
        }
    }

    private PushTokenAuthenticationException invalidPrincipal() {
        return new PushTokenAuthenticationException("유효하지 않은 인증 사용자입니다.");
    }
}
