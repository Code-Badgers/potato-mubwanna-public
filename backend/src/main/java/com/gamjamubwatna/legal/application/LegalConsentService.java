package com.gamjamubwatna.legal.application;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.legal.api.LegalConsentSnapshotResponse;
import com.gamjamubwatna.legal.api.LegalConsentSyncRequest;
import com.gamjamubwatna.legal.domain.LegalConsentEvent;
import com.gamjamubwatna.legal.domain.LegalConsentEventRepository;
import com.gamjamubwatna.legal.domain.LegalConsentType;
import com.gamjamubwatna.user.application.UserProfileAuthenticationException;
import java.time.Clock;
import java.time.Instant;
import java.util.Optional;
import java.util.regex.Pattern;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class LegalConsentService {

    private static final Pattern VERSION_PATTERN = Pattern.compile("^[A-Za-z0-9._-]{1,80}$");

    private final UserRepository userRepository;
    private final LegalConsentEventRepository eventRepository;
    private final Clock clock;

    @Autowired
    public LegalConsentService(
        UserRepository userRepository,
        LegalConsentEventRepository eventRepository
    ) {
        this(userRepository, eventRepository, Clock.systemUTC());
    }

    LegalConsentService(
        UserRepository userRepository,
        LegalConsentEventRepository eventRepository,
        Clock clock
    ) {
        this.userRepository = userRepository;
        this.eventRepository = eventRepository;
        this.clock = clock;
    }

    @Transactional
    public void synchronize(Long userId, LegalConsentSyncRequest request) {
        if (request == null || !isValidVersion(request.requiredDocumentsVersion())) {
            throw new IllegalArgumentException("필수 약관 버전을 확인해주세요.");
        }
        validateOptionalVersion(request.personalLocationConsentVersion());
        validateOptionalVersion(request.healthDataConsentVersion());

        User user = userRepository.findById(userId)
            .orElseThrow(() -> new UserProfileAuthenticationException("사용자를 찾을 수 없습니다."));
        Instant now = Instant.now(clock);

        recordIfChanged(
            user,
            LegalConsentType.REQUIRED_DOCUMENTS,
            request.requiredDocumentsVersion(),
            true,
            now
        );
        synchronizeOptional(
            user,
            LegalConsentType.PERSONAL_LOCATION,
            request.personalLocationConsentVersion(),
            now
        );
        synchronizeOptional(
            user,
            LegalConsentType.HEALTH_DATA,
            request.healthDataConsentVersion(),
            now
        );
    }

    @Transactional(readOnly = true)
    public LegalConsentSnapshotResponse getSnapshot(Long userId) {
        userRepository.findById(userId)
            .orElseThrow(() -> new UserProfileAuthenticationException("사용자를 찾을 수 없습니다."));

        return new LegalConsentSnapshotResponse(
            latestAcceptedVersion(userId, LegalConsentType.REQUIRED_DOCUMENTS),
            latestAcceptedVersion(userId, LegalConsentType.PERSONAL_LOCATION),
            latestAcceptedVersion(userId, LegalConsentType.HEALTH_DATA)
        );
    }

    private String latestAcceptedVersion(Long userId, LegalConsentType type) {
        return eventRepository
            .findFirstByUserIdAndTypeOrderByRecordedAtDescIdDesc(userId, type)
            .filter(LegalConsentEvent::isAccepted)
            .map(LegalConsentEvent::getDocumentVersion)
            .orElse(null);
    }

    private void synchronizeOptional(
        User user,
        LegalConsentType type,
        String acceptedVersion,
        Instant now
    ) {
        Optional<LegalConsentEvent> latest = eventRepository
            .findFirstByUserIdAndTypeOrderByRecordedAtDescIdDesc(user.getId(), type);
        if (acceptedVersion != null) {
            recordIfChanged(user, type, acceptedVersion, true, now, latest);
        } else if (latest.filter(LegalConsentEvent::isAccepted).isPresent()) {
            recordIfChanged(user, type, latest.get().getDocumentVersion(), false, now, latest);
        }
    }

    private void recordIfChanged(
        User user,
        LegalConsentType type,
        String version,
        boolean accepted,
        Instant now
    ) {
        Optional<LegalConsentEvent> latest = eventRepository
            .findFirstByUserIdAndTypeOrderByRecordedAtDescIdDesc(user.getId(), type);
        recordIfChanged(user, type, version, accepted, now, latest);
    }

    private void recordIfChanged(
        User user,
        LegalConsentType type,
        String version,
        boolean accepted,
        Instant now,
        Optional<LegalConsentEvent> latest
    ) {
        if (latest.isPresent()
            && latest.get().isAccepted() == accepted
            && latest.get().getDocumentVersion().equals(version)) {
            return;
        }
        eventRepository.save(new LegalConsentEvent(user, type, version, accepted, now));
    }

    private void validateOptionalVersion(String version) {
        if (version != null && !isValidVersion(version)) {
            throw new IllegalArgumentException("선택 동의 버전을 확인해주세요.");
        }
    }

    private boolean isValidVersion(String version) {
        return version != null && VERSION_PATTERN.matcher(version).matches();
    }
}
