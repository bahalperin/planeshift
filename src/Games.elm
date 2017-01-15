module Games
    exposing
        ( Games
        , Game
        , GameId
        , fromList
        , joinGame
        , fetchGames
        , view
        )

import List.Extra
import Html exposing (..)
import Http
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode
import Card exposing (Card)
import Deck exposing (Deck)
import User exposing (User)


type Games
    = Games
        { setup : List SetupGame
        , active : List ActiveGame
        }


type Game
    = Setup SetupGame
    | Active ActiveGame


type alias GameId =
    String


type alias GameBasics =
    { id : GameId
    , name : String
    }


type alias SetupGame =
    { basics : GameBasics
    , state : SetupState
    }


type alias ActiveGame =
    { basics : GameBasics
    , state : ActiveState
    }


type alias SetupState =
    { players : ( Maybe SetupPlayer, Maybe SetupPlayer )
    }


type alias SetupPlayer =
    { username : String
    , cardsForGame : List Card
    , remainingCards : List Card
    }


type alias ActiveState =
    { players : ( ActivePlayer, ActivePlayer )
    , battlefield : List Card
    , exile : List Card
    , stack : List Card
    }


type alias ActivePlayer =
    { username : String
    , hand : List Card
    , graveyard : List Card
    , library : List Card
    }


toList : Games -> List Game
toList (Games { setup, active }) =
    List.map Setup setup ++ List.map Active active


fromList : List Game -> Games
fromList gameList =
    Games
        { setup =
            List.filterMap
                (\game ->
                    case game of
                        Setup setupGame ->
                            Just setupGame

                        Active _ ->
                            Nothing
                )
                gameList
        , active =
            List.filterMap
                (\game ->
                    case game of
                        Active activeGame ->
                            Just activeGame

                        Setup _ ->
                            Nothing
                )
                gameList
        }


isActive : Game -> Bool
isActive game =
    case game of
        Active _ ->
            True

        Setup _ ->
            False


view : (String -> GameId -> message) -> User -> Games -> Html message
view joinGame user games =
    table
        []
        (List.append
            [ tr
                []
                [ th [] [ text "Game" ]
                , th [] [ text "Players" ]
                ]
            ]
            (games
                |> toList
                |> List.sortBy (getName >> String.toLower)
                |> List.map
                    (\game ->
                        case game of
                            Setup setupGame ->
                                viewSetupGame user setupGame joinGame

                            Active _ ->
                                Html.span [] []
                    )
            )
        )


viewSetupGame : User -> SetupGame -> (String -> GameId -> message) -> Html message
viewSetupGame user ({ basics, state } as setupGame) joinGame =
    tr
        []
        [ td [] [ text basics.name ]
        , td [] [ text <| (setupPlayerList setupGame |> List.length |> toString) ++ "/" ++ (setupPlayerList setupGame |> List.length |> toString) ]
        , td
            []
            [ button
                [ Html.Events.onClick (joinGame (User.getUsername user) basics.id)
                , Html.Attributes.disabled (Tuple.first state.players /= Nothing && Tuple.second state.players /= Nothing)
                ]
                [ Html.text "Join Game" ]
            ]
        ]


setupPlayersFromList : List SetupPlayer -> ( Maybe SetupPlayer, Maybe SetupPlayer )
setupPlayersFromList playerList =
    case playerList of
        first :: second :: rest ->
            ( Just first, Just second )

        first :: [] ->
            ( Just first, Nothing )

        [] ->
            ( Nothing, Nothing )


setupPlayerList : SetupGame -> List SetupPlayer
setupPlayerList { state } =
    [ Tuple.first state.players, Tuple.second state.players ]
        |> List.filterMap identity


findSetupPlayer : String -> SetupGame -> Maybe SetupPlayer
findSetupPlayer username setupGame =
    setupGame
        |> setupPlayerList
        |> List.Extra.find (\setupPlayer -> setupPlayer.username == username)


