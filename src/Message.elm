module Message
    exposing
        ( Message(..)
        , AnonymousMessage(..)
        , LoggedInMessage(..)
        )

import Http
import Route exposing (Route, PublicRoute)
import User exposing (User)
import Card exposing (Card)
import Deck exposing (Deck)
import Game exposing (Game)


type Message
    = Anonymous AnonymousMessage
    | LoggedIn LoggedInMessage
    | HandleRouteChange Route
    | NoOp


type LoggedInMessage
    = ChangeRoute Route
    | SetCardSearchQuery String
    | SearchForCardsRequest
    | SearchForCardsResponse (Result Http.Error (List Card))
    | SetAddNewDeckName String
    | AddDeckRequest
    | AddDeckResponse (Result Http.Error Deck)
    | SelectMtgCard Card
    | FetchDecksResponse (Result Http.Error (List Deck))
    | AddCardToMainDeck Deck.Id Card
    | RemoveCardFromMainDeck Deck.Id Card
    | AddCardToSideboard Deck.Id Card
    | RemoveCardFromSideboard Deck.Id Card
    | JoinGame String Game.Id
    | HandleGameJoined String Game.Id
    | FetchGamesRequest
    | FetchGamesResponse (Result Http.Error (List Game))
    | SaveDeckRequest Deck
    | SaveDeckResponse (Result Http.Error Deck)
    | DeleteDeckRequest Deck.Id
    | DeleteDeckResponse (Result Http.Error ())


type AnonymousMessage
    = ChangePublicRoute PublicRoute
    | FetchUserRequest
    | FetchUserResponse (Result Http.Error User)
    | RegisterUserRequest
    | RegisterUserResponse (Result Http.Error User)
    | SetSignupUsername String
    | SetSignupPassword String
    | SetLoginUsername String
    | SetLoginPassword String
    | LoginRequest
    | LoginResponse (Result Http.Error User)
