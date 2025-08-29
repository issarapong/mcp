-- Sample Data for MCP PostgreSQL Lab

-- Insert sample categories for e-commerce
INSERT INTO ecommerce.categories (name, description) VALUES
('Electronics', 'Electronic devices and gadgets'),
('Computers', 'Laptops, desktops, and computer accessories'),
('Smartphones', 'Mobile phones and accessories'),
('Home & Garden', 'Furniture, appliances, and garden supplies'),
('Books', 'Physical and digital books'),
('Clothing', 'Fashion and apparel'),
('Sports', 'Sports equipment and gear')
ON CONFLICT (name) DO NOTHING;

-- Insert sample products
INSERT INTO ecommerce.products (name, description, price, category_id, stock_quantity, sku) VALUES
('MacBook Pro 16"', 'High-performance laptop for professionals', 2499.99, 2, 15, 'MBP16-001'),
('iPhone 15 Pro', 'Latest smartphone with advanced features', 999.99, 3, 50, 'IPH15P-001'),
('Samsung 4K Monitor', '32-inch 4K UHD monitor for work and gaming', 399.99, 2, 25, 'SAM4K-001'),
('Wireless Mouse', 'Ergonomic wireless mouse with long battery life', 29.99, 2, 100, 'WMOUSE-001'),
('Office Chair', 'Comfortable ergonomic office chair', 299.99, 4, 20, 'CHAIR-001'),
('Programming Book', 'Complete guide to modern programming', 49.99, 5, 75, 'BOOK-001'),
('Running Shoes', 'Professional running shoes for athletes', 129.99, 7, 60, 'SHOES-001'),
('Coffee Maker', 'Automatic drip coffee maker', 89.99, 4, 30, 'COFFEE-001')
ON CONFLICT (sku) DO NOTHING;

-- Insert sample customers
INSERT INTO ecommerce.customers (first_name, last_name, email, phone, date_of_birth) VALUES
('John', 'Doe', 'john.doe@email.com', '+1234567890', '1985-03-15'),
('Jane', 'Smith', 'jane.smith@email.com', '+1234567891', '1990-07-22'),
('Bob', 'Johnson', 'bob.johnson@email.com', '+1234567892', '1988-11-10'),
('Alice', 'Brown', 'alice.brown@email.com', '+1234567893', '1992-05-08'),
('Charlie', 'Wilson', 'charlie.wilson@email.com', '+1234567894', '1987-09-30')
ON CONFLICT (email) DO NOTHING;

-- Insert sample addresses
INSERT INTO ecommerce.addresses (customer_id, type, street_address, city, state, postal_code, country, is_default) VALUES
(1, 'shipping', '123 Main St', 'New York', 'NY', '10001', 'USA', true),
(1, 'billing', '123 Main St', 'New York', 'NY', '10001', 'USA', true),
(2, 'shipping', '456 Oak Ave', 'Los Angeles', 'CA', '90210', 'USA', true),
(3, 'shipping', '789 Pine Rd', 'Chicago', 'IL', '60601', 'USA', true),
(4, 'shipping', '321 Elm St', 'Houston', 'TX', '77001', 'USA', true),
(5, 'shipping', '654 Maple Dr', 'Phoenix', 'AZ', '85001', 'USA', true);

-- Insert sample orders
INSERT INTO ecommerce.orders (customer_id, order_number, status, total_amount, shipping_address_id, billing_address_id) VALUES
(1, 'ORD-2024-001', 'delivered', 2529.98, 1, 2),
(2, 'ORD-2024-002', 'shipped', 999.99, 3, 3),
(3, 'ORD-2024-003', 'processing', 429.98, 4, 4),
(4, 'ORD-2024-004', 'pending', 179.98, 5, 5),
(5, 'ORD-2024-005', 'delivered', 89.99, 6, 6);

-- Insert sample order items
INSERT INTO ecommerce.order_items (order_id, product_id, quantity, unit_price, total_price) VALUES
(1, 1, 1, 2499.99, 2499.99),
(1, 4, 1, 29.99, 29.99),
(2, 2, 1, 999.99, 999.99),
(3, 3, 1, 399.99, 399.99),
(3, 4, 1, 29.99, 29.99),
(4, 6, 1, 49.99, 49.99),
(4, 7, 1, 129.99, 129.99),
(5, 8, 1, 89.99, 89.99);

