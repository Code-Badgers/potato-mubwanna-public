package com.gamjamubwatna.legal.domain;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LegalConsentEventRepository extends JpaRepository<LegalConsentEvent, Long> {

    Optional<LegalConsentEvent> findFirstByUserIdAndTypeOrderByRecordedAtDescIdDesc(
        Long userId,
        LegalConsentType type
    );
}
