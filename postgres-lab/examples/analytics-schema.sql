-- Analytics Schema for MCP PostgreSQL Lab

-- Create analytics schema tables
CREATE TABLE IF NOT EXISTS analytics.events (
    id SERIAL PRIMARY KEY,
    event_name VARCHAR(100) NOT NULL,
    user_id INTEGER,
    session_id VARCHAR(255),
    properties JSONB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    page_url VARCHAR(500),
    referrer_url VARCHAR(500)
);

CREATE TABLE IF NOT EXISTS analytics.page_views (
    id SERIAL PRIMARY KEY,
    page_url VARCHAR(500) NOT NULL,
    page_title VARCHAR(255),
    user_id INTEGER,
    session_id VARCHAR(255),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    duration_seconds INTEGER,
    bounce BOOLEAN DEFAULT FALSE,
    ip_address INET,
    user_agent TEXT,
    referrer_url VARCHAR(500)
);

CREATE TABLE IF NOT EXISTS analytics.user_sessions (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) UNIQUE NOT NULL,
    user_id INTEGER,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    page_views INTEGER DEFAULT 0,
    events INTEGER DEFAULT 0,
    ip_address INET,
    user_agent TEXT,
    referrer_url VARCHAR(500),
    exit_page VARCHAR(500)
);

CREATE TABLE IF NOT EXISTS analytics.conversions (
    id SERIAL PRIMARY KEY,
    conversion_type VARCHAR(50) NOT NULL,
    user_id INTEGER,
    session_id VARCHAR(255),
    value DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'USD',
    properties JSONB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS analytics.ab_tests (
    id SERIAL PRIMARY KEY,
    test_name VARCHAR(100) NOT NULL,
    variant_name VARCHAR(50) NOT NULL,
    user_id INTEGER,
    session_id VARCHAR(255),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    converted BOOLEAN DEFAULT FALSE,
    conversion_value DECIMAL(10,2)
);

-- Create partitioned table for daily metrics
CREATE TABLE IF NOT EXISTS analytics.daily_metrics (
    date DATE NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(15,2) NOT NULL,
    dimensions JSONB,
    PRIMARY KEY (date, metric_name)
) PARTITION BY RANGE (date);

-- Create partitions for current and next year
DO $$
DECLARE
    start_date DATE := DATE_TRUNC('year', CURRENT_DATE);
    end_date DATE := start_date + INTERVAL '2 years';
    partition_date DATE := start_date;
    partition_name TEXT;
BEGIN
    WHILE partition_date < end_date LOOP
        partition_name := 'daily_metrics_' || TO_CHAR(partition_date, 'YYYY_MM');
        
        EXECUTE format('CREATE TABLE IF NOT EXISTS analytics.%I PARTITION OF analytics.daily_metrics
                       FOR VALUES FROM (%L) TO (%L)',
                       partition_name,
                       partition_date,
                       partition_date + INTERVAL '1 month');
        
        partition_date := partition_date + INTERVAL '1 month';
    END LOOP;
END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_events_name ON analytics.events(event_name);
CREATE INDEX IF NOT EXISTS idx_events_user ON analytics.events(user_id);
CREATE INDEX IF NOT EXISTS idx_events_session ON analytics.events(session_id);
CREATE INDEX IF NOT EXISTS idx_events_timestamp ON analytics.events(timestamp);
CREATE INDEX IF NOT EXISTS idx_events_properties ON analytics.events USING GIN(properties);

CREATE INDEX IF NOT EXISTS idx_page_views_url ON analytics.page_views(page_url);
CREATE INDEX IF NOT EXISTS idx_page_views_user ON analytics.page_views(user_id);
CREATE INDEX IF NOT EXISTS idx_page_views_session ON analytics.page_views(session_id);
CREATE INDEX IF NOT EXISTS idx_page_views_timestamp ON analytics.page_views(timestamp);

CREATE INDEX IF NOT EXISTS idx_sessions_user ON analytics.user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_start ON analytics.user_sessions(start_time);

CREATE INDEX IF NOT EXISTS idx_conversions_type ON analytics.conversions(conversion_type);
CREATE INDEX IF NOT EXISTS idx_conversions_user ON analytics.conversions(user_id);
CREATE INDEX IF NOT EXISTS idx_conversions_timestamp ON analytics.conversions(timestamp);

CREATE INDEX IF NOT EXISTS idx_ab_tests_name ON analytics.ab_tests(test_name);
CREATE INDEX IF NOT EXISTS idx_ab_tests_user ON analytics.ab_tests(user_id);

-- Create materialized views for common queries
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.daily_page_views AS
SELECT 
    DATE(timestamp) as date,
    page_url,
    COUNT(*) as views,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT session_id) as unique_sessions,
    AVG(duration_seconds) as avg_duration
FROM analytics.page_views 
WHERE timestamp >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(timestamp), page_url;

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.daily_events AS
SELECT 
    DATE(timestamp) as date,
    event_name,
    COUNT(*) as occurrences,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT session_id) as unique_sessions
FROM analytics.events 
WHERE timestamp >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(timestamp), event_name;

-- Create unique indexes on materialized views
CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_page_views_unique 
ON analytics.daily_page_views (date, page_url);

CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_events_unique 
ON analytics.daily_events (date, event_name);
