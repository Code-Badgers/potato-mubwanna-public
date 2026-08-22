package com.gamjamubwatna.stamp.domain;

import jakarta.persistence.LockModeType;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface StampRepository extends JpaRepository<Stamp, Long> {

    List<Stamp> findAllByOrderByDisplayOrderAsc();

    // 같은 관광지의 인증 요청이 동시에 처리돼도 패스포트 스탬프는 한 번만 지급한다.
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT stamp FROM Stamp stamp WHERE stamp.touristSpot.id = :touristSpotId")
    Optional<Stamp> findByTouristSpotIdForUpdate(
        @Param("touristSpotId") Long touristSpotId
    );
}
