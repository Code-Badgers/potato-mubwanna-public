package com.gamjamubwatna.potato.application;

import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.potato.api.PotatoCatalogItemResponse;
import com.gamjamubwatna.potato.api.PotatoCatalogResponse;
import com.gamjamubwatna.potato.api.PotatoGrowthSummaryResponse;
import com.gamjamubwatna.potato.api.UserPotatoCollectionItemResponse;
import com.gamjamubwatna.potato.api.UserPotatoCollectionResponse;
import com.gamjamubwatna.potato.domain.Potato;
import com.gamjamubwatna.potato.domain.PotatoRepository;
import com.gamjamubwatna.potato.domain.UserDailyActivity;
import com.gamjamubwatna.potato.domain.UserDailyActivityRepository;
import com.gamjamubwatna.potato.domain.UserPotato;
import com.gamjamubwatna.potato.domain.UserPotatoInteraction;
import com.gamjamubwatna.potato.domain.UserPotatoInteractionRepository;
import com.gamjamubwatna.potato.domain.UserPotatoRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PotatoQueryService {

    private static final int DAILY_STEP_GOAL = 10000;
    private static final double METERS_PER_KILOMETER = 1000.0;
    private static final ZoneId SERVICE_ZONE_ID = ZoneId.of("Asia/Seoul");

    private final PotatoRepository potatoRepository;
    private final UserPotatoRepository userPotatoRepository;
    private final UserDailyActivityRepository userDailyActivityRepository;
    private final UserPotatoInteractionRepository userPotatoInteractionRepository;
    private final UserRepository userRepository;
    private final PotatoCareStatusPolicy potatoCareStatusPolicy;
    private final Clock clock;

    @Autowired
    public PotatoQueryService(
        PotatoRepository potatoRepository,
        UserPotatoRepository userPotatoRepository,
        UserDailyActivityRepository userDailyActivityRepository,
        UserPotatoInteractionRepository userPotatoInteractionRepository,
        UserRepository userRepository,
        PotatoCareStatusPolicy potatoCareStatusPolicy
    ) {
        this(
            potatoRepository,
            userPotatoRepository,
            userDailyActivityRepository,
            userPotatoInteractionRepository,
            userRepository,
            potatoCareStatusPolicy,
            Clock.system(SERVICE_ZONE_ID)
        );
    }

    PotatoQueryService(
        PotatoRepository potatoRepository,
        UserPotatoRepository userPotatoRepository,
        UserDailyActivityRepository userDailyActivityRepository,
        UserPotatoInteractionRepository userPotatoInteractionRepository,
        UserRepository userRepository,
        PotatoCareStatusPolicy potatoCareStatusPolicy,
        Clock clock
    ) {
        this.potatoRepository = potatoRepository;
        this.userPotatoRepository = userPotatoRepository;
        this.userDailyActivityRepository = userDailyActivityRepository;
        this.userPotatoInteractionRepository = userPotatoInteractionRepository;
        this.userRepository = userRepository;
        this.potatoCareStatusPolicy = potatoCareStatusPolicy;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public PotatoCatalogResponse getPotatoes() {
        List<PotatoCatalogItemResponse> items = potatoRepository
            .findByActiveTrueOrderByDisplayOrderAsc()
            .stream()
            .map(PotatoCatalogItemResponse::from)
            .toList();

        return new PotatoCatalogResponse(items.size(), items);
    }

    @Transactional(readOnly = true)
    public UserPotatoCollectionResponse getMyPotatoes(Long userId) {
        if (!userRepository.existsById(userId)) {
            throw new PotatoAuthenticationException("사용자를 찾을 수 없습니다.");
        }

        List<Potato> potatoes = potatoRepository.findByActiveTrueOrderByDisplayOrderAsc();
        List<UserPotato> userPotatoes = userPotatoRepository.findByUserId(userId);
        Map<Long, UserPotato> userPotatoesByPotatoId = userPotatoes
            .stream()
            .collect(Collectors.toMap(
                userPotato -> userPotato.getPotato().getId(),
                Function.identity()
            ));
        List<Long> userPotatoIds = userPotatoes.stream()
            .map(UserPotato::getId)
            .filter(Objects::nonNull)
            .toList();
        Map<Long, List<UserPotatoInteraction>> interactionsByUserPotatoId = userPotatoIds.isEmpty()
            ? Map.of()
            : userPotatoInteractionRepository.findByUserPotatoIdIn(userPotatoIds)
                .stream()
                .collect(Collectors.groupingBy(
                    interaction -> interaction.getUserPotato().getId()
                ));
        Instant calculatedAt = Instant.now(clock);
        List<UserPotatoCollectionItemResponse> items = potatoes.stream()
            .map(potato -> {
                UserPotato userPotato = userPotatoesByPotatoId.get(potato.getId());
                return UserPotatoCollectionItemResponse.from(
                    potato,
                    userPotato,
                    userPotato == null
                        ? null
                        : potatoCareStatusPolicy.calculate(
                            userPotato,
                            userPotato.getId() == null
                                ? List.of()
                                : interactionsByUserPotatoId.getOrDefault(
                                    userPotato.getId(),
                                    List.of()
                                ),
                            calculatedAt
                        )
                );
            })
            .toList();

        return new UserPotatoCollectionResponse(
            items.size(),
            userPotatoesByPotatoId.size(),
            items
        );
    }

    @Transactional(readOnly = true)
    public PotatoGrowthSummaryResponse getGrowthSummary(Long userId) {
        return getGrowthSummary(userId, LocalDate.now(clock));
    }

    PotatoGrowthSummaryResponse getGrowthSummary(Long userId, LocalDate today) {
        if (!userRepository.existsById(userId)) {
            throw new PotatoAuthenticationException("사용자를 찾을 수 없습니다.");
        }

        LocalDate startOfMonth = today.withDayOfMonth(1);
        LocalDate startOfWeek = today.minusDays(6);
        LocalDate queryStartDate = startOfMonth.isBefore(startOfWeek) ? startOfMonth : startOfWeek;
        List<UserDailyActivity> activities =
            userDailyActivityRepository.findByUserIdAndActivityDateBetween(
                userId,
                queryStartDate,
                today
            );
        int todaySteps = activities.stream()
            .filter(activity -> activity.getActivityDate().isEqual(today))
            .mapToInt(UserDailyActivity::getSteps)
            .sum();
        double weeklyDistanceKm = activities.stream()
            .filter(activity -> !activity.getActivityDate().isBefore(startOfWeek))
            .mapToDouble(UserDailyActivity::getDistanceMeters)
            .sum() / METERS_PER_KILOMETER;
        double monthlyDistanceKm = activities.stream()
            .filter(activity -> !activity.getActivityDate().isBefore(startOfMonth))
            .mapToDouble(UserDailyActivity::getDistanceMeters)
            .sum() / METERS_PER_KILOMETER;

        return new PotatoGrowthSummaryResponse(
            todaySteps,
            DAILY_STEP_GOAL,
            weeklyDistanceKm,
            monthlyDistanceKm,
            remainingDistanceKmForRepresentative(userId)
        );
    }

    private double remainingDistanceKmForRepresentative(Long userId) {
        double remainingDistanceKmForRepresentative = userPotatoRepository.findByUserId(userId)
            .stream()
            .filter(UserPotato::isRepresentative)
            .findFirst()
            .map(this::remainingGrowthDistanceKm)
            .orElse(0.0);
        return remainingDistanceKmForRepresentative;
    }

    private double remainingGrowthDistanceKm(UserPotato userPotato) {
        if (userPotato.isFullyGrown()) {
            return 0.0;
        }
        double remainingMeters = Math.max(
            0.0,
            userPotato.getPotato().getGrowthGoalDistance() - userPotato.getGrowthDistance()
        );
        return remainingMeters / METERS_PER_KILOMETER;
    }
}
