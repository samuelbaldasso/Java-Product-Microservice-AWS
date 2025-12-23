package com.sbaldasso.ecommerce_aws.interceptor;

import com.sbaldasso.ecommerce_aws.config.CloudWatchMetricsService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;
import software.amazon.awssdk.services.cloudwatch.model.StandardUnit;

@Slf4j
@Component
@RequiredArgsConstructor
public class RequestLoggingInterceptor implements HandlerInterceptor {

    private final CloudWatchMetricsService metricsService;
    private static final String START_TIME = "startTime";

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, 
                            Object handler) {
        request.setAttribute(START_TIME, System.currentTimeMillis());
        
        log.info("Request: {} {} from IP: {}", 
                request.getMethod(), 
                request.getRequestURI(),
                request.getRemoteAddr());
        
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, 
                               Object handler, Exception ex) {
        Long startTime = (Long) request.getAttribute(START_TIME);
        if (startTime != null) {
            long duration = System.currentTimeMillis() - startTime;
            
            log.info("Response: {} {} - Status: {} - Duration: {}ms",
                    request.getMethod(),
                    request.getRequestURI(),
                    response.getStatus(),
                    duration);
            
            // Enviar métrica para CloudWatch
            metricsService.publishMetric("RequestDuration", duration, StandardUnit.MILLISECONDS);
            metricsService.publishMetric("RequestCount", 1.0, StandardUnit.COUNT);
            
            if (response.getStatus() >= 400) {
                metricsService.publishMetric("ErrorCount", 1.0, StandardUnit.COUNT);
            }
        }
    }
}