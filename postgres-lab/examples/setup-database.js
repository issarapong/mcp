#!/usr/bin/env node

/**
 * Database Setup Script for MCP PostgreSQL Lab
 * 
 * This script initializes the database with schemas and sample data
 */

import pkg from 'pg';
const { Pool } = pkg;
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Database configuration
const dbConfig = {
  host: process.env.POSTGRES_HOST || 'localhost',
  port: parseInt(process.env.POSTGRES_PORT || '5432'),
  user: process.env.POSTGRES_USER || 'mcplab',
  password: process.env.POSTGRES_PASSWORD || 'mcplab123',
  database: process.env.POSTGRES_DB || 'mcplab',
};

const pool = new Pool(dbConfig);

async function waitForDatabase(maxAttempts = 30, delay = 2000) {
  console.log('🔄 Waiting for PostgreSQL to be ready...');
  
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      const client = await pool.connect();
      await client.query('SELECT 1');
      client.release();
      console.log('✅ PostgreSQL is ready!');
      return;
    } catch (error) {
      console.log(`⏳ Attempt ${attempt}/${maxAttempts}: Database not ready yet...`);
      if (attempt === maxAttempts) {
        throw new Error(`Failed to connect to database after ${maxAttempts} attempts: ${error.message}`);
      }
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}

async function executeSQL(sqlContent, description) {
  console.log(`🔧 ${description}...`);
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    await client.query(sqlContent);
    await client.query('COMMIT');
    console.log(`✅ ${description} completed successfully`);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error(`❌ ${description} failed:`, error.message);
    throw error;
  } finally {
    client.release();
  }
}

async function setupDatabase() {
  try {
    console.log('🚀 Starting MCP PostgreSQL Lab database setup...\n');
    
    // Wait for database to be ready
    await waitForDatabase();
    
    // Create schemas
    console.log('📋 Creating database schemas...');
    await executeSQL(`
      CREATE SCHEMA IF NOT EXISTS ecommerce;
      CREATE SCHEMA IF NOT EXISTS blog;
      CREATE SCHEMA IF NOT EXISTS analytics;
      
      -- Create update trigger function if it doesn't exist
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
          NEW.updated_at = CURRENT_TIMESTAMP;
          RETURN NEW;
      END;
      $$ language 'plpgsql';
    `, 'Schema creation');
    
    // Execute schema files
    const schemaFiles = [
      { file: 'ecommerce-schema.sql', description: 'Creating e-commerce schema' },
      { file: 'blog-schema.sql', description: 'Creating blog schema' },
      { file: 'analytics-schema.sql', description: 'Creating analytics schema' }
    ];
    
    for (const { file, description } of schemaFiles) {
      try {
        const sqlContent = readFileSync(join(__dirname, file), 'utf8');
        await executeSQL(sqlContent, description);
      } catch (error) {
        if (error.code === 'ENOENT') {
          console.log(`⚠️  Schema file ${file} not found, skipping...`);
        } else {
          throw error;
        }
      }
    }
    
    // Insert sample data
    try {
      const sampleDataSQL = readFileSync(join(__dirname, 'sample-data.sql'), 'utf8');
      await executeSQL(sampleDataSQL, 'Inserting sample data');
    } catch (error) {
      if (error.code === 'ENOENT') {
        console.log('⚠️  Sample data file not found, skipping...');
      } else {
        console.log('⚠️  Sample data insertion failed (this is often normal if data already exists)');
      }
    }
    
    // Refresh materialized views
    console.log('🔄 Refreshing materialized views...');
    try {
      await executeSQL(`
        REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.daily_page_views;
        REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.daily_events;
      `, 'Refreshing materialized views');
    } catch (error) {
      console.log('⚠️  Could not refresh materialized views (they might not exist yet)');
    }
    
    // Display summary
    console.log('\n📊 Database setup summary:');
    
    const client = await pool.connect();
    try {
      // Count tables in each schema
      const schemaStats = await client.query(`
        SELECT 
          schemaname,
          COUNT(*) as table_count
        FROM pg_tables 
        WHERE schemaname IN ('ecommerce', 'blog', 'analytics', 'public')
        GROUP BY schemaname
        ORDER BY schemaname
      `);
      
      schemaStats.rows.forEach(row => {
        console.log(`  📋 ${row.schemaname} schema: ${row.table_count} tables`);
      });
      
      // Show sample data counts
      const dataCounts = await client.query(`
        SELECT 
          'ecommerce.products' as table_name,
          COUNT(*) as row_count
        FROM ecommerce.products
        UNION ALL
        SELECT 
          'blog.posts' as table_name,
          COUNT(*) as row_count
        FROM blog.posts
        UNION ALL
        SELECT 
          'analytics.events' as table_name,
          COUNT(*) as row_count
        FROM analytics.events
        ORDER BY table_name
      `);
      
      console.log('\n📈 Sample data counts:');
      dataCounts.rows.forEach(row => {
        console.log(`  📊 ${row.table_name}: ${row.row_count} rows`);
      });
      
    } catch (error) {
      console.log('⚠️  Could not generate summary statistics');
    } finally {
      client.release();
    }
    
    console.log('\n🎉 Database setup completed successfully!');
    console.log('\n📚 Next steps:');
    console.log('  1. Start the MCP server: npm start');
    console.log('  2. Test with the client: npm run client');
    console.log('  3. Access pgAdmin at: http://localhost:8080');
    console.log('  4. Explore the sample data and schemas');
    
  } catch (error) {
    console.error('\n❌ Database setup failed:', error.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

// Handle graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🛑 Setup interrupted');
  await pool.end();
  process.exit(1);
});

// Run setup
setupDatabase();
