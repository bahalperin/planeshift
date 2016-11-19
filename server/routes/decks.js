var _ = require('underscore');
var routeUtils = require('./utils.js');
var objectID = require('mongodb').ObjectID;

module.exports = function(app, db) {
    app.get('/api/decks', routeUtils.ensureAuthenticated, function(req, res) {
        const username = req.session.passport.user;
        const decks = db.collection('decks');
        decks.find({
            createdUser: username
        }).toArray((err, docs) => {
            res.json(docs);
        });
    });

    app.post('/api/decks', routeUtils.ensureAuthenticated, function(req, res) {
        let deck = req.body.deck;
        const decks = db.collection('decks');
        const username = req.session.passport.user;

        if (!deck._id) {
            deck = _.extend({}, deck, {
                main: [],
                sideboard: [],
                createdUser: username
            });
            decks.insertOne(deck, (err, results) => {
                res.send(deck);
            });
        } else {
            decks.replaceOne({
                _id: objectID(deck._id)
            }, _.omit(deck, '_id'), (err, results) => {
                res.send(deck);
            });
        }
    });

    app.delete('/api/decks', routeUtils.ensureAuthenticated, function(req, res) {
        const args = req.body;
        const deckId = args.deckId;
        const decks = db.collection('decks');
        decks.remove({
            _id: objectID(deckId)
        }, (err, results) => {
            res.end();
        });
    });
};
