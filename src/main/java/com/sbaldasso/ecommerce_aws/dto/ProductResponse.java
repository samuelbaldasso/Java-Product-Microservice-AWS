package com.sbaldasso.ecommerce_aws.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ProductResponse {
    private Long id;
    private String sku;
    private String name;
    private String description;
    private BigDecimal price;
    private Integer quantity;
    private Instant createdAt;
    private Instant updatedAt;
}

