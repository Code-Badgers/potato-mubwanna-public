package com.gamjamubwatna.potato.application;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.potato.api.PotatoAcquisitionResponse;
import com.gamjamubwatna.potato.domain.Potato;
import com.gamjamubwatna.potato.domain.PotatoAcquisitionType;
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

    private static final String PROVINCE_REGION = "강원특별자치도";

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

        Optional<Potato> selectedPotato = selectPotato(spot, ownedPotatoIds);
        if (selectedPotato.isEmpty()) {
            return new PotatoAcquisitionResult(false, null);
        }

        Potato potato = selectedPotato.get();
        boolean alreadyOwned = ownedPotatoIds.contains(potato.getId());

        if (!alreadyOwned) {
            boolean firstPotato = ownedPotatoes.isEmpty();
            userPotatoRepository.save(new UserPotato(
                user,
                potato,
                acquiredAt,
                1,
                0.0,
                firstPotato,
                PotatoAcquisitionType.VISIT
            ));
        }

        return new PotatoAcquisitionResult(
            !alreadyOwned,
            PotatoAcquisitionResponse.from(potato, alreadyOwned, PotatoAcquisitionType.VISIT)
        );
    }

    private Optional<Potato> selectPotato(TouristSpot spot, Set<Long> ownedPotatoIds) {
        List<Potato> activePotatoes = potatoRepository.findByActiveTrueOrderByDisplayOrderAsc();
        List<PotatoRarity> rarityOrder =
            congestionRarityPolicy.visitAcquisitionCandidates(spot.getCongestionLevel());

        // 다른 시군의 미션 전용 감자는 방문 대체 보상으로 사용하지 않는다.
        return findCandidate(activePotatoes, rarityOrder, ownedPotatoIds, spot.getCityName(), true)
            .or(() -> findCandidate(activePotatoes, rarityOrder, ownedPotatoIds, spot.getCityName(), false))
            .or(() -> findCandidate(activePotatoes, rarityOrder, ownedPotatoIds, PROVINCE_REGION, true))
            .or(() -> findCandidate(activePotatoes, rarityOrder, ownedPotatoIds, PROVINCE_REGION, false));
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
