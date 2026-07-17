package com.gamjamubwatna.stamp.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.stamp.application.StampAuthenticationException;
import com.gamjamubwatna.stamp.application.StampQueryService;
import com.gamjamubwatna.stamp.application.StampRewardConfigurationException;
import com.gamjamubwatna.stamp.application.StampRewardConflictException;
import com.gamjamubwatna.stamp.application.StampRewardInvalidTargetException;
import com.gamjamubwatna.stamp.application.StampRewardService;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/stamps")
public class StampController {

    private static final Pattern USER_PRINCIPAL_PATTERN = Pattern.compile("^user:([1-9]\\d*)$");

    private final StampQueryService stampQueryService;
    private final StampRewardService stampRewardService;

    public StampController(
        StampQueryService stampQueryService,
        StampRewardService stampRewardService
    ) {
        this.stampQueryService = stampQueryService;
        this.stampRewardService = stampRewardService;
    }

    // 랠리북 진입 시 전체 스탬프와 로그인 사용자의 획득 상태를 조회한다.
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

    // 스탬프 진행도와 아직 받지 않은 가장 낮은 달성 보상을 조회한다.
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

    // 달성한 스탬프 기준의 보상 이력과 쿠폰을 한 번만 발급한다.
    @PostMapping("/rewards/claim")
    public ResponseEntity<AuthApiResponse<StampRewardClaimResponse>> claimReward(
        Authentication authentication,
        @RequestBody StampRewardClaimRequest request
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                stampRewardService.claimReward(
                    userId(authentication),
                    request == null ? null : request.targetCount()
                )
            ));
        } catch (StampAuthenticationException exception) {
            return unauthorized();
        } catch (StampRewardInvalidTargetException exception) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(AuthApiResponse.failure(exception.getMessage()));
        } catch (StampRewardConflictException exception) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(AuthApiResponse.failure(exception.getMessage()));
        } catch (StampRewardConfigurationException exception) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
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

    private StampAuthenticationException invalidPrincipal() {
        return new StampAuthenticationException("유효하지 않은 인증 사용자입니다.");
    }

    private <T> ResponseEntity<AuthApiResponse<T>> unauthorized() {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
            .body(AuthApiResponse.failure("인증 정보를 확인할 수 없습니다."));
    }
}
