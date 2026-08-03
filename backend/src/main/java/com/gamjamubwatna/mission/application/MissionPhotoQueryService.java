package com.gamjamubwatna.mission.application;

import com.gamjamubwatna.mission.domain.UserMission;
import com.gamjamubwatna.mission.domain.UserMissionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class MissionPhotoQueryService {

    private final UserMissionRepository userMissionRepository;
    private final MissionPhotoStorage missionPhotoStorage;

    public MissionPhotoQueryService(
        UserMissionRepository userMissionRepository,
        MissionPhotoStorage missionPhotoStorage
    ) {
        this.userMissionRepository = userMissionRepository;
        this.missionPhotoStorage = missionPhotoStorage;
    }

    public StoredMissionPhotoFile getCompletedMissionPhoto(Long userId, Long completionId) {
        UserMission completion = userMissionRepository
            .findOwnedEvidenceCompletion(completionId, userId)
            .orElseThrow(MissionPhotoNotFoundException::new);
        try {
            return missionPhotoStorage.read(completion.getEvidenceUploadKey());
        } catch (MissionUploadException exception) {
            // DB 관계는 남아 있어도 실제 파일이 없으면 외부에는 동일한 404만 노출한다.
            throw new MissionPhotoNotFoundException();
        }
    }
}
