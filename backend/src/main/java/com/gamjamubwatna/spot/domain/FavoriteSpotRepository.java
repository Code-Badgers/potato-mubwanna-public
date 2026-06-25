package com.gamjamubwatna.spot.domain;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface FavoriteSpotRepository extends JpaRepository<FavoriteSpot, Long> {

    boolean existsByUserIdAndTouristSpotId(Long userId, Long touristSpotId);

    Optional<FavoriteSpot> findByUserIdAndTouristSpotId(Long userId, Long touristSpotId);

    @Query("""
        SELECT favoriteSpot
        FROM FavoriteSpot favoriteSpot
        JOIN FETCH favoriteSpot.touristSpot spot
        WHERE favoriteSpot.user.id = :userId
        ORDER BY favoriteSpot.createdAt DESC
        """)
    List<FavoriteSpot> findByUserIdWithTouristSpot(@Param("userId") Long userId);
}