isSetupPlayerInGame : String -> SetupGame -> Bool
isSetupPlayerInGame username setupGame =
    setupGame
        |> findSetupPlayer username
        |> (\maybePlayer ->
                case maybePlayer of
                    Just player ->
                        True

                    Nothing ->
                        False
           )


getName : Game -> String
getName game =
    case game of
        Setup { basics } ->
            basics.name

        Active { basics } ->
            basics.name


joinGame : GameId -> String -> Games -> Games
joinGame gameId username (Games { setup, active }) =
    Games
        { active = active
        , setup =
            setup
                |> List.Extra.updateIf
                    (\{ basics } -> basics.id == gameId)
                    (joinGameHelp (initSetupPlayer username))
        }


joinGameHelp : SetupPlayer -> SetupGame -> SetupGame
joinGameHelp setupPlayer ({ basics, state } as setupGame) =
    { setupGame
        | state =
            { state
                | players =
                    case state.players of
                        ( Nothing, a ) ->
                            ( Just setupPlayer, a )

                        ( a, Nothing ) ->
                            ( a, Just setupPlayer )

                        ( Just player1, Just player2 ) ->
                            state.players
            }
    }


initSetupPlayer : String -> SetupPlayer
initSetupPlayer username =
    { username = username
    , cardsForGame = []
    , remainingCards = []
    }


loadDeck : String -> GameId -> Deck -> Games -> Games
loadDeck username gameId deck (Games games) =
    Games
        { games
            | setup = List.Extra.updateIf (\{ basics } -> basics.id == gameId) (loadDeckHelp username deck) games.setup
        }


loadDeckHelp : String -> Deck -> SetupGame -> SetupGame
loadDeckHelp username deck ({ basics, state } as setupGame) =
    setupGame
        |> updateSetupPlayer username (\setupPlayer -> { setupPlayer | cardsForGame = Deck.getMainDeck deck, remainingCards = Deck.getSideboard deck })


updateSetupPlayer : String -> (SetupPlayer -> SetupPlayer) -> SetupGame -> SetupGame
updateSetupPlayer username update ({ basics, state } as setupGame) =
    { basics = basics
    , state =
        { state
            | players =
                setupPlayerList setupGame
                    |> List.Extra.updateIf (\setupPlayer -> setupPlayer.username == username) update
                    |> setupPlayersFromList
        }
    }


gameDecoder : Json.Decode.Decoder Game
gameDecoder =
    Json.Decode.oneOf
        [ Json.Decode.map Setup setupGameDecoder
        ]


setupGameDecoder : Json.Decode.Decoder SetupGame
setupGameDecoder =
    Json.Decode.map2
        SetupGame
        gameBasicsDecoder
        setupStateDecoder


gameBasicsDecoder : Json.Decode.Decoder GameBasics
gameBasicsDecoder =
    Json.Decode.map2
        GameBasics
        (Json.Decode.field "_id" Json.Decode.string)
        (Json.Decode.field "name" Json.Decode.string)


setupStateDecoder : Json.Decode.Decoder SetupState
setupStateDecoder =
    Json.Decode.map SetupState
        (Json.Decode.map2 (,)
            (Json.Decode.field "player1" (Json.Decode.nullable setupPlayerDecoder))
            (Json.Decode.field "player2" (Json.Decode.nullable setupPlayerDecoder))
        )


setupPlayerDecoder : Json.Decode.Decoder SetupPlayer
setupPlayerDecoder =
    Json.Decode.map3
        SetupPlayer
        (Json.Decode.field "username" Json.Decode.string)
        (Json.Decode.field "cardsForGame" Card.listDecoder)
        (Json.Decode.field "remainingCards" Card.listDecoder)


gamesUrl : String
gamesUrl =
    "/api/games"


fetchGames : (Result Http.Error (List Game) -> msg) -> Cmd msg
fetchGames onResult =
    let
        request =
            Http.get gamesUrl (Json.Decode.list gameDecoder)
    in
        request
            |> Http.send onResult
