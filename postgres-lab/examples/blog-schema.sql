-- Blog Schema for MCP PostgreSQL Lab

-- Create blog schema tables
CREATE TABLE IF NOT EXISTS blog.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    bio TEXT,
    avatar_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    is_admin BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS blog.categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    color VARCHAR(7), -- HEX color code
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS blog.tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    slug VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS blog.posts (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    content TEXT NOT NULL,
    excerpt TEXT,
    author_id INTEGER REFERENCES blog.users(id),
    category_id INTEGER REFERENCES blog.categories(id),
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    featured_image_url VARCHAR(500),
    is_featured BOOLEAN DEFAULT FALSE,
    view_count INTEGER DEFAULT 0,
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS blog.post_tags (
    post_id INTEGER REFERENCES blog.posts(id) ON DELETE CASCADE,
    tag_id INTEGER REFERENCES blog.tags(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, tag_id)
);

CREATE TABLE IF NOT EXISTS blog.comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES blog.posts(id) ON DELETE CASCADE,
    author_id INTEGER REFERENCES blog.users(id) ON DELETE SET NULL,
    parent_id INTEGER REFERENCES blog.comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    author_name VARCHAR(100), -- For guest comments
    author_email VARCHAR(255), -- For guest comments
    is_approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS blog.post_views (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES blog.posts(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES blog.users(id) ON DELETE SET NULL,
    ip_address INET,
    user_agent TEXT,
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_posts_author ON blog.posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_category ON blog.posts(category_id);
CREATE INDEX IF NOT EXISTS idx_posts_status ON blog.posts(status);
CREATE INDEX IF NOT EXISTS idx_posts_published ON blog.posts(published_at);
CREATE INDEX IF NOT EXISTS idx_posts_slug ON blog.posts(slug);
CREATE INDEX IF NOT EXISTS idx_comments_post ON blog.comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent ON blog.comments(parent_id);
CREATE INDEX IF NOT EXISTS idx_post_views_post ON blog.post_views(post_id);

-- Create triggers for updated_at columns
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON blog.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at
    BEFORE UPDATE ON blog.posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comments_updated_at
    BEFORE UPDATE ON blog.comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
