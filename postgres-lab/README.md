# MCP PostgreSQL Lab

A comprehensive laboratory environment for exploring the Model Context Protocol (MCP) with PostgreSQL database integration.

## Overview

This lab demonstrates how to build and use MCP servers and clients that interact with PostgreSQL databases. It includes practical examples, sample data, and complete documentation to help you understand MCP concepts and PostgreSQL integration.

## Features

- **MCP Server**: Complete PostgreSQL MCP server implementation
- **MCP Client**: Example client applications
- **Docker Setup**: Containerized PostgreSQL environment
- **Sample Data**: Pre-configured database schemas and sample data
- **Examples**: Practical use cases and demonstrations
- **Documentation**: Comprehensive guides and API documentation

## Quick Start

### 1. Prerequisites

- Node.js (v18 or higher)
- Docker and Docker Compose
- Git

### 2. Installation

```bash
# Clone and navigate to the lab
cd postgres-lab

# Install dependencies
npm install

# Start PostgreSQL with Docker
npm run docker:up

# Wait for PostgreSQL to be ready, then setup the database
npm run setup-db
```

### 3. Run the MCP Server

```bash
# Start the MCP server
npm start

# Or run in development mode with auto-reload
npm run dev
```

### 4. Test with MCP Client

```bash
# In another terminal, run the example client
npm run client
```

## Project Structure

```
postgres-lab/
├── server/           # MCP server implementation
├── client/           # MCP client examples
├── docker/           # Docker configuration
├── examples/         # Example schemas and data
├── docs/            # Documentation
└── README.md        # This file
```

## Database Schema

The lab includes several example schemas:

- **E-commerce**: Products, orders, customers
- **Blog**: Posts, comments, users
- **Analytics**: Events, metrics, reports

## MCP Tools Available

The PostgreSQL MCP server provides these tools:

- `query` - Execute SQL queries
- `describe_table` - Get table schema information
- `list_tables` - List all tables in the database
- `get_table_data` - Retrieve data from specific tables
- `create_table` - Create new tables
- `insert_data` - Insert data into tables
- `update_data` - Update existing records
- `delete_data` - Delete records

## Configuration

Copy `.env.example` to `.env` and configure your database connection:

```env
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=mcplab
POSTGRES_PASSWORD=mcplab123
POSTGRES_DB=mcplab
```

## Docker Services

The included Docker setup provides:

- **PostgreSQL 15**: Main database server
- **pgAdmin**: Web-based database administration
- **Redis**: For caching and session management

## Examples

### Basic Query

```javascript
const result = await mcpClient.callTool("query", {
  sql: "SELECT * FROM products WHERE price > $1",
  params: [100]
});
```

### Table Description

```javascript
const schema = await mcpClient.callTool("describe_table", {
  table: "products"
});
```

## Development

### Adding New Tools

1. Implement the tool in `server/tools/`
2. Register it in `server/index.js`
3. Add tests in `server/tests/`
4. Update documentation

### Database Migrations

```bash
# Run database setup
npm run setup-db

# Or manually run SQL files
psql -h localhost -U mcplab -d mcplab -f examples/schema.sql
```

## Troubleshooting

### Common Issues

1. **PostgreSQL Connection Failed**
   - Ensure Docker is running: `npm run docker:up`
   - Check logs: `npm run docker:logs`

2. **MCP Server Won't Start**
   - Verify Node.js version: `node --version`
   - Install dependencies: `npm install`

3. **Permission Denied**
   - Check PostgreSQL user permissions
   - Verify database exists and is accessible

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Resources

- [Model Context Protocol Documentation](https://modelcontextprotocol.io/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MCP SDK for Node.js](https://github.com/modelcontextprotocol/sdk)

## Support

For questions and support:
- Open an issue on GitHub
- Check the documentation in the `docs/` folder
- Review the examples in the `examples/` folder
