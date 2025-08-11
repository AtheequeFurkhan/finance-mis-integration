# Finance MIS Integration

A comprehensive financial management information system built with Ballerina, featuring a backend service for data management and a REST bridge for API access.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│   Frontend      │◄──►│  REST Bridge    │◄──►│  Finance Backend│
│   Application   │    │  (Port 8090)    │    │  (Port 8080)    │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │                 │
                                               │  MySQL Database │
                                               │                 │
                                               └─────────────────┘
```

## Features

### Finance Backend (`ballerina-backend/finance_backend/`)

- **CRUD Operations**: Full Create, Read, Update, Delete operations for transactions
- **Advanced Filtering**: Filter transactions by category, date range, with pagination support
- **Financial Analytics**: Summary endpoint with revenue, expenses, and key metrics
- **Database Integration**: MySQL with connection pooling and optimized queries
- **Error Handling**: Comprehensive error handling with structured responses
- **Logging**: Detailed logging for monitoring and debugging
- **Health Checks**: Built-in health check endpoint

### REST Bridge (`rest-bridge/finance_bridge/`)

- **API Gateway**: Secure access layer with API key authentication
- **Request Proxying**: Intelligent request forwarding to backend services
- **CORS Support**: Cross-origin resource sharing for web applications
- **Rate Limiting**: Built-in timeout and retry mechanisms
- **Documentation**: Auto-generated API documentation endpoint
- **Legacy Support**: Backward compatibility with existing endpoints

## API Endpoints

### Backend Service (localhost:8080)

#### Transactions

- `GET /finance/transactions` - Get all transactions with optional filtering
  - Query params: `category`, `startDate`, `endDate`, `limit`, `offset`
- `GET /finance/transactions/{id}` - Get specific transaction
- `POST /finance/transactions` - Create new transaction
- `PUT /finance/transactions/{id}` - Update transaction
- `DELETE /finance/transactions/{id}` - Delete transaction

#### Analytics

- `GET /finance/summary` - Get financial summary and analytics

#### Utilities

- `GET /finance/health` - Health check
- `GET /finance/data` - Legacy endpoint (backward compatibility)

### Bridge Service (localhost:8090)

All backend endpoints are available through the bridge with the same paths under `/bridge/`:

- `GET /bridge/transactions`
- `GET /bridge/transactions/{id}`
- `POST /bridge/transactions`
- `PUT /bridge/transactions/{id}`
- `DELETE /bridge/transactions/{id}`
- `GET /bridge/summary`
- `GET /bridge/health`
- `GET /bridge/docs` - API documentation

**Authentication**: All bridge endpoints require an API key in the `x-api-key` header.

## Data Models

### Transaction

```json
{
  "id": 1,
  "name": "New Sales",
  "amount": 1200.5,
  "category": "Revenue",
  "description": "New customer acquisition",
  "created_at": "2025-08-11 10:30:00"
}
```

### Transaction Summary

```json
{
  "totalRevenue": 10000.0,
  "totalExpenses": 2500.0,
  "netIncome": 7500.0,
  "transactionCount": 15,
  "averageTransaction": 500.0
}
```

## Setup Instructions

### Prerequisites

- Ballerina 2201.8.6 or later
- MySQL 8.0 or later
- Java 17 (for MySQL connector)

### Database Setup

1. Install and start MySQL
2. Run the database initialization script:
   ```bash
   mysql -u root -p < ballerina-backend/finance_backend/db.sql
   ```

### Backend Service Setup

1. Navigate to the backend directory:

   ```bash
   cd ballerina-backend/finance_backend
   ```

2. Configure database connection in `Config.toml`:

   ```toml
   dbHost = "localhost"
   dbPort = 3306
   dbUser = "root"
   dbPassword = "your_password"
   dbDatabase = "finance_db"
   ```

3. Build and run:
   ```bash
   bal build
   bal run
   ```

### Bridge Service Setup

1. Navigate to the bridge directory:

   ```bash
   cd rest-bridge/finance_bridge
   ```

2. Configure in `Config.toml`:

   ```toml
   backendUrl = "http://localhost:8080/finance"
   apiKey = "your-secure-api-key"
   serverPort = 8090
   timeoutSeconds = 30
   ```

3. Build and run:
   ```bash
   bal build
   bal run
   ```

## Usage Examples

### Create a Transaction

```bash
curl -X POST http://localhost:8090/bridge/transactions \
  -H "Content-Type: application/json" \
  -H "x-api-key: your-secure-api-key" \
  -d '{
    "name": "Consulting Revenue",
    "amount": 2500.00,
    "category": "Revenue",
    "description": "Professional services consultation"
  }'
```

### Get Filtered Transactions

```bash
curl "http://localhost:8090/bridge/transactions?category=Revenue&startDate=2025-01-01&limit=10" \
  -H "x-api-key: your-secure-api-key"
```

### Get Financial Summary

```bash
curl http://localhost:8090/bridge/summary \
  -H "x-api-key: your-secure-api-key"
```

## Configuration

### Backend Configuration (`Config.toml`)

- `dbHost`: Database hostname
- `dbPort`: Database port
- `dbUser`: Database username
- `dbPassword`: Database password
- `dbDatabase`: Database name
- `serverPort`: Backend service port (default: 8080)

### Bridge Configuration (`Config.toml`)

- `backendUrl`: Backend service URL
- `apiKey`: API authentication key
- `serverPort`: Bridge service port (default: 8090)
- `timeoutSeconds`: Request timeout duration

## Development

### Project Structure

```
finance-mis-integration/
├── ballerina-backend/
│   └── finance_backend/
│       ├── main.bal              # Backend service implementation
│       ├── Ballerina.toml        # Project configuration
│       ├── Config.toml           # Runtime configuration
│       ├── db.sql                # Database schema
│       └── lib/                  # MySQL connector library
└── rest-bridge/
    └── finance_bridge/
        ├── main.bal              # Bridge service implementation
        ├── Ballerina.toml        # Project configuration
        └── Config.toml           # Runtime configuration
```

### Adding New Features

1. **Backend**: Add new endpoints in `ballerina-backend/finance_backend/main.bal`
2. **Bridge**: Add corresponding proxy methods in `rest-bridge/finance_bridge/main.bal`
3. **Database**: Update schema in `db.sql` and add migration scripts

### Monitoring and Logging

- Both services include comprehensive logging
- Health check endpoints for monitoring
- Structured error responses for debugging

## Security Considerations

- API key authentication for bridge access
- Database connection credentials in config files (excluded from git)
- CORS configuration for web application integration
- Input validation and sanitization

## Performance Features

- Database connection pooling
- Query optimization with indexes
- Request timeout and retry mechanisms
- Efficient data streaming for large result sets

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit a pull request

## License

This project is licensed under the MIT License.
