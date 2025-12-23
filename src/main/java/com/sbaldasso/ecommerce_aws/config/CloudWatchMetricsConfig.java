package com.sbaldasso.ecommerce_aws.config;

import io.micrometer.cloudwatch2.CloudWatchConfig;
import io.micrometer.cloudwatch2.CloudWatchMeterRegistry;
import io.micrometer.core.instrument.Clock;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.services.cloudwatch.CloudWatchAsyncClient;

import java.time.Duration;
import java.util.Map;

@Configuration
@ConditionalOnProperty(prefix = "management.metrics.export.cloudwatch", name = "enabled", havingValue = "true")
public class CloudWatchMetricsConfig {

    @Bean
    public CloudWatchAsyncClient cloudWatchAsyncClient(AwsProperties awsProperties) {
        return CloudWatchAsyncClient.builder()
                .region(software.amazon.awssdk.regions.Region.of(awsProperties.getRegion()))
                .build();
    }

    @Bean
    public CloudWatchConfig cloudWatchConfig() {
        return new CloudWatchConfig() {
            private final Map<String, String> configuration = Map.of(
                    "cloudwatch.namespace", "EcommerceProductService",
                    "cloudwatch.step", Duration.ofMinutes(1).toString()
            );

            @Override
            public String get(String key) {
                return configuration.get(key);
            }
        };
    }

    @Bean
    public MeterRegistry cloudWatchMeterRegistry(CloudWatchConfig cloudWatchConfig,
                                                   CloudWatchAsyncClient cloudWatchAsyncClient) {
        return new CloudWatchMeterRegistry(cloudWatchConfig, Clock.SYSTEM, cloudWatchAsyncClient);
    }
}
