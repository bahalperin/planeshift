var appServer = require("./server/bundle");
var apiServer = require("./server");

var PORT = process.env.PORT || 3000;
var PROD = process.env.NODE_ENV === "production";

if (PROD) {
    apiServer(PORT);
} else {
    apiServer(PORT - 1);
    appServer(PORT);
}
