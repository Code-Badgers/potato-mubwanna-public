package com.gamjamubwatna.spot.domain;

import java.util.Collection;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface SpotMenuItemRepository extends JpaRepository<SpotMenuItem, Long> {

    @Query("""
        SELECT item
        FROM SpotMenuItem item
        WHERE item.touristSpotId IN :touristSpotIds
          AND item.active = true
        ORDER BY item.touristSpotId ASC, item.displayOrder ASC, item.id ASC
        """)
    List<SpotMenuItem> findActiveByTouristSpotIds(
        @Param("touristSpotIds") Collection<Long> touristSpotIds
    );
}
