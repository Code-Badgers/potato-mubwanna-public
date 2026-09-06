package com.gamjamubwatna.mission.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.mission.api.MissionVerifyRequest;
import com.gamjamubwatna.mission.domain.MissionRepository;
import com.gamjamubwatna.mission.domain.MissionType;
import com.gamjamubwatna.stamp.domain.UserStampRepository;
import com.gamjamubwatna.visit.api.VisitVerifyRequest;
import com.gamjamubwatna.visit.application.VisitDuplicateException;
import com.gamjamubwatna.visit.application.VisitVerificationService;
import com.gamjamubwatna.visit.domain.UserVisitRepository;
import java.nio.file.Path;
import java.time.Instant;
import java.util.Base64;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:photo_target_rewards;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa", "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
class PhotoTargetRewardFlowIntegrationTest {
    @TempDir static Path uploads;
    @DynamicPropertySource
    static void storage(DynamicPropertyRegistry registry) {
        registry.add("mission.upload.local-dir", () -> uploads.toString());
    }

    @Autowired UserRepository users;
    @Autowired MissionRepository missions;
    @Autowired MissionUploadService uploadService;
    @Autowired MissionService missionService;
    @Autowired VisitVerificationService visitService;
    @Autowired UserVisitRepository visits;
    @Autowired UserStampRepository stamps;

    @Test
    void uploadsPhotoThenIssuesVisitStampOnceWithMigratedTarget() {
        var mission = missions.findAllByOrderByDisplayOrderAsc().stream()
            .filter(m -> m.getCode().equals("MISSION_SOKCHO_YEONGGEUMJEONG_PHOTO"))
            .findFirst().orElseThrow();
        var spot = mission.getTargetSpot();
        var user = users.save(new User(AuthProvider.KAKAO, "photo-target-flow", null,
            "테스트", null, Instant.now()));
        byte[] png = Base64.getDecoder().decode(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aH7sAAAAASUVORK5CYII=");
        var uploaded = uploadService.issueUploadKey(user.getId(), mission.getId(),
            new MockMultipartFile("file", "test.png", "image/png", png));
        var request = new MissionVerifyRequest(MissionType.PHOTO, null, null, uploaded.uploadKey(),
            null, spot.getLatitude(), spot.getLongitude());
        assertThat(missionService.verifyMission(user.getId(), mission.getId(), request).completed()).isTrue();
        var photoVisits = visits.findByUserIdOrderByVisitedAtDesc(user.getId());
        assertThat(photoVisits).hasSize(1);
        assertThat(photoVisits.getFirst().isVisitRewardsProcessed()).isFalse();
        assertThat(stamps.countByUserId(user.getId())).isZero();

        var visitRequest = new VisitVerifyRequest(spot.getId(), spot.getLatitude(), spot.getLongitude());
        assertThat(visitService.verifyVisit(user.getId(), visitRequest).stampIssued()).isTrue();
        assertThatThrownBy(() -> visitService.verifyVisit(user.getId(), visitRequest))
            .isInstanceOf(VisitDuplicateException.class);
        assertThatThrownBy(() -> missionService.verifyMission(user.getId(), mission.getId(), request))
            .isInstanceOf(MissionAlreadyCompletedException.class);
        assertThat(visits.findByUserIdOrderByVisitedAtDesc(user.getId())).hasSize(1);
        assertThat(stamps.countByUserId(user.getId())).isEqualTo(1);
    }
}
