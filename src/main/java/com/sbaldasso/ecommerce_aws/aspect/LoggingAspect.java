package com.sbaldasso.ecommerce_aws.aspect;

import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.stereotype.Component;

import java.util.Arrays;

@Slf4j
@Aspect
@Component
public class LoggingAspect {

    @Around("@within(org.springframework.web.bind.annotation.RestController)")
    public Object logController(ProceedingJoinPoint joinPoint) throws Throwable {
        String methodName = joinPoint.getSignature().getName();
        String className = joinPoint.getTarget().getClass().getSimpleName();
        
        log.info("Calling {}.{} with args: {}", 
                className, methodName, Arrays.toString(joinPoint.getArgs()));
        
        long startTime = System.currentTimeMillis();
        
        try {
            Object result = joinPoint.proceed();
            long duration = System.currentTimeMillis() - startTime;
            
            log.info("Method {}.{} executed successfully in {}ms", 
                    className, methodName, duration);
            
            return result;
        } catch (Exception e) {
            log.error("Error in {}.{}: {}", className, methodName, e.getMessage(), e);
            throw e;
        }
    }

    @Around("@within(org.springframework.stereotype.Service)")
    public Object logService(ProceedingJoinPoint joinPoint) throws Throwable {
        String methodName = joinPoint.getSignature().getName();
        String className = joinPoint.getTarget().getClass().getSimpleName();
        
        log.debug("Service {}.{} called", className, methodName);
        
        try {
            return joinPoint.proceed();
        } catch (Exception e) {
            log.error("Service error in {}.{}: {}", className, methodName, e.getMessage());
            throw e;
        }
    }
}