module User
    exposing
        ( User
        , Id
        , getUsername
        , new
        , decoder
        , fetchCurrentUser
        )

import Http
import Result exposing (Result)
import Json.Decode exposing (Decoder, field)


-- MODEL


type User
    = User UserData


type alias UserData =
    { id : Id
    , username : String
    }


type alias Id =
    String


new : Id -> String -> User
new id username =
    User
        { id = id
        , username = username
        }


getUsername : User -> String
getUsername (User userData) =
    userData.username



-- ENCODE/DECODE


decoder : Decoder User
decoder =
    Json.Decode.map2
        UserData
        (field "_id" Json.Decode.string)
        (field "username" Json.Decode.string)
        |> Json.Decode.map User


fetchCurrentUser : (Result Http.Error User -> msg) -> Cmd msg
fetchCurrentUser onResult =
    let
        url =
            "/api/current-user"

        request =
            Http.get url decoder
    in
        request
            |> Http.send onResult
