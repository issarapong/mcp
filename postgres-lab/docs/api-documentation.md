# MCP PostgreSQL Lab - API Documentation

This document provides comprehensive documentation for the MCP PostgreSQL server tools and resources.

## Overview

The MCP PostgreSQL server provides a set of tools that allow AI agents to interact with PostgreSQL databases through the Model Context Protocol. These tools enable querying, data manipulation, and schema inspection.

## Tools

### 1. query

Execute raw SQL queries on the PostgreSQL database.

**Parameters:**
- `sql` (string, required): The SQL query to execute
- `params` (array, optional): Parameters for the SQL query (for prepared statements)

**Example:**
```javascript
await mcpClient.callTool("query", {
  sql: "SELECT * FROM products WHERE price > $1",
  params: [100]
});
```

**Response:**
```json
{
  "content": [{
    "type": "text",
    "text": "{
      \"rows\": [...],
      \"rowCount\": 5,
      \"command\": \"SELECT\",
      \"fields\": [...]
    }"
  }]
}
```

### 2. list_tables

List all tables in the database, optionally filtered by schema.

**Parameters:**
- `schema` (string, optional): Schema name to filter tables

**Example:**
```javascript
await mcpClient.callTool("list_tables", {
  schema: "ecommerce"
});
```

**Response:**
```json
{
  "content": [{
    "type": "text",
    "text": "[
      {
        \"schemaname\": \"ecommerce\",
        \"tablename\": \"products\",
        \"tableowner\": \"mcplab\",
        \"hasindexes\": true,
        \"hasrules\": false,
        \"hastriggers\": true,
        \"rowsecurity\": false
      }
    ]"
  }]
}
```

### 3. describe_table

Get detailed information about a table's structure including columns, data types, and constraints.

**Parameters:**
- `table` (string, required): Name of the table to describe
- `schema` (string, optional): Schema name (defaults to 'public')

**Example:**
```javascript
await mcpClient.callTool("describe_table", {
  table: "products",
  schema: "ecommerce"
});
```

**Response:**
```json
{
  "content": [{
    "type": "text",
    "text": "{
      \"table\": \"ecommerce.products\",
      \"columns\": [
        {
          \"column_name\": \"id\",
          \"data_type\": \"integer\",
          \"is_nullable\": \"NO\",
          \"column_default\": \"nextval('ecommerce.products_id_seq'::regclass)\",
          \"ordinal_position\": 1
        }
      ]
    }"
  }]
}
```

### 4. get_table_data

Retrieve data from a specific table with optional filtering and ordering.

**Parameters:**
- `table` (string, required): Name of the table
- `schema` (string, optional): Schema name (defaults to 'public')
- `limit` (number, optional): Maximum number of rows to return (default: 100)
- `where` (string, optional): WHERE clause for filtering
- `order_by` (string, optional): ORDER BY clause for sorting

**Example:**
```javascript
await mcpClient.callTool("get_table_data", {
  table: "products",
  schema: "ecommerce",
  where: "price > 100",
  order_by: "price DESC",
  limit: 10
});
```

**Response:**
```json
{
  "content": [{
    "type": "text",
    "text": "{
      \"table\": \"ecommerce.products\",
      \"rows\": [...],
      \"rowCount\": 10
    }"
  }]
}
```

### 5. insert_data

Insert new data into a table.

**Parameters:**
- `table` (string, required): Name of the table
- `schema` (string, optional): Schema name (defaults to 'public')
- `data` (object, required): Data to insert as column-value pairs

**Example:**
```javascript
await mcpClient.callTool("insert_data", {
  table: "products",
  schema: "ecommerce",
  data: {
    name: "New Product",
    price: 99.99,
    category_id: 1,
    stock_quantity: 50
  }
});
```

**Response:**
```json
{
  "content": [{
    "type": "text",
    "text": "{
      \"table\": \"ecommerce.products\",
      \"inserted\": {
        \"id\": 123,
        \"name\": \"New Product\",
        \"price\": \"99.99\",
        ...
      },
      \"rowCount\": 1
    }"
  }]
}
```

### 6. update_data

Update existing data in a table.

**Parameters:**
- `table` (string, required): Name of the table
- `schema` (string, optional): Schema name (defaults to 'public')
- `data` (object, required): Data to update as column-value pairs
- `where` (string, required): WHERE clause to identify rows to update

**Example:**
```javascript
await mcpClient.callTool("update_data", {
  table: "products",
  schema: "ecommerce",
  data: {
    price: 89.99,
    stock_quantity: 25
  },
  where: "id = 123"
});
```

**Response:**
```json
{
  "content": [{
    "type": "text",
    "text": "{
      \"table\": \"ecommerce.products\",
      \"updated\": [...],
      \"rowCount\": 1
    }"
  }]
}
```

### 7. delete_data

Delete data from a table.

**Parameters:**
- `table` (string, required): Name of the table
- `schema` (string, optional): Schema name (defaults to 'public')
- `where` (string, required): WHERE clause to identify rows to delete

**Example:**
```javascript
await mcpClient.callTool("delete_data", {
  table: "products",
  schema: "ecommerce",
  where: "id = 123"
});
```

**Response:**
```json
{
  "content": [{
    "type": "text",
    "text": "{
      \"table\": \"ecommerce.products\",
      \"deleted\": [...],
      \"rowCount\": 1
    }"
  }]
}
```

## Resources

### 1. postgresql://tables

Provides a list of all tables in the database grouped by schema.

**Example:**
```javascript
await mcpClient.readResource("postgresql://tables");
```

