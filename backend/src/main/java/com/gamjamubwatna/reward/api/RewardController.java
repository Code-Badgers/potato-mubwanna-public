package com.gamjamubwatna.reward.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.reward.application.RewardAuthenticationException;
import com.gamjamubwatna.reward.application.RewardHistoryService;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/rewards")
public class RewardController {

    private static final Pattern USER_PRINCIPAL_PATTERN = Pattern.compile("^user:([1-9]\\d*)$");

    private final RewardHistoryService rewardHistoryService;

    public RewardController(RewardHistoryService rewardHistoryService) {
        this.rewardHistoryService = rewardHistoryService;
    }

    // 보상함을 연 사용자가 지금까지 지급받은 보상 이력을 최신순으로 조회한다.
    @GetMapping("/history")
    public ResponseEntity<AuthApiResponse<RewardHistoryListResponse>> getRewardHistory(
        Authentication authentication
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                rewardHistoryService.getRewardHistory(userId(authentication))
            ));
        } catch (RewardAuthenticationException exception) {
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

    private RewardAuthenticationException invalidPrincipal() {
        return new RewardAuthenticationException("유효하지 않은 인증 사용자입니다.");
    }
}
