import finance_mis_integration.database;
import ballerina/log;

public function main() returns error? {
    log:printInfo("Starting Finance MIS Integration Service");

    // Initialize database
    check database:initDatabase();

    // Service defined with its own listener in services module
    log:printInfo("Finance MIS Integration Service initialized");
}
