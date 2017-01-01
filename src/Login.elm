module Login
    exposing
        ( LoginForm
        , init
        , setUsername
        , setPassword
        , view
        , login
        )

import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Encode
import Http
import Message exposing (Message(..), AnonymousMessage(..), LoggedInMessage(..))
import User exposing (User)


-- MODEL


type alias LoginForm =
    { username : String
    , password : String
    }


init : LoginForm
init =
    { username = ""
    , password = ""
    }



-- UPDATE


setUsername : String -> LoginForm -> LoginForm
setUsername username login =
    { login | username = username }


setPassword : String -> LoginForm -> LoginForm
setPassword password login =
    { login | password = password }



-- VIEW


view : LoginForm -> Html Message
view loginForm =
    Html.div
        []
        [ Html.h3
            []
            [ Html.text "Login" ]
        , Html.form
            [ Html.Events.onSubmit LoginRequest
            ]
            [ Html.label
                [ Html.Attributes.for "login-username" ]
                [ Html.text "Username" ]
            , Html.input
                [ Html.Attributes.id "login-username"
                , Html.Attributes.value loginForm.username
                , Html.Events.onInput SetLoginUsername
                ]
                []
            , Html.label
                [ Html.Attributes.for "login-password" ]
                [ Html.text "Password" ]
            , Html.input
                [ Html.Attributes.id "login-password"
                , Html.Attributes.type_ "password"
                , Html.Attributes.value loginForm.password
                , Html.Events.onInput SetLoginPassword
                ]
                []
            , Html.button
                [ Html.Attributes.type_ "submit" ]
                [ Html.text "Login!" ]
            ]
        ]
        |> Html.map Anonymous



-- ENCODE/DECODE


encoder : LoginForm -> Json.Encode.Value
encoder model =
    Json.Encode.object
        [ ( "username", Json.Encode.string model.username )
        , ( "password", Json.Encode.string model.password )
        ]



-- COMMANDS


login : (Result Http.Error User -> message) -> LoginForm -> Cmd message
login onResult model =
    let
        url =
            "/api/login"

        request =
            Http.post url
                (Http.jsonBody
                    (encoder model)
                )
                User.decoder
    in
        request
            |> Http.send onResult
