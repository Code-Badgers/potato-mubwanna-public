package com.gamjamubwatna.spot.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.spot.application.SpotRouteEstimateExternalException;
import com.gamjamubwatna.spot.application.SpotRouteEstimateService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/spots")
public class SpotRouteEstimateController {

    private final SpotRouteEstimateService routeEstimateService;

    public SpotRouteEstimateController(SpotRouteEstimateService routeEstimateService) {
        this.routeEstimateService = routeEstimateService;
    }

    @PostMapping("/route-estimate")
    public ResponseEntity<AuthApiResponse<SpotRouteEstimateResponse>> estimate(
        @Valid @RequestBody SpotRouteEstimateRequest request
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                routeEstimateService.estimate(request.spotIds())
            ));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest()
                .body(AuthApiResponse.failure(exception.getMessage()));
        } catch (SpotRouteEstimateExternalException exception) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(AuthApiResponse.failure(exception.getMessage()));
        }
    }
}
