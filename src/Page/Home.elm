module Page.Home
    exposing
        ( HomePage
        , init
        , getLoginForm
        , getSignupForm
        , setLoginUsername
        , setLoginPassword
        , setSignupUsername
        , setSignupPassword
        , view
        )

import Html exposing (Html)
import Html.Events
import Message exposing (Message(..))
import Login exposing (LoginForm)
import Signup exposing (SignupForm)
import User exposing (User)
import Route exposing (Route(..))


-- MODEL


type HomePage
    = HomePage HomePageData


type alias HomePageData =
    { signupForm : SignupForm
    , loginForm : LoginForm
    }


init : HomePage
init =
    HomePage
        { signupForm = Signup.init
        , loginForm = Login.init
        }


getLoginForm : HomePage -> LoginForm
getLoginForm (HomePage homePageData) =
    homePageData.loginForm


getSignupForm : HomePage -> SignupForm
getSignupForm (HomePage homePageData) =
    homePageData.signupForm



-- UPDATE


setLoginUsername : String -> HomePage -> HomePage
setLoginUsername username (HomePage homePageData) =
    HomePage
        { homePageData | loginForm = Login.setUsername username homePageData.loginForm }


setLoginPassword : String -> HomePage -> HomePage
setLoginPassword password (HomePage homePageData) =
    HomePage
        { homePageData | loginForm = Login.setPassword password homePageData.loginForm }


setSignupUsername : String -> HomePage -> HomePage
setSignupUsername username (HomePage homePageData) =
    HomePage
        { homePageData | signupForm = Signup.setUsername username homePageData.signupForm }


setSignupPassword : String -> HomePage -> HomePage
setSignupPassword password (HomePage homePageData) =
    HomePage
        { homePageData | signupForm = Signup.setPassword password homePageData.signupForm }



-- VIEW


view : Maybe User -> HomePage -> Html Message
view maybeUser (HomePage homePageData) =
    case maybeUser of
        Just user ->
            loggedInHomePage homePageData

        Nothing ->
            defaultHomePage homePageData


loggedInHomePage : HomePageData -> Html Message
loggedInHomePage homePageData =
    Html.div
        []
        [ Html.h3
            []
            [ Html.text "Go to:" ]
        , Html.ul
            []
            [ Html.li
                []
                [ Html.a
                    [ Html.Events.onClick (ChangeRoute <| Authorized Route.Decks) ]
                    [ Html.text "Decks" ]
                ]
            , Html.li
                []
                [ Html.a
                    [ Html.Events.onClick (ChangeRoute <| Authorized Route.Games) ]
                    [ Html.text "Games" ]
                ]
            ]
        ]


defaultHomePage : HomePageData -> Html Message
defaultHomePage homePageData =
    Html.div
        []
        [ homePageData.signupForm
            |> Signup.view
        , homePageData.loginForm
            |> Login.view
        ]
