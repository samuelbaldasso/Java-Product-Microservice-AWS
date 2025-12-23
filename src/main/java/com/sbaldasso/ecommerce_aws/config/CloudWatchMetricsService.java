package com.sbaldasso.ecommerce_aws.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.cloudwatch.CloudWatchClient;
import software.amazon.awssdk.services.cloudwatch.model.*;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class CloudWatchMetricsService {

    private final CloudWatchClient cloudWatchClient;
    
    @Value("${aws.cloudwatch.namespace}")
    private String namespace;

    public void publishMetric(String metricName, double value, StandardUnit unit) {
        try {
            MetricDatum datum = MetricDatum.builder()
                    .metricName(metricName)
                    .value(value)
                    .unit(unit)
                    .timestamp(Instant.now())
                    .build();

            PutMetricDataRequest request = PutMetricDataRequest.builder()
                    .namespace(namespace)
                    .metricData(datum)
                    .build();

            cloudWatchClient.putMetricData(request);
            log.debug("Métrica publicada: {} = {}", metricName, value);
        } catch (Exception e) {
            log.error("Erro ao publicar métrica no CloudWatch", e);
        }
    }

    public void publishMetricWithDimensions(String metricName, double value, 
                                           StandardUnit unit, List<Dimension> dimensions) {
        try {
            MetricDatum datum = MetricDatum.builder()
                    .metricName(metricName)
                    .value(value)
                    .unit(unit)
                    .timestamp(Instant.now())
                    .dimensions(dimensions)
                    .build();

            PutMetricDataRequest request = PutMetricDataRequest.builder()
                    .namespace(namespace)
                    .metricData(datum)
                    .build();

            cloudWatchClient.putMetricData(request);
        } catch (Exception e) {
            log.error("Erro ao publicar métrica com dimensões", e);
        }
    }
}