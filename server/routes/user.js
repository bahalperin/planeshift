var bcrypt = require('bcrypt');
var passport = require('passport');
var routeUtils = require('./utils');

module.exports = function(app, db) {
    app.get('/api/current-user', routeUtils.ensureAuthenticated, function(req, res) {
        const username = req.session.passport.user;
        res.json({
            username: username
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

                res.send({
                    username: username
                })
            });
        });
    });

    app.post('/api/login', passport.authenticate('login'), (req, res) => {
        res.json({
            username: req.user.username
        });
    });
};
