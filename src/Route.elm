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


type Route
    = Home
    | Authorized AuthorizedRoute
    | NotFound String


type AuthorizedRoute
    = Decks
    | EditDeck Deck.Id


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


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ UrlParser.map (Authorized << EditDeck) editDeck
        , UrlParser.map (Authorized Decks) viewDecks
        , UrlParser.map Home UrlParser.top
        ]
