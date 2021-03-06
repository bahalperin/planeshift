module Decks exposing (..)

import List.Extra
import Card exposing (Card)
import Deck exposing (Deck)
import SelectableList exposing (SelectableList)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Message exposing (Message(..), AnonymousMessage(..), LoggedInMessage(..))


type alias Decks =
    List DeckData


type alias DeckData =
    { deck : Deck, editPage : EditDeckPage }


type alias EditDeckPage =
    { cardSearchQuery : String
    , cardSearchResults : SelectableList Card
    , isSearchingForCards : Bool
    }


initEditDeckPage : EditDeckPage
initEditDeckPage =
    { cardSearchQuery = ""
    , cardSearchResults = SelectableList.fromList []
    , isSearchingForCards = False
    }


getCardSearchQuery : Deck.Id -> Decks -> String
getCardSearchQuery deckId decks =
    decks
        |> List.Extra.find (\{ deck } -> Deck.getId deck == deckId)
        |> Maybe.map (\{ editPage } -> editPage.cardSearchQuery)
        |> Maybe.withDefault ""


setSelectedCard : Deck.Id -> Int -> Decks -> Decks
setSelectedCard deckId cardId decks =
    List.Extra.updateIf (\{ deck } -> Deck.getId deck == deckId) (\({ editPage } as deckData) -> { deckData | editPage = { editPage | cardSearchResults = SelectableList.select (\card -> Card.getId card == cardId) editPage.cardSearchResults } }) decks


setCardSearchQuery : Deck.Id -> String -> Decks -> Decks
setCardSearchQuery deckId query decks =
    List.Extra.updateIf (\{ deck } -> Deck.getId deck == deckId) (\({ editPage } as deckData) -> { deckData | editPage = { editPage | cardSearchQuery = query } }) decks


startSearchingForCards : Deck.Id -> Decks -> Decks
startSearchingForCards deckId decks =
    List.Extra.updateIf (\{ deck } -> Deck.getId deck == deckId) (\({ editPage } as deckData) -> { deckData | editPage = { editPage | isSearchingForCards = True } }) decks


setCardSearchResults : Deck.Id -> List Card -> Decks -> Decks
setCardSearchResults deckId cards decks =
    List.Extra.updateIf (\{ deck } -> Deck.getId deck == deckId) (\({ editPage } as deckData) -> { deckData | editPage = { editPage | cardSearchResults = SelectableList.fromList cards, isSearchingForCards = False } }) decks



-- VIEW


view : Deck.Id -> Decks -> Html Message
view deckId decks =
    decks
        |> List.Extra.find (\{ deck } -> Deck.getId deck == deckId)
        |> Maybe.map
            (\deckData ->
                Html.div
                    []
                    [ viewSelectedCard deckData.editPage
                    , viewDeckList deckData
                    , viewCardList deckData
                    ]
            )
        |> Maybe.withDefault (Html.div [] [])


viewDeckList : DeckData -> Html Message
viewDeckList { deck, editPage } =
    Html.div
        []
        [ Html.h1 [] [ Html.text (Deck.getName deck) ]
        , Html.button [ Html.Events.onClick (LoggedIn <| SaveDeckRequest deck) ] [ Html.text "Save" ]
        , Html.h3
            []
            [ Html.text <|
                "Main - ("
                    ++ (deck |> Deck.getMainDeck |> List.length |> toString)
                    ++ ")"
            ]
        , Html.ul
            []
            (deck
                |> Deck.getMainDeck
                |> Card.groupByName
                |> List.sortBy (\( card, count ) -> Card.getName card |> String.toLower)
                |> List.map (\( card, count ) -> mainDeckCard count card deck)
            )
        , Html.h3
            []
            [ Html.text <|
                "Sideboard - ("
                    ++ (deck |> Deck.getSideboard |> List.length |> toString)
                    ++ ")"
            ]
        , Html.ul
            []
            (deck
                |> Deck.getSideboard
                |> Card.groupByName
                |> List.sortBy (\( card, count ) -> Card.getName card |> String.toLower)
                |> List.map (\( card, count ) -> sideboardCard count card deck)
            )
        ]


mainDeckCard : Int -> Card -> Deck -> Html Message
mainDeckCard count card deck =
    deckListCard count card (AddCardToMainDeck (Deck.getId deck) card) (RemoveCardFromMainDeck (Deck.getId deck) card) (SelectMtgCard (Deck.getId deck) card)
        |> Html.map LoggedIn


sideboardCard : Int -> Card -> Deck -> Html Message
sideboardCard count card deck =
    deckListCard count card (AddCardToSideboard (Deck.getId deck) card) (RemoveCardFromSideboard (Deck.getId deck) card) (SelectMtgCard (Deck.getId deck) card)
        |> Html.map LoggedIn


deckListCard : Int -> Card -> message -> message -> message -> Html message
deckListCard count card addCard removeCard selectCard =
    Html.li
        []
        [ Html.span
            [ Html.Events.onClick selectCard ]
            [ Html.text <| (count |> toString) ++ " - " ++ Card.getName card ]
        , Html.button
            [ Html.Events.onClick addCard ]
            [ Html.text "+" ]
        , Html.button
            [ Html.Events.onClick removeCard ]
            [ Html.text "-" ]
        ]


cardSearch : DeckData -> Html Message
cardSearch { deck, editPage } =
    Html.form
        [ Html.Events.onSubmit <| SearchForCardsRequest (Deck.getId deck) ]
        [ Html.input
            [ Html.Events.onInput <| SetCardSearchQuery (Deck.getId deck)
            , Html.Attributes.value editPage.cardSearchQuery
            ]
            []
        , Html.button
            [ Html.Attributes.type_ "submit"
            ]
            [ Html.text "Search" ]
        ]
        |> Html.map LoggedIn


viewCardList : DeckData -> Html Message
viewCardList ({ deck, editPage } as deckData) =
    Html.div
        []
        [ cardSearch deckData
        , loadingText editPage.isSearchingForCards
        , viewCardSearchResults deckData
        ]


loadingText : Bool -> Html Message
loadingText isLoading =
    if isLoading then
        Html.span [] [ Html.text "Loading" ]
    else
        Html.span [] []


viewCardSearchResults : DeckData -> Html Message
viewCardSearchResults { deck, editPage } =
    Html.ul
        []
        (List.map
            (\card ->
                Html.li
                    []
                    [ Html.span
                        [ Html.Events.onClick (SelectMtgCard (Deck.getId deck) card) ]
                        [ Html.text (Card.getName card) ]
                    , Html.button [ Html.Events.onClick (AddCardToMainDeck (Deck.getId deck) card) ] [ Html.text "Add Card" ]
                    , Html.button [ Html.Events.onClick (AddCardToSideboard (Deck.getId deck) card) ] [ Html.text "Add to Sideboard" ]
                    ]
            )
            (SelectableList.toList editPage.cardSearchResults)
        )
        |> Html.map LoggedIn


viewSelectedCard : EditDeckPage -> Html Message
viewSelectedCard editDeckPageData =
    Html.img
        [ editDeckPageData.cardSearchResults
            |> SelectableList.getSelected
            |> Maybe.map Card.frontImageUrl
            |> Maybe.withDefault Card.backImageUrl
            |> Html.Attributes.src
        ]
        []
