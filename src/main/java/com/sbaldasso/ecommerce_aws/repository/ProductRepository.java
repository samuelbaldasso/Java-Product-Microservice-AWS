package com.sbaldasso.ecommerce_aws.repository;

import com.sbaldasso.ecommerce_aws.entities.Product;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {
    boolean existsBySku(String sku);
    Page<Product> findByNameContainingIgnoreCase(String name, Pageable pageable);
}
