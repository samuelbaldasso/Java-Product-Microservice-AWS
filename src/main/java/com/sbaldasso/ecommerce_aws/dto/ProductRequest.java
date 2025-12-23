package com.sbaldasso.ecommerce_aws.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ProductRequest {
    @NotBlank
    private String sku;

    @NotBlank
    private String name;

    private String description;

    @NotNull
    @DecimalMin("0.0")
    private BigDecimal price;

    @NotNull
    @Min(0)
    private Integer quantity;
}
