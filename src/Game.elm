module Game
    exposing
        ( Game
        , Id
        , getId
        , getName
        , getPlayers
        , getMaxPlayers
        , addPlayer
        , fetchGames
        )

import Json.Decode
import Json.Encode
import Http


-- MODEL


type Game
    = Game GameData


type alias GameData =
    { id : Id
    , name : String
    , maxPlayers : Int
    , players : List Player
    }


type alias Player =
    { username : String
    }


type alias Id =
    String


getId : Game -> Id
getId (Game gameData) =
    gameData.id


getName : Game -> String
getName (Game gameData) =
    gameData.name


getPlayers : Game -> List Player
getPlayers (Game gameData) =
    gameData.players


getMaxPlayers : Game -> Int
getMaxPlayers (Game gameData) =
    gameData.maxPlayers


addPlayer : String -> Game -> Game
addPlayer playerName (Game gameData) =
    if List.length gameData.players < gameData.maxPlayers then
        Game
            { gameData | players = { username = playerName } :: gameData.players }
    else
        Game gameData



-- ENCODE/DECODE


encoder : Game -> Json.Encode.Value
encoder (Game gameData) =
    Json.Encode.object
        [ ( "_id", Json.Encode.string gameData.id )
        , ( "name", Json.Encode.string gameData.name )
        , ( "players", Json.Encode.list <| List.map playerEncoder gameData.players )
        ]


listDecoder : Json.Decode.Decoder (List Game)
listDecoder =
    Json.Decode.list decoder


decoder : Json.Decode.Decoder Game
decoder =
    Json.Decode.map4
        GameData
        (Json.Decode.field "_id" Json.Decode.string)
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "maxPlayers" Json.Decode.int)
        (Json.Decode.field "players" (Json.Decode.list playerDecoder))
        |> Json.Decode.map Game


playerEncoder : Player -> Json.Encode.Value
playerEncoder player =
    Json.Encode.object
        [ ( "username", Json.Encode.string player.username )
        ]


playerDecoder : Json.Decode.Decoder Player
playerDecoder =
    Json.Decode.map
        Player
        (Json.Decode.field "username" Json.Decode.string)



-- COMMANDS


gamesUrl : String
gamesUrl =
    "/api/games"


fetchGames : (Result Http.Error (List Game) -> msg) -> Cmd msg
fetchGames onResult =
    let
        request =
            Http.get gamesUrl listDecoder
    in
        request
            |> Http.send onResult
