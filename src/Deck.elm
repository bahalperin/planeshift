module Deck
    exposing
        ( Deck
        , Id
        , getId
        , getName
        , getMainDeck
        , getSideboard
        , addCardToMainDeck
        , addCardToSideboard
        , removeCardFromMainDeck
        , removeCardFromSideboard
        , fetchDecks
        , addDeck
        , saveDeck
        , deleteDeck
        )

import Json.Encode
import Json.Decode exposing (field)
import Card exposing (Card)
import Http


-- MODEL


type Deck
    = Deck DeckData


type alias DeckData =
    { id : Id
    , name : String
    , main : List Card
    , sideboard : List Card
    , createdUser : String
    }


type alias Id =
    String


getId : Deck -> String
getId (Deck deckData) =
    deckData.id


getName : Deck -> String
getName (Deck deckData) =
    deckData.name


getMainDeck : Deck -> List Card
getMainDeck (Deck deckData) =
    deckData.main


getSideboard : Deck -> List Card
getSideboard (Deck deckData) =
    deckData.sideboard



-- UPDATE


addCardToMainDeck : Card -> Deck -> Deck
addCardToMainDeck card (Deck deckData) =
    Deck { deckData | main = card :: deckData.main }


addCardToSideboard : Card -> Deck -> Deck
addCardToSideboard card (Deck deckData) =
    Deck { deckData | sideboard = card :: deckData.sideboard }


removeCardFromMainDeck : Card -> Deck -> Deck
removeCardFromMainDeck card (Deck deckData) =
    Deck { deckData | main = removeCardFromList card deckData.main }


removeCardFromSideboard : Card -> Deck -> Deck
removeCardFromSideboard card (Deck deckData) =
    Deck { deckData | sideboard = removeCardFromList card deckData.sideboard }


removeCardFromList : Card -> List Card -> List Card
removeCardFromList card cardList =
    let
        ( matchingCards, remainingCards ) =
            List.partition (\c -> Card.getId c == Card.getId card) cardList
    in
        matchingCards
            |> List.tail
            |> Maybe.withDefault []
            |> List.append remainingCards



-- ENCODE/DECODE


encoder : Deck -> Json.Encode.Value
encoder (Deck deckData) =
    Json.Encode.object
        [ ( "_id", Json.Encode.string deckData.id )
        , ( "name", Json.Encode.string deckData.name )
        , ( "main", Json.Encode.list (List.map Card.encoder deckData.main) )
        , ( "sideboard", Json.Encode.list (List.map Card.encoder deckData.sideboard) )
        , ( "createdUser", Json.Encode.string deckData.createdUser )
        ]


listDecoder : Json.Decode.Decoder (List Deck)
listDecoder =
    Json.Decode.list decoder


decoder : Json.Decode.Decoder Deck
decoder =
    Json.Decode.map5
        DeckData
        (field "_id" Json.Decode.string)
        (field "name" Json.Decode.string)
        (field "main" Card.listDecoder)
        (field "sideboard" Card.listDecoder)
        (field "createdUser" Json.Decode.string)
        |> Json.Decode.map Deck



-- COMMANDS


decksUrl : String
decksUrl =
    "/api/decks"


fetchDecks : (Result Http.Error (List Deck) -> msg) -> Cmd msg
fetchDecks onResult =
    let
        request =
            Http.get decksUrl listDecoder
    in
        request
            |> Http.send onResult


addDeck : (Result Http.Error Deck -> msg) -> String -> Cmd msg
addDeck onResult name =
    let
        request =
            Http.post decksUrl
                (Http.jsonBody
                    (Json.Encode.object
                        [ ( "deck", Json.Encode.object [ ( "name", Json.Encode.string name ) ] )
                        ]
                    )
                )
                decoder
    in
        request
            |> Http.send onResult


saveDeck : (Result Http.Error Deck -> msg) -> Deck -> Cmd msg
saveDeck onResult deck =
    let
        request =
            Http.post decksUrl
                (Http.jsonBody
                    (Json.Encode.object
                        [ ( "deck", encoder deck )
                        ]
                    )
                )
                (decoder)
    in
        request
            |> Http.send onResult


deleteDeck : (Result Http.Error () -> msg) -> String -> Cmd msg
deleteDeck onResult deckId =
    let
        request =
            Http.request
                { method = "DELETE"
                , headers = []
                , url = decksUrl
                , body =
                    (Http.stringBody
                        "application/json"
                        ("{ \"deckId\": \"" ++ deckId ++ "\" }")
                    )
                , expect = Http.expectStringResponse (\_ -> Ok ())
                , timeout = Nothing
                , withCredentials = False
                }
    in
        request
            |> Http.send onResult
