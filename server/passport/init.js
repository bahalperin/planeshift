var login = require('./login');
var signup = require('./signup');

module.exports = function(passport, db) {

    // Passport needs to be able to serialize and deserialize users to support persistent login sessions
    passport.serializeUser(function(user, done) {
        done(null, user.username);
    });

    passport.deserializeUser(function(username, done) {
        const users = db.collection('users');
        users.findOne({
            'username': username
        }, function(err, user) {
            done(err, user);
        });
    });

    login(passport, db);
    signup(passport, db);

}
