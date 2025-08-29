-- Initialize MCP PostgreSQL Lab Database
-- This script creates the initial database structure

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create schemas
CREATE SCHEMA IF NOT EXISTS ecommerce;
CREATE SCHEMA IF NOT EXISTS blog;
CREATE SCHEMA IF NOT EXISTS analytics;

-- Set search path
ALTER DATABASE mcplab SET search_path = public, ecommerce, blog, analytics;

-- Create a function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

COMMENT ON DATABASE mcplab IS 'MCP PostgreSQL Lab Database - Demonstration environment for Model Context Protocol with PostgreSQL';