-- Insert sample blog users
INSERT INTO blog.users (username, email, password_hash, first_name, last_name, bio, is_admin) VALUES
('admin', 'admin@blog.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4p0/9.KO2C', 'Admin', 'User', 'Blog administrator', true),
('john_writer', 'john@blog.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4p0/9.KO2C', 'John', 'Writer', 'Technology enthusiast and writer', false),
('jane_author', 'jane@blog.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4p0/9.KO2C', 'Jane', 'Author', 'Science and innovation blogger', false),
('tech_guru', 'guru@blog.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4p0/9.KO2C', 'Tech', 'Guru', 'Expert in AI and machine learning', false)
ON CONFLICT (username) DO NOTHING;

-- Insert sample blog categories
INSERT INTO blog.categories (name, slug, description, color) VALUES
('Technology', 'technology', 'Latest tech trends and innovations', '#3B82F6'),
('Programming', 'programming', 'Coding tutorials and best practices', '#10B981'),
('AI & ML', 'ai-ml', 'Artificial Intelligence and Machine Learning', '#8B5CF6'),
('Web Development', 'web-dev', 'Frontend and backend development', '#F59E0B'),
('Data Science', 'data-science', 'Data analysis and visualization', '#EF4444')
ON CONFLICT (name) DO NOTHING;

-- Insert sample blog tags
INSERT INTO blog.tags (name, slug) VALUES
('JavaScript', 'javascript'),
('Python', 'python'),
('React', 'react'),
('Node.js', 'nodejs'),
('PostgreSQL', 'postgresql'),
('Docker', 'docker'),
('AI', 'ai'),
('Machine Learning', 'machine-learning'),
('Tutorial', 'tutorial'),
('Best Practices', 'best-practices')
ON CONFLICT (name) DO NOTHING;

-- Insert sample blog posts
INSERT INTO blog.posts (title, slug, content, excerpt, author_id, category_id, status, published_at) VALUES
(
    'Getting Started with PostgreSQL and MCP',
    'getting-started-postgresql-mcp',
    'This comprehensive guide will walk you through setting up PostgreSQL with the Model Context Protocol...',
    'Learn how to integrate PostgreSQL with MCP for powerful AI applications.',
    2,
    1,
    'published',
    CURRENT_TIMESTAMP - INTERVAL '2 days'
),
(
    'Building Modern Web Applications with React',
    'building-modern-web-apps-react',
    'React has revolutionized the way we build user interfaces. In this post, we explore advanced patterns...',
    'Explore advanced React patterns and best practices for modern web development.',
    3,
    4,
    'published',
    CURRENT_TIMESTAMP - INTERVAL '1 week'
),
(
    'Machine Learning with Python: A Comprehensive Guide',
    'machine-learning-python-guide',
    'Python has become the go-to language for machine learning. This guide covers everything from basics...',
    'Complete guide to machine learning using Python and popular libraries.',
    4,
    3,
    'published',
    CURRENT_TIMESTAMP - INTERVAL '3 days'
),
(
    'Docker Best Practices for Development',
    'docker-best-practices-development',
    'Docker has transformed how we develop and deploy applications. Here are essential best practices...',
    'Essential Docker practices every developer should know.',
    2,
    1,
    'draft',
    NULL
);

-- Insert sample post tags
INSERT INTO blog.post_tags (post_id, tag_id) VALUES
(1, 5), (1, 9), (1, 10), -- PostgreSQL, Tutorial, Best Practices
(2, 3), (2, 9), (2, 10), -- React, Tutorial, Best Practices  
(3, 2), (3, 7), (3, 8), (3, 9), -- Python, AI, Machine Learning, Tutorial
(4, 6), (4, 10); -- Docker, Best Practices

