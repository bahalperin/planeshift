module Main exposing (..)

import Html exposing (Html)
import Navigation
import Login
import Signup
import User exposing (User)
import Route exposing (Route(..))
import Message exposing (Message(..))
import Card
import Deck exposing (Deck)
import Page.Home exposing (HomePage)
import Page.Decks exposing (DecksPage)
import Page.EditDeck exposing (EditDeckPage)


main : Program Never Model Message
main =
    Navigation.program (HandleRouteChange << Route.fromLocation)
        { init = init
        , view = view
        , update = update
        , subscriptions = (\_ -> Sub.none)
        }



-- MODEL


type alias Model =
    { user : User
    , route : Route
    , decks : Maybe (List Deck)
    , homePage : HomePage
    , decksPage : DecksPage
    , editDeckPage : Maybe EditDeckPage
    }


init : Navigation.Location -> ( Model, Cmd Message )
init location =
    let
        route =
            Route.fromLocation location

        editDeckPage =
            case route of
                Authorized (Route.EditDeck deckId) ->
                    Just <| Page.EditDeck.init deckId

                _ ->
                    Nothing
    in
        ( { user = User.anonymous
          , route = route
          , decks = Nothing
          , homePage = Page.Home.init
          , decksPage = Page.Decks.init
          , editDeckPage = editDeckPage
          }
        , User.fetchCurrentUser FetchUserResponse
        )



