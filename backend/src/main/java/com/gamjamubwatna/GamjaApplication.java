package com.gamjamubwatna;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class GamjaApplication {

    public static void main(String[] args) {
        SpringApplication.run(GamjaApplication.class, args);
    }
}

