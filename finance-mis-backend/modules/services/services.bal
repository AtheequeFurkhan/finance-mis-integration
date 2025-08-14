import ballerina/http;
import ballerina/log;
import ballerina/time;
import finance_mis_integration.database;
import finance_mis_integration.models;

# Finance MIS HTTP service
# Provides REST API endpoints for the Finance MIS system
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowHeaders: ["*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE"]
    }
}
service /financeMisService on new http:Listener(8080) {
    
    # Get dashboard summary data endpoint
    # + return - Dashboard summary data or error
    resource function get dashboard/summary() returns json|error {
        log:printInfo("GET request received for dashboard summary");
        return database:getDashboardSummary();
    }

    # Get revenue by department endpoint
    # + return - Revenue data by department or error
    resource function get revenue/department() returns json|error {
        log:printInfo("GET request received for revenue by department");
        return database:getRevenueDepartment();
    }
    
    # Get expenses by category endpoint
    # + return - Expense data by category or error
    resource function get expense/category() returns json|error {
        log:printInfo("GET request received for expenses by category");
        return database:getExpenseCategory();
    }
    
    # Get financial data by date endpoint
    # + return - Financial data by date or error
    resource function get financials/date() returns json|error {
        log:printInfo("GET request received for financials by date");
        return database:getFinancialsByDate();
    }

    # Get all departments endpoint
    # + return - Array of departments or error
    resource function get departments() returns models:Department[]|error {
        log:printInfo("GET request received for all departments");
        return database:getAllDepartments();
    }

    # Get department by ID endpoint
    # + id - Department ID
    # + return - Department details or error
    resource function get departments/[int id]() returns models:Department|error {
        log:printInfo(string `GET request received for department ID: ${id}`);
        models:Department|error result = database:getDepartmentById(id);
        
        if result is error {
            log:printError(string `Department with ID ${id} not found`);
            return error(string `Department with ID ${id} not found`);
        }
        
        return result;
    }

    # Create new department endpoint
    # + request - Department creation request
    # + return - Created department or error
    resource function post departments(@http:Payload models:Department request) returns models:Department|error {
        log:printInfo(string `POST request received to create department: ${request.name}`);
        return database:createDepartment(request);
    }

    # Update department endpoint
    # + id - Department ID to update
    # + request - Updated department data
    # + return - Updated department or error
    resource function put departments/[int id](@http:Payload models:Department request) returns models:Department|error {
        log:printInfo(string `PUT request received to update department ID: ${id}`);
        return database:updateDepartment(id, request);
    }

    # Delete department endpoint
    # + id - Department ID to delete
    # + return - Success message or error
    resource function delete departments/[int id]() returns json|error {
        log:printInfo(string `DELETE request received for department ID: ${id}`);
        boolean|error result = database:deleteDepartment(id);
        
        if result is error {
            log:printError(string `Failed to delete department ID: ${id}`, 'error = result);
            return error(string `Failed to delete department ID: ${id}`);
        }
        
        return { success: true, message: string `Department ID ${id} deleted successfully` };
    }

    # Get all expense categories endpoint
    # + return - Array of expense categories or error
    resource function get expense/categories() returns models:ExpenseCategory[]|error {
        log:printInfo("GET request received for all expense categories");
        return database:getAllExpenseCategories();
    }

    # Get expense category by ID endpoint
    # + id - Category ID
    # + return - Expense category details or error
    resource function get expense/categories/[int id]() returns models:ExpenseCategory|error {
        log:printInfo(string `GET request received for expense category ID: ${id}`);
        models:ExpenseCategory|error result = database:getExpenseCategoryById(id);
        
        if result is error {
            log:printError(string `Expense category with ID ${id} not found`);
            return error(string `Expense category with ID ${id} not found`);
        }
        
        return result;
    }

    # Create new expense category endpoint
    # + request - Expense category creation request
    # + return - Created expense category or error
    resource function post expense/categories(@http:Payload models:ExpenseCategory request) returns models:ExpenseCategory|error {
        log:printInfo(string `POST request received to create expense category: ${request.name}`);
        return database:createExpenseCategory(request);
    }

    # Update expense category endpoint
    # + id - Expense category ID to update
    # + request - Updated expense category data
    # + return - Updated expense category or error
    resource function put expense/categories/[int id](@http:Payload models:ExpenseCategory request) returns models:ExpenseCategory|error {
        log:printInfo(string `PUT request received to update expense category ID: ${id}`);
        return database:updateExpenseCategory(id, request);
    }

    # Delete expense category endpoint
    # + id - Expense category ID to delete
    # + return - Success message or error
    resource function delete expense/categories/[int id]() returns json|error {
        log:printInfo(string `DELETE request received for expense category ID: ${id}`);
        boolean|error result = database:deleteExpenseCategory(id);
        
        if result is error {
            log:printError(string `Failed to delete expense category ID: ${id}`, 'error = result);
            return error(string `Failed to delete expense category ID: ${id}`);
        }
        
        return { success: true, message: string `Expense category ID ${id} deleted successfully` };
    }

    # Get all transactions endpoint
    # + return - Array of transactions or error
    resource function get transactions() returns models:Transaction[]|error {
        log:printInfo("GET request received for all transactions");
        return database:getAllTransactions();
    }

    # Get transaction by ID endpoint
    # + id - Transaction ID
    # + return - Transaction details or error
    resource function get transactions/[int id]() returns models:Transaction|error {
        log:printInfo(string `GET request received for transaction ID: ${id}`);
        models:Transaction|error result = database:getTransactionById(id);
        
        if result is error {
            log:printError(string `Transaction with ID ${id} not found`);
            return error(string `Transaction with ID ${id} not found`);
        }
        
        return result;
    }

    # Create new transaction endpoint
    # + request - Transaction creation request
    # + return - Created transaction or error
    resource function post transactions(@http:Payload models:Transaction request) returns models:Transaction|error {
        log:printInfo(string `POST request received to create ${request.transaction_type} transaction: ${request.amount}`);
        return database:createTransaction(request);
    }

    # Update transaction endpoint
    # + id - Transaction ID to update
    # + request - Updated transaction data
    # + return - Updated transaction or error
    resource function put transactions/[int id](@http:Payload models:Transaction request) returns models:Transaction|error {
        log:printInfo(string `PUT request received to update transaction ID: ${id}`);
        return database:updateTransaction(id, request);
    }

    # Delete transaction endpoint
    # + id - Transaction ID to delete
    # + return - Success message or error
    resource function delete transactions/[int id]() returns json|error {
        log:printInfo(string `DELETE request received for transaction ID: ${id}`);
        boolean|error result = database:deleteTransaction(id);
        
        if result is error {
            log:printError(string `Failed to delete transaction ID: ${id}`, 'error = result);
            return error(string `Failed to delete transaction ID: ${id}`);
        }
        
        return { success: true, message: string `Transaction ID ${id} deleted successfully` };
    }

    # Health check endpoint
    # + return - Service health status
    resource function get health() returns json {
        log:printInfo("Health check request received");
        
        // Get current UTC time
        string timestamp = time:utcToString(time:utcNow());
        
        return {
            "status": "UP",
            "timestamp": timestamp,
            "service": "Finance MIS Integration",
            "author": "AtheequeFurkhan",
            "version": "0.1.0"
        };
    }
};