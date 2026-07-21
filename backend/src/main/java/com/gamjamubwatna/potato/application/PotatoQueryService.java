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
import com.gamjamubwatna.potato.domain.UserPotatoRepository;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PotatoQueryService {

    private static final int MVP_TODAY_STEPS = 7842;
    private static final int MVP_DAILY_STEP_GOAL = 10000;
    private static final double MVP_WEEKLY_DISTANCE_KM = 28.4;
    private static final double MVP_MONTHLY_DISTANCE_KM = 116.8;
    private static final double METERS_PER_KILOMETER = 1000.0;

    private final PotatoRepository potatoRepository;
    private final UserPotatoRepository userPotatoRepository;
    private final UserDailyActivityRepository userDailyActivityRepository;
    private final UserRepository userRepository;

    public PotatoQueryService(
        PotatoRepository potatoRepository,
        UserPotatoRepository userPotatoRepository,
        UserDailyActivityRepository userDailyActivityRepository,
        UserRepository userRepository
    ) {
        this.potatoRepository = potatoRepository;
        this.userPotatoRepository = userPotatoRepository;
        this.userDailyActivityRepository = userDailyActivityRepository;
        this.userRepository = userRepository;
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
        Map<Long, UserPotato> userPotatoesByPotatoId = userPotatoRepository.findByUserId(userId)
            .stream()
            .collect(Collectors.toMap(
                userPotato -> userPotato.getPotato().getId(),
                Function.identity()
            ));
        List<UserPotatoCollectionItemResponse> items = potatoes.stream()
            .map(potato -> UserPotatoCollectionItemResponse.from(
                potato,
                userPotatoesByPotatoId.get(potato.getId())
            ))
            .toList();

        return new UserPotatoCollectionResponse(
            items.size(),
            userPotatoesByPotatoId.size(),
            items
        );
    }

    @Transactional(readOnly = true)
    public PotatoGrowthSummaryResponse getGrowthSummary(Long userId) {
        if (!userRepository.existsById(userId)) {
            throw new PotatoAuthenticationException("사용자를 찾을 수 없습니다.");
        }

        LocalDate today = LocalDate.now();
        List<UserDailyActivity> monthlyActivities =
            userDailyActivityRepository.findByUserIdAndActivityDateBetween(
                userId,
                today.withDayOfMonth(1),
                today
            );
        if (monthlyActivities.isEmpty()) {
            return mvpGrowthSummary(userId);
        }

        int todaySteps = monthlyActivities.stream()
            .filter(activity -> activity.getActivityDate().isEqual(today))
            .mapToInt(UserDailyActivity::getSteps)
            .sum();
        double weeklyDistanceKm = monthlyActivities.stream()
            .filter(activity -> !activity.getActivityDate().isBefore(today.minusDays(6)))
            .mapToDouble(UserDailyActivity::getDistanceMeters)
            .sum() / METERS_PER_KILOMETER;
        double monthlyDistanceKm = monthlyActivities.stream()
            .mapToDouble(UserDailyActivity::getDistanceMeters)
            .sum() / METERS_PER_KILOMETER;

        return new PotatoGrowthSummaryResponse(
            todaySteps,
            MVP_DAILY_STEP_GOAL,
            weeklyDistanceKm,
            monthlyDistanceKm,
            remainingDistanceKmForRepresentative(userId)
        );
    }

    private PotatoGrowthSummaryResponse mvpGrowthSummary(Long userId) {
        return new PotatoGrowthSummaryResponse(
            MVP_TODAY_STEPS,
            MVP_DAILY_STEP_GOAL,
            MVP_WEEKLY_DISTANCE_KM,
            MVP_MONTHLY_DISTANCE_KM,
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
        double remainingMeters = Math.max(
            0.0,
            userPotato.getPotato().getGrowthGoalDistance() - userPotato.getGrowthDistance()
        );
        return remainingMeters / METERS_PER_KILOMETER;
    }
}
