var _ = require('underscore');
var routeUtils = require('./utils.js');
var objectID = require('mongodb').ObjectID;

module.exports = function(app, db) {
    const games = db.collection('games');
    app.get('/api/games', routeUtils.ensureAuthenticated, (req, res) => {
        games.find().toArray((err, docs) => {
            res.json(docs);
        });
    });
};
