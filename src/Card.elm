module Card
    exposing
        ( Card
        , new
        , getId
        , getName
        , frontImageUrl
        , backImageUrl
        , groupByName
        , encoder
        , listDecoder
        , getCardsByName
        )

import Dict exposing (Dict)
import Json.Encode
import Json.Decode exposing (field)
import Http


-- MODEL


type Card
    = Card CardData


type alias CardData =
    { name : String
    , multiverseId : Int
    }


new : Int -> String -> Card
new multiverseId name =
    Card
        { name = name
        , multiverseId = multiverseId
        }


getId : Card -> Int
getId (Card cardData) =
    cardData.multiverseId


getName : Card -> String
getName (Card cardData) =
    cardData.name


frontImageUrl : Card -> String
frontImageUrl (Card cardData) =
    imageUrlHelp cardData.multiverseId


backImageUrl : String
backImageUrl =
    imageUrlHelp 0


imageUrlHelp : Int -> String
imageUrlHelp multiverseId =
    "http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=" ++ (multiverseId |> toString) ++ "&type=card"


groupByName : List Card -> List ( Card, Int )
groupByName cards =
    groupByNameHelp cards Dict.empty Dict.empty


groupByNameHelp : List Card -> Dict String Card -> Dict String Int -> List ( Card, Int )
groupByNameHelp newCards cardsByName cardCounts =
    case newCards of
        (Card first) :: rest ->
            let
                count =
                    cardCounts
                        |> Dict.get (first.name)
                        |> Maybe.withDefault 0
            in
                groupByNameHelp rest (Dict.insert first.name (Card first) cardsByName) (Dict.insert first.name (count + 1) cardCounts)

        [] ->
            cardCounts
                |> Dict.toList
                |> List.filterMap
                    (\( cardName, count ) ->
                        let
                            maybeCard =
                                Dict.get cardName cardsByName
                        in
                            case maybeCard of
                                Just card ->
                                    Just ( card, count )

                                Nothing ->
                                    Nothing
                    )



-- ENCODE/DECODE


encoder : Card -> Json.Encode.Value
encoder (Card cardData) =
    Json.Encode.object
        [ ( "name", Json.Encode.string cardData.name )
        , ( "multiverseid", Json.Encode.int cardData.multiverseId )
        ]


listDecoder : Json.Decode.Decoder (List Card)
listDecoder =
    Json.Decode.list decoder
        |> Json.Decode.map (\cards -> List.filterMap identity cards)


decoder : Json.Decode.Decoder (Maybe Card)
decoder =
    Json.Decode.map2
        CardData
        (field "name" Json.Decode.string)
        (field "multiverseid" Json.Decode.int)
        |> Json.Decode.map Card
        |> Json.Decode.maybe



-- COMMANDS


getCardsByName : (Result Http.Error (List Card) -> msg) -> String -> Cmd msg
getCardsByName onResult name =
    let
        url =
            "https://api.magicthegathering.io/v1/cards?name=" ++ name

        request =
            Http.get url (Json.Decode.at [ "cards" ] listDecoder)
    in
        request
            |> Http.send onResult
