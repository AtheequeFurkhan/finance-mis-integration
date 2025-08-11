import ballerina/http;
import ballerina/log;
import ballerina/time;

// Configuration
configurable string backendUrl = ?;
configurable string apiKey = ?;
configurable int serverPort = 8090;
configurable int timeoutSeconds = 30;

// Data types
type ApiResponse record {|
    boolean success;
    string message;
    json data?;
    string timestamp;
|};

type ProxyRequest record {|
    string method;
    string path;
    json? body;
    map<string> headers?;
|};

// HTTP client with timeout and retry configuration
http:Client backendClient = check new (backendUrl, {
    timeout: <decimal>timeoutSeconds,
    retryConfig: {
        count: 3,
        interval: 2
    }
});

// CORS configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["x-api-key", "Authorization", "Content-Type"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service /bridge on new http:Listener(serverPort) {

    # Fetch all transactions with optional filtering
    # + req - HTTP request
    # + category - Filter by transaction category
    # + startDate - Filter transactions from this date
    # + endDate - Filter transactions until this date
    # + 'limit - Limit number of results
    # + offset - Offset for pagination
    # + return - Transactions data or error response
    resource function get transactions(http:Request req, string? category = (), string? startDate = (),
            string? endDate = (), int? 'limit = (), int? offset = ())
                                    returns json|http:Response|error {
        log:printInfo("Bridge: Fetching transactions with filters");

        // Validate API key
        string|http:Response authResult = check validateApiKey(req);
        if authResult is http:Response {
            return authResult;
        }

        do {
            // Build query parameters
            string queryParams = "";
            map<string> params = {};

            if category is string {
                params["category"] = category;
            }
            if startDate is string {
                params["startDate"] = startDate;
            }
            if endDate is string {
                params["endDate"] = endDate;
            }
            if 'limit is int {
                params["limit"] = 'limit.toString();
            }
            if offset is int {
                params["offset"] = offset.toString();
            }

            if params.length() > 0 {
                string[] paramPairs = [];
                foreach var [key, value] in params.entries() {
                    paramPairs.push(key + "=" + value);
                }
                queryParams = "?" + string:'join("&", ...paramPairs);
            }

            http:Response backendRes = check backendClient->get("/transactions" + queryParams);
            json payload = check backendRes.getJsonPayload();

            http:Response resp = new;
            resp.statusCode = backendRes.statusCode;
            resp.setJsonPayload(payload);
            return resp;
        } on fail error e {
            log:printError("Bridge: Error fetching transactions", 'error = e);
            return createErrorResponse(500, "Failed to fetch transactions from backend");
        }
    }

    # Get a specific transaction by ID
    # + req - HTTP request
    # + id - Transaction ID
    # + return - Transaction data or error response
    resource function get transactions/[int id](http:Request req) returns json|http:Response|error {
        log:printInfo("Bridge: Fetching transaction", id = id);

        // Validate API key
        string|http:Response authResult = check validateApiKey(req);
        if authResult is http:Response {
            return authResult;
        }

        do {
            http:Response backendRes = check backendClient->get("/transactions/" + id.toString());
            json payload = check backendRes.getJsonPayload();

            http:Response resp = new;
            resp.statusCode = backendRes.statusCode;
            resp.setJsonPayload(payload);
            return resp;
        } on fail error e {
            log:printError("Bridge: Error fetching transaction", 'error = e, id = id);
            return createErrorResponse(500, "Failed to fetch transaction from backend");
        }
    }

    # Create a new transaction
    # + req - HTTP request containing transaction data
    # + return - Created transaction or error response
    resource function post transactions(http:Request req) returns json|http:Response|error {
        log:printInfo("Bridge: Creating new transaction");

        // Validate API key
        string|http:Response authResult = check validateApiKey(req);
        if authResult is http:Response {
            return authResult;
        }

        do {
            json requestBody = check req.getJsonPayload();

            http:Request backendRequest = new;
            backendRequest.setJsonPayload(requestBody);

            http:Response backendRes = check backendClient->post("/transactions", backendRequest);
            json payload = check backendRes.getJsonPayload();

            http:Response resp = new;
            resp.statusCode = backendRes.statusCode;
            resp.setJsonPayload(payload);
            return resp;
        } on fail error e {
            log:printError("Bridge: Error creating transaction", 'error = e);
            return createErrorResponse(500, "Failed to create transaction in backend");
        }
    }

    # Update an existing transaction
    # + req - HTTP request containing updated transaction data
    # + id - Transaction ID to update
    # + return - Updated transaction or error response
    resource function put transactions/[int id](http:Request req) returns json|http:Response|error {
        log:printInfo("Bridge: Updating transaction", id = id);

        // Validate API key
        string|http:Response authResult = check validateApiKey(req);
        if authResult is http:Response {
            return authResult;
        }

        do {
            json requestBody = check req.getJsonPayload();

            http:Request backendRequest = new;
            backendRequest.setJsonPayload(requestBody);

            http:Response backendRes = check backendClient->put("/transactions/" + id.toString(), backendRequest);
            json payload = check backendRes.getJsonPayload();

            http:Response resp = new;
            resp.statusCode = backendRes.statusCode;
            resp.setJsonPayload(payload);
            return resp;
        } on fail error e {
            log:printError("Bridge: Error updating transaction", 'error = e, id = id);
            return createErrorResponse(500, "Failed to update transaction in backend");
        }
    }

    # Delete a transaction
    # + req - HTTP request
    # + id - Transaction ID to delete
    # + return - Success message or error response
    resource function delete transactions/[int id](http:Request req) returns json|http:Response|error {
        log:printInfo("Bridge: Deleting transaction", id = id);

        // Validate API key
        string|http:Response authResult = check validateApiKey(req);
        if authResult is http:Response {
            return authResult;
        }

        do {
            http:Response backendRes = check backendClient->delete("/transactions/" + id.toString());
            json payload = check backendRes.getJsonPayload();

            http:Response resp = new;
            resp.statusCode = backendRes.statusCode;
            resp.setJsonPayload(payload);
            return resp;
        } on fail error e {
            log:printError("Bridge: Error deleting transaction", 'error = e, id = id);
            return createErrorResponse(500, "Failed to delete transaction from backend");
        }
    }

    # Get financial summary
    # + req - HTTP request
    # + return - Financial summary or error response
    resource function get summary(http:Request req) returns json|http:Response|error {
        log:printInfo("Bridge: Fetching financial summary");

        // Validate API key
        string|http:Response authResult = check validateApiKey(req);
        if authResult is http:Response {
            return authResult;
        }

        do {
            http:Response backendRes = check backendClient->get("/summary");
            json payload = check backendRes.getJsonPayload();

            http:Response resp = new;
            resp.statusCode = backendRes.statusCode;
            resp.setJsonPayload(payload);
            return resp;
        } on fail error e {
            log:printError("Bridge: Error fetching summary", 'error = e);
            return createErrorResponse(500, "Failed to fetch summary from backend");
        }
    }

    # Legacy endpoint for backward compatibility
    # + req - HTTP request
    # + return - Transaction data or error response
    resource function get fetchData(http:Request req) returns json|http:Response|error {
        log:printInfo("Bridge: Legacy fetchData endpoint called");

        // Validate API key
        string|http:Response authResult = check validateApiKey(req);
        if authResult is http:Response {
            return authResult;
        }

        do {
            http:Response backendRes = check backendClient->get("/data");
            json payload = check backendRes.getJsonPayload();

            http:Response resp = new;
            resp.statusCode = 200;
            resp.setJsonPayload(payload);
            return resp;
        } on fail error e {
            log:printError("Bridge: Error in legacy fetchData", 'error = e);
            return createErrorResponse(500, "Failed to fetch data from backend");
        }
    }

    # Health check endpoint
    # + return - Health status
    resource function get health() returns json {
        return {
            success: true,
            message: "Finance bridge is healthy",
            timestamp: time:utcToString(time:utcNow()),
            version: "1.0.0",
            backend: backendUrl
        };
    }

    # API documentation endpoint
    # + return - API documentation
    resource function get docs() returns json {
        return {
            title: "Finance Bridge API",
            version: "1.0.0",
            description: "REST API bridge for finance backend services",
            endpoints: {
                "GET /bridge/health": "Health check",
                "GET /bridge/transactions": "Get all transactions (supports filtering)",
                "GET /bridge/transactions/{id}": "Get specific transaction",
                "POST /bridge/transactions": "Create new transaction",
                "PUT /bridge/transactions/{id}": "Update transaction",
                "DELETE /bridge/transactions/{id}": "Delete transaction",
                "GET /bridge/summary": "Get financial summary",
                "GET /bridge/fetchData": "Legacy endpoint for backward compatibility"
            },
            authentication: "API key required in x-api-key header",
            queryParameters: {
                transactions: {
                    category: "Filter by transaction category",
                    startDate: "Filter from date (YYYY-MM-DD)",
                    endDate: "Filter until date (YYYY-MM-DD)",
                    limitParam: "Limit number of results",
                    offset: "Offset for pagination"
                }
            }
        };
    }
}

# Validate API key from request header
# + req - HTTP request
# + return - Success string or error response
function validateApiKey(http:Request req) returns string|http:Response|error {
    string? key = check req.getHeader("x-api-key");

    if key is () || key != apiKey {
        log:printWarn("Bridge: Unauthorized access attempt");
        return createErrorResponse(401, "Unauthorized: Invalid or missing API key");
    }

    return "valid";
}

# Create standardized error response
# + statusCode - HTTP status code
# + message - Error message
# + return - HTTP error response
function createErrorResponse(int statusCode, string message) returns http:Response {
    http:Response errorResp = new;
    errorResp.statusCode = statusCode;

    ApiResponse errorData = {
        success: false,
        message: message,
        timestamp: time:utcToString(time:utcNow())
    };

    errorResp.setJsonPayload(errorData);
    return errorResp;
}
