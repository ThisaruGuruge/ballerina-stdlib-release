import ballerina/config;
import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/runtime;

public function main() {
    http:Client httpClient = new (API_PATH);
    string accessToken = config:getAsString(ACCESS_TOKEN_ENV);
    string accessTokenHeaderValue = "Bearer " + accessToken;
    http:Request request = createRequest(accessTokenHeaderValue);

    var result = readFileAndGetJson(CONFIG_FILE_PATH);
    if (result is error) {
        log:printError("Error occurred whie reading the file", result);
    }
    json jsonFile = <json>result;
    json[] modules = <json[]>jsonFile.modules;
    int level = -1;
    foreach json module in modules {
        int nextLevel = <int>module.level;
        log:printInfo(module.name.toString());
        if (nextLevel > level && nextLevel != 0) {
            runtime:sleep(WAIT_TIME_TO_BUILD);
            level = nextLevel;
        }
        processModule(<map<json>>module, httpClient, request);
    }
}

function processModule(map<json> module, http:Client httpClient, http:Request request) {
    boolean ballerinaRelease = <boolean>module[BALLERINA_RELEASE];
    boolean githubRelease = <boolean>module[GITHUB_RELEASE];
    if (githubRelease) {
        releaseToGithub(module, httpClient, request);
    } else if (ballerinaRelease) {
        releaseToBallerina(module, httpClient, request);
    }
}

function releaseToGithub(map<json> module, http:Client httpClient, http:Request request) {
    string moduleName = module.name.toString();
    string 'version = module.'version.toString();
    string branch = module.branch.toString();
    string notes = module.notes.toString();

    log:printInfo("Releasing " + moduleName + " to the Github. Version: " + 'version);

    // TODO: Adding draft and prerelease options. These aren't necessary for now.
    json payload = {
        tag_name: "v" + 'version,
        target_commitish: branch,
        name: 'version,
        notes: notes
    };
    request.setJsonPayload(payload);

    string modulePath = "/" + ORG_NAME + "/" + moduleName + "/releases";
    var result = httpClient->post(modulePath, request);

    if (result is error) {
        log:printError("Error occurred while retrieving the reponse for module: " + moduleName, result);
        panic result;
    }
    http:Response response = <http:Response>result;
    validateResponse(response, moduleName);
}

function releaseToBallerina(map<json> module, http:Client httpClient, http:Request request) {
    string moduleName = module.name.toString();
    string 'version = module.'version.toString();
    log:printInfo("Releasing " + moduleName + " to the Ballerina Central Version: " + 'version);

    // TODO: Add branch as a payload parameter, then checkout the needed branch at the destination.
    json payload = {
        event_type: EVENT_TYPE,
        client_payload: {
            'version: 'version
        }
    };
    request.setJsonPayload(payload);

    string modulePath = "/" + ORG_NAME + "/" + moduleName + "/dispatches";
    var result = httpClient->post(modulePath, request);

    if (result is error) {
        log:printError("Error occurred while retrieving the reponse for module: " + moduleName, result);
        panic result;
    }
    http:Response response = <http:Response>result;
    validateResponse(response, moduleName);
}

function validateResponse(http:Response response, string moduleName) {
    int statusCode = response.statusCode;
    if (statusCode != 200 || statusCode != 201 || statusCode != 202 || statusCode != 204) {
        string errMessage = "Error response received from the module workflow.";
        string errInfo = "Modlue: " + moduleName + " Status Code: " + statusCode.toString();
        log:printInfo(errInfo);
        log:printInfo(response.getJsonPayload().toString());
    }
}

function createRequest(string accessTokenHeaderValue) returns http:Request {
    http:Request request = new;
    request.addHeader(ACCEPT_HEADER_KEY, ACCEPT_HEADER_VALUE);
    request.addHeader(AUTH_HEADER_KEY, accessTokenHeaderValue);
    return request;
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
