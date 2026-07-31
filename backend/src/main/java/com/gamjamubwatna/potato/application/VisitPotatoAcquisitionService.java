package com.gamjamubwatna.potato.application;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.potato.api.PotatoAcquisitionResponse;
import com.gamjamubwatna.potato.domain.Potato;
import com.gamjamubwatna.potato.domain.PotatoRepository;
import com.gamjamubwatna.potato.domain.PotatoRarity;
import com.gamjamubwatna.potato.domain.UserPotato;
import com.gamjamubwatna.potato.domain.UserPotatoRepository;
import com.gamjamubwatna.spot.domain.CongestionLevel;
import com.gamjamubwatna.spot.domain.TouristSpot;
import java.time.Instant;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class VisitPotatoAcquisitionService {

    private final PotatoRepository potatoRepository;
    private final UserPotatoRepository userPotatoRepository;
    private final CongestionRarityPolicy congestionRarityPolicy;

    public VisitPotatoAcquisitionService(
        PotatoRepository potatoRepository,
        UserPotatoRepository userPotatoRepository,
        CongestionRarityPolicy congestionRarityPolicy
    ) {
        this.potatoRepository = potatoRepository;
        this.userPotatoRepository = userPotatoRepository;
        this.congestionRarityPolicy = congestionRarityPolicy;
    }

    @Transactional
    public PotatoAcquisitionResult acquireForVisit(User user, TouristSpot spot, Instant acquiredAt) {
        Potato potato = selectPotato(spot.getCongestionLevel());
        boolean alreadyOwned = userPotatoRepository
            .findByUserIdAndPotatoId(user.getId(), potato.getId())
            .isPresent();

        if (!alreadyOwned) {
            boolean firstPotato = userPotatoRepository.countByUserId(user.getId()) == 0;
            userPotatoRepository.save(new UserPotato(user, potato, acquiredAt, 1, 0.0, firstPotato));
        }

        return new PotatoAcquisitionResult(
            !alreadyOwned,
            PotatoAcquisitionResponse.from(potato, alreadyOwned)
        );
    }

    private Potato selectPotato(CongestionLevel congestionLevel) {
        // 방문 인증 기본 보상에서는 전설 감자를 제외한다. 전설 등급은 미션/장기 성장 보상으로 분리한다.
        for (PotatoRarity rarity : congestionRarityPolicy.visitAcquisitionCandidates(congestionLevel)) {
            java.util.Optional<Potato> potato =
                potatoRepository.findFirstByActiveTrueAndRarityOrderByDisplayOrderAsc(rarity);
            if (potato.isPresent()) {
                return potato.get();
            }
        }
        throw new PotatoRepresentativeException("방문 인증으로 지급할 감자를 찾을 수 없습니다.");
    }

    public record PotatoAcquisitionResult(
        boolean newlyAcquired,
        PotatoAcquisitionResponse potato
    ) {
    }
}
