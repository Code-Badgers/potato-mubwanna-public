package com.gamjamubwatna.potato.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.potato.application.PotatoActivityException;
import com.gamjamubwatna.potato.application.PotatoAuthenticationException;
import com.gamjamubwatna.potato.application.PotatoCommandService;
import com.gamjamubwatna.potato.application.PotatoInteractionCooldownException;
import com.gamjamubwatna.potato.application.PotatoInteractionException;
import com.gamjamubwatna.potato.application.PotatoQueryService;
import com.gamjamubwatna.potato.application.PotatoRepresentativeException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/potatoes")
public class PotatoController {

    private static final Pattern USER_PRINCIPAL_PATTERN = Pattern.compile("^user:([1-9]\\d*)$");

    private final PotatoQueryService potatoQueryService;
    private final PotatoCommandService potatoCommandService;

    public PotatoController(
        PotatoQueryService potatoQueryService,
        PotatoCommandService potatoCommandService
    ) {
        this.potatoQueryService = potatoQueryService;
        this.potatoCommandService = potatoCommandService;
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

    // 도감 상단 카드에서 대표 감자 성장까지 남은 거리와 사용자의 걸음 요약을 표시한다.
    @GetMapping("/me/growth-summary")
    public ResponseEntity<AuthApiResponse<PotatoGrowthSummaryResponse>> getMyPotatoGrowthSummary(
        Authentication authentication
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                potatoQueryService.getGrowthSummary(userId(authentication))
            ));
        } catch (PotatoAuthenticationException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(AuthApiResponse.failure("인증 정보를 확인할 수 없습니다."));
        }
    }

    // HealthKit/Health Connect에서 읽은 일일 걸음 수를 서버 집계로 동기화한다.
    @PutMapping("/me/activity/daily")
    public ResponseEntity<AuthApiResponse<PotatoDailyActivitySyncResponse>> syncDailyActivity(
        Authentication authentication,
        @RequestBody PotatoDailyActivitySyncRequest request
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                potatoCommandService.syncDailyActivity(userId(authentication), request)
            ));
        } catch (PotatoAuthenticationException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(AuthApiResponse.failure("인증 정보를 확인할 수 없습니다."));
        } catch (PotatoActivityException exception) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(AuthApiResponse.failure(exception.getMessage()));
        }
    }

    // 도감에서 사용자가 보유한 감자 중 하나를 대표 감자로 지정한다.
    @PatchMapping("/me/representative")
    public ResponseEntity<AuthApiResponse<PotatoRepresentativeResponse>> updateRepresentativePotato(
        Authentication authentication,
        @RequestBody PotatoRepresentativeRequest request
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                potatoCommandService.updateRepresentativePotato(
                    userId(authentication),
                    request.potatoId()
                )
            ));
        } catch (PotatoAuthenticationException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(AuthApiResponse.failure("인증 정보를 확인할 수 없습니다."));
        } catch (PotatoRepresentativeException exception) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(AuthApiResponse.failure(exception.getMessage()));
        }
    }

    // 대표 감자에게 짧은 돌봄 행동을 적용하고 쿨타임 기준으로 성장 보너스를 지급한다.
    @PostMapping("/me/representative/interactions")
    public ResponseEntity<AuthApiResponse<PotatoInteractionResponse>> interactWithRepresentativePotato(
        Authentication authentication,
        @RequestBody PotatoInteractionRequest request
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                potatoCommandService.interactWithRepresentativePotato(userId(authentication), request)
            ));
        } catch (PotatoAuthenticationException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(AuthApiResponse.failure("인증 정보를 확인할 수 없습니다."));
        } catch (PotatoInteractionCooldownException exception) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                .body(AuthApiResponse.failure(exception.getMessage()));
        } catch (PotatoInteractionException exception) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(AuthApiResponse.failure(exception.getMessage()));
        }
    }

    // 완전히 성장한 대표 감자를 수확해 도감/대표 감자 화면에서 획득 상태로 고정한다.
    @PostMapping("/me/representative/harvest")
    public ResponseEntity<AuthApiResponse<PotatoHarvestResponse>> harvestRepresentativePotato(
        Authentication authentication
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                potatoCommandService.harvestRepresentativePotato(userId(authentication))
            ));
        } catch (PotatoAuthenticationException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(AuthApiResponse.failure("인증 정보를 확인할 수 없습니다."));
        } catch (PotatoInteractionException exception) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
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

    private PotatoAuthenticationException invalidPrincipal() {
        return new PotatoAuthenticationException("유효하지 않은 인증 사용자입니다.");
    }
}