-- UPDATE


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    case message of
        ChangeRoute route ->
            ( model, Route.goTo route )

        HandleRouteChange route ->
            if User.isRegistered model.user then
                case route of
                    Authorized (Route.EditDeck deckId) ->
                        ( { model | route = route, editDeckPage = Just <| Page.EditDeck.init deckId }, Cmd.none )

                    _ ->
                        ( { model | route = route }, Cmd.none )
            else
                case route of
                    Authorized _ ->
                        ( model, Route.goTo Home )

                    _ ->
                        ( { model | route = route }, Cmd.none )

        FetchUserRequest ->
            ( model, User.fetchCurrentUser FetchUserResponse )

        FetchUserResponse result ->
            result
                |> Result.map
                    (\user ->
                        ( { model | user = user }
                        , Cmd.batch
                            [ Deck.fetchDecks FetchDecksResponse
                            ]
                        )
                    )
                |> Result.withDefault ( model, Route.goTo Home )

        SetCardSearchQuery query ->
            model.editDeckPage
                |> Maybe.map
                    (\editDeckPage ->
                        ( { model | editDeckPage = Just <| Page.EditDeck.setCardSearchQuery query editDeckPage }, Cmd.none )
                    )
                |> Maybe.withDefault ( model, Cmd.none )

        SearchForCardsRequest ->
            model.editDeckPage
                |> Maybe.map
                    (\editDeckPage ->
                        ( model
                        , editDeckPage
                            |> Page.EditDeck.getCardSearchQuery
                            |> Card.getCardsByName SearchForCardsResponse
                        )
                    )
                |> Maybe.withDefault ( model, Cmd.none )

        SearchForCardsResponse result ->
            case result of
                Ok cards ->
                    model.editDeckPage
                        |> Maybe.map
                            (\editDeckPage ->
                                ( { model | editDeckPage = Just <| Page.EditDeck.setCardSearchResults cards editDeckPage }, Cmd.none )
                            )
                        |> Maybe.withDefault ( model, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        SelectMtgCard card ->
            model.editDeckPage
                |> Maybe.map
                    (\editDeckPage ->
                        ( { model
                            | editDeckPage =
                                editDeckPage
                                    |> Page.EditDeck.setSelectedCard (Card.id card)
                                    |> Just
                          }
                        , Cmd.none
                        )
                    )
                |> Maybe.withDefault ( model, Cmd.none )

        SetAddNewDeckName name ->
            ( { model | decksPage = Page.Decks.setNewDeckName name model.decksPage }, Cmd.none )

        AddDeckRequest ->
            ( { model | decksPage = Page.Decks.setNewDeckName "" model.decksPage }
            , model.decksPage
                |> Page.Decks.getNewDeckName
                |> Deck.addDeck AddDeckResponse
            )

        AddDeckResponse result ->
            case result of
                Ok deck ->
                    let
                        allDecks =
                            model.decks
                                |> Maybe.withDefault []
                    in
                        ( { model | editDeckPage = Just <| Page.EditDeck.init (Deck.getId deck), decks = Just (deck :: allDecks) }, Route.goTo (Authorized <| Route.EditDeck (Deck.getId deck)) )

                Err _ ->
                    ( model, Cmd.none )

        FetchDecksResponse result ->
            result
                |> Result.map
                    (\decks ->
                        ( { model | decks = Just decks }, Cmd.none )
                    )
                |> Result.withDefault ( model, Cmd.none )

        RegisterUserRequest ->
            ( model, Signup.signup RegisterUserResponse (Page.Home.getSignupForm model.homePage) )

        RegisterUserResponse result ->
            result
                |> Result.map
                    (\username ->
                        ( { model | user = User.fromUsername username }, Cmd.none )
                    )
                |> Result.withDefault ( model, Cmd.none )

        SetSignupUsername username ->
            ( { model | homePage = Page.Home.setSignupUsername username model.homePage }, Cmd.none )

        SetSignupPassword password ->
            ( { model | homePage = Page.Home.setSignupPassword password model.homePage }, Cmd.none )

        SetLoginUsername username ->
            ( { model | homePage = Page.Home.setLoginUsername username model.homePage }, Cmd.none )

        SetLoginPassword password ->
            ( { model | homePage = Page.Home.setLoginPassword password model.homePage }, Cmd.none )

        LoginRequest ->
            ( model, Login.login LoginResponse (Page.Home.getLoginForm model.homePage) )

        LoginResponse result ->
            result
                |> Result.map
                    (\username ->
                        ( { model | user = User.fromUsername username }
                        , Cmd.batch
                            [ Deck.fetchDecks FetchDecksResponse
                            ]
                        )
                    )
                |> Result.withDefault ( model, Cmd.none )

        AddCardToMainDeck deckId card ->
            ( { model
                | decks =
                    model.decks
                        |> Maybe.map
                            (List.map
                                (\d ->
                                    if Deck.getId d == deckId then
                                        Deck.addCardToMainDeck card d
                                    else
                                        d
                                )
                            )
              }
            , Cmd.none
            )

        RemoveCardFromMainDeck deckId card ->
            ( { model
                | decks =
                    model.decks
                        |> Maybe.map
                            (List.map
                                (\d ->
                                    if Deck.getId d == deckId then
                                        Deck.removeCardFromMainDeck card d
                                    else
                                        d
                                )
                            )
              }
            , Cmd.none
            )

        AddCardToSideboard deckId card ->
            ( { model
                | decks =
                    model.decks
                        |> Maybe.map
                            (List.map
                                (\d ->
                                    if Deck.getId d == deckId then
                                        Deck.addCardToSideboard card d
                                    else
                                        d
                                )
                            )
              }
            , Cmd.none
            )

        RemoveCardFromSideboard deckId card ->
            ( { model
                | decks =
                    model.decks
                        |> Maybe.map
                            (List.map
                                (\d ->
                                    if Deck.getId d == deckId then
                                        Deck.removeCardFromSideboard card d
                                    else
                                        d
                                )
                            )
              }
            , Cmd.none
            )

        SaveDeckRequest deckId ->
            let
                maybeDeck =
                    model.decks
                        |> Maybe.withDefault []
                        |> List.filter (\d -> Deck.getId d == deckId)
                        |> List.head
            in
                case maybeDeck of
                    Just deck ->
                        ( model, Deck.saveDeck SaveDeckResponse deck )

                    Nothing ->
                        ( model, Cmd.none )

        SaveDeckResponse result ->
            ( model, Cmd.none )

        DeleteDeckRequest deckId ->
            let
                updatedDecks =
                    model.decks
                        |> Maybe.withDefault []
                        |> List.filter (\d -> Deck.getId d /= deckId)
            in
                ( { model | decks = Just updatedDecks }, Deck.deleteDeck DeleteDeckResponse deckId )

        DeleteDeckResponse result ->
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Message
view model =
    case model.route of
        Home ->
            Page.Home.view model.user model.homePage

        Authorized authorizedRoute ->
            case authorizedRoute of
                Route.Decks ->
                    let
                        decks =
                            Maybe.withDefault [] model.decks
                    in
                        model.decksPage
                            |> Page.Decks.view decks
                            |> layout model

                Route.EditDeck deckId ->
                    let
                        decks =
                            Maybe.withDefault [] model.decks
                    in
                        model.editDeckPage
                            |> Maybe.map (Page.EditDeck.view decks)
                            |> Maybe.map (layout model)
                            |> Maybe.withDefault
                                (Html.text "No deck is currently being edited")

        NotFound url ->
            Html.div
                []
                [ Html.text ("Not Found: " ++ url)
                ]


layout : Model -> Html Message -> Html Message
layout model content =
    let
        username =
            User.getUsername model.user
                |> Maybe.withDefault "log in"
    in
        Html.div
            []
            [ Html.nav
                []
                [ Html.div
                    []
                    [ Html.span
                        []
                        [ Html.text username ]
                    ]
                ]
            , content
            ]
