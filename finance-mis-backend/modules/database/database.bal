import finance_mis_integration.models;

import ballerina/io;
import ballerina/log;
import ballerina/os;
import ballerina/sql;
import ballerina/time;
import ballerinax/postgresql;

// Database configuration
final string dbHost = os:getEnv("DB_HOST") == "" ? "localhost" : os:getEnv("DB_HOST");
final int dbPort = check int:fromString(os:getEnv("DB_PORT") == "" ? "5432" : os:getEnv("DB_PORT"));
final string dbName = os:getEnv("DB_NAME") == "" ? "finance_db" : os:getEnv("DB_NAME");
final string dbUser = os:getEnv("DB_USER") == "" ? "postgres" : os:getEnv("DB_USER");
final string dbPassword = os:getEnv("DB_PASSWORD") == "" ? "postgres" : os:getEnv("DB_PASSWORD");

// Database client
final postgresql:Client dbClient = check new (
    host = dbHost,
    port = dbPort,
    username = dbUser,
    password = dbPassword,
    database = dbName
);

# Initialize the database with tables if they don't exist
public function initDatabase() returns error? {
    log:printInfo("Initializing finance database");

    string sqlScript = check io:fileReadString("resources/create_tables.sql");
    string[] statements = re `;\s*`.split(sqlScript);

    foreach string statement in statements {
        string trimmedStatement = statement.trim();
        if trimmedStatement.length() > 0 {
            // Use direct SQL execution instead of parameterized query
            _ = check dbClient->execute(`${trimmedStatement}`);
        }
    }

    log:printInfo("Database initialized successfully");
}

# Function to get revenue data by department
# + return - Revenue data by department or error
public function getRevenueDepartment() returns map<json>|error {
    log:printInfo("Fetching revenue by department data");

    sql:ParameterizedQuery query = `
        SELECT 
            d.department_id,
            d.name as department_name,
            d.cost_center,
            SUM(t.amount) as total_revenue
        FROM 
            departments d
        JOIN 
            transactions t ON d.department_id = t.department_id
        WHERE 
            t.transaction_type = 'REVENUE'
        GROUP BY 
            d.department_id, d.name, d.cost_center
        ORDER BY 
            total_revenue DESC
    `;

    stream<record {}, error?> resultStream = dbClient->query(query);

    map<json> results = {};
    results["departments"] = [];

    // Fix the check operator usage
    check from record {} result in resultStream
        do {
            json[] departmentsArray = <json[]>results["departments"];
            json jsonResult = result.toJson();
            departmentsArray.push(jsonResult);
            results["departments"] = departmentsArray;
        };

    return results;
}

# Function to get expense data by category
public function getExpenseCategory() returns map<json>|error {
    log:printInfo("Fetching expenses by category data");

    sql:ParameterizedQuery query = `
        SELECT 
            c.category_id,
            c.name as category_name,
            SUM(t.amount) as total_expenses
        FROM 
            expense_categories c
        JOIN 
            transactions t ON c.category_id = t.category_id
        WHERE 
            t.transaction_type = 'EXPENSE'
        GROUP BY 
            c.category_id, c.name
        ORDER BY 
            total_expenses DESC
    `;

    stream<record {}, error?> resultStream = dbClient->query(query);

    map<json> results = {};
    results["expense_categories"] = [];

    check from record {} result in resultStream
        do {
            json[] categoriesArray = <json[]>results["expense_categories"];
            categoriesArray.push(check result.toJson());
            results["expense_categories"] = categoriesArray;
        };

    return results;
}

# Function to get financial data by date
public function getFinancialsByDate() returns map<json>|error {
    log:printInfo("Fetching financial data by date");

    sql:ParameterizedQuery query = `
        SELECT 
            DATE(t.transaction_date) as date,
            SUM(CASE WHEN t.transaction_type = 'REVENUE' THEN t.amount ELSE 0 END) as total_revenue,
            SUM(CASE WHEN t.transaction_type = 'EXPENSE' THEN t.amount ELSE 0 END) as total_expenses,
            SUM(CASE WHEN t.transaction_type = 'REVENUE' THEN t.amount ELSE -t.amount END) as net_income
        FROM 
            transactions t
        GROUP BY 
            DATE(t.transaction_date)
        ORDER BY 
            date
    `;

    stream<record {}, error?> resultStream = dbClient->query(query);

    map<json> results = {};
    results["daily_financials"] = [];

    check from record {} result in resultStream
        do {
            json[] financialsArray = <json[]>results["daily_financials"];
            financialsArray.push(check result.toJson());
            results["daily_financials"] = financialsArray;
        };

    return results;
}

# Function to get all departments
public function getAllDepartments() returns models:Department[]|error {
    log:printInfo("Fetching all departments");

    sql:ParameterizedQuery query = `SELECT * FROM departments ORDER BY name`;
    stream<models:Department, error?> resultStream = dbClient->query(query);

    models:Department[] departments = [];
    check from models:Department dept in resultStream
        do {
            departments.push(dept);
        };

    return departments;
}

