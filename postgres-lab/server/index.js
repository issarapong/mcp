#!/usr/bin/env node

/**
 * MCP PostgreSQL Server
 * 
 * A Model Context Protocol server that provides PostgreSQL database access
 * through standardized tools and resources.
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ErrorCode,
  ListResourcesRequestSchema,
  ListToolsRequestSchema,
  McpError,
  ReadResourceRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

import pkg from 'pg';
const { Pool } = pkg;
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Database configuration
const dbConfig = {
  host: process.env.POSTGRES_HOST || 'localhost',
  port: parseInt(process.env.POSTGRES_PORT || '5432'),
  user: process.env.POSTGRES_USER || 'mcplab',
  password: process.env.POSTGRES_PASSWORD || 'mcplab123',
  database: process.env.POSTGRES_DB || 'mcplab',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
};

// Initialize database pool
const pool = new Pool(dbConfig);

// Initialize MCP server
const server = new Server(
  {
    name: 'postgres-mcp-server',
    version: '1.0.0',
  },
  {
    capabilities: {
      resources: {},
      tools: {},
    },
  }
);

// Tool definitions
const TOOLS = [
  {
    name: 'query',
    description: 'Execute a SQL query on the PostgreSQL database',
    inputSchema: {
      type: 'object',
      properties: {
        sql: {
          type: 'string',
          description: 'The SQL query to execute',
        },
        params: {
          type: 'array',
          description: 'Parameters for the SQL query (optional)',
          items: {
            type: ['string', 'number', 'boolean', 'null'],
          },
        },
      },
      required: ['sql'],
    },
  },
  {
    name: 'list_tables',
    description: 'List all tables in the database',
    inputSchema: {
      type: 'object',
      properties: {
        schema: {
          type: 'string',
          description: 'Optional schema name to filter tables',
        },
      },
    },
  },
  {
    name: 'describe_table',
    description: 'Get detailed information about a table structure',
    inputSchema: {
      type: 'object',
      properties: {
        table: {
          type: 'string',
          description: 'Name of the table to describe',
        },
        schema: {
          type: 'string',
          description: 'Schema name (optional, defaults to public)',
        },
      },
      required: ['table'],
    },
  },
  {
    name: 'get_table_data',
    description: 'Retrieve data from a specific table with optional filtering',
    inputSchema: {
      type: 'object',
      properties: {
        table: {
          type: 'string',
          description: 'Name of the table',
        },
        schema: {
          type: 'string',
          description: 'Schema name (optional)',
        },
        limit: {
          type: 'number',
          description: 'Maximum number of rows to return (default: 100)',
        },
        where: {
          type: 'string',
          description: 'WHERE clause (optional)',
        },
        order_by: {
          type: 'string',
          description: 'ORDER BY clause (optional)',
        },
      },
      required: ['table'],
    },
  },
  {
    name: 'insert_data',
    description: 'Insert data into a table',
    inputSchema: {
      type: 'object',
      properties: {
        table: {
          type: 'string',
          description: 'Name of the table',
        },
        schema: {
          type: 'string',
          description: 'Schema name (optional)',
        },
        data: {
          type: 'object',
          description: 'Data to insert (column: value pairs)',
        },
      },
      required: ['table', 'data'],
    },
  },
  {
    name: 'update_data',
    description: 'Update data in a table',
    inputSchema: {
      type: 'object',
      properties: {
        table: {
          type: 'string',
          description: 'Name of the table',
        },
        schema: {
          type: 'string',
          description: 'Schema name (optional)',
        },
        data: {
          type: 'object',
          description: 'Data to update (column: value pairs)',
        },
        where: {
          type: 'string',
          description: 'WHERE clause to identify rows to update',
        },
      },
      required: ['table', 'data', 'where'],
    },
  },
  {
    name: 'delete_data',
    description: 'Delete data from a table',
    inputSchema: {
      type: 'object',
      properties: {
        table: {
          type: 'string',
          description: 'Name of the table',
        },
        schema: {
          type: 'string',
          description: 'Schema name (optional)',
        },
        where: {
          type: 'string',
          description: 'WHERE clause to identify rows to delete',
        },
      },
      required: ['table', 'where'],
    },
  },
];

// Resource definitions
const RESOURCES = [
  {
    uri: 'postgresql://tables',
    name: 'Database Tables',
    description: 'List of all tables in the database',
    mimeType: 'application/json',
  },
  {
    uri: 'postgresql://schemas',
    name: 'Database Schemas',
    description: 'List of all schemas in the database',
    mimeType: 'application/json',
  },
];

// Helper functions
function buildTableName(table, schema = 'public') {
  return schema === 'public' ? table : `${schema}.${table}`;
}

async function executeQuery(sql, params = []) {
  const client = await pool.connect();
  try {
    const result = await client.query(sql, params);
    return result;
  } finally {
    client.release();
  }
}

// Tool handlers
async function handleQuery(args) {
  try {
    const { sql, params = [] } = args;
    const result = await executeQuery(sql, params);
    
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            rows: result.rows,
            rowCount: result.rowCount,
            command: result.command,
            fields: result.fields?.map(f => ({
              name: f.name,
              dataTypeID: f.dataTypeID,
            })),
          }, null, 2),
        },
      ],
    };
  } catch (error) {
    throw new McpError(
      ErrorCode.InternalError,
      `Database query failed: ${error.message}`
    );
  }
}

async function handleListTables(args) {
  try {
    const { schema } = args;
    let sql = `
      SELECT 
        schemaname,
        tablename,
        tableowner,
        hasindexes,
        hasrules,
        hastriggers,
        rowsecurity
      FROM pg_tables
    `;
    
    const params = [];
    if (schema) {
      sql += ' WHERE schemaname = $1';
      params.push(schema);
    }
    
    sql += ' ORDER BY schemaname, tablename';
    
    const result = await executeQuery(sql, params);
    
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(result.rows, null, 2),
        },
      ],
    };
  } catch (error) {
    throw new McpError(
      ErrorCode.InternalError,
      `Failed to list tables: ${error.message}`
    );
  }
}

async function handleDescribeTable(args) {
  try {
    const { table, schema = 'public' } = args;
    
    const sql = `
      SELECT 
        column_name,
        data_type,
        character_maximum_length,
        is_nullable,
        column_default,
        ordinal_position
      FROM information_schema.columns
      WHERE table_name = $1 AND table_schema = $2
      ORDER BY ordinal_position
    `;
    
    const result = await executeQuery(sql, [table, schema]);
    
    if (result.rows.length === 0) {
      throw new McpError(
        ErrorCode.InvalidRequest,
        `Table '${buildTableName(table, schema)}' not found`
      );
    }
    
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            table: buildTableName(table, schema),
            columns: result.rows,
          }, null, 2),
        },
      ],
    };
  } catch (error) {
    if (error instanceof McpError) throw error;
    throw new McpError(
      ErrorCode.InternalError,
      `Failed to describe table: ${error.message}`
    );
  }
}

async function handleGetTableData(args) {
  try {
    const { table, schema = 'public', limit = 100, where, order_by } = args;
    
    let sql = `SELECT * FROM ${buildTableName(table, schema)}`;
    const params = [];
    
    if (where) {
      sql += ` WHERE ${where}`;
    }
    
    if (order_by) {
      sql += ` ORDER BY ${order_by}`;
    }
    
    sql += ` LIMIT $${params.length + 1}`;
    params.push(limit);
    
    const result = await executeQuery(sql, params);
    
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            table: buildTableName(table, schema),
            rows: result.rows,
            rowCount: result.rowCount,
          }, null, 2),
        },
      ],
    };
  } catch (error) {
    throw new McpError(
      ErrorCode.InternalError,
      `Failed to get table data: ${error.message}`
    );
  }
}

async function handleInsertData(args) {
  try {
    const { table, schema = 'public', data } = args;
    
    const columns = Object.keys(data);
    const values = Object.values(data);
    const placeholders = values.map((_, i) => `$${i + 1}`).join(', ');
    
    const sql = `
      INSERT INTO ${buildTableName(table, schema)} (${columns.join(', ')})
      VALUES (${placeholders})
      RETURNING *
    `;
    
    const result = await executeQuery(sql, values);
    
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            table: buildTableName(table, schema),
            inserted: result.rows[0],
            rowCount: result.rowCount,
          }, null, 2),
        },
      ],
    };
  } catch (error) {
    throw new McpError(
      ErrorCode.InternalError,
      `Failed to insert data: ${error.message}`
    );
  }
}

async function handleUpdateData(args) {
  try {
    const { table, schema = 'public', data, where } = args;
    
    const columns = Object.keys(data);
    const values = Object.values(data);
    const setClause = columns.map((col, i) => `${col} = $${i + 1}`).join(', ');
    
    const sql = `
      UPDATE ${buildTableName(table, schema)}
      SET ${setClause}
      WHERE ${where}
      RETURNING *
    `;
    
    const result = await executeQuery(sql, values);
    
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            table: buildTableName(table, schema),
            updated: result.rows,
            rowCount: result.rowCount,
          }, null, 2),
        },
      ],
    };
  } catch (error) {
    throw new McpError(
      ErrorCode.InternalError,
      `Failed to update data: ${error.message}`
    );
  }
}

async function handleDeleteData(args) {
  try {
    const { table, schema = 'public', where } = args;
    
    const sql = `
      DELETE FROM ${buildTableName(table, schema)}
      WHERE ${where}
      RETURNING *
    `;
    
    const result = await executeQuery(sql);
    
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            table: buildTableName(table, schema),
            deleted: result.rows,
            rowCount: result.rowCount,
          }, null, 2),
        },
      ],
    };
  } catch (error) {
    throw new McpError(
      ErrorCode.InternalError,
      `Failed to delete data: ${error.message}`
    );
  }
}

// Resource handlers
async function handleListResources() {
  return {
    resources: RESOURCES,
  };
}

async function handleReadResource(args) {
  const { uri } = args;
  
  try {
    if (uri === 'postgresql://tables') {
      const result = await executeQuery(`
        SELECT schemaname, tablename
        FROM pg_tables
        ORDER BY schemaname, tablename
      `);
      
      return {
        contents: [
          {
            uri,
            mimeType: 'application/json',
            text: JSON.stringify(result.rows, null, 2),
          },
        ],
      };
    }
    
    if (uri === 'postgresql://schemas') {
      const result = await executeQuery(`
        SELECT schema_name
        FROM information_schema.schemata
        WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
        ORDER BY schema_name
      `);
      
      return {
        contents: [
          {
            uri,
            mimeType: 'application/json',
            text: JSON.stringify(result.rows, null, 2),
          },
        ],
      };
    }
    
    throw new McpError(ErrorCode.InvalidRequest, `Unknown resource: ${uri}`);
  } catch (error) {
    if (error instanceof McpError) throw error;
    throw new McpError(
      ErrorCode.InternalError,
      `Failed to read resource: ${error.message}`
    );
  }
}

// Register handlers
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: TOOLS,
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  
  switch (name) {
    case 'query':
      return await handleQuery(args);
    case 'list_tables':
      return await handleListTables(args);
    case 'describe_table':
      return await handleDescribeTable(args);
    case 'get_table_data':
      return await handleGetTableData(args);
    case 'insert_data':
      return await handleInsertData(args);
    case 'update_data':
      return await handleUpdateData(args);
    case 'delete_data':
      return await handleDeleteData(args);
    default:
      throw new McpError(ErrorCode.MethodNotFound, `Unknown tool: ${name}`);
  }
});

server.setRequestHandler(ListResourcesRequestSchema, handleListResources);
server.setRequestHandler(ReadResourceRequestSchema, handleReadResource);

// Error handling
process.on('SIGINT', async () => {
  console.log('Shutting down MCP PostgreSQL server...');
  await pool.end();
  process.exit(0);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Start server
async function main() {
  try {
    // Test database connection
    const client = await pool.connect();
    console.log('Connected to PostgreSQL database');
    client.release();
    
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.log('MCP PostgreSQL server running on stdio');
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

main();
