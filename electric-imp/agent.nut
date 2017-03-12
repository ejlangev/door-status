server.log("Agent started (version: " + imp.getsoftwareversion() + ")");
local awsUrl = "<YOUR API GATEWAY URL>";
local awsHeaders = { "Content-Type": "application/json" };

function handleHttpResponse(responseTable) {
        // Called when the imp receives a response from the remote service
    if (responseTable.statuscode == 200) {
        server.log("Successfully updated status")
    } else {
        // Log an error
        server.log("Error response: " + responseTable.statuscode);
    }
}

device.on("doorChange", function(data) {
    local id = data.readn('b');
    local status = data.readn('b');
    server.log("Id: " + id + " Status: " + status);
    local data = http.jsonencode({
        "doorId": id,
        "doorStatus": status
    });
    local request = http.post(awsUrl, awsHeaders, data);
    request.sendasync(handleHttpResponse);
});
