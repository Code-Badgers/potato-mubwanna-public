package com.gamjamubwatna.legal.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.legal.application.LegalConsentService;
import com.gamjamubwatna.user.application.UserProfileAuthenticationException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/users/me/legal-consents")
public class LegalConsentController {

    private static final Pattern USER_PRINCIPAL_PATTERN = Pattern.compile("^user:([1-9]\\d*)$");

    private final LegalConsentService legalConsentService;

    public LegalConsentController(LegalConsentService legalConsentService) {
        this.legalConsentService = legalConsentService;
    }

    // 앱의 현재 약관 동의 스냅샷을 멱등하게 서버 이력으로 동기화한다.
    @PutMapping
    public ResponseEntity<AuthApiResponse<Void>> synchronize(
        Authentication authentication,
        @RequestBody LegalConsentSyncRequest request
    ) {
        try {
            legalConsentService.synchronize(userId(authentication), request);
            return ResponseEntity.ok(AuthApiResponse.success(null));
        } catch (UserProfileAuthenticationException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(AuthApiResponse.failure("인증 정보를 확인할 수 없습니다."));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest()
                .body(AuthApiResponse.failure(exception.getMessage()));
        }
    }

    private Long userId(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            throw new UserProfileAuthenticationException("유효하지 않은 인증 사용자입니다.");
        }
        Matcher matcher = USER_PRINCIPAL_PATTERN.matcher(authentication.getName());
        if (!matcher.matches()) {
            throw new UserProfileAuthenticationException("유효하지 않은 인증 사용자입니다.");
        }
        return Long.parseLong(matcher.group(1));
    }
}
