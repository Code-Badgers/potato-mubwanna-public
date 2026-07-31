package com.gamjamubwatna.visit.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.visit.application.VisitAuthenticationException;
import com.gamjamubwatna.visit.application.VisitHistoryService;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/users/me/visits")
public class VisitHistoryController {

    private static final Pattern USER_PRINCIPAL_PATTERN = Pattern.compile("^user:([1-9]\\d*)$");

    private final VisitHistoryService visitHistoryService;

    public VisitHistoryController(VisitHistoryService visitHistoryService) {
        this.visitHistoryService = visitHistoryService;
    }

    // 로그인 사용자가 마이페이지에서 방문 인증 완료 장소를 최신순으로 확인한다.
    @GetMapping
    public ResponseEntity<AuthApiResponse<List<VisitHistoryResponse>>> getMyVisits(
        Authentication authentication
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                visitHistoryService.getMyVisits(userId(authentication))
            ));
        } catch (VisitAuthenticationException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(AuthApiResponse.failure("인증 정보를 확인할 수 없습니다."));
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
