var _ = require('underscore');
var LocalStrategy = require('passport-local').Strategy;
var bCrypt = require('bcrypt');


module.exports = function(passport, db) {

    passport.use('signup', new LocalStrategy({
            passReqToCallback: true // allows us to pass back the entire request to the callback
        },
        function(req, username, password, done) {

            findOrCreateUser = function() {
                // find a user in Mongo with provided username
                const users = db.collection('users');
                users.findOne({
                    'username': username
                }, function(err, user) {
                    // In case of any error, return using the done method
                    if (err) {
                        console.log('Error in SignUp: ' + err);
                        return done(err);
                    }
                    // already exists
                    if (user) {
                        console.log('User already exists with username: ' + username);
                        return done(null, false);
                    } else {
                        const newUser = {
                            username: username,
                            password: createHash(password)
                        };

                        // save the user
                        users.insertOne(newUser, function(err) {
                            if (err) {
                                console.log('Error in Saving user: ' + err);
                                throw err;
                            }
                            return done(null, newUser);
                        });
                    }
                });
            };
            // Delay the execution of findOrCreateUser and execute the method
            // in the next tick of the event loop
            process.nextTick(findOrCreateUser);
        }));

    // Generates hash using bCrypt
    var createHash = function(password) {
        return bCrypt.hashSync(password, bCrypt.genSaltSync(10), null);
    }

}
