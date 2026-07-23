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

    // 같은 지역의 서로 다른 스팟이 동시에 인증돼도 스탬프는 한 번만 지급한다.
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT stamp FROM Stamp stamp WHERE stamp.cityName = :cityName")
    Optional<Stamp> findByCityNameForUpdate(@Param("cityName") String cityName);
}
