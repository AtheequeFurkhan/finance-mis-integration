import finance_mis_integration.database;
import finance_mis_integration.models;

import ballerina/http;
import ballerina/log;

// Define service directly in main file for simplicity
service / on new http:Listener(9090) {
    // Department endpoints
    resource function get departments() returns json|error {
        return database:getAllDepartments();
    }

    resource function get departments/[int departmentId]() returns json|error {
        return database:getDepartmentById(departmentId);
    }

    resource function post departments(@http:Payload models:Department department) returns json|error {
        return database:createDepartment(department);
    }

    resource function put departments/[int departmentId](@http:Payload models:Department department) returns json|error {
        return database:updateDepartment(departmentId, department);
    }

    resource function delete departments/[int departmentId]() returns json|error {
        return database:deleteDepartment(departmentId);
    }

    // Category endpoints
    resource function get categories() returns json|error {
        return database:getAllExpenseCategories();
    }

    resource function get categories/[int categoryId]() returns json|error {
        return database:getExpenseCategoryById(categoryId);
    }

    // Transaction endpoints
    resource function get transactions() returns json|error {
        return database:getAllTransactions();
    }
    // Report endpoints
    resource function get revenue/department() returns json|error {
        return database:getRevenueDepartment();
    }

    resource function get expense/department() returns json|error {
        return database:getExpenseByDepartment();
    }

    resource function get expense/category() returns json|error {
        return database:getExpenseCategory();
    }
}

public function main() returns error? {
    log:printInfo("Starting Finance MIS Integration Service");

    // Initialize database
    check database:initDatabase();

    log:printInfo("Finance MIS Integration Service initialized on port 9090");
    // With this approach, the service will keep running - no need for waitForExit()
}
