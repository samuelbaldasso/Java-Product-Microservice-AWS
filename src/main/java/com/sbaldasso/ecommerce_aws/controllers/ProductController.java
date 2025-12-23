package com.sbaldasso.ecommerce_aws.controllers;

import com.sbaldasso.ecommerce_aws.dto.ProductRequest;
import com.sbaldasso.ecommerce_aws.dto.ProductResponse;
import com.sbaldasso.ecommerce_aws.services.ProductService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/products")
public class ProductController {

    private final ProductService svc;

    public ProductController(ProductService svc) {
        this.svc = svc;
    }

    @PostMapping
    public ResponseEntity<ProductResponse> create(@Valid @RequestBody ProductRequest req) {
        return ResponseEntity.ok(svc.create(req));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ProductResponse> get(@PathVariable Long id) {
        return ResponseEntity.ok(svc.findById(id));
    }

    @GetMapping
    public ResponseEntity<Page<ProductResponse>> list(
            @RequestParam(required = false) String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        return ResponseEntity.ok(svc.search(q, PageRequest.of(page, size)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ProductResponse> update(@PathVariable Long id, @Valid @RequestBody ProductRequest req) {
        return ResponseEntity.ok(svc.update(id, req));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        svc.delete(id);
        return ResponseEntity.noContent().build();
    }
}
