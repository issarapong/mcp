-- E-commerce Schema for MCP PostgreSQL Lab

-- Create ecommerce schema tables
CREATE TABLE IF NOT EXISTS ecommerce.categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_id INTEGER REFERENCES ecommerce.categories(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ecommerce.products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    category_id INTEGER REFERENCES ecommerce.categories(id),
    stock_quantity INTEGER DEFAULT 0 CHECK (stock_quantity >= 0),
    sku VARCHAR(50) UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ecommerce.customers (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ecommerce.addresses (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES ecommerce.customers(id) ON DELETE CASCADE,
    type VARCHAR(20) DEFAULT 'shipping' CHECK (type IN ('shipping', 'billing')),
    street_address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ecommerce.orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES ecommerce.customers(id),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),
    shipping_address_id INTEGER REFERENCES ecommerce.addresses(id),
    billing_address_id INTEGER REFERENCES ecommerce.addresses(id),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    shipped_date TIMESTAMP,
    delivered_date TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ecommerce.order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES ecommerce.orders(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES ecommerce.products(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    total_price DECIMAL(10,2) NOT NULL CHECK (total_price >= 0)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_products_category ON ecommerce.products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_sku ON ecommerce.products(sku);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON ecommerce.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON ecommerce.orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON ecommerce.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON ecommerce.order_items(product_id);

-- Create triggers for updated_at columns
CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE ON ecommerce.categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON ecommerce.products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON ecommerce.customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
