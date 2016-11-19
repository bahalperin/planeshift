module User
    exposing
        ( User
        , getUsername
        , isRegistered
        , fromUsername
        , anonymous
        , fetchCurrentUser
        )

import Http
import Result exposing (Result)
import Json.Decode exposing (Decoder, field)


-- MODEL


type User
    = Registered UserData
    | Anonymous


type alias UserData =
    { username : String
    }


fromUsername : String -> User
fromUsername username =
    Registered
        { username = username
        }


anonymous : User
anonymous =
    Anonymous


getUsername : User -> Maybe String
getUsername user =
    case user of
        Registered userData ->
            Just userData.username

        _ ->
            Nothing


isRegistered : User -> Bool
isRegistered user =
    case user of
        Registered _ ->
            True

        _ ->
            False



-- ENCODE/DECODE


decoder : Decoder User
decoder =
    Json.Decode.map
        UserData
        (field "username" Json.Decode.string)
        |> Json.Decode.maybe
        |> Json.Decode.map
            (\result ->
                case result of
                    Just userData ->
                        Registered userData

                    Nothing ->
                        Anonymous
            )


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
