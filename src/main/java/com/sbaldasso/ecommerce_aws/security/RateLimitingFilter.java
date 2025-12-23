package com.sbaldasso.ecommerce_aws.security;

import io.github.bucket4j.Bucket;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import com.sbaldasso.ecommerce_aws.config.RateLimitConfig;

import java.io.IOException;
import java.util.Map;

@Component
public class RateLimitingFilter extends OncePerRequestFilter {

    private final RateLimitConfig rateLimitConfig;
    private final Map<String, Bucket> rateLimitBuckets;

    public RateLimitingFilter(RateLimitConfig rateLimitConfig, Map<String, Bucket> rateLimitBuckets) {
        this.rateLimitConfig = rateLimitConfig;
        this.rateLimitBuckets = rateLimitBuckets;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        
        if (!rateLimitConfig.isEnabled()) {
            filterChain.doFilter(request, response);
            return;
        }

        String clientIp = getClientIP(request);
        Bucket bucket = rateLimitBuckets.computeIfAbsent(clientIp, k -> rateLimitConfig.createNewBucket());

        if (bucket.tryConsume(1)) {
            filterChain.doFilter(request, response);
        } else {
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            response.setContentType("application/json");
            response.getWriter().write("{\"error\":\"Too many requests\",\"message\":\"Rate limit exceeded. Please try again later.\"}");
        }
    }

    private String getClientIP(HttpServletRequest request) {
        String xfHeader = request.getHeader("X-Forwarded-For");
        if (xfHeader == null) {
            return request.getRemoteAddr();
        }
        return xfHeader.split(",")[0];
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        return path.startsWith("/actuator/health") || path.startsWith("/actuator/info");
    }
}
