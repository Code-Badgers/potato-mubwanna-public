package com.gamjamubwatna.global.common;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

    // Provides a simple API-level health check before domain endpoints are implemented.
    @GetMapping("/health")
    public String health() {
        return "ok";
    }
}
