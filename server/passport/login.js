var _ = require('underscore');
var LocalStrategy = require('passport-local').Strategy;
var bCrypt = require('bcrypt');

module.exports = function(passport, db) {

    passport.use('login', new LocalStrategy({
            passReqToCallback: true
        },
        function(req, username, password, done) {
            // check in mongo if a user with username exists or not
            const users = db.collection('users');
            users.findOne({
                    'username': username
                },
                function(err, user) {
                    // In case of any error, return using the done method
                    if (err)
                        return done(err);
                    // Username does not exist, log the error and redirect back
                    if (!user) {
                        console.log('User Not Found with username ' + username);
                        return done(null, false);
                    }
                    // User exists but wrong password, log the error
                    if (!isValidPassword(user, password)) {
                        console.log('Invalid Password');
                        return done(null, false); // redirect back to login page
                    }
                    // User and password both match, return user from done method
                    // which will be treated like success
                    //                    req.session.user = _.omit(user, 'password');
                    return done(null, user);
                }
            );

        }));


    var isValidPassword = function(user, password) {
        return bCrypt.compareSync(password, user.password);
    }

}
