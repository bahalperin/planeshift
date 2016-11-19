var express = require('express');
var path = require('path');
var httpProxy = require('http-proxy');
var serveStatic = require('serve-static');
var bodyParser = require('body-parser');

var serverConfig = require('./server/config');
var mongoClient = require('mongodb').MongoClient;
var mongoUrl = serverConfig.mongoUrl;

var passport = require('passport');
var initPassport = require('./server/passport/init');
var expressSession = require('express-session');
var routes = require('./server/routes');

module.exports = function(port) {
    var proxy = httpProxy.createProxyServer();
    var app = express();

    var publicPath = path.resolve(__dirname, 'public');

    app.use(express.static(publicPath));
    app.use(serveStatic(__dirname + "/build"));

    app.use(bodyParser.json());
    app.use(bodyParser.urlencoded({
        extended: true
    }));
    app.use(expressSession({
        secret: serverConfig.expressSessionSecretKey,
        resave: false,
        saveUninitialized: true
    }));

    mongoClient.connect(mongoUrl, function(err, db) {
        if (err) {
            console.log(err);
            return;
        }

        initPassport(passport, db);

        app.use(passport.initialize());
        app.use(passport.session());

        routes(app, db);

        app.listen(port, function() {
            console.log('Server running on port ' + port);
        });

    });

};
