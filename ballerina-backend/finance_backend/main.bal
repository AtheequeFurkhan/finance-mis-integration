import ballerina/http;
import ballerinax/mysql;

configurable string dbHost = ?;
configurable int dbPort = ?;
configurable string dbUser = ?;
configurable string dbPassword = ?;
configurable string dbDatabase = ?;

mysql:Client dbClient = check new (host = dbHost,
    port = dbPort,
    user = dbUser,
    password = dbPassword,
    database = dbDatabase
);

service /finance on new http:Listener(8080) {
    # Description.
    # + return - return value description
    resource function get data() returns json|error {
        stream<record {int id; string name; decimal amount; string created_at;}, error?> resultStream =
            dbClient->query(`SELECT id, name, amount, DATE_FORMAT(created_at, '%Y-%m-%d') AS created_at FROM transactions`);

        json[] results = []; // mutable array of json

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
