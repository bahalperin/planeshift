module Message exposing (Message(..))

import Http
import Route exposing (Route)
import User exposing (User)
import Card exposing (Card)
import Deck exposing (Deck)
import Game exposing (Game)


type Message
    = HandleRouteChange Route
    | ChangeRoute Route
      --
    | FetchUserRequest
    | FetchUserResponse (Result Http.Error User)
      --
    | SetCardSearchQuery String
    | SearchForCardsRequest
    | SearchForCardsResponse (Result Http.Error (List Card))
      --
    | SelectMtgCard Card
      --
    | SetAddNewDeckName String
    | AddDeckRequest
    | AddDeckResponse (Result Http.Error Deck)
      --
    | FetchDecksResponse (Result Http.Error (List Deck))
      --
    | RegisterUserRequest
    | RegisterUserResponse (Result Http.Error String)
      --
    | SetSignupUsername String
    | SetSignupPassword String
    | SetLoginUsername String
    | SetLoginPassword String
      --
    | LoginRequest
    | LoginResponse (Result Http.Error String)
      --
    | AddCardToMainDeck Deck.Id Card
    | RemoveCardFromMainDeck Deck.Id Card
    | AddCardToSideboard Deck.Id Card
    | RemoveCardFromSideboard Deck.Id Card
      --
    | SaveDeckRequest Deck.Id
    | SaveDeckResponse (Result Http.Error Deck)
      --
    | DeleteDeckRequest Deck.Id
    | DeleteDeckResponse (Result Http.Error ())
      --
    | JoinGame String Game.Id
    | HandleGameJoined String Game.Id
    | FetchGamesRequest
    | FetchGamesResponse (Result Http.Error (List Game))
      --
    | NoOp
