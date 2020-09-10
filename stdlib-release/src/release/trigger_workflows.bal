import ballerina/io;
import ballerina/log;

public function main() {
    string filePath = "./resources/stdlib_modules.json";

    var result = readFileAndGetJson(filePath);
    if (result is error) {
        log:printError("Error occurred whie reading the file", result);
    }
    json jsonFile = <json>result;
    json[] modules = <json[]>jsonFile.modules;
    foreach json module in modules {
        io:println(module);
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
