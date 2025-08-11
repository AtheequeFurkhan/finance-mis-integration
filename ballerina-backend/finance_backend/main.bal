import ballerina/config;
import ballerina/http;
import ballerina/sql;
import ballerinax/mysql;

mysql:Client dbClient = check new ({
    host: config:getAsString("database.host"),
    port: config:getAsInt("database.port"),
    user: config:getAsString("database.user"),
    password: config:getAsString("database.password"),
    database: config:getAsString("database.database")
});

service /finance on new http:Listener(8080) {

    resource function get data() returns json|error {
        stream<record {int id; string name; decimal amount; string created_at;}, error?> resultStream =
            dbClient->query(`SELECT id, name, amount, DATE_FORMAT(created_at, '%Y-%m-%d') AS created_at FROM transactions`);

        json results = [];
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
