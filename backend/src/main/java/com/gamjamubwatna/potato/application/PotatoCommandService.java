package com.gamjamubwatna.potato.application;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.potato.api.PotatoDailyActivitySyncRequest;
import com.gamjamubwatna.potato.api.PotatoDailyActivitySyncResponse;
import com.gamjamubwatna.potato.api.PotatoGrowthResultResponse;
import com.gamjamubwatna.potato.api.PotatoInteractionRequest;
import com.gamjamubwatna.potato.api.PotatoInteractionResponse;
import com.gamjamubwatna.potato.api.PotatoRepresentativeResponse;
import com.gamjamubwatna.potato.domain.ActivitySource;
import com.gamjamubwatna.potato.domain.PotatoInteractionAction;
import com.gamjamubwatna.potato.domain.UserDailyActivity;
import com.gamjamubwatna.potato.domain.UserDailyActivityRepository;
import com.gamjamubwatna.potato.domain.UserPotato;
import com.gamjamubwatna.potato.domain.UserPotatoInteraction;
import com.gamjamubwatna.potato.domain.UserPotatoInteractionRepository;
import com.gamjamubwatna.potato.domain.UserPotatoRepository;
import com.gamjamubwatna.push.application.PushEventPublisher;
import com.gamjamubwatna.push.application.PushNotificationMessage;
import com.gamjamubwatna.push.domain.PushDestination;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PotatoCommandService {

    private static final int MAX_DAILY_STEPS = 100_000;
    private static final double MAX_DAILY_DISTANCE_METERS = 100_000.0;

    private final UserPotatoRepository userPotatoRepository;
    private final UserPotatoInteractionRepository userPotatoInteractionRepository;
    private final UserDailyActivityRepository userDailyActivityRepository;
    private final UserRepository userRepository;
    private final PushEventPublisher pushEventPublisher;
    private final Clock clock;

    @Autowired
    public PotatoCommandService(
        UserPotatoRepository userPotatoRepository,
        UserPotatoInteractionRepository userPotatoInteractionRepository,
        UserDailyActivityRepository userDailyActivityRepository,
        UserRepository userRepository,
        PushEventPublisher pushEventPublisher
    ) {
        this(
            userPotatoRepository,
            userPotatoInteractionRepository,
            userDailyActivityRepository,
            userRepository,
            pushEventPublisher,
            Clock.systemUTC()
        );
    }

    PotatoCommandService(
        UserPotatoRepository userPotatoRepository,
        UserPotatoInteractionRepository userPotatoInteractionRepository,
        UserDailyActivityRepository userDailyActivityRepository,
        UserRepository userRepository,
        Clock clock
    ) {
        this(
            userPotatoRepository,
            userPotatoInteractionRepository,
            userDailyActivityRepository,
            userRepository,
            PushEventPublisher.noop(),
            clock
        );
    }

    PotatoCommandService(
        UserPotatoRepository userPotatoRepository,
        UserPotatoInteractionRepository userPotatoInteractionRepository,
        UserDailyActivityRepository userDailyActivityRepository,
        UserRepository userRepository,
        PushEventPublisher pushEventPublisher,
        Clock clock
    ) {
        this.userPotatoRepository = userPotatoRepository;
        this.userPotatoInteractionRepository = userPotatoInteractionRepository;
        this.userDailyActivityRepository = userDailyActivityRepository;
        this.userRepository = userRepository;
        this.pushEventPublisher = pushEventPublisher;
        this.clock = clock;
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
        publishLevelUp(userId, growthResult);
        return PotatoDailyActivitySyncResponse.from(savedActivity, growthResult);
    }

    @Transactional
    public PotatoInteractionResponse interactWithRepresentativePotato(
        Long userId,
        PotatoInteractionRequest request
    ) {
        if (!userRepository.existsById(userId)) {
            throw new PotatoAuthenticationException("사용자를 찾을 수 없습니다.");
        }
        if (request == null || request.action() == null) {
            throw new PotatoInteractionException("감자 돌봄 행동을 확인할 수 없습니다.");
        }

        UserPotato representative = userPotatoRepository.findByUserId(userId)
            .stream()
            .filter(UserPotato::isRepresentative)
            .findFirst()
            .orElseThrow(() -> new PotatoInteractionException("대표 감자를 먼저 설정해주세요."));
        if (representative.isFullyGrown()) {
            throw new PotatoInteractionException("이미 최대 레벨까지 성장한 감자입니다.");
        }

        PotatoInteractionAction action = request.action();
        Instant now = Instant.now(clock);
        validateInteractionCooldown(representative, action, now);

        int previousLevel = representative.getLevel();
        representative.addGrowthDistance(action.growthDistance());
        userPotatoInteractionRepository.save(new UserPotatoInteraction(
            representative,
            action,
            action.growthDistance(),
            now
        ));

        PotatoInteractionResponse response = PotatoInteractionResponse.from(
            representative,
            action,
            now.plus(action.cooldown()),
            previousLevel
        );
        publishLevelUp(userId, response.growthResult());
        return response;
    }

    private void publishLevelUp(Long userId, PotatoGrowthResultResponse growthResult) {
        if (growthResult == null || !growthResult.leveledUp()) {
            return;
        }
        pushEventPublisher.publish(
            userId,
            new PushNotificationMessage(
                "감자가 성장했어요!",
                "대표 감자 '" + growthResult.potatoName() + "'가 Lv."
                    + growthResult.currentLevel() + "로 성장했어요.",
                PushDestination.POTATOES,
                null
            )
        );
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

    private void validateInteractionCooldown(
        UserPotato representative,
        PotatoInteractionAction action,
        Instant now
    ) {
        Optional<UserPotatoInteraction> lastInteraction = userPotatoInteractionRepository
            .findTopByUserPotatoIdAndActionOrderByInteractedAtDesc(representative.getId(), action);
        if (lastInteraction.isEmpty()) {
            return;
        }

        Duration cooldown = action.cooldown();
        Instant nextAvailableAt = lastInteraction.get().getInteractedAt().plus(cooldown);
        if (now.isBefore(nextAvailableAt)) {
            throw new PotatoInteractionCooldownException(
                "아직 다시 돌볼 수 없습니다. 잠시 후 다시 시도해주세요.",
                nextAvailableAt
            );
        }
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
