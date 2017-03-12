#require "Button.class.nut:1.2.0"

enum DOOR_STATUS {
    CLOSED,
    OPEN
}

enum DOOR_ID {
    FIRST,
    SECOND
}

function makeSwitchHandler(id, status) {
    return function() {
        return handleStatusChange(id, status);
    }
}

function handleStatusChange(id, status) {
    local data = blob();
    data.writen(id, 'b');
    data.writen(status, 'b');
    agent.send("doorChange", data);
}

// Alias the GPIO pin as 'button'
button1 <- Button(hardware.pin1, DIGITAL_IN_PULLUP, Button.NORMALLY_HIGH)
    .onPress(makeSwitchHandler(DOOR_ID.FIRST, DOOR_STATUS.CLOSED))
    .onRelease(makeSwitchHandler(DOOR_ID.FIRST, DOOR_STATUS.OPEN));

handleStatusChange(DOOR_ID.FIRST, hardware.pin1.read());

// Configure the button to call buttonPress() when the pin's state changes
server.log("Device started (firmware version: " + imp.getsoftwareversion() + ")");
server.setsendtimeoutpolicy(RETURN_ON_ERROR, WAIT_TIL_SENT, 10);

// Define the disconnection handler function
function disconnectionHandler(reason) {
    if (reason != SERVER_CONNECTED) {
        // Attempt to reconnect in 10 minutes' time
        imp.wakeup(600, reconnect);
    } else {
        server.log("Device reconncted");
    }
}

// Define the reconnection function
function reconnect() {
    // Attempt to reconnect
    // server.connect calls disconnectHandler() on success or failure
    // with an appropriate reason parameter
    server.connect(disconnectionHandler, 60);
}

// Register the unexpected disconnect handler
server.onunexpecteddisconnect(disconnectionHandler);
