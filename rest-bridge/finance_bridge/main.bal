import ballerina/http;

configurable string backendUrl = ?;
configurable string apiKey = ?;

service /bridge on new http:Listener(8090) {

    resource function get fetchData(http:Caller caller, http:Request req) returns error? {
        string? key = req.getHeader("x-api-key");

        if key is () || key != apiKey {
            check caller->respond({ message: "Unauthorized" }, 401);
            return;
        }

        http:Client backendClient = check new (backendUrl);
        http:Response res = check backendClient->get("/data");
        json payload = check res.getJsonPayload();

        check caller->respond(payload);
    }
}
