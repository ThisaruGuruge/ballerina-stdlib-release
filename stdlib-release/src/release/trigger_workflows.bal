import ballerina/config;
import ballerina/io;
import ballerina/http;
import ballerina/log;

public function main() {
    http:Client httpClient = new(API_PATH);

    var result = readFileAndGetJson(CONFIG_FILE_PATH);
    if (result is error) {
        log:printError("Error occurred whie reading the file", result);
    }
    json jsonFile = <json>result;
    json[] modules = <json[]>jsonFile.modules;
    foreach json module in modules {
        releaseModule(module, httpClient);
    }
}

function releaseModule(json module, http:Client httpClient) {
    string moduleName = module.name.toString();
    string orgName = module.org.toString();

    string accessToken = config:getAsString(ACCESS_TOKEN_ENV);
    string accessTokenHeaderValue = "Bearer " + accessToken;

    http:Request request = new;
    request.addHeader(ACCEPT_HEADER_KEY, ACCEPT_HEADER_VALUE);
    request.addHeader(AUTH_HEADER_KEY, accessTokenHeaderValue);

    json payload = {
        event_type: "Ballerina Release Pipeline",
        client_payload: {
            sample: "example-value"
        }
    };

    request.setJsonPayload(payload);
    string modulePath = "/" + ORG_NAME + "/" + moduleName + "/dispatches";
    log:printInfo(API_PATH + modulePath);
    printRequestHeaders(request);
    var result = httpClient->post(modulePath, request);
    if (result is error) {
        log:printError("Error occurred while retrieving the reponse", result);
    }
    http:Response response = <http:Response>result;
    log:printInfo(response.getJsonPayload().toString());
}

function printRequestHeaders(http:Request request) {
    string[] headers = request.getHeaderNames();
    foreach string header in headers {
        log:printInfo(header + ": " + request.getHeader(<@untainted>header));
    }
    var payload = request.getJsonPayload();
    if (payload is error) {
        log:printError("Payload Error", payload);
    } else {
        log:printInfo(payload.toJsonString());
    }
}

function readFileAndGetJson(string path) returns json|error {
    io:ReadableByteChannel rbc = check <@untainted>io:openReadableFile(path);
    io:ReadableCharacterChannel rch = new (rbc, "UTF8");
    var result = <@untainted>rch.readJson();
    closeReadChannel(rch);
    return result;
}

function closeReadChannel(io:ReadableCharacterChannel rc) {
    var result = rc.close();
    if (result is error) {
        log:printError("Error occurred while closing character stream", result);
    }
}
