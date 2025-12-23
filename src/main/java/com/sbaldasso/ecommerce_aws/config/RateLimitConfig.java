package com.sbaldasso.ecommerce_aws.config;

import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import io.github.bucket4j.Refill;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import lombok.Data;

import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Configuration
@ConfigurationProperties(prefix = "rate-limit")
@Data
public class RateLimitConfig {
    private boolean enabled = true;
    private long capacity = 100;
    private long refillTokens = 100;
    private String refillDuration = "1m";

    @Bean
    public Map<String, Bucket> rateLimitBuckets() {
        return new ConcurrentHashMap<>();
    }

    public Bucket createNewBucket() {
        Duration duration = parseDuration(refillDuration);
        Bandwidth limit = Bandwidth.classic(capacity, Refill.intervally(refillTokens, duration));
        return Bucket.builder()
                .addLimit(limit)
                .build();
    }

    private Duration parseDuration(String duration) {
        if (duration.endsWith("s")) {
            return Duration.ofSeconds(Long.parseLong(duration.substring(0, duration.length() - 1)));
        } else if (duration.endsWith("m")) {
            return Duration.ofMinutes(Long.parseLong(duration.substring(0, duration.length() - 1)));
        } else if (duration.endsWith("h")) {
            return Duration.ofHours(Long.parseLong(duration.substring(0, duration.length() - 1)));
        }
        return Duration.ofMinutes(1);
    }
}
