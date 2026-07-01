package com.gamjamubwatna.mission.application;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.mission.api.MissionCompleteResponse;
import com.gamjamubwatna.mission.api.MissionItemResponse;
import com.gamjamubwatna.mission.api.MissionListResponse;
import com.gamjamubwatna.mission.domain.Mission;
import com.gamjamubwatna.mission.domain.MissionRepository;
import com.gamjamubwatna.mission.domain.MissionStatus;
import com.gamjamubwatna.mission.domain.UserMission;
import com.gamjamubwatna.mission.domain.UserMissionRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MissionService {

    private final MissionRepository missionRepository;
    private final UserMissionRepository userMissionRepository;
    private final UserRepository userRepository;
    private final Clock clock;

    @Autowired
    public MissionService(
        MissionRepository missionRepository,
        UserMissionRepository userMissionRepository,
        UserRepository userRepository
    ) {
        this(missionRepository, userMissionRepository, userRepository, Clock.systemUTC());
    }

    MissionService(
        MissionRepository missionRepository,
        UserMissionRepository userMissionRepository,
        UserRepository userRepository,
        Clock clock
    ) {
        this.missionRepository = missionRepository;
        this.userMissionRepository = userMissionRepository;
        this.userRepository = userRepository;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public MissionListResponse getMissions(Long userId) {
        validateUser(userId);

        List<Mission> missions = missionRepository.findAllByOrderByDisplayOrderAsc();
        Map<Long, UserMission> completedByMissionId = userMissionRepository.findByUserId(userId)
            .stream()
            .collect(Collectors.toMap(
                userMission -> userMission.getMission().getId(),
                Function.identity()
            ));
        List<MissionItemResponse> items = missions.stream()
            .map(mission -> MissionItemResponse.from(
                mission,
                completedByMissionId.get(mission.getId())
            ))
            .toList();

        return new MissionListResponse(
            items.size(),
            (int) items.stream().filter(MissionItemResponse::completed).count(),
            items
        );
    }

    @Transactional(readOnly = true)
    public MissionItemResponse getMission(Long userId, Long missionId) {
        validateUser(userId);
        Mission mission = mission(missionId);
        UserMission userMission = userMissionRepository.findByUserIdAndMissionId(userId, missionId)
            .orElse(null);
        return MissionItemResponse.from(mission, userMission);
    }

    @Transactional
    public MissionCompleteResponse completeMission(Long userId, Long missionId) {
        User user = user(userId);
        Mission mission = mission(missionId);
        if (!mission.isActive() || mission.getDefaultStatus() == MissionStatus.LOCKED) {
            throw new MissionCompletionException("아직 완료할 수 없는 미션입니다.");
        }
        if (userMissionRepository.existsByUserIdAndMissionId(userId, missionId)) {
            throw new MissionAlreadyCompletedException("이미 완료한 미션입니다.");
        }

        Instant completedAt = Instant.now(clock);
        UserMission userMission = userMissionRepository.save(new UserMission(
            user,
            mission,
            completedAt
        ));

        return new MissionCompleteResponse(
            mission.getId(),
            true,
            userMission.getCompletedAt(),
            mission.getRewardType(),
            mission.getRewardLabel()
        );
    }

    private void validateUser(Long userId) {
        if (!userRepository.existsById(userId)) {
            throw new MissionAuthenticationException("사용자를 찾을 수 없습니다.");
        }
    }

    private User user(Long userId) {
        return userRepository.findById(userId)
            .orElseThrow(() -> new MissionAuthenticationException("사용자를 찾을 수 없습니다."));
    }

    private Mission mission(Long missionId) {
        return missionRepository.findById(missionId)
            .orElseThrow(() -> new MissionNotFoundException("미션을 찾을 수 없습니다."));
    }
}
