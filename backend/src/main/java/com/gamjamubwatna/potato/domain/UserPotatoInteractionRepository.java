package com.gamjamubwatna.potato.domain;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserPotatoInteractionRepository extends JpaRepository<UserPotatoInteraction, Long> {

    Optional<UserPotatoInteraction> findTopByUserPotatoIdAndActionOrderByInteractedAtDesc(
        Long userPotatoId,
        PotatoInteractionAction action
    );
}
