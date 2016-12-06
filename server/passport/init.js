var login = require('./login');
var signup = require('./signup');
var objectID = require('mongodb').ObjectID;

module.exports = function(passport, db) {

    // Passport needs to be able to serialize and deserialize users to support persistent login sessions
    passport.serializeUser(function(user, done) {
        done(null, user._id);
    });

    passport.deserializeUser(function(id, done) {
        const users = db.collection('users');
        users.findOne({
            _id: objectID(id)
        }, function(err, user) {
            done(err, user);
        });
    });

    login(passport, db);
    signup(passport, db);

}
