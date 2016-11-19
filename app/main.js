'use strict';

import 'ace-css/css/ace.css';
import 'font-awesome/css/font-awesome.css';

import '../public/index.html';

import Elm from '../src/Main.elm';
const mountNode = document.getElementById('main');

const app = Elm.Main.embed(mountNode);
