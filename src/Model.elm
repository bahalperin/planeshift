module Model exposing (Model)

import User exposing (User)
import Route exposing (Route)
import Deck exposing (Deck)
import Page.Home exposing (HomePage)
import Page.Decks exposing (DecksPage)
import Page.EditDeck exposing (EditDeckPage)


type alias Model =
    { user : User
    , route : Route
    , decks : Maybe (List Deck)
    , homePage : HomePage
    , decksPage : DecksPage
    , editDeckPage : Maybe EditDeckPage
    }
