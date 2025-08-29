#!/usr/bin/env node

/**
 * MCP PostgreSQL Client Example
 * 
 * This example demonstrates how to interact with the PostgreSQL MCP server
 * using the Model Context Protocol SDK.
 */

import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';
import { spawn } from 'child_process';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

class PostgreSQLMCPClient {
  constructor() {
    this.client = null;
    this.transport = null;
  }

  async connect() {
    try {
      // Start the MCP server as a subprocess
      const serverProcess = spawn('node', ['server/index.js'], {
        stdio: ['pipe', 'pipe', 'inherit'],
        cwd: process.cwd(),
      });

      // Create transport using the subprocess stdio
      this.transport = new StdioClientTransport({
        reader: serverProcess.stdout,
        writer: serverProcess.stdin,
      });

      // Initialize client
      this.client = new Client(
        {
          name: 'postgres-mcp-client',
          version: '1.0.0',
        },
        {
          capabilities: {
            resources: {},
            tools: {},
          },
        }
      );

      await this.client.connect(this.transport);
      console.log('✅ Connected to MCP PostgreSQL server');
      
      return this;
    } catch (error) {
      console.error('❌ Failed to connect to MCP server:', error);
      throw error;
    }
  }

  async listTools() {
    try {
      const response = await this.client.listTools();
      console.log('📋 Available tools:');
      response.tools.forEach(tool => {
        console.log(`  - ${tool.name}: ${tool.description}`);
      });
      return response.tools;
    } catch (error) {
      console.error('❌ Failed to list tools:', error);
      throw error;
    }
  }

  async listResources() {
    try {
      const response = await this.client.listResources();
      console.log('📚 Available resources:');
      response.resources.forEach(resource => {
        console.log(`  - ${resource.uri}: ${resource.name}`);
      });
      return response.resources;
    } catch (error) {
      console.error('❌ Failed to list resources:', error);
      throw error;
    }
  }

  async callTool(name, args = {}) {
    try {
      console.log(`🔧 Calling tool: ${name}`, args);
      const response = await this.client.callTool({ name, arguments: args });
      return response;
    } catch (error) {
      console.error(`❌ Failed to call tool ${name}:`, error);
      throw error;
    }
  }

  async readResource(uri) {
    try {
      console.log(`📖 Reading resource: ${uri}`);
      const response = await this.client.readResource({ uri });
      return response;
    } catch (error) {
      console.error(`❌ Failed to read resource ${uri}:`, error);
      throw error;
    }
  }

  async close() {
    if (this.client) {
      await this.client.close();
      console.log('✅ Disconnected from MCP server');
    }
  }
}

// Example usage and demonstrations
async function runExamples() {
  const client = new PostgreSQLMCPClient();
  
  try {
    // Connect to the server
    await client.connect();
    
    // List available tools and resources
    await client.listTools();
    console.log('');
    await client.listResources();
    console.log('');

    // Example 1: List all tables
    console.log('🔍 Example 1: List all tables');
    const tablesResponse = await client.callTool('list_tables');
    console.log('Tables:', JSON.parse(tablesResponse.content[0].text));
    console.log('');

    // Example 2: Check if sample tables exist, if not create them
    console.log('🔍 Example 2: Setting up sample data');
    try {
      await client.callTool('describe_table', { table: 'users' });
      console.log('Sample tables already exist');
    } catch (error) {
      console.log('Creating sample tables...');
      
      // Create users table
      await client.callTool('query', {
        sql: `
          CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            email VARCHAR(255) UNIQUE NOT NULL,
            age INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        `
      });

      // Create posts table
      await client.callTool('query', {
        sql: `
          CREATE TABLE IF NOT EXISTS posts (
            id SERIAL PRIMARY KEY,
            user_id INTEGER REFERENCES users(id),
            title VARCHAR(255) NOT NULL,
            content TEXT,
            published BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        `
      });

      console.log('✅ Sample tables created');
    }
    console.log('');

    // Example 3: Insert sample data
    console.log('🔍 Example 3: Insert sample data');
    const userResult = await client.callTool('insert_data', {
      table: 'users',
      data: {
        name: 'Alice Johnson',
        email: `alice.${Date.now()}@example.com`,
        age: 30
      }
    });
    console.log('Inserted user:', JSON.parse(userResult.content[0].text));

    const userId = JSON.parse(userResult.content[0].text).inserted.id;

    const postResult = await client.callTool('insert_data', {
      table: 'posts',
      data: {
        user_id: userId,
        title: 'My First MCP Post',
        content: 'This is a sample post created through the MCP PostgreSQL server!',
        published: true
      }
    });
    console.log('Inserted post:', JSON.parse(postResult.content[0].text));
    console.log('');

    // Example 4: Query data with joins
    console.log('🔍 Example 4: Query data with joins');
    const joinResult = await client.callTool('query', {
      sql: `
        SELECT 
          u.name,
          u.email,
          p.title,
          p.content,
          p.created_at
        FROM users u
        JOIN posts p ON u.id = p.user_id
        WHERE p.published = true
        ORDER BY p.created_at DESC
        LIMIT 5
      `
    });
    console.log('Recent published posts:', JSON.parse(joinResult.content[0].text));
    console.log('');

    // Example 5: Describe table structure
    console.log('🔍 Example 5: Describe table structure');
    const tableDesc = await client.callTool('describe_table', { table: 'users' });
    console.log('Users table structure:', JSON.parse(tableDesc.content[0].text));
    console.log('');

    // Example 6: Get table data with filtering
    console.log('🔍 Example 6: Get table data with filtering');
    const userData = await client.callTool('get_table_data', {
      table: 'users',
      where: 'age >= 25',
      order_by: 'created_at DESC',
      limit: 10
    });
    console.log('Users 25 and older:', JSON.parse(userData.content[0].text));
    console.log('');

    // Example 7: Update data
    console.log('🔍 Example 7: Update data');
    const updateResult = await client.callTool('update_data', {
      table: 'users',
      data: { age: 31 },
      where: `id = ${userId}`
    });
    console.log('Updated user:', JSON.parse(updateResult.content[0].text));
    console.log('');

    // Example 8: Read resources
    console.log('🔍 Example 8: Read resources');
    const tablesResource = await client.readResource('postgresql://tables');
    console.log('Tables resource:', JSON.parse(tablesResource.contents[0].text));
    console.log('');

    const schemasResource = await client.readResource('postgresql://schemas');
    console.log('Schemas resource:', JSON.parse(schemasResource.contents[0].text));
    console.log('');

    console.log('🎉 All examples completed successfully!');

  } catch (error) {
    console.error('❌ Example failed:', error);
  } finally {
    await client.close();
  }
}

// Handle graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down client...');
  process.exit(0);
});

// Run the examples
if (import.meta.url === `file://${process.argv[1]}`) {
  runExamples().catch(console.error);
}

export { PostgreSQLMCPClient };
