module User
    exposing
        ( User
        , getUsername
        , fromUsername
        , fetchCurrentUser
        )

import Http
import Result exposing (Result)
import Json.Decode exposing (Decoder, field)


-- MODEL


type User
    = User UserData


type alias UserData =
    { username : String
    }


fromUsername : String -> User
fromUsername username =
    User
        { username = username
        }


getUsername : User -> String
getUsername (User userData) =
    userData.username



-- ENCODE/DECODE


decoder : Decoder User
decoder =
    Json.Decode.map
        UserData
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
