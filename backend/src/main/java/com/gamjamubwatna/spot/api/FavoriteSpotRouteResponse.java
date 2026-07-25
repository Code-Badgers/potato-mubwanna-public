package com.gamjamubwatna.spot.api;

import java.util.List;

public record FavoriteSpotRouteResponse(
    String routeName,
    double totalDistanceKm,
    int estimatedMinutes,
    List<FavoriteSpotRouteWaypointResponse> waypoints,
    List<FavoriteSpotRoutePointResponse> polyline
) {
}
