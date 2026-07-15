package com.gamjamubwatna.potato.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.potato.application.PotatoAuthenticationException;
import com.gamjamubwatna.potato.application.PotatoQueryService;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/potatoes")
public class PotatoController {

    private static final Pattern USER_PRINCIPAL_PATTERN = Pattern.compile("^user:([1-9]\\d*)$");

    private final PotatoQueryService potatoQueryService;

    public PotatoController(PotatoQueryService potatoQueryService) {
        this.potatoQueryService = potatoQueryService;
    }

    // 감자 도감 진입 전 앱이 표시할 전체 감자 카탈로그를 정렬 순서대로 조회한다.
    @GetMapping
    public ResponseEntity<AuthApiResponse<PotatoCatalogResponse>> getPotatoes() {
        return ResponseEntity.ok(AuthApiResponse.success(potatoQueryService.getPotatoes()));
    }

    // 로그인 사용자의 획득 여부와 성장 정보를 전체 카탈로그에 합쳐 도감 화면에 내려준다.
    @GetMapping("/me")
    public ResponseEntity<AuthApiResponse<UserPotatoCollectionResponse>> getMyPotatoes(
        Authentication authentication
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                potatoQueryService.getMyPotatoes(userId(authentication))
            ));
        } catch (PotatoAuthenticationException exception) {
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

    private PotatoAuthenticationException invalidPrincipal() {
        return new PotatoAuthenticationException("유효하지 않은 인증 사용자입니다.");
    }
}