# Function to get department by ID
public function getDepartmentById(int departmentId) returns models:Department|error {
    log:printInfo(string `Fetching department with ID: ${departmentId}`);

    sql:ParameterizedQuery query = `SELECT * FROM departments WHERE department_id = ${departmentId}`;
    models:Department|error result = dbClient->queryRow(query);

    if result is error {
        log:printError(string `Department with ID ${departmentId} not found`, 'error = result);
        return error("Department not found");
    }

    return result;
}

# Function to create a new department
public function createDepartment(models:Department department) returns models:Department|error {
    log:printInfo(string `Creating new department: ${department.name}`);

    sql:ParameterizedQuery query = `
        INSERT INTO departments (name, cost_center, manager)
        VALUES (${department.name}, ${department.cost_center}, ${department.manager})
        RETURNING *
    `;

    models:Department|error result = dbClient->queryRow(query);

    if result is error {
        log:printError("Failed to create department", 'error = result);
        return error("Failed to create department");
    }

    return result;
}

# Function to update a department
public function updateDepartment(int departmentId, models:Department department) returns models:Department|error {
    log:printInfo(string `Updating department ID: ${departmentId}`);

    sql:ParameterizedQuery query = `
        UPDATE departments
        SET name = ${department.name}, 
            cost_center = ${department.cost_center}, 
            manager = ${department.manager}
        WHERE department_id = ${departmentId}
        RETURNING *
    `;

    models:Department|error result = dbClient->queryRow(query);

    if result is error {
        log:printError(string `Failed to update department ID: ${departmentId}`, 'error = result);
        return error("Department update failed");
    }

    return result;
}

# Function to delete a department
public function deleteDepartment(int departmentId) returns boolean|error {
    log:printInfo(string `Deleting department ID: ${departmentId}`);

    sql:ParameterizedQuery query = `DELETE FROM departments WHERE department_id = ${departmentId}`;
    sql:ExecutionResult result = check dbClient->execute(query);

    if result.affectedRowCount == 0 {
        log:printError(string `Department ID ${departmentId} not found for deletion`);
        return error("Department not found");
    }

    return true;
}

# Function to get all expense categories
public function getAllExpenseCategories() returns models:ExpenseCategory[]|error {
    log:printInfo("Fetching all expense categories");

    sql:ParameterizedQuery query = `SELECT * FROM expense_categories ORDER BY name`;
    stream<models:ExpenseCategory, error?> resultStream = dbClient->query(query);

    models:ExpenseCategory[] categories = [];
    check from models:ExpenseCategory category in resultStream
        do {
            categories.push(category);
        };

    return categories;
}

# Function to get expense category by ID
public function getExpenseCategoryById(int categoryId) returns models:ExpenseCategory|error {
    log:printInfo(string `Fetching expense category with ID: ${categoryId}`);

    sql:ParameterizedQuery query = `SELECT * FROM expense_categories WHERE category_id = ${categoryId}`;
    models:ExpenseCategory|error result = dbClient->queryRow(query);

    if result is error {
        log:printError(string `Expense category with ID ${categoryId} not found`, 'error = result);
        return error("Expense category not found");
    }

    return result;
}

# Function to create a new expense category
public function createExpenseCategory(models:ExpenseCategory category) returns models:ExpenseCategory|error {
    log:printInfo(string `Creating new expense category: ${category.name}`);

    sql:ParameterizedQuery query = `
        INSERT INTO expense_categories (name, description)
        VALUES (${category.name}, ${category.description})
        RETURNING *
    `;

    models:ExpenseCategory|error result = dbClient->queryRow(query);

    if result is error {
        log:printError("Failed to create expense category", 'error = result);
        return error("Failed to create expense category");
    }

    return result;
}

# Function to update an expense category
public function updateExpenseCategory(int categoryId, models:ExpenseCategory category) returns models:ExpenseCategory|error {
    log:printInfo(string `Updating expense category ID: ${categoryId}`);

    sql:ParameterizedQuery query = `
        UPDATE expense_categories
        SET name = ${category.name}, 
            description = ${category.description}
        WHERE category_id = ${categoryId}
        RETURNING *
    `;

    models:ExpenseCategory|error result = dbClient->queryRow(query);

    if result is error {
        log:printError(string `Failed to update expense category ID: ${categoryId}`, 'error = result);
        return error("Expense category update failed");
    }

    return result;
}

# Function to delete an expense category
public function deleteExpenseCategory(int categoryId) returns boolean|error {
    log:printInfo(string `Deleting expense category ID: ${categoryId}`);

    sql:ParameterizedQuery query = `DELETE FROM expense_categories WHERE category_id = ${categoryId}`;
    sql:ExecutionResult result = check dbClient->execute(query);

    if result.affectedRowCount == 0 {
        log:printError(string `Expense category ID ${categoryId} not found for deletion`);
        return error("Expense category not found");
    }

    return true;
}

# Function to get all transactions
public function getAllTransactions() returns models:Transaction[]|error {
    log:printInfo("Fetching all transactions");

    sql:ParameterizedQuery query = `
        SELECT * FROM transactions 
        ORDER BY transaction_date DESC
    `;

    stream<models:Transaction, error?> resultStream = dbClient->query(query);

    models:Transaction[] transactions = [];
    check from models:Transaction txn in resultStream
        do {
            transactions.push(txn);
        };

    return transactions;
}

# Function to get transaction by ID
public function getTransactionById(int transactionId) returns models:Transaction|error {
    log:printInfo(string `Fetching transaction with ID: ${transactionId}`);

    sql:ParameterizedQuery query = `SELECT * FROM transactions WHERE transaction_id = ${transactionId}`;
    models:Transaction|error result = dbClient->queryRow(query);

    if result is error {
        log:printError(string `Transaction with ID ${transactionId} not found`, 'error = result);
        return error("Transaction not found");
    }

    return result;
}

# Function to create a new transaction
public function createTransaction(models:Transaction txn) returns models:Transaction|error {
    log:printInfo(string `Creating new ${txn.transaction_type} transaction for amount ${txn.amount}`);

    // Set current timestamp if not provided
    string transactionDate = txn.transaction_date;
    if transactionDate == "" {
        time:Utc currentTime = time:utcNow();
        transactionDate = time:utcToString(currentTime);
    }

    sql:ParameterizedQuery query = `
        INSERT INTO transactions (
            transaction_type, department_id, category_id, 
            amount, transaction_date, description
        )
        VALUES (
            ${txn.transaction_type}, ${txn.department_id}, 
            ${txn.category_id}, ${txn.amount}, 
            ${transactionDate}, ${txn.description}
        )
        RETURNING *
    `;

    models:Transaction|error result = dbClient->queryRow(query);

    if result is error {
        log:printError("Failed to create transaction", 'error = result);
        return error("Failed to create transaction");
    }

    return result;
}

# Function to update a transaction
public function updateTransaction(int transactionId, models:Transaction txn) returns models:Transaction|error {
    log:printInfo(string `Updating transaction ID: ${transactionId}`);

    sql:ParameterizedQuery query = `
        UPDATE transactions
        SET transaction_type = ${txn.transaction_type},
            department_id = ${txn.department_id},
            category_id = ${txn.category_id},
            amount = ${txn.amount},
            transaction_date = ${txn.transaction_date},
            description = ${txn.description}
        WHERE transaction_id = ${transactionId}
        RETURNING *
    `;

    models:Transaction|error result = dbClient->queryRow(query);

    if result is error {
        log:printError(string `Failed to update transaction ID: ${transactionId}`, 'error = result);
        return error("Transaction update failed");
    }

    return result;
}

# Function to delete a transaction
public function deleteTransaction(int transactionId) returns boolean|error {
    log:printInfo(string `Deleting transaction ID: ${transactionId}`);

    sql:ParameterizedQuery query = `DELETE FROM transactions WHERE transaction_id = ${transactionId}`;
    sql:ExecutionResult result = check dbClient->execute(query);

    if result.affectedRowCount == 0 {
        log:printError(string `Transaction ID ${transactionId} not found for deletion`);
        return error("Transaction not found");
    }

    return true;
}

# Function to get dashboard summary data
public function getDashboardSummary() returns map<json>|error {
    log:printInfo("Fetching dashboard summary data");

    // Total revenue
    sql:ParameterizedQuery revenueQuery = `
        SELECT COALESCE(SUM(amount), 0) as total_revenue 
        FROM transactions 
        WHERE transaction_type = 'REVENUE'
    `;
    record {|decimal total_revenue;|}|error revenueResult = dbClient->queryRow(revenueQuery);

    // Total expenses
    sql:ParameterizedQuery expenseQuery = `
        SELECT COALESCE(SUM(amount), 0) as total_expenses 
        FROM transactions 
        WHERE transaction_type = 'EXPENSE'
    `;
    record {|decimal total_expenses;|}|error expenseResult = dbClient->queryRow(expenseQuery);

    // Department count
    sql:ParameterizedQuery deptQuery = `SELECT COUNT(*) as dept_count FROM departments`;
    record {|int dept_count;|}|error deptResult = dbClient->queryRow(deptQuery);

    // Transaction count
    sql:ParameterizedQuery txnQuery = `SELECT COUNT(*) as txn_count FROM transactions`;
    record {|int txn_count;|}|error txnResult = dbClient->queryRow(txnQuery);

    decimal totalRevenue = 0;
    if revenueResult is record {|decimal total_revenue;|} {
        totalRevenue = revenueResult.total_revenue;
    }

    decimal totalExpenses = 0;
    if expenseResult is record {|decimal total_expenses;|} {
        totalExpenses = expenseResult.total_expenses;
    }

    int departmentCount = 0;
    if deptResult is record {|int dept_count;|} {
        departmentCount = deptResult.dept_count;
    }

    int transactionCount = 0;
    if txnResult is record {|int txn_count;|} {
        transactionCount = txnResult.txn_count;
    }

    decimal netIncome = totalRevenue - totalExpenses;

    map<json> summary = {
        "total_revenue": totalRevenue,
        "total_expenses": totalExpenses,
        "net_income": netIncome,
        "department_count": departmentCount,
        "transaction_count": transactionCount,
        "last_updated": time:utcToString(time:utcNow())
    };

    return summary;
}
