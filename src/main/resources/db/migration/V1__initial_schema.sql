-- Initial schema for products table
CREATE TABLE IF NOT EXISTS products (
    id BIGSERIAL PRIMARY KEY,
    sku VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(2000),
    price DECIMAL(19, 2) NOT NULL,
    quantity INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP,
    CONSTRAINT chk_price_positive CHECK (price >= 0),
    CONSTRAINT chk_quantity_positive CHECK (quantity >= 0)
);

-- Create index on SKU for faster lookups
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);

-- Create index on name for search functionality
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
