package com.gamjamubwatna.stamp.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.stamp.application.StampAuthenticationException;
import com.gamjamubwatna.stamp.application.StampQueryService;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/stamps")
public class StampController {

    private static final Pattern USER_PRINCIPAL_PATTERN = Pattern.compile("^user:([1-9]\\d*)$");

    private final StampQueryService stampQueryService;

    public StampController(StampQueryService stampQueryService) {
        this.stampQueryService = stampQueryService;
    }

    @GetMapping("/me")
    public ResponseEntity<AuthApiResponse<StampBookResponse>> getMyStamps(
        Authentication authentication
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                stampQueryService.getStampBook(userId(authentication))
            ));
        } catch (StampAuthenticationException exception) {
            return unauthorized();
        }
    }

    @GetMapping("/rewards/check")
    public ResponseEntity<AuthApiResponse<StampRewardStatusResponse>> getRewardStatus(
        Authentication authentication
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                stampQueryService.getRewardStatus(userId(authentication))
            ));
        } catch (StampAuthenticationException exception) {
            return unauthorized();
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

    private StampAuthenticationException invalidPrincipal() {
        return new StampAuthenticationException("유효하지 않은 인증 사용자입니다.");
    }

    private <T> ResponseEntity<AuthApiResponse<T>> unauthorized() {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
            .body(AuthApiResponse.failure("인증 정보를 확인할 수 없습니다."));
    }
}
