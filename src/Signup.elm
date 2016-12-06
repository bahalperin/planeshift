module Signup
    exposing
        ( SignupForm
        , init
        , setUsername
        , setPassword
        , view
        , encoder
        , signup
        )

import Html
    exposing
        ( Html
        , div
        , text
        , h3
        , form
        , input
        , label
        , button
        , ul
        , li
        )
import Html.Attributes
    exposing
        ( id
        , value
        , for
        , type_
        , disabled
        )
import Html.Events exposing (onInput)
import Json.Encode
import Http
import Message exposing (Message(..))
import User exposing (User)


-- MODEL


type alias SignupForm =
    { username : String
    , password : String
    }


init : SignupForm
init =
    { username = ""
    , password = ""
    }


type alias Error =
    String



-- UPDATE


setUsername : String -> SignupForm -> SignupForm
setUsername username signup =
    { signup | username = username }


setPassword : String -> SignupForm -> SignupForm
setPassword password signup =
    { signup | password = password }



-- VIEW


view : SignupForm -> Html Message
view signupForm =
    div
        []
        [ h3
            []
            [ text "Sign up" ]
        , form
            [ Html.Events.onSubmit RegisterUserRequest
            ]
            [ label
                [ for "register-username" ]
                [ text "Username" ]
            , input
                [ id "register-username"
                , value signupForm.username
                , onInput SetSignupUsername
                ]
                []
            , label
                [ for "register-password" ]
                [ text "Password" ]
            , input
                [ id "register-password"
                , type_ "password"
                , value signupForm.password
                , onInput SetSignupPassword
                ]
                []
            , button
                [ type_ "submit"
                ]
                [ text "Sign up!" ]
            ]
        ]



-- ENCODE/DECODE


encoder : SignupForm -> Json.Encode.Value
encoder model =
    Json.Encode.object
        [ ( "username", Json.Encode.string model.username )
        , ( "password", Json.Encode.string model.password )
        ]



-- COMMANDS


signup : (Result Http.Error User -> message) -> SignupForm -> Cmd message
signup onResult model =
    let
        url =
            "/api/signup"

        request =
            Http.post url
                (Http.jsonBody
                    (encoder model)
                )
                User.decoder
    in
        request
            |> Http.send onResult
