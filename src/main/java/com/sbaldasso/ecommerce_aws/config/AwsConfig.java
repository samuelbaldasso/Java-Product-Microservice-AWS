package com.sbaldasso.ecommerce_aws.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.cloudfront.CloudFrontClient;
import software.amazon.awssdk.services.secretsmanager.SecretsManagerClient;
import software.amazon.awssdk.services.cloudwatch.CloudWatchClient;
import software.amazon.awssdk.services.cloudwatchlogs.CloudWatchLogsClient;

@Configuration
public class AwsConfig {

    private final AwsProperties awsProperties;

    public AwsConfig(AwsProperties awsProperties) {
        this.awsProperties = awsProperties;
    }

    @Bean
    @ConditionalOnProperty(prefix = "aws.secrets", name = "enabled", havingValue = "true", matchIfMissing = true)
    public SecretsManagerClient secretsManagerClient() {
        return SecretsManagerClient.builder()
                .region(Region.of(awsProperties.getRegion()))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build();
    }

    @Bean
    public CloudWatchClient cloudWatchClient() {
        return CloudWatchClient.builder()
                .region(Region.of(awsProperties.getRegion()))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build();
    }

    @Bean
    public CloudWatchLogsClient cloudWatchLogsClient() {
        return CloudWatchLogsClient.builder()
                .region(Region.of(awsProperties.getRegion()))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build();
    }

    @Bean
    public CloudFrontClient cloudFrontClient() {
        return CloudFrontClient.builder()
                .region(Region.AWS_GLOBAL)
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build();
    }
}
