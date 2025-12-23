package com.sbaldasso.ecommerce_aws.mappers;

import com.sbaldasso.ecommerce_aws.dto.ProductRequest;
import com.sbaldasso.ecommerce_aws.dto.ProductResponse;
import com.sbaldasso.ecommerce_aws.entities.Product;

public class ProductMapper {
    public static Product toEntity(ProductRequest req) {
        Product p = new Product();
        p.setSku(req.getSku());
        p.setName(req.getName());
        p.setDescription(req.getDescription());
        p.setPrice(req.getPrice());
        p.setQuantity(req.getQuantity());
        return p;
    }

    public static ProductResponse toResponse(Product p) {
        ProductResponse r = new ProductResponse();
        r.setId(p.getId());
        r.setSku(p.getSku());
        r.setName(p.getName());
        r.setDescription(p.getDescription());
        r.setPrice(p.getPrice());
        r.setQuantity(p.getQuantity());
        r.setCreatedAt(p.getCreatedAt());
        r.setUpdatedAt(p.getUpdatedAt());
        return r;
    }

    public static void updateEntity(Product p, ProductRequest req) {
        p.setName(req.getName());
        p.setDescription(req.getDescription());
        p.setPrice(req.getPrice());
        p.setQuantity(req.getQuantity());
    }
}
