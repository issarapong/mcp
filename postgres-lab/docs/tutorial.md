# MCP PostgreSQL Lab - Tutorial

This tutorial will guide you through setting up and using the MCP PostgreSQL Lab environment step by step.

## Prerequisites

Before starting, ensure you have:
- Node.js (v18 or higher)
- Docker and Docker Compose
- Git
- A code editor (VS Code recommended)

## Step 1: Project Setup

1. **Navigate to the lab directory:**
```bash
cd postgres-lab
```

2. **Install dependencies:**
```bash
npm install
```

3. **Copy environment variables:**
```bash
cp .env.example .env
```

4. **Review the environment configuration:**
```bash
cat .env
```

## Step 2: Start the Database

1. **Start PostgreSQL with Docker:**
```bash
npm run docker:up
```

2. **Wait for PostgreSQL to be ready (this may take a minute):**
```bash
npm run docker:logs
```

Look for the message: `database system is ready to accept connections`

3. **Set up the database schemas and sample data:**
```bash
npm run setup-db
```

## Step 3: Explore the Database

1. **Access pgAdmin (optional):**
   - Open http://localhost:8080 in your browser
   - Email: `admin@mcplab.com`
   - Password: `admin123`
   - Add server with connection details from `.env`

2. **Connect to PostgreSQL directly (optional):**
```bash
psql -h localhost -U mcplab -d mcplab
```

3. **View the created schemas:**
```sql
\dn
```

4. **List tables in each schema:**
```sql
\dt ecommerce.*
\dt blog.*
\dt analytics.*
```

## Step 4: Start the MCP Server

1. **Start the server:**
```bash
npm start
```

The server will start and wait for MCP client connections via stdio.

2. **In another terminal, test with the example client:**
```bash
npm run client
```

## Step 5: Understanding the Client Output

The example client will demonstrate various MCP operations:

### 1. Tool Discovery
```
📋 Available tools:
  - query: Execute a SQL query on the PostgreSQL database
  - list_tables: List all tables in the database
  - describe_table: Get detailed information about a table structure
  - get_table_data: Retrieve data from a specific table with optional filtering
  - insert_data: Insert data into a table
  - update_data: Update data in a table
  - delete_data: Delete data from a table
```

### 2. Resource Discovery
```
📚 Available resources:
  - postgresql://tables: Database Tables
  - postgresql://schemas: Database Schemas
```

### 3. Data Operations
The client will show examples of:
- Listing tables
- Creating sample tables
- Inserting data
- Querying with joins
- Describing table structures
- Updating records

## Step 6: Interactive Exploration

Now that everything is set up, try these manual operations:

### 1. Custom Queries

Create a simple Node.js script to run custom queries:

```javascript
import { PostgreSQLMCPClient } from './client/index.js';

const client = new PostgreSQLMCPClient();
await client.connect();

// Your custom query
const result = await client.callTool('query', {
  sql: 'SELECT COUNT(*) as total_products FROM ecommerce.products'
});

console.log(result);
await client.close();
```

### 2. Explore E-commerce Data

```javascript
// Top selling products
const topProducts = await client.callTool('query', {
  sql: `
    SELECT 
      p.name,
      SUM(oi.quantity) as total_sold,
      SUM(oi.total_price) as revenue
    FROM ecommerce.products p
    JOIN ecommerce.order_items oi ON p.id = oi.product_id
    GROUP BY p.id, p.name
    ORDER BY revenue DESC
    LIMIT 5
  `
});
```

### 3. Blog Analytics

```javascript
// Most commented posts
const popularPosts = await client.callTool('query', {
  sql: `
    SELECT 
      p.title,
      COUNT(c.id) as comment_count,
      p.view_count
    FROM blog.posts p
    LEFT JOIN blog.comments c ON p.id = c.post_id
    WHERE p.status = 'published'
    GROUP BY p.id, p.title, p.view_count
    ORDER BY comment_count DESC
  `
});
```

## Step 7: Advanced Usage

### Working with Schemas

1. **Switch between schemas:**
```javascript
// List tables in specific schema
await client.callTool('list_tables', { schema: 'analytics' });

// Get data from specific schema
await client.callTool('get_table_data', {
  table: 'events',
  schema: 'analytics',
  limit: 10
});
```

2. **Cross-schema queries:**
```javascript
await client.callTool('query', {
  sql: `
    SELECT 
      c.first_name,
      c.last_name,
      COUNT(DISTINCT o.id) as orders,
      COUNT(DISTINCT e.id) as events
    FROM ecommerce.customers c
    LEFT JOIN ecommerce.orders o ON c.id = o.customer_id
    LEFT JOIN analytics.events e ON c.id = e.user_id
    GROUP BY c.id, c.first_name, c.last_name
  `
});
```

### Working with JSON Data

The analytics schema includes JSONB columns for flexible data storage:

```javascript
// Query events with specific properties
await client.callTool('query', {
  sql: `
    SELECT 
      event_name,
      properties->>'product_id' as product_id,
      properties->>'product_name' as product_name,
      timestamp
    FROM analytics.events
    WHERE properties->>'product_id' IS NOT NULL
    ORDER BY timestamp DESC
  `
});
```

### Data Manipulation

