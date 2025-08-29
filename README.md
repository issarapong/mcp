# MCP (Model Context Protocol) Examples

This repository contains examples and laboratories for exploring the Model Context Protocol (MCP).

## Projects

### PostgreSQL Lab (`postgres-lab/`)

A comprehensive laboratory environment for exploring MCP with PostgreSQL database integration.

**Features:**
- Complete MCP server implementation for PostgreSQL
- Example client applications
- Docker-based development environment
- Multiple database schemas (e-commerce, blog, analytics)
- Sample data and realistic use cases
- Comprehensive documentation and tutorials

**Quick Start:**
```bash
cd postgres-lab
npm install
npm run docker:up
npm run setup-db
npm start  # In one terminal
npm run client  # In another terminal
```

**What's Included:**
- 🗄️ **PostgreSQL MCP Server**: Full-featured server with 7+ tools for database operations
- 🐳 **Docker Environment**: PostgreSQL, pgAdmin, and Redis containers
- 📊 **Sample Schemas**: E-commerce, blog, and analytics with realistic data
- 🔧 **Client Examples**: Working client implementations and use cases
- 📚 **Documentation**: Complete API docs, tutorials, and sample queries
- 🧪 **Testing Suite**: Examples and patterns for testing MCP integrations

**Tools Available:**
- `query` - Execute SQL queries
- `list_tables` - List database tables
- `describe_table` - Get table schema information
- `get_table_data` - Retrieve filtered table data
- `insert_data` - Insert new records
- `update_data` - Update existing records
- `delete_data` - Delete records

For detailed setup and usage instructions, see [`postgres-lab/README.md`](postgres-lab/README.md).

## Getting Started

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd mcp
   ```

2. **Choose a lab and follow its README:**
   - [PostgreSQL Lab](postgres-lab/README.md) - Database integration with MCP

## Contributing

Contributions are welcome! Please feel free to submit pull requests with:
- New MCP server implementations
- Additional client examples
- Documentation improvements
- Bug fixes and optimizations

## Resources

- [Model Context Protocol Specification](https://spec.modelcontextprotocol.io/)
- [MCP SDK Documentation](https://github.com/modelcontextprotocol/sdk)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## License

MIT License - see individual project directories for specific license information.