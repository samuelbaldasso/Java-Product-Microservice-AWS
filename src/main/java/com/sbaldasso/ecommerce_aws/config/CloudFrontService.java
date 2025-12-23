package com.sbaldasso.ecommerce_aws.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.cloudfront.CloudFrontClient;
import software.amazon.awssdk.services.cloudfront.model.*;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class CloudFrontService {

    private final CloudFrontClient cloudFrontClient;
    
    @Value("${aws.cloudfront.distribution-id}")
    private String distributionId;

    public void invalidateCache(List<String> paths) {
        try {
            Paths invalidationPaths = Paths.builder()
                    .items(paths)
                    .quantity(paths.size())
                    .build();

            InvalidationBatch batch = InvalidationBatch.builder()
                    .paths(invalidationPaths)
                    .callerReference(UUID.randomUUID().toString())
                    .build();

            CreateInvalidationRequest request = CreateInvalidationRequest.builder()
                    .distributionId(distributionId)
                    .invalidationBatch(batch)
                    .build();

            CreateInvalidationResponse response = cloudFrontClient.createInvalidation(request);
            log.info("Cache invalidado no CloudFront. Invalidation ID: {}", 
                    response.invalidation().id());
        } catch (Exception e) {
            log.error("Erro ao invalidar cache do CloudFront", e);
            throw new RuntimeException("Falha ao invalidar cache", e);
        }
    }

    public void invalidateAllCache() {
        invalidateCache(List.of("/*"));
    }

    public DistributionConfig getDistributionConfig() {
        try {
            GetDistributionConfigRequest request = GetDistributionConfigRequest.builder()
                    .id(distributionId)
                    .build();

            GetDistributionConfigResponse response = cloudFrontClient.getDistributionConfig(request);
            return response.distributionConfig();
        } catch (Exception e) {
            log.error("Erro ao obter configuração do CloudFront", e);
            throw new RuntimeException("Falha ao obter configuração", e);
        }
    }
}