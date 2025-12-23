package com.sbaldasso.ecommerce_aws.controllers;

import com.sbaldasso.ecommerce_aws.config.CloudWatchMetricsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import software.amazon.awssdk.services.cloudwatch.model.StandardUnit;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/health")
@RequiredArgsConstructor
public class HealthController {

    private final CloudWatchMetricsService metricsService;

    @GetMapping
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "UP");
        health.put("timestamp", System.currentTimeMillis());
        
        metricsService.publishMetric("HealthCheck", 1.0, StandardUnit.COUNT);
        
        return ResponseEntity.ok(health);
    }

    @GetMapping("/ready")
    public ResponseEntity<String> ready() {
        return ResponseEntity.ok("Ready");
    }

    @GetMapping("/live")
    public ResponseEntity<String> live() {
        return ResponseEntity.ok("Live");
    }
}