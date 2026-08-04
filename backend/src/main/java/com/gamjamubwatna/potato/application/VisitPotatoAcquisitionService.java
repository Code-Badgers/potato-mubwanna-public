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
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
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
        List<UserPotato> ownedPotatoes = userPotatoRepository.findByUserId(user.getId());
        Set<Long> ownedPotatoIds = new HashSet<>();
        for (UserPotato ownedPotato : ownedPotatoes) {
            ownedPotatoIds.add(ownedPotato.getPotato().getId());
        }

        Potato potato = selectPotato(spot, ownedPotatoIds);
        boolean alreadyOwned = ownedPotatoIds.contains(potato.getId());

        if (!alreadyOwned) {
            boolean firstPotato = ownedPotatoes.isEmpty();
            userPotatoRepository.save(new UserPotato(user, potato, acquiredAt, 1, 0.0, firstPotato));
        }

        return new PotatoAcquisitionResult(
            !alreadyOwned,
            PotatoAcquisitionResponse.from(potato, alreadyOwned)
        );
    }

    private Potato selectPotato(TouristSpot spot, Set<Long> ownedPotatoIds) {
        List<Potato> activePotatoes = potatoRepository.findByActiveTrueOrderByDisplayOrderAsc();
        List<PotatoRarity> rarityOrder =
            congestionRarityPolicy.visitAcquisitionCandidates(spot.getCongestionLevel());

        // 지역 획득 힌트와 실제 보상을 맞추되, 지역 안에서는 기존 혼잡도별 희귀도 순서를 유지한다.
        return findCandidate(activePotatoes, rarityOrder, ownedPotatoIds, spot.getCityName(), true)
            .or(() -> findCandidate(activePotatoes, rarityOrder, ownedPotatoIds, spot.getCityName(), false))
            .or(() -> findCandidate(activePotatoes, rarityOrder, ownedPotatoIds, null, true))
            .or(() -> findCandidate(activePotatoes, rarityOrder, ownedPotatoIds, null, false))
            .orElseThrow(() -> new PotatoRepresentativeException("방문 인증으로 지급할 감자를 찾을 수 없습니다."));
    }

    private Optional<Potato> findCandidate(
        List<Potato> activePotatoes,
        List<PotatoRarity> rarityOrder,
        Set<Long> ownedPotatoIds,
        String region,
        boolean unownedOnly
    ) {
        // 방문 인증 기본 보상에서는 전설 감자를 제외한다. 전설 등급은 미션/장기 성장 보상으로 분리한다.
        for (PotatoRarity rarity : rarityOrder) {
            for (Potato potato : activePotatoes) {
                if (potato.getRarity() != rarity) {
                    continue;
                }
                if (region != null && !Objects.equals(region, potato.getRegion())) {
                    continue;
                }
                if (unownedOnly && ownedPotatoIds.contains(potato.getId())) {
                    continue;
                }
                return Optional.of(potato);
            }
        }
        return Optional.empty();
    }

    public record PotatoAcquisitionResult(
        boolean newlyAcquired,
        PotatoAcquisitionResponse potato
    ) {
    }
}
