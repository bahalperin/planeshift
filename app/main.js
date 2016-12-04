'use strict';

import 'ace-css/css/ace.css';
import 'font-awesome/css/font-awesome.css';

import '../public/index.html';
import io from 'socket.io-client';


import Elm from '../src/Main.elm';
const mountNode = document.getElementById('main');

const app = Elm.Main.embed(mountNode);

const socketUrl = 'http://localhost:4000';
const games = io.connect(`${socketUrl}/games`);

games.on('added', function(data) {
    app.ports.handleGameAdded.send("Message");
});

games.on('joined', function(data) {
    app.ports.handleGameJoined.send(data);
});

app.ports.broadcastGameJoined.subscribe((data) => {
    games.emit("joined", data);
});

console.log(app);
