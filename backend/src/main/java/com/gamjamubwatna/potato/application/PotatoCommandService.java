package com.gamjamubwatna.potato.application;

import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.potato.api.PotatoRepresentativeResponse;
import com.gamjamubwatna.potato.domain.UserPotato;
import com.gamjamubwatna.potato.domain.UserPotatoRepository;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PotatoCommandService {

    private final UserPotatoRepository userPotatoRepository;
    private final UserRepository userRepository;

    public PotatoCommandService(
        UserPotatoRepository userPotatoRepository,
        UserRepository userRepository
    ) {
        this.userPotatoRepository = userPotatoRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public PotatoRepresentativeResponse updateRepresentativePotato(Long userId, Long potatoId) {
        if (!userRepository.existsById(userId)) {
            throw new PotatoAuthenticationException("사용자를 찾을 수 없습니다.");
        }
        if (potatoId == null || potatoId < 1) {
            throw new PotatoRepresentativeException("대표 감자를 확인할 수 없습니다.");
        }

        List<UserPotato> userPotatoes = userPotatoRepository.findByUserId(userId);
        UserPotato selected = userPotatoes.stream()
            .filter(userPotato -> userPotato.getPotato().getId().equals(potatoId))
            .findFirst()
            .orElseThrow(() -> new PotatoRepresentativeException(
                "획득한 감자만 대표 감자로 설정할 수 있습니다."
            ));

        // 대표 감자는 사용자당 하나만 유지해야 하므로, 같은 감자를 다시 선택해도 전체 상태를 정규화한다.
        userPotatoes.forEach(userPotato -> {
            if (userPotato == selected) {
                userPotato.markRepresentative();
                return;
            }
            userPotato.unmarkRepresentative();
        });

        return PotatoRepresentativeResponse.from(selected);
    }
}
