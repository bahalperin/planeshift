module Page.EditDeck
    exposing
        ( EditDeckPage
        , init
        , getCurrentDeckId
        , getCardSearchQuery
        , setSelectedCard
        , startSearchingForCards
        , setCardSearchQuery
        , setCardSearchResults
        , view
        )

import Html exposing (Html)
import Html.Attributes
import Html.Events
import String
import Card exposing (Card)
import Deck exposing (Deck)
import Message exposing (Message(..), AnonymousMessage(..), LoggedInMessage(..))
import SelectableList exposing (SelectableList)


-- MODEL


type EditDeckPage
    = EditDeckPage EditDeckPageData


type alias EditDeckPageData =
    { deckId : String
    , cardSearchQuery : String
    , cardSearchResults : CardSearchResults
    , isSearchingForCards : Bool
    }


type alias CardSearchResults =
    SelectableList Card


init : String -> EditDeckPage
init deckId =
    EditDeckPage
        { deckId = deckId
        , cardSearchQuery = ""
        , cardSearchResults = SelectableList.fromList []
        , isSearchingForCards = False
        }


getCurrentDeckId : EditDeckPage -> String
getCurrentDeckId (EditDeckPage editDeckPageData) =
    editDeckPageData.deckId


getCardSearchQuery : EditDeckPage -> String
getCardSearchQuery (EditDeckPage editDeckPageData) =
    editDeckPageData.cardSearchQuery



-- UPDATE


setSelectedCard : Int -> EditDeckPage -> EditDeckPage
setSelectedCard cardId (EditDeckPage editDeckPageData) =
    EditDeckPage
        { editDeckPageData
            | cardSearchResults = SelectableList.select (\card -> Card.getId card == cardId) editDeckPageData.cardSearchResults
        }


setCardSearchQuery : String -> EditDeckPage -> EditDeckPage
setCardSearchQuery query (EditDeckPage editDeckPageData) =
    EditDeckPage
        { editDeckPageData | cardSearchQuery = query }


startSearchingForCards : EditDeckPage -> EditDeckPage
startSearchingForCards (EditDeckPage editDeckPageData) =
    EditDeckPage
        { editDeckPageData | isSearchingForCards = True }


setCardSearchResults : List Card -> EditDeckPage -> EditDeckPage
setCardSearchResults cards (EditDeckPage editDeckPageData) =
    EditDeckPage
        { editDeckPageData
            | cardSearchResults = SelectableList.fromList cards
            , isSearchingForCards = False
        }



-- VIEW


view : List Deck -> EditDeckPage -> Html Message
view decks (EditDeckPage editDeckPageData) =
    Html.div
        []
        [ viewSelectedCard decks editDeckPageData
        , viewDeckList decks editDeckPageData
        , viewCardList editDeckPageData
        ]


viewDeckList : List Deck -> EditDeckPageData -> Html Message
viewDeckList decks editDeckPageData =
    decks
        |> List.filter (\d -> Deck.getId d == editDeckPageData.deckId)
        |> List.head
        |> Maybe.map
            (\deck ->
                Html.div
                    []
                    [ Html.h1 [] [ Html.text (Deck.getName deck) ]
                    , Html.button [ Html.Events.onClick (LoggedIn <| SaveDeckRequest (Deck.getId deck)) ] [ Html.text "Save" ]
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
            )
        |> Maybe.withDefault
            (Html.div
                []
                [ Html.h1 [] [ Html.text "Deck Not Found" ]
                ]
            )


mainDeckCard : Int -> Card -> Deck -> Html Message
mainDeckCard count card deck =
    deckListCard count card (AddCardToMainDeck (Deck.getId deck) card) (RemoveCardFromMainDeck (Deck.getId deck) card) (SelectMtgCard card)
        |> Html.map LoggedIn


sideboardCard : Int -> Card -> Deck -> Html Message
sideboardCard count card deck =
    deckListCard count card (AddCardToSideboard (Deck.getId deck) card) (RemoveCardFromSideboard (Deck.getId deck) card) (SelectMtgCard card)
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


cardSearch : EditDeckPageData -> Html Message
cardSearch editDeckPageData =
    Html.form
        [ Html.Events.onSubmit SearchForCardsRequest ]
        [ Html.input
            [ Html.Events.onInput SetCardSearchQuery
            , Html.Attributes.value editDeckPageData.cardSearchQuery
            ]
            []
        , Html.button
            [ Html.Attributes.type_ "submit"
            ]
            [ Html.text "Search" ]
        ]
        |> Html.map LoggedIn


viewCardList : EditDeckPageData -> Html Message
viewCardList editDeckPageData =
    Html.div
        []
        [ cardSearch editDeckPageData
        , loadingText editDeckPageData.isSearchingForCards
        , editDeckPageData.cardSearchResults
            |> SelectableList.toList
            |> (\cards -> viewCardSearchResults cards editDeckPageData)
        ]


loadingText : Bool -> Html Message
loadingText isLoading =
    if isLoading then
        Html.span [] [ Html.text "Loading" ]
    else
        Html.span [] []


viewCardSearchResults : List Card -> EditDeckPageData -> Html Message
viewCardSearchResults cards editDeckPageData =
    Html.ul
        []
        (List.map
            (\card ->
                Html.li
                    []
                    [ Html.span
                        [ Html.Events.onClick (SelectMtgCard card) ]
                        [ Html.text (Card.getName card) ]
                    , Html.button [ Html.Events.onClick (AddCardToMainDeck editDeckPageData.deckId card) ] [ Html.text "Add Card" ]
                    , Html.button [ Html.Events.onClick (AddCardToSideboard editDeckPageData.deckId card) ] [ Html.text "Add to Sideboard" ]
                    ]
            )
            cards
        )
        |> Html.map LoggedIn


viewSelectedCard : List Deck -> EditDeckPageData -> Html Message
viewSelectedCard decks editDeckPageData =
    Html.img
        [ editDeckPageData.cardSearchResults
            |> SelectableList.getSelected
            |> Maybe.map Card.frontImageUrl
            |> Maybe.withDefault Card.backImageUrl
            |> Html.Attributes.src
        ]
        []
