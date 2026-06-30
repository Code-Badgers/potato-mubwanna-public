package com.gamjamubwatna.stamp.domain;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StampRepository extends JpaRepository<Stamp, Long> {

    List<Stamp> findAllByOrderByDisplayOrderAsc();
}