**Response:**
```json
{
  "contents": [{
    "uri": "postgresql://tables",
    "mimeType": "application/json",
    "text": "[
      {\"schemaname\": \"ecommerce\", \"tablename\": \"products\"},
      {\"schemaname\": \"ecommerce\", \"tablename\": \"customers\"},
      ...
    ]"
  }]
}
```

### 2. postgresql://schemas

Provides a list of all schemas in the database (excluding system schemas).

**Example:**
```javascript
await mcpClient.readResource("postgresql://schemas");
```

**Response:**
```json
{
  "contents": [{
    "uri": "postgresql://schemas",
    "mimeType": "application/json",
    "text": "[
      {\"schema_name\": \"public\"},
      {\"schema_name\": \"ecommerce\"},
      {\"schema_name\": \"blog\"},
      {\"schema_name\": \"analytics\"}
    ]"
  }]
}
```

## Error Handling

All tools return standardized error responses when operations fail:

```json
{
  "error": {
    "code": "InternalError",
    "message": "Database query failed: relation \"invalid_table\" does not exist"
  }
}
```

Common error codes:
- `InvalidRequest`: Invalid parameters or malformed requests
- `InternalError`: Database errors, connection issues, or server errors
- `MethodNotFound`: Unknown tool names

## Security Considerations

### SQL Injection Prevention

The server uses parameterized queries for the `query` tool when parameters are provided:

```javascript
// Safe - uses parameterized query
await mcpClient.callTool("query", {
  sql: "SELECT * FROM users WHERE id = $1",
  params: [userId]
});

// Potentially unsafe - direct string interpolation
await mcpClient.callTool("query", {
  sql: `SELECT * FROM users WHERE id = ${userId}` // Don't do this!
});
```

### Access Control

The server operates with the permissions of the configured database user. Ensure the database user has appropriate permissions:

- Read-only access for analytical workloads
- Limited write access for specific schemas
- No access to system tables or sensitive data

### Connection Security

- Always use SSL/TLS for database connections in production
- Store credentials in environment variables
- Use connection pooling to manage database connections efficiently

## Performance Tips

### Efficient Querying

1. **Use LIMIT** for large result sets:
```javascript
await mcpClient.callTool("get_table_data", {
  table: "large_table",
  limit: 100
});
```

2. **Add WHERE clauses** to filter data:
```javascript
await mcpClient.callTool("get_table_data", {
  table: "orders",
  where: "created_at >= CURRENT_DATE - INTERVAL '7 days'"
});
```

3. **Use appropriate indexes** on frequently queried columns

4. **Avoid SELECT \*** for large tables - specify needed columns:
```javascript
await mcpClient.callTool("query", {
  sql: "SELECT id, name, price FROM products WHERE category_id = $1",
  params: [categoryId]
});
```

### Connection Management

- The server uses connection pooling to manage database connections
- Connections are automatically released after each query
- Configure pool size based on expected concurrent usage

### Monitoring

Monitor these metrics for optimal performance:
- Query execution time
- Connection pool usage
- Database locks and blocking queries
- Index usage statistics

## Best Practices

### Data Validation

Always validate data before insertion:

```javascript
// Validate required fields
if (!data.name || !data.price) {
  throw new Error("Name and price are required");
}

// Validate data types
if (typeof data.price !== 'number' || data.price < 0) {
  throw new Error("Price must be a positive number");
}

await mcpClient.callTool("insert_data", {
  table: "products",
  data: data
});
```

### Transaction Management

For multi-step operations, use transactions:

```javascript
await mcpClient.callTool("query", { sql: "BEGIN" });

try {
  // Multiple operations
  await mcpClient.callTool("insert_data", {...});
  await mcpClient.callTool("update_data", {...});
  
  await mcpClient.callTool("query", { sql: "COMMIT" });
} catch (error) {
  await mcpClient.callTool("query", { sql: "ROLLBACK" });
  throw error;
}
```

### Schema Organization

- Use schemas to organize related tables (`ecommerce`, `blog`, `analytics`)
- Follow consistent naming conventions
- Document table relationships and constraints
- Use meaningful column names and types

### Testing

Test your MCP tools with:
- Valid and invalid input data
- Edge cases (empty results, large datasets)
- Error conditions (network failures, invalid SQL)
- Performance under load

## Integration Examples

### With AI Agents

```javascript
// AI agent analyzing sales data
const salesData = await mcpClient.callTool("query", {
  sql: `
    SELECT 
      DATE_TRUNC('month', order_date) as month,
      SUM(total_amount) as revenue,
      COUNT(*) as order_count
    FROM ecommerce.orders 
    WHERE status = 'delivered'
    AND order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY DATE_TRUNC('month', order_date)
    ORDER BY month
  `
});

// Process results for AI analysis
const trends = JSON.parse(salesData.content[0].text);
```

### With Web Applications

```javascript
// Express.js API endpoint
app.get('/api/products', async (req, res) => {
  try {
    const products = await mcpClient.callTool("get_table_data", {
      table: "products",
      schema: "ecommerce",
      where: "is_active = true",
      limit: parseInt(req.query.limit) || 20
    });
    
    res.json(JSON.parse(products.content[0].text));
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

### With Analytics Tools

```javascript
// Generate daily report
const report = await mcpClient.callTool("query", {
  sql: `
    WITH daily_stats AS (
      SELECT 
        DATE(timestamp) as date,
        COUNT(*) as page_views,
        COUNT(DISTINCT user_id) as unique_users
      FROM analytics.page_views
      WHERE timestamp >= CURRENT_DATE - INTERVAL '7 days'
      GROUP BY DATE(timestamp)
    )
    SELECT * FROM daily_stats ORDER BY date DESC
  `
});
```
