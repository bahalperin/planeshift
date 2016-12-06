var bcrypt = require('bcrypt');
var passport = require('passport');
var routeUtils = require('./utils');
var objectID = require('mongodb').ObjectID;

module.exports = function(app, db) {
    app.get('/api/current-user', routeUtils.ensureAuthenticated, function(req, res) {
        const userId = req.session.passport.user;

        const users = db.collection('users');
        users.findOne({
            _id: objectID(userId)
        }, function(err, user) {
            res.json(user);
        });
    });
    app.post('/api/signup', passport.authenticate('signup'), function(req, res) {
        const username = req.body.username;
        const password = req.body.password;
        const saltRounds = 10;
        bcrypt.hash(password, saltRounds, function(err, hash) {
            const users = db.collection('users');
            users.insertOne({
                username: username,
                password: hash
            }, (err, results) => {
                users.findOne({
                    username: username
                }, function(err, user) {
                    res.json(user);
                });
            });
        });
    });

    app.post('/api/login', passport.authenticate('login'), (req, res) => {
        const users = db.collection('users');
        users.findOne({
            username: req.user.username
        }, function(err, user) {
            res.json(user);
        });
    });
};
