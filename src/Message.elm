module Message
    exposing
        ( Message(..)
        , LoadingMessage(..)
        , AnonymousMessage(..)
        , LoggedInMessage(..)
        )

import Http
import Route exposing (Route, PublicRoute)
import User exposing (User)
import Card exposing (Card)
import Deck exposing (Deck)
import Games exposing (Game)


type Message
    = Loading LoadingMessage
    | Anonymous AnonymousMessage
    | LoggedIn LoggedInMessage
    | HandleRouteChange Route
    | NoOp


type LoggedInMessage
    = ChangeRoute Route
    | SetCardSearchQuery Deck.Id String
    | SearchForCardsRequest Deck.Id
    | SearchForCardsResponse Deck.Id (Result Http.Error (List Card))
    | SetAddNewDeckName String
    | AddDeckRequest
    | AddDeckResponse (Result Http.Error Deck)
    | SelectMtgCard Deck.Id Card
    | FetchDecksResponse (Result Http.Error (List Deck))
    | AddCardToMainDeck Deck.Id Card
    | RemoveCardFromMainDeck Deck.Id Card
    | AddCardToSideboard Deck.Id Card
    | RemoveCardFromSideboard Deck.Id Card
    | JoinGame String Games.GameId
    | HandleGameJoined String Games.GameId
    | FetchGamesRequest
    | FetchGamesResponse (Result Http.Error (List Game))
    | SaveDeckRequest Deck
    | SaveDeckResponse (Result Http.Error Deck)
    | DeleteDeckRequest Deck.Id
    | DeleteDeckResponse (Result Http.Error ())


type AnonymousMessage
    = ChangePublicRoute PublicRoute
    | RegisterUserRequest
    | RegisterUserResponse (Result Http.Error User)
    | SetSignupUsername String
    | SetSignupPassword String
    | SetLoginUsername String
    | SetLoginPassword String
    | LoginRequest
    | LoginResponse (Result Http.Error User)


type LoadingMessage
    = FetchUserRequest
    | FetchUserResponse (Result Http.Error User)
