package com.sbaldasso.ecommerce_aws.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import lombok.Data;

@Configuration
@ConfigurationProperties(prefix = "aws")
@Data
public class AwsProperties {
    private String region = "us-east-1";
    private Secrets secrets = new Secrets();
    private S3 s3 = new S3();
    private Sqs sqs = new Sqs();
    private XRay xray = new XRay();

    @Data
    public static class Secrets {
        private boolean enabled = true;
        private String name = "ecommerce/product-service";
    }

    @Data
    public static class S3 {
        private String bucket = "ecommerce-products";
    }

    @Data
    public static class Sqs {
        private String queueUrl;
    }

    @Data
    public static class XRay {
        private boolean enabled = true;
    }
}
