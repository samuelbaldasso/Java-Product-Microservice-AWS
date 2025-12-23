package com.sbaldasso.ecommerce_aws.services;

import com.sbaldasso.ecommerce_aws.config.RabbitMQConfig;
import com.sbaldasso.ecommerce_aws.dto.ProductCreatedEvent;
import com.sbaldasso.ecommerce_aws.dto.ProductRequest;
import com.sbaldasso.ecommerce_aws.dto.ProductResponse;
import com.sbaldasso.ecommerce_aws.entities.Product;
import com.sbaldasso.ecommerce_aws.mappers.ProductMapper;
import com.sbaldasso.ecommerce_aws.repository.ProductRepository;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.domain.PageImpl;

import java.util.stream.Collectors;

@Service
@Transactional
public class ProductService {

    private final ProductRepository repo;
    private final RabbitTemplate rabbitTemplate; // Injetar RabbitTemplate

    public ProductService(ProductRepository repo, RabbitTemplate rabbitTemplate) {
        this.repo = repo;
        this.rabbitTemplate = rabbitTemplate;
    }

    public ProductResponse create(ProductRequest req) {
        if (repo.existsBySku(req.getSku())) {
            throw new IllegalArgumentException("SKU already exists");
        }
        Product p = ProductMapper.toEntity(req);
        p = repo.save(p);

        // Publicar evento no RabbitMQ
        ProductCreatedEvent event = new ProductCreatedEvent(p.getId(), p.getSku());
        rabbitTemplate.convertAndSend(RabbitMQConfig.PRODUCT_CREATED_QUEUE, event);

        return ProductMapper.toResponse(p);
    }

    public ProductResponse update(Long id, ProductRequest req) {
        Product p = repo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Product not found"));
        ProductMapper.updateEntity(p, req);
        p = repo.save(p);
        return ProductMapper.toResponse(p);
    }

    @Transactional(readOnly = true)
    public ProductResponse findById(Long id) {
        return repo.findById(id)
                .map(ProductMapper::toResponse)
                .orElseThrow(() -> new IllegalArgumentException("Product not found"));
    }

    @Transactional(readOnly = true)
    public Page<ProductResponse> search(String name, Pageable pageable) {
        Page<Product> page = repo.findByNameContainingIgnoreCase(name == null ? "" : name, pageable);
        return new PageImpl<>(
                page.stream().map(ProductMapper::toResponse).collect(Collectors.toList()),
                pageable,
                page.getTotalElements()
        );
    }

    public void delete(Long id) {
        if (!repo.existsById(id)) {
            throw new IllegalArgumentException("Product not found");
        }
        repo.deleteById(id);
    }
}

