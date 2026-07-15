package com.gamjamubwatna.potato.application;

import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.potato.api.PotatoCatalogItemResponse;
import com.gamjamubwatna.potato.api.PotatoCatalogResponse;
import com.gamjamubwatna.potato.api.UserPotatoCollectionItemResponse;
import com.gamjamubwatna.potato.api.UserPotatoCollectionResponse;
import com.gamjamubwatna.potato.domain.Potato;
import com.gamjamubwatna.potato.domain.PotatoRepository;
import com.gamjamubwatna.potato.domain.UserPotato;
import com.gamjamubwatna.potato.domain.UserPotatoRepository;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PotatoQueryService {

    private final PotatoRepository potatoRepository;
    private final UserPotatoRepository userPotatoRepository;
    private final UserRepository userRepository;

    public PotatoQueryService(
        PotatoRepository potatoRepository,
        UserPotatoRepository userPotatoRepository,
        UserRepository userRepository
    ) {
        this.potatoRepository = potatoRepository;
        this.userPotatoRepository = userPotatoRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public PotatoCatalogResponse getPotatoes() {
        List<PotatoCatalogItemResponse> items = potatoRepository
            .findByActiveTrueOrderByDisplayOrderAsc()
            .stream()
            .map(PotatoCatalogItemResponse::from)
            .toList();

        return new PotatoCatalogResponse(items.size(), items);
    }

    @Transactional(readOnly = true)
    public UserPotatoCollectionResponse getMyPotatoes(Long userId) {
        if (!userRepository.existsById(userId)) {
            throw new PotatoAuthenticationException("사용자를 찾을 수 없습니다.");
        }

        List<Potato> potatoes = potatoRepository.findByActiveTrueOrderByDisplayOrderAsc();
        Map<Long, UserPotato> userPotatoesByPotatoId = userPotatoRepository.findByUserId(userId)
            .stream()
            .collect(Collectors.toMap(
                userPotato -> userPotato.getPotato().getId(),
                Function.identity()
            ));
        List<UserPotatoCollectionItemResponse> items = potatoes.stream()
            .map(potato -> UserPotatoCollectionItemResponse.from(
                potato,
                userPotatoesByPotatoId.get(potato.getId())
            ))
            .toList();

        return new UserPotatoCollectionResponse(
            items.size(),
            userPotatoesByPotatoId.size(),
            items
        );
    }
}
