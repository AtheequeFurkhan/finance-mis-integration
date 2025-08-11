import ballerina/http;
import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerinax/mysql;

// Configuration
configurable string dbHost = ?;
configurable int dbPort = ?;
configurable string dbUser = ?;
configurable string dbPassword = ?;
configurable string dbDatabase = ?;
configurable int serverPort = 8080;

// Database connection with connection pooling
mysql:Client dbClient = check new (
    host = dbHost,
    port = dbPort,
    user = dbUser,
    password = dbPassword,
    database = dbDatabase,
    connectionPool = {
        maxOpenConnections: 10,
        maxConnectionLifeTime: 30,
        minIdleConnections: 5
    }
);

// Data types
type Transaction record {|
    int id?;
    string name;
    decimal amount;
    string created_at?;
    string category?;
    string description?;
|};

type TransactionInput record {|
    string name;
    decimal amount;
    string? category;
    string? description;
|};

type TransactionSummary record {|
    decimal totalRevenue;
    decimal totalExpenses;
    decimal netIncome;
    int transactionCount;
    decimal averageTransaction;
|};

type ApiResponse record {|
    boolean success;
    string message;
    json data?;
    string timestamp;
|};

// CORS configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["CORELATION_ID", "Authorization", "Content-Type"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service /finance on new http:Listener(serverPort) {

    # Get all transactions with optional filtering
    # + category - Filter by transaction category
    # + startDate - Filter transactions from this date (YYYY-MM-DD)
    # + endDate - Filter transactions until this date (YYYY-MM-DD)
    # + 'limit - Limit number of results
    # + offset - Offset for pagination
    # + return - List of transactions or error
    resource function get transactions(string? category = (), string? startDate = (),
            string? endDate = (), int? 'limit = (), int? offset = ())
                                    returns json|http:InternalServerError {
        log:printInfo("Fetching transactions with filters");

        sql:ParameterizedQuery sqlQuery = `SELECT id, name, amount, DATE_FORMAT(created_at, '%Y-%m-%d %H:%i:%s') AS created_at FROM transactions WHERE 1=1`;

        // Add category filter
        if category is string {
            sqlQuery = sql:queryConcat(sqlQuery, ` AND category = ${category}`);
        }

        // Add date filters
        if startDate is string {
            sqlQuery = sql:queryConcat(sqlQuery, ` AND DATE(created_at) >= ${startDate}`);
        }

        if endDate is string {
            sqlQuery = sql:queryConcat(sqlQuery, ` AND DATE(created_at) <= ${endDate}`);
        }

        // Add ordering
        sqlQuery = sql:queryConcat(sqlQuery, ` ORDER BY created_at DESC`);

        // Add pagination
        if 'limit is int {
            sqlQuery = sql:queryConcat(sqlQuery, ` LIMIT ${'limit}`);
            if offset is int {
                sqlQuery = sql:queryConcat(sqlQuery, ` OFFSET ${offset}`);
            }
        }

        do {
            stream<record {int id; string name; decimal amount; string created_at;}, error?> resultStream =
                dbClient->query(sqlQuery);

            json[] results = [];
            check from record {int id; string name; decimal amount; string created_at;} row in resultStream
                do {
                    results.push({
                        id: row.id,
                        name: row.name,
                        amount: row.amount,
                        created_at: row.created_at
                    });
                };

            ApiResponse response = {
                success: true,
                message: "Transactions retrieved successfully",
                data: results,
                timestamp: time:utcToString(time:utcNow())
            };

            return response;
        } on fail error e {
            log:printError("Error fetching transactions", 'error = e);
            return <http:InternalServerError>{
                body: {
                    success: false,
                    message: "Failed to fetch transactions",
                    timestamp: time:utcToString(time:utcNow())
                }
            };
        }
    }

    # Get a specific transaction by ID
    # + id - Transaction ID
    # + return - Transaction details or error
    resource function get transactions/[int id]() returns json|http:NotFound|http:InternalServerError {
        log:printInfo("Fetching transaction", id = id);

        do {
            stream<record {int id; string name; decimal amount; string created_at;}, error?> resultStream =
                dbClient->query(`SELECT id, name, amount, DATE_FORMAT(created_at, '%Y-%m-%d %H:%i:%s') AS created_at FROM transactions WHERE id = ${id}`);

            record {|record {int id; string name; decimal amount; string created_at;} value;|}|error? result = resultStream.next();

            if result is error? {
                return <http:NotFound>{
                    body: {
                        success: false,
                        message: "Transaction not found",
                        timestamp: time:utcToString(time:utcNow())
                    }
                };
            }

            ApiResponse response = {
                success: true,
                message: "Transaction retrieved successfully",
                data: result.value.toJson(),
                timestamp: time:utcToString(time:utcNow())
            };

            return response;
        } on fail error e {
            log:printError("Error fetching transaction", 'error = e);
            return <http:InternalServerError>{
                body: {
                    success: false,
                    message: "Failed to fetch transaction",
                    timestamp: time:utcToString(time:utcNow())
                }
            };
        }
    }

    # Create a new transaction
    # + request - HTTP request containing transaction data
    # + return - Created transaction or error
    resource function post transactions(http:Request request) returns json|http:BadRequest|http:InternalServerError {
        log:printInfo("Creating new transaction");

        do {
            json payload = check request.getJsonPayload();
            TransactionInput transactionData = check payload.cloneWithType(TransactionInput);

            // Validate required fields
            if transactionData.name.trim().length() == 0 {
                return <http:BadRequest>{
                    body: {
                        success: false,
                        message: "Transaction name is required",
                        timestamp: time:utcToString(time:utcNow())
                    }
                };
            }

            sql:ExecutionResult result = check dbClient->execute(`
                INSERT INTO transactions (name, amount, category, description) 
                VALUES (${transactionData.name}, ${transactionData.amount}, ${transactionData.category}, ${transactionData.description})
            `);

            ApiResponse response = {
                success: true,
                message: "Transaction created successfully",
                data: {
                    id: result.lastInsertId,
                    name: transactionData.name,
                    amount: transactionData.amount,
                    category: transactionData.category,
                    description: transactionData.description
                },
                timestamp: time:utcToString(time:utcNow())
            };

            return response;
        } on fail error e {
            log:printError("Error creating transaction", 'error = e);
            return <http:InternalServerError>{
                body: {
                    success: false,
                    message: "Failed to create transaction",
                    timestamp: time:utcToString(time:utcNow())
                }
            };
        }
    }

    # Update an existing transaction
    # + id - Transaction ID to update
    # + request - HTTP request containing updated transaction data
    # + return - Updated transaction or error
    resource function put transactions/[int id](http:Request request) returns json|http:BadRequest|http:NotFound|http:InternalServerError {
        log:printInfo("Updating transaction", id = id);

        do {
            json payload = check request.getJsonPayload();
            TransactionInput transactionData = check payload.cloneWithType(TransactionInput);

            // Check if transaction exists
            stream<record {int count;}, error?> countStream =
                dbClient->query(`SELECT COUNT(*) as count FROM transactions WHERE id = ${id}`);
            record {|record {int count;} value;|}|error? countResult = countStream.next();

            if countResult is error? || (countResult is record {|record {int count;} value;|} && countResult.value.count == 0) {
                return <http:NotFound>{
                    body: {
                        success: false,
                        message: "Transaction not found",
                        timestamp: time:utcToString(time:utcNow())
                    }
                };
            }

            sql:ExecutionResult _ = check dbClient->execute(`
                UPDATE transactions 
                SET name = ${transactionData.name}, amount = ${transactionData.amount}, 
                    category = ${transactionData.category}, description = ${transactionData.description}
                WHERE id = ${id}
            `);

            ApiResponse response = {
                success: true,
                message: "Transaction updated successfully",
                data: {
                    id: id,
                    name: transactionData.name,
                    amount: transactionData.amount,
                    category: transactionData.category,
                    description: transactionData.description
                },
                timestamp: time:utcToString(time:utcNow())
            };

            return response;
        } on fail error e {
            log:printError("Error updating transaction", 'error = e);
            return <http:InternalServerError>{
                body: {
                    success: false,
                    message: "Failed to update transaction",
                    timestamp: time:utcToString(time:utcNow())
                }
            };
        }
    }

    # Delete a transaction
    # + id - Transaction ID to delete
    # + return - Success message or error
    resource function delete transactions/[int id]() returns json|http:NotFound|http:InternalServerError {
        log:printInfo("Deleting transaction", id = id);

        do {
            sql:ExecutionResult result = check dbClient->execute(`DELETE FROM transactions WHERE id = ${id}`);

            if result.affectedRowCount == 0 {
                return <http:NotFound>{
                    body: {
                        success: false,
                        message: "Transaction not found",
                        timestamp: time:utcToString(time:utcNow())
                    }
                };
            }

            ApiResponse response = {
                success: true,
                message: "Transaction deleted successfully",
                timestamp: time:utcToString(time:utcNow())
            };

            return response;
        } on fail error e {
            log:printError("Error deleting transaction", 'error = e);
            return <http:InternalServerError>{
                body: {
                    success: false,
                    message: "Failed to delete transaction",
                    timestamp: time:utcToString(time:utcNow())
                }
            };
        }
    }

    # Get financial summary and analytics
    # + return - Financial summary or error
    resource function get summary() returns json|http:InternalServerError {
        log:printInfo("Fetching financial summary");

        do {
            stream<record {decimal total_revenue; decimal total_expenses; decimal net_income; int transaction_count; decimal avg_transaction;}, error?> resultStream =
                dbClient->query(`
                    SELECT 
                        COALESCE(SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END), 0) as total_revenue,
                        COALESCE(SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END), 0) as total_expenses,
                        COALESCE(SUM(amount), 0) as net_income,
                        COUNT(*) as transaction_count,
                        COALESCE(AVG(amount), 0) as avg_transaction
                    FROM transactions
                `);

            record {|record {decimal total_revenue; decimal total_expenses; decimal net_income; int transaction_count; decimal avg_transaction;} value;|}|error? result = resultStream.next();

            if result is error? {
                return <http:InternalServerError>{
                    body: {
                        success: false,
                        message: "Failed to calculate summary",
                        timestamp: time:utcToString(time:utcNow())
                    }
                };
            }

            TransactionSummary summary = {
                totalRevenue: result.value.total_revenue,
                totalExpenses: result.value.total_expenses,
                netIncome: result.value.net_income,
                transactionCount: result.value.transaction_count,
                averageTransaction: result.value.avg_transaction
            };

            ApiResponse response = {
                success: true,
                message: "Financial summary retrieved successfully",
                data: summary,
                timestamp: time:utcToString(time:utcNow())
            };

            return response;
        } on fail error e {
            log:printError("Error fetching financial summary", 'error = e);
            return <http:InternalServerError>{
                body: {
                    success: false,
                    message: "Failed to fetch financial summary",
                    timestamp: time:utcToString(time:utcNow())
                }
            };
        }
    }

    # Health check endpoint
    # + return - Health status
    resource function get health() returns json {
        return {
            success: true,
            message: "Finance backend is healthy",
            timestamp: time:utcToString(time:utcNow()),
            version: "1.0.0"
        };
    }

    # Legacy endpoint for backward compatibility
    # + return - return value description
    resource function get data() returns json|error {
        stream<record {int id; string name; decimal amount; string created_at;}, error?> resultStream =
            dbClient->query(`SELECT id, name, amount, DATE_FORMAT(created_at, '%Y-%m-%d') AS created_at FROM transactions`);

        json[] results = [];

        check from record {int id; string name; decimal amount; string created_at;} row in resultStream
            do {
                results.push({
                    id: row.id,
                    name: row.name,
                    amount: row.amount,
                    created_at: row.created_at
                });
            };

        return results;
    }
}
