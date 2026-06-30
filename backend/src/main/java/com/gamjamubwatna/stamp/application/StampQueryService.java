package com.gamjamubwatna.stamp.application;

import com.gamjamubwatna.stamp.api.StampBookResponse;
import com.gamjamubwatna.stamp.api.StampItemResponse;
import com.gamjamubwatna.stamp.api.StampRewardStatusResponse;
import com.gamjamubwatna.stamp.domain.Stamp;
import com.gamjamubwatna.stamp.domain.StampRepository;
import com.gamjamubwatna.stamp.domain.UserStamp;
import com.gamjamubwatna.stamp.domain.UserStampRepository;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class StampQueryService {

    private static final List<Integer> REWARD_TARGETS = List.of(6, 12, 18);

    private final StampRepository stampRepository;
    private final UserStampRepository userStampRepository;

    public StampQueryService(
        StampRepository stampRepository,
        UserStampRepository userStampRepository
    ) {
        this.stampRepository = stampRepository;
        this.userStampRepository = userStampRepository;
    }

    public StampBookResponse getStampBook(Long userId) {
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
        int acquiredCount = userStampRepository.countByUserId(userId);
        Integer nextTargetCount = REWARD_TARGETS.stream()
            .filter(target -> target > acquiredCount)
            .findFirst()
            .orElse(null);

        return new StampRewardStatusResponse(
            acquiredCount,
            nextTargetCount,
            nextTargetCount == null ? 0 : nextTargetCount - acquiredCount,
            nextTargetCount == null
        );
    }
}
