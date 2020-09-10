import ballerina/io;
import ballerina/http;
import ballerina/log;
import ballerina/config;

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
    string accessTokenHeaderValue = "Bearer " + ACCESS_TOKEN_ENV;

    http:Request request = new;
    request.addHeader(ACCEPT_HEADER_KEY, ACCEPT_HEADER_VALUE);
    request.addHeader(AUTH_HEADER_KEY, accessTokenHeaderValue);

    json payload = {
        event_type: "my_event_type",
        client_payload: {
            sample: "example-value"
        }
    };

    request.setPayload(payload);
    string modulePath =  orgName + "/" + moduleName + "/dispatches";
    log:printInfo(modulePath);
    log:printInfo(accessTokenHeaderValue);
    var result = httpClient->post(modulePath, request);
    if (result is error) {
        log:printError("Error occurred while retrieving the reponse", result);
    }
    http:Response response = <http:Response>result;
    log:printInfo(response.getJsonPayload().toString());
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
