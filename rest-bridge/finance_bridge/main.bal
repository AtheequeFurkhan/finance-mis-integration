import ballerina/http;

configurable string backendUrl = ?;
configurable string apiKey = ?;

service /bridge on new http:Listener(8090) {

    resource function get fetchData(http:Request req) returns json|http:Response|error {
        // Get API key from request header
        string? key = check req.getHeader("x-api-key");

        if key is () || key != apiKey {
            http:Response unauthorized = new;
            unauthorized.statusCode = 401;
            unauthorized.setJsonPayload({ message: "Unauthorized" });
            return unauthorized;
        }

        // Create backend client
        http:Client backendClient = check new (backendUrl);

        // Call backend endpoint
        http:Response backendRes = check backendClient->get("/data");

        // Forward backend response as-is
        json payload = check backendRes.getJsonPayload();

        http:Response resp = new;
        resp.statusCode = 200;
        resp.setJsonPayload(payload);
        return resp;
    }
}