-- Insert sample comments
INSERT INTO blog.comments (post_id, author_id, content, is_approved) VALUES
(1, 3, 'Great tutorial! This really helped me understand the MCP integration.', true),
(1, 4, 'Thanks for sharing this. Looking forward to more PostgreSQL content.', true),
(2, 2, 'Excellent breakdown of React patterns. Very useful for my current project.', true),
(3, 1, 'Comprehensive guide! The examples are particularly helpful.', true);

-- Insert sample analytics events
INSERT INTO analytics.events (event_name, user_id, session_id, properties, page_url) VALUES
('page_view', 1, 'sess_001', '{"page": "home", "source": "direct"}', '/'),
('page_view', 1, 'sess_001', '{"page": "products", "source": "navigation"}', '/products'),
('product_view', 1, 'sess_001', '{"product_id": 1, "product_name": "MacBook Pro 16"}', '/products/1'),
('add_to_cart', 1, 'sess_001', '{"product_id": 1, "quantity": 1}', '/products/1'),
('checkout_start', 1, 'sess_001', '{"cart_value": 2499.99}', '/checkout'),
('purchase', 1, 'sess_001', '{"order_id": 1, "total": 2529.98}', '/checkout/success'),
('page_view', 2, 'sess_002', '{"page": "home", "source": "google"}', '/'),
('page_view', 2, 'sess_002', '{"page": "blog", "source": "navigation"}', '/blog'),
('blog_read', 2, 'sess_002', '{"post_id": 1, "reading_time": 300}', '/blog/getting-started-postgresql-mcp');

-- Insert sample page views
INSERT INTO analytics.page_views (page_url, page_title, user_id, session_id, duration_seconds) VALUES
('/', 'Home Page', 1, 'sess_001', 45),
('/products', 'Products', 1, 'sess_001', 120),
('/products/1', 'MacBook Pro 16"', 1, 'sess_001', 180),
('/checkout', 'Checkout', 1, 'sess_001', 240),
('/checkout/success', 'Order Confirmation', 1, 'sess_001', 30),
('/', 'Home Page', 2, 'sess_002', 30),
('/blog', 'Blog', 2, 'sess_002', 60),
('/blog/getting-started-postgresql-mcp', 'Getting Started with PostgreSQL and MCP', 2, 'sess_002', 300);

-- Insert sample conversions
INSERT INTO analytics.conversions (conversion_type, user_id, session_id, value, properties) VALUES
('purchase', 1, 'sess_001', 2529.98, '{"order_id": 1, "products": [{"id": 1, "name": "MacBook Pro 16\"", "price": 2499.99}]}'),
('newsletter_signup', 2, 'sess_002', 0, '{"source": "blog_post", "post_id": 1}'),
('account_creation', 3, 'sess_003', 0, '{"source": "homepage", "method": "email"}');

-- Insert sample A/B test data
INSERT INTO analytics.ab_tests (test_name, variant_name, user_id, session_id, converted, conversion_value) VALUES
('homepage_hero_test', 'control', 1, 'sess_001', true, 2529.98),
('homepage_hero_test', 'variant_a', 2, 'sess_002', false, 0),
('checkout_flow_test', 'control', 1, 'sess_001', true, 2529.98),
('product_page_layout', 'variant_b', 3, 'sess_003', false, 0);

-- Insert sample daily metrics
INSERT INTO analytics.daily_metrics (date, metric_name, metric_value, dimensions) VALUES
(CURRENT_DATE - INTERVAL '1 day', 'total_revenue', 2529.98, '{"currency": "USD"}'),
(CURRENT_DATE - INTERVAL '1 day', 'total_orders', 1, '{}'),
(CURRENT_DATE - INTERVAL '1 day', 'unique_visitors', 3, '{}'),
(CURRENT_DATE - INTERVAL '1 day', 'page_views', 8, '{}'),
(CURRENT_DATE - INTERVAL '2 days', 'total_revenue', 0, '{"currency": "USD"}'),
(CURRENT_DATE - INTERVAL '2 days', 'total_orders', 0, '{}'),
(CURRENT_DATE - INTERVAL '2 days', 'unique_visitors', 2, '{}'),
(CURRENT_DATE - INTERVAL '2 days', 'page_views', 5, '{}')
ON CONFLICT (date, metric_name) DO NOTHING;
