module Route
    exposing
        ( Route(..)
        , PublicRoute(..)
        , fromLocation
        , toUrl
        , goTo
        , toPublicRoute
        )

import Navigation
import UrlParser
    exposing
        ( Parser
        , (</>)
        , s
        , oneOf
        , int
        , string
        )
import Deck
import Games exposing (GameId)


type Route
    = Public PublicRoute
    | Decks
    | EditDeck Deck.Id
    | Games
    | PlayGame GameId


type PublicRoute
    = Home
    | NotFound String


goTo : Route -> Cmd msg
goTo route =
    Navigation.newUrl (toUrl route)


toUrl : Route -> String
toUrl route =
    case route of
        Public publicRoute ->
            case publicRoute of
                Home ->
                    "/"

                NotFound str ->
                    str

        Decks ->
            "/decks"

        EditDeck deckId ->
            "/edit-deck/" ++ deckId

        Games ->
            "/games"

        PlayGame gameId ->
            "/game/" ++ gameId


fromLocation : Navigation.Location -> Route
fromLocation location =
    let
        path =
            String.dropLeft 1 location.pathname
    in
        UrlParser.parsePath routeParser location
            |> Maybe.withDefault (Public <| NotFound path)


toPublicRoute : Route -> PublicRoute
toPublicRoute route =
    case route of
        Public publicRoute ->
            publicRoute

        _ ->
            Home


viewDecks : Parser a a
viewDecks =
    s "decks"


editDeck : Parser (String -> a) a
editDeck =
    s "edit-deck" </> string


games : Parser a a
games =
    s "games"


playGame : Parser (String -> a) a
playGame =
    s "game" </> string


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ UrlParser.map (PlayGame) playGame
        , UrlParser.map (Games) games
        , UrlParser.map (EditDeck) editDeck
        , UrlParser.map (Decks) viewDecks
        , UrlParser.map (Public Home) UrlParser.top
        ]
