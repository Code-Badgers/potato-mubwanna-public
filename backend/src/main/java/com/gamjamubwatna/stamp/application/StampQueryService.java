package com.gamjamubwatna.stamp.application;

import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.reward.domain.RewardHistoryRepository;
import com.gamjamubwatna.reward.domain.RewardSourceType;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import com.gamjamubwatna.stamp.api.RallybookSpotResponse;
import com.gamjamubwatna.stamp.api.StampBookResponse;
import com.gamjamubwatna.stamp.api.StampItemResponse;
import com.gamjamubwatna.stamp.api.StampNextTargetResponse;
import com.gamjamubwatna.stamp.api.StampRewardStatusResponse;
import com.gamjamubwatna.stamp.domain.Stamp;
import com.gamjamubwatna.stamp.domain.StampRepository;
import com.gamjamubwatna.stamp.domain.StampRewardPolicy;
import com.gamjamubwatna.stamp.domain.UserStamp;
import com.gamjamubwatna.stamp.domain.UserStampRepository;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class StampQueryService {

    private static final int NEXT_TARGET_LIMIT = 3;

    private final StampRepository stampRepository;
    private final UserStampRepository userStampRepository;
    private final UserRepository userRepository;
    private final RewardHistoryRepository rewardHistoryRepository;
    private final TouristSpotRepository touristSpotRepository;

    public StampQueryService(
        StampRepository stampRepository,
        UserStampRepository userStampRepository,
        UserRepository userRepository,
        RewardHistoryRepository rewardHistoryRepository,
        TouristSpotRepository touristSpotRepository
    ) {
        this.stampRepository = stampRepository;
        this.userStampRepository = userStampRepository;
        this.userRepository = userRepository;
        this.rewardHistoryRepository = rewardHistoryRepository;
        this.touristSpotRepository = touristSpotRepository;
    }

    public StampBookResponse getStampBook(Long userId) {
        validateUser(userId);
        List<Stamp> stamps = stampRepository.findAllByOrderByDisplayOrderAsc();
        Map<Long, UserStamp> acquiredByStampId = userStampRepository
            .findByUserIdWithStamp(userId)
            .stream()
            .collect(Collectors.toMap(
                userStamp -> userStamp.getStamp().getId(),
                Function.identity()
            ));

        List<StampItemResponse> items = stamps.stream()
            .map(stamp -> StampItemResponse.from(stamp, acquiredByStampId.get(stamp.getId())))
            .toList();
        int acquiredCount = (int) items.stream()
            .filter(StampItemResponse::acquired)
            .count();

        return new StampBookResponse(items.size(), acquiredCount, items);
    }

    public StampRewardStatusResponse getRewardStatus(Long userId) {
        validateUser(userId);
        int acquiredCount = userStampRepository.countByUserId(userId);
        int totalCount = Math.toIntExact(stampRepository.count());
        Integer nextTargetCount = StampRewardPolicy.nextTargetCount(acquiredCount);
        Set<Long> claimedTargetCounts = Set.copyOf(
            rewardHistoryRepository.findSourceIdsByUserIdAndSourceType(
                userId,
                RewardSourceType.STAMP
            )
        );
        Integer claimableTargetCount = StampRewardPolicy.claimableTargetCount(
            acquiredCount,
            claimedTargetCounts
        );

        return new StampRewardStatusResponse(
            acquiredCount,
            nextTargetCount,
            nextTargetCount == null
                ? Math.max(totalCount - acquiredCount, 0)
                : nextTargetCount - acquiredCount,
            acquiredCount >= totalCount,
            claimableTargetCount != null,
            claimableTargetCount
        );
    }

    public List<StampNextTargetResponse> getNextTargets(Long userId) {
        validateUser(userId);
        Set<Long> acquiredStampIds = userStampRepository.findByUserIdWithStamp(userId)
            .stream()
            .map(userStamp -> userStamp.getStamp().getId())
            .collect(Collectors.toSet());
        return stampRepository.findAllByOrderByDisplayOrderAsc()
            .stream()
            .filter(stamp -> !acquiredStampIds.contains(stamp.getId()))
            .map(Stamp::getTouristSpot)
            .limit(NEXT_TARGET_LIMIT)
            .map(StampNextTargetResponse::from)
            .toList();
    }

    public List<RallybookSpotResponse> getRallybookSpots(Long userId) {
        validateUser(userId);
        Map<Long, Integer> spotDisplayOrders = stampRepository
            .findAllByOrderByDisplayOrderAsc()
            .stream()
            .collect(Collectors.toMap(
                stamp -> stamp.getTouristSpot().getId(),
                Stamp::getDisplayOrder
            ));

        return touristSpotRepository.findActiveRallybookSpots()
            .stream()
            .sorted(java.util.Comparator.comparingInt(spot -> spotDisplayOrders.getOrDefault(
                spot.getId(),
                Integer.MAX_VALUE
            )))
            .map(RallybookSpotResponse::from)
            .toList();
    }

    private void validateUser(Long userId) {
        if (!userRepository.existsById(userId)) {
            throw new StampAuthenticationException("사용자를 찾을 수 없습니다.");
        }
    }
}
