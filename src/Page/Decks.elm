module Page.Decks
    exposing
        ( DecksPage
        , init
        , getNewDeckName
        , setNewDeckName
        , view
        )

import Html
    exposing
        ( Html
        , div
        , text
        , h3
        , form
        , input
        , button
        , ul
        , li
        , a
        )
import Html.Attributes
    exposing
        ( value
        , type_
        )
import Html.Events
    exposing
        ( onInput
        , onSubmit
        , onClick
        )
import Deck exposing (Deck)
import Message exposing (Message(..))
import Route
    exposing
        ( Route(..)
        , AuthorizedRoute(..)
        )


-- MODEL


type DecksPage
    = DecksPage DecksPageData


type alias DecksPageData =
    { addNewDeckName : String
    }


init : DecksPage
init =
    DecksPage
        { addNewDeckName = ""
        }


getNewDeckName : DecksPage -> String
getNewDeckName (DecksPage decksPageData) =
    decksPageData.addNewDeckName



-- UPDATE


setNewDeckName : String -> DecksPage -> DecksPage
setNewDeckName name (DecksPage decksPageData) =
    DecksPage
        { decksPageData | addNewDeckName = name }



-- VIEW


view : List Deck -> DecksPage -> Html Message
view decks (DecksPage decksPageData) =
    div
        []
        [ form
            [ onSubmit AddDeckRequest ]
            [ input
                [ value decksPageData.addNewDeckName
                , onInput SetAddNewDeckName
                ]
                []
            , button
                [ type_ "submit" ]
                [ text "Add new deck" ]
            ]
        , h3
            []
            [ text "Decks"
            ]
        , ul
            []
            (decks
                |> List.sortBy Deck.getName
                |> List.map viewDeck
            )
        ]


viewDeck : Deck -> Html Message
viewDeck deck =
    li
        []
        [ a
            [ onClick (ChangeRoute <| Authorized (EditDeck (Deck.getId deck)))
            ]
            [ text (Deck.getName deck)
            ]
        , button
            [ onClick <| DeleteDeckRequest (Deck.getId deck) ]
            [ text "X" ]
        ]
