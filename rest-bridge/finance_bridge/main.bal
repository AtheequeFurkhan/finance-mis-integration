import ballerina/http;

configurable string backendUrl = ?;
configurable string apiKey = ?;

service /bridge on new http:Listener(8090) {

    resource function get fetchData(http:Request req) returns json|http:Response|error {
        string? key = check req.getHeader("x-api-key");

        if key is () || key != apiKey {
            return {
                body: { message: "Unauthorized" },
                statusCode: 401
            };
        }

        http:Client backendClient = check new (backendUrl);
        http:Response res = check backendClient->get("/data");
        json payload = check res.getJsonPayload();

        return {
            body: payload,
            statusCode: 200
        };
    }
}
