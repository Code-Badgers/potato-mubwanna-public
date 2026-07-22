package com.gamjamubwatna.visit.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.visit.application.VisitAuthenticationException;
import com.gamjamubwatna.visit.application.VisitDuplicateException;
import com.gamjamubwatna.visit.application.VisitNotFoundException;
import com.gamjamubwatna.visit.application.VisitVerificationException;
import com.gamjamubwatna.visit.application.VisitVerificationService;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/visits")
public class VisitController {

    private static final Pattern USER_PRINCIPAL_PATTERN = Pattern.compile("^user:([1-9]\\d*)$");

    private final VisitVerificationService visitVerificationService;

    public VisitController(VisitVerificationService visitVerificationService) {
        this.visitVerificationService = visitVerificationService;
    }

    // 관광지 상세의 방문 인증 버튼에서 GPS 좌표와 스팟 반경을 최종 서버 검증한다.
    @PostMapping("/verify")
    public ResponseEntity<AuthApiResponse<VisitVerifyResponse>> verifyVisit(
        Authentication authentication,
        @RequestBody VisitVerifyRequest request
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                visitVerificationService.verifyVisit(userId(authentication), request)
            ));
        } catch (VisitAuthenticationException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(AuthApiResponse.failure(exception.getMessage()));
        } catch (VisitNotFoundException exception) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(AuthApiResponse.failure(exception.getMessage()));
        } catch (VisitDuplicateException exception) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(AuthApiResponse.failure(exception.getMessage()));
        } catch (VisitVerificationException exception) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(AuthApiResponse.failure(exception.getMessage()));
        } catch (org.springframework.dao.DataIntegrityViolationException exception) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(AuthApiResponse.failure("이미 방문 인증한 감자 스팟입니다."));
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

    private VisitAuthenticationException invalidPrincipal() {
        return new VisitAuthenticationException("인증 정보를 확인할 수 없습니다.");
    }
}
