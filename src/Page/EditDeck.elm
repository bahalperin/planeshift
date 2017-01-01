module Page.EditDeck
    exposing
        ( EditDeckPage
        , init
        , getCurrentDeckId
        , getCardSearchQuery
        , setSelectedCard
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


-- MODEL


type EditDeckPage
    = EditDeckPage EditDeckPageData


type alias EditDeckPageData =
    { deckId : String
    , selectedCardId : Maybe Int
    , cardSearchQuery : String
    , cardSearchResults : Maybe (List Card)
    }


init : String -> EditDeckPage
init deckId =
    EditDeckPage
        { deckId = deckId
        , selectedCardId = Nothing
        , cardSearchQuery = ""
        , cardSearchResults = Just []
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
        { editDeckPageData | selectedCardId = Just cardId }


setCardSearchQuery : String -> EditDeckPage -> EditDeckPage
setCardSearchQuery query (EditDeckPage editDeckPageData) =
    EditDeckPage
        { editDeckPageData | cardSearchQuery = query }


setCardSearchResults : List Card -> EditDeckPage -> EditDeckPage
setCardSearchResults cards (EditDeckPage editDeckPageData) =
    EditDeckPage
        { editDeckPageData | cardSearchResults = Just cards }



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
    let
        results =
            editDeckPageData.cardSearchResults
                |> Maybe.map
                    (\cards -> viewCardSearchResults cards editDeckPageData)
                |> Maybe.withDefault
                    (Html.span
                        []
                        [ Html.text "Loading" ]
                    )
    in
        Html.div
            []
            [ cardSearch editDeckPageData
            , results
            ]


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
    let
        deckCards =
            decks
                |> List.map (\d -> List.append (Deck.getMainDeck d) (Deck.getSideboard d))
                |> List.concat

        cardImageUrl =
            editDeckPageData.cardSearchResults
                |> Maybe.withDefault []
                |> List.append deckCards
                |> List.filter (\c -> Card.getId c == (editDeckPageData.selectedCardId |> Maybe.withDefault 0))
                |> List.head
                |> Maybe.map Card.frontImageUrl
                |> Maybe.withDefault Card.backImageUrl
    in
        Html.img
            [ Html.Attributes.src cardImageUrl ]
            []
