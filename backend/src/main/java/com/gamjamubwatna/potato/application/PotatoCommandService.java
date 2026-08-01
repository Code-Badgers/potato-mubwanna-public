package com.gamjamubwatna.potato.application;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.potato.api.PotatoDailyActivitySyncRequest;
import com.gamjamubwatna.potato.api.PotatoDailyActivitySyncResponse;
import com.gamjamubwatna.potato.api.PotatoGrowthResultResponse;
import com.gamjamubwatna.potato.api.PotatoRepresentativeResponse;
import com.gamjamubwatna.potato.domain.ActivitySource;
import com.gamjamubwatna.potato.domain.UserDailyActivity;
import com.gamjamubwatna.potato.domain.UserDailyActivityRepository;
import com.gamjamubwatna.potato.domain.UserPotato;
import com.gamjamubwatna.potato.domain.UserPotatoRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PotatoCommandService {

    private static final int MAX_DAILY_STEPS = 100_000;
    private static final double MAX_DAILY_DISTANCE_METERS = 100_000.0;

    private final UserPotatoRepository userPotatoRepository;
    private final UserDailyActivityRepository userDailyActivityRepository;
    private final UserRepository userRepository;

    public PotatoCommandService(
        UserPotatoRepository userPotatoRepository,
        UserDailyActivityRepository userDailyActivityRepository,
        UserRepository userRepository
    ) {
        this.userPotatoRepository = userPotatoRepository;
        this.userDailyActivityRepository = userDailyActivityRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public PotatoRepresentativeResponse updateRepresentativePotato(Long userId, Long potatoId) {
        if (!userRepository.existsById(userId)) {
            throw new PotatoAuthenticationException("사용자를 찾을 수 없습니다.");
        }
        if (potatoId == null || potatoId < 1) {
            throw new PotatoRepresentativeException("대표 감자를 확인할 수 없습니다.");
        }

        List<UserPotato> userPotatoes = userPotatoRepository.findByUserId(userId);
        UserPotato selected = userPotatoes.stream()
            .filter(userPotato -> userPotato.getPotato().getId().equals(potatoId))
            .findFirst()
            .orElseThrow(() -> new PotatoRepresentativeException(
                "획득한 감자만 대표 감자로 설정할 수 있습니다."
            ));

        // 대표 감자는 사용자당 하나만 유지해야 하므로, 같은 감자를 다시 선택해도 전체 상태를 정규화한다.
        userPotatoes.forEach(userPotato -> {
            if (userPotato == selected) {
                userPotato.markRepresentative();
                return;
            }
            userPotato.unmarkRepresentative();
        });

        return PotatoRepresentativeResponse.from(selected);
    }

    @Transactional
    public PotatoDailyActivitySyncResponse syncDailyActivity(
        Long userId,
        PotatoDailyActivitySyncRequest request
    ) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new PotatoAuthenticationException("사용자를 찾을 수 없습니다."));
        validateDailyActivityRequest(request);

        LocalDate activityDate = request.activityDate();
        ActivitySource source = request.source();
        Instant now = Instant.now();

        UserDailyActivity activity;
        double additionalGrowthDistance;
        Optional<UserDailyActivity> existingActivity = userDailyActivityRepository
            .findByUserIdAndActivityDateAndSource(userId, activityDate, source);
        if (existingActivity.isPresent()) {
            activity = existingActivity.get();
            // 건강 데이터가 줄어들거나 재전송돼도 이미 지급한 성장량은 회수하거나 중복 지급하지 않는다.
            additionalGrowthDistance = activity.mergeSnapshot(
                request.steps(),
                request.distanceMeters(),
                now
            );
        } else {
            activity = new UserDailyActivity(
                user,
                activityDate,
                request.steps(),
                request.distanceMeters(),
                source,
                now
            );
            additionalGrowthDistance = request.distanceMeters();
        }

        UserDailyActivity savedActivity = userDailyActivityRepository.save(activity);
        PotatoGrowthResultResponse growthResult = applyRepresentativePotatoGrowth(
            userId,
            additionalGrowthDistance
        );
        return PotatoDailyActivitySyncResponse.from(savedActivity, growthResult);
    }

    private PotatoGrowthResultResponse applyRepresentativePotatoGrowth(
        Long userId,
        double additionalGrowthDistance
    ) {
        if (additionalGrowthDistance <= 0) {
            return null;
        }

        Optional<UserPotato> representativePotato = userPotatoRepository.findByUserId(userId)
            .stream()
            .filter(UserPotato::isRepresentative)
            .filter(userPotato -> !userPotato.isFullyGrown())
            .findFirst();
        if (representativePotato.isEmpty()) {
            return null;
        }

        UserPotato userPotato = representativePotato.get();
        int previousLevel = userPotato.getLevel();
        userPotato.addGrowthDistance(additionalGrowthDistance);
        return PotatoGrowthResultResponse.from(userPotato, previousLevel);
    }

    private void validateDailyActivityRequest(PotatoDailyActivitySyncRequest request) {
        if (request == null || request.activityDate() == null || request.source() == null) {
            throw new PotatoActivityException("걸음 수 동기화 정보를 확인할 수 없습니다.");
        }
        if (request.steps() == null || request.steps() < 0 || request.steps() > MAX_DAILY_STEPS) {
            throw new PotatoActivityException("걸음 수가 허용 범위를 벗어났습니다.");
        }
        if (request.distanceMeters() == null
            || !Double.isFinite(request.distanceMeters())
            || request.distanceMeters() < 0
            || request.distanceMeters() > MAX_DAILY_DISTANCE_METERS) {
            throw new PotatoActivityException("이동 거리가 허용 범위를 벗어났습니다.");
        }
    }
}
