module Route
    exposing
        ( Route(..)
        , AuthorizedRoute(..)
        , fromLocation
        , toUrl
        , goTo
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
import Game


type Route
    = Home
    | Authorized AuthorizedRoute
    | NotFound String


type AuthorizedRoute
    = Decks
    | EditDeck Deck.Id
    | Games
    | PlayGame Game.Id


goTo : Route -> Cmd msg
goTo route =
    Navigation.newUrl (toUrl route)


toUrl : Route -> String
toUrl route =
    case route of
        Home ->
            "/"

        Authorized authorizedRoute ->
            case authorizedRoute of
                Decks ->
                    "/decks"

                EditDeck deckId ->
                    "/edit-deck/" ++ deckId

                Games ->
                    "/games"

                PlayGame gameId ->
                    "/game/" ++ gameId

        NotFound str ->
            str


fromLocation : Navigation.Location -> Route
fromLocation location =
    let
        path =
            String.dropLeft 1 location.pathname
    in
        UrlParser.parsePath routeParser location
            |> Maybe.withDefault (NotFound path)


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
        [ UrlParser.map (Authorized << PlayGame) playGame
        , UrlParser.map (Authorized Games) games
        , UrlParser.map (Authorized << EditDeck) editDeck
        , UrlParser.map (Authorized Decks) viewDecks
        , UrlParser.map Home UrlParser.top
        ]
