port module Ports exposing (..)

import Games exposing (GameId)


port broadcastGameJoined : { username : String, gameId : GameId } -> Cmd message


port handleGameJoined : ({ username : String, gameId : GameId } -> message) -> Sub message
