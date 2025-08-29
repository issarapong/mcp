# PostgreSQL Queries for MCP Lab

This document contains useful SQL queries for exploring and working with the MCP PostgreSQL Lab database.

## E-commerce Queries

### Top Selling Products
```sql
SELECT 
    p.name,
    p.price,
    SUM(oi.quantity) as total_sold,
    SUM(oi.total_price) as total_revenue
FROM ecommerce.products p
JOIN ecommerce.order_items oi ON p.id = oi.product_id
JOIN ecommerce.orders o ON oi.order_id = o.id
WHERE o.status IN ('shipped', 'delivered')
GROUP BY p.id, p.name, p.price
ORDER BY total_revenue DESC;
```

### Customer Order History
```sql
SELECT 
    c.first_name || ' ' || c.last_name as customer_name,
    c.email,
    o.order_number,
    o.status,
    o.total_amount,
    o.order_date
FROM ecommerce.customers c
JOIN ecommerce.orders o ON c.id = o.customer_id
ORDER BY o.order_date DESC;
```

### Monthly Sales Report
```sql
SELECT 
    DATE_TRUNC('month', order_date) as month,
    COUNT(*) as total_orders,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value
FROM ecommerce.orders
WHERE status IN ('shipped', 'delivered')
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month DESC;
```

### Low Stock Alert
```sql
SELECT 
    name,
    stock_quantity,
    price,
    sku
FROM ecommerce.products
WHERE stock_quantity < 20 AND is_active = true
ORDER BY stock_quantity ASC;
```

## Blog Queries

### Most Popular Posts
```sql
SELECT 
    p.title,
    p.view_count,
    u.username as author,
    c.name as category,
    p.published_at
FROM blog.posts p
JOIN blog.users u ON p.author_id = u.id
JOIN blog.categories c ON p.category_id = c.id
WHERE p.status = 'published'
ORDER BY p.view_count DESC
LIMIT 10;
```

### Posts with Comments
```sql
SELECT 
    p.title,
    p.author_id,
    COUNT(com.id) as comment_count,
    MAX(com.created_at) as latest_comment
FROM blog.posts p
LEFT JOIN blog.comments com ON p.id = com.post_id
WHERE p.status = 'published'
GROUP BY p.id, p.title, p.author_id
ORDER BY comment_count DESC;
```

### Tag Usage Statistics
```sql
SELECT 
    t.name,
    COUNT(pt.post_id) as usage_count
FROM blog.tags t
JOIN blog.post_tags pt ON t.id = pt.tag_id
JOIN blog.posts p ON pt.post_id = p.id
WHERE p.status = 'published'
GROUP BY t.id, t.name
ORDER BY usage_count DESC;
```

## Analytics Queries

### Daily Page Views
```sql
SELECT 
    DATE(timestamp) as date,
    COUNT(*) as page_views,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT session_id) as unique_sessions
FROM analytics.page_views
WHERE timestamp >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE(timestamp)
ORDER BY date DESC;
```

### Top Pages by Traffic
```sql
SELECT 
    page_url,
    COUNT(*) as views,
    COUNT(DISTINCT user_id) as unique_visitors,
    AVG(duration_seconds) as avg_duration
FROM analytics.page_views
WHERE timestamp >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY page_url
ORDER BY views DESC
LIMIT 10;
```

### Conversion Funnel
```sql
WITH funnel AS (
    SELECT 
        session_id,
        MAX(CASE WHEN event_name = 'page_view' THEN 1 ELSE 0 END) as viewed,
        MAX(CASE WHEN event_name = 'product_view' THEN 1 ELSE 0 END) as product_viewed,
        MAX(CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END) as added_to_cart,
        MAX(CASE WHEN event_name = 'checkout_start' THEN 1 ELSE 0 END) as checkout_started,
        MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) as purchased
    FROM analytics.events
    WHERE timestamp >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY session_id
)
SELECT 
    SUM(viewed) as page_views,
    SUM(product_viewed) as product_views,
    SUM(added_to_cart) as cart_additions,
    SUM(checkout_started) as checkout_starts,
    SUM(purchased) as purchases,
    ROUND(SUM(product_viewed)::numeric / SUM(viewed) * 100, 2) as view_to_product_rate,
    ROUND(SUM(purchased)::numeric / SUM(viewed) * 100, 2) as overall_conversion_rate
FROM funnel;
```

### User Behavior Analysis
```sql
SELECT 
    user_id,
    COUNT(DISTINCT session_id) as sessions,
    COUNT(*) as total_events,
    COUNT(DISTINCT event_name) as unique_events,
    MIN(timestamp) as first_seen,
    MAX(timestamp) as last_seen
FROM analytics.events
WHERE user_id IS NOT NULL
GROUP BY user_id
ORDER BY total_events DESC
LIMIT 20;
```

## Cross-Schema Analytics

### Customer Lifetime Value
```sql
WITH customer_metrics AS (
    SELECT 
        c.id,
        c.first_name || ' ' || c.last_name as name,
        c.email,
        COUNT(o.id) as total_orders,
        SUM(o.total_amount) as total_spent,
        MIN(o.order_date) as first_order,
        MAX(o.order_date) as last_order
    FROM ecommerce.customers c
    LEFT JOIN ecommerce.orders o ON c.id = o.customer_id
    WHERE o.status IN ('shipped', 'delivered')
    GROUP BY c.id, c.first_name, c.last_name, c.email
)
SELECT 
    *,
    ROUND(total_spent / NULLIF(total_orders, 0), 2) as avg_order_value,
    CASE 
        WHEN total_spent > 1000 THEN 'High Value'
        WHEN total_spent > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END as customer_segment
FROM customer_metrics
WHERE total_orders > 0
ORDER BY total_spent DESC;
```

### Blog Engagement vs E-commerce Conversion
```sql
WITH blog_readers AS (
    SELECT DISTINCT user_id
    FROM analytics.events
    WHERE event_name = 'blog_read'
    AND user_id IS NOT NULL
),
purchasers AS (
    SELECT DISTINCT user_id
    FROM analytics.events
    WHERE event_name = 'purchase'
    AND user_id IS NOT NULL
)
SELECT 
    COUNT(DISTINCT br.user_id) as blog_readers,
    COUNT(DISTINCT p.user_id) as purchasers,
    COUNT(DISTINCT CASE WHEN br.user_id = p.user_id THEN br.user_id END) as blog_readers_who_purchased,
    ROUND(
        COUNT(DISTINCT CASE WHEN br.user_id = p.user_id THEN br.user_id END)::numeric 
        / NULLIF(COUNT(DISTINCT br.user_id), 0) * 100, 
        2
    ) as blog_to_purchase_conversion_rate
FROM blog_readers br
FULL OUTER JOIN purchasers p ON br.user_id = p.user_id;
```

## Performance and Monitoring

### Table Sizes
```sql
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    pg_total_relation_size(schemaname||'.'||tablename) as size_bytes
FROM pg_tables 
WHERE schemaname IN ('ecommerce', 'blog', 'analytics')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Index Usage
```sql
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_tup_read,
    idx_tup_fetch,
    idx_scan
FROM pg_stat_user_indexes
WHERE schemaname IN ('ecommerce', 'blog', 'analytics')
ORDER BY idx_scan DESC;
```

### Recent Activity
```sql
SELECT 
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    n_live_tup as live_rows,
    n_dead_tup as dead_rows,
    last_autoanalyze,
    last_autovacuum
FROM pg_stat_user_tables
WHERE schemaname IN ('ecommerce', 'blog', 'analytics')
ORDER BY (n_tup_ins + n_tup_upd + n_tup_del) DESC;
```
