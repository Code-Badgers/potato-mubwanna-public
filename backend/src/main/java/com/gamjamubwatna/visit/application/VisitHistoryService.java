package com.gamjamubwatna.visit.application;

import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.visit.api.VisitHistoryResponse;
import com.gamjamubwatna.visit.domain.UserVisitRepository;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class VisitHistoryService {

    private final UserRepository userRepository;
    private final UserVisitRepository userVisitRepository;

    public VisitHistoryService(
        UserRepository userRepository,
        UserVisitRepository userVisitRepository
    ) {
        this.userRepository = userRepository;
        this.userVisitRepository = userVisitRepository;
    }

    public List<VisitHistoryResponse> getMyVisits(Long userId) {
        if (!userRepository.existsById(userId)) {
            throw new VisitAuthenticationException("인증 정보를 확인할 수 없습니다.");
        }

        return userVisitRepository.findByUserIdOrderByVisitedAtDesc(userId)
            .stream()
            .map(VisitHistoryResponse::from)
            .toList();
    }
}
