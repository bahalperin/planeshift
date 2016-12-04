port module Ports exposing (..)

import Game


port broadcastGameJoined : { username : String, gameId : Game.Id } -> Cmd message


port handleGameJoined : ({ username : String, gameId : Game.Id } -> message) -> Sub message
