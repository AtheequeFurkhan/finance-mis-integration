import finance_mis_integration.database;
import finance_mis_integration.services;

import ballerina/http;
import ballerina/lang.runtime;
import ballerina/log;

public function main() returns error? {
    log:printInfo("Starting Finance MIS Integration Service");

    // Initialize database
    check database:initDatabase();

    // Start HTTP service
    http:Listener httpListener = check new (9090);

    // Attach and start the service
    check httpListener.attach(services:financeMisService);
    check httpListener.'start();

    log:printInfo("Finance MIS Integration Service started on port 9090");

    // Keep the service running
    // runtime:sleepSeconds(36000); // Sleep for 10 hours
}
