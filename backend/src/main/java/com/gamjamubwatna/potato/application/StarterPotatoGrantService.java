package com.gamjamubwatna.potato.application;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.potato.domain.Potato;
import com.gamjamubwatna.potato.domain.PotatoRepository;
import com.gamjamubwatna.potato.domain.UserPotato;
import com.gamjamubwatna.potato.domain.UserPotatoRepository;
import java.time.Instant;
import org.springframework.stereotype.Service;

@Service
public class StarterPotatoGrantService {

    public static final String STARTER_POTATO_CODE = "POTATO_DEFAULT_BEGINNER";

    private final PotatoRepository potatoRepository;
    private final UserPotatoRepository userPotatoRepository;

    public StarterPotatoGrantService(
        PotatoRepository potatoRepository,
        UserPotatoRepository userPotatoRepository
    ) {
        this.potatoRepository = potatoRepository;
        this.userPotatoRepository = userPotatoRepository;
    }

    public void grantIfNeeded(User user, Instant acquiredAt) {
        if (userPotatoRepository.countByUserId(user.getId()) > 0) {
            return;
        }

        Potato starterPotato = potatoRepository.findByCode(STARTER_POTATO_CODE)
            .orElseThrow(() -> new IllegalStateException(
                "기본 감자 카탈로그를 찾을 수 없습니다."
            ));

        userPotatoRepository.save(new UserPotato(
            user,
            starterPotato,
            acquiredAt,
            1,
            0,
            true
        ));
    }
}
