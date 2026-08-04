package com.gamjamubwatna.potato.domain;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PotatoRepository extends JpaRepository<Potato, Long> {

    List<Potato> findByActiveTrueOrderByDisplayOrderAsc();
}