1. **Insert new customer:**
```javascript
await client.callTool('insert_data', {
  table: 'customers',
  schema: 'ecommerce',
  data: {
    first_name: 'Tutorial',
    last_name: 'User',
    email: `tutorial.${Date.now()}@example.com`,
    phone: '+1555123456'
  }
});
```

2. **Update product stock:**
```javascript
await client.callTool('update_data', {
  table: 'products',
  schema: 'ecommerce',
  data: { stock_quantity: 75 },
  where: "sku = 'BOOK-001'"
});
```

## Step 8: Building Your Own Tools

### Custom MCP Tool

Extend the server with custom tools:

```javascript
// Add to server/index.js
const CUSTOM_TOOLS = [
  {
    name: 'get_customer_summary',
    description: 'Get comprehensive customer summary with orders and analytics',
    inputSchema: {
      type: 'object',
      properties: {
        customer_id: { type: 'number', description: 'Customer ID' }
      },
      required: ['customer_id']
    }
  }
];

async function handleCustomerSummary(args) {
  const { customer_id } = args;
  
  const sql = `
    SELECT 
      c.*,
      COUNT(DISTINCT o.id) as total_orders,
      SUM(o.total_amount) as total_spent,
      COUNT(DISTINCT e.session_id) as total_sessions
    FROM ecommerce.customers c
    LEFT JOIN ecommerce.orders o ON c.id = o.customer_id
    LEFT JOIN analytics.events e ON c.id = e.user_id
    WHERE c.id = $1
    GROUP BY c.id
  `;
  
  const result = await executeQuery(sql, [customer_id]);
  return { content: [{ type: 'text', text: JSON.stringify(result.rows[0]) }] };
}
```

### Custom Client Application

Create specialized clients for different use cases:

```javascript
// analytics-client.js
class AnalyticsClient extends PostgreSQLMCPClient {
  async getDailyStats(days = 7) {
    return await this.callTool('query', {
      sql: `
        SELECT 
          DATE(timestamp) as date,
          COUNT(*) as page_views,
          COUNT(DISTINCT user_id) as unique_users,
          COUNT(DISTINCT session_id) as sessions
        FROM analytics.page_views
        WHERE timestamp >= CURRENT_DATE - INTERVAL '${days} days'
        GROUP BY DATE(timestamp)
        ORDER BY date DESC
      `
    });
  }

  async getConversionFunnel() {
    // Implementation here
  }
}
```

## Step 9: Troubleshooting

### Common Issues

1. **Database connection failed:**
```bash
# Check if PostgreSQL is running
docker ps

# Check PostgreSQL logs
npm run docker:logs

# Restart services
npm run docker:down
npm run docker:up
```

2. **MCP server won't start:**
```bash
# Check Node.js version
node --version  # Should be 18+

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

3. **Client connection issues:**
```bash
# Make sure server is running first
npm start

# Then in another terminal
npm run client
```

### Performance Issues

1. **Slow queries:**
   - Add indexes to frequently queried columns
   - Use LIMIT clauses for large datasets
   - Optimize JOIN operations

2. **Memory usage:**
   - Limit result set sizes
   - Use connection pooling
   - Monitor database statistics

### Debugging

1. **Enable query logging:**
```bash
# In PostgreSQL, enable logging
ALTER SYSTEM SET log_statement = 'all';
SELECT pg_reload_conf();
```

2. **Add debug logging to MCP server:**
```javascript
// In server/index.js
console.log('Executing query:', sql, params);
```

## Step 10: Next Steps

### Production Deployment

1. **Security hardening:**
   - Use environment-specific credentials
   - Enable SSL/TLS for database connections
   - Implement proper access controls
   - Regular security updates

2. **Performance optimization:**
   - Configure connection pooling
   - Add database indexes
   - Monitor query performance
   - Implement caching strategies

3. **Monitoring and logging:**
   - Set up application monitoring
   - Database performance monitoring
   - Error tracking and alerting
   - Backup and recovery procedures

### Integration with AI Systems

1. **LLM Integration:**
   - Connect with OpenAI, Anthropic, or other LLM providers
   - Implement RAG (Retrieval-Augmented Generation) patterns
   - Build AI-powered analytics dashboards

2. **Automation:**
   - Scheduled data processing
   - Automated report generation
   - Real-time alerting systems

### Extending the Lab

1. **Additional schemas:**
   - User management system
   - Inventory management
   - Financial reporting
   - Customer support tickets

2. **Advanced features:**
   - Real-time data streaming
   - Machine learning pipelines
   - API rate limiting
   - Multi-tenant architecture

## Conclusion

You now have a fully functional MCP PostgreSQL lab environment! This setup provides:

- ✅ Complete MCP server implementation
- ✅ Working client examples
- ✅ Multiple database schemas with sample data
- ✅ Docker-based development environment
- ✅ Comprehensive documentation and examples

Use this foundation to:
- Experiment with MCP concepts
- Build AI-powered applications
- Develop custom database tools
- Learn PostgreSQL and MCP integration patterns

For more advanced topics, refer to:
- [API Documentation](api-documentation.md)
- [Sample Queries](../examples/sample-queries.md)
- [MCP Specification](https://spec.modelcontextprotocol.io/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
