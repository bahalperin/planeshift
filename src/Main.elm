module Main exposing (..)

import Html exposing (Html)
import Navigation
import List.Extra
import Return exposing (Return)
import Login
import Signup
import User exposing (User)
import Route exposing (Route(..), PublicRoute(..))
import Message exposing (Message(..), AnonymousMessage(..), LoggedInMessage(..))
import Card
import Deck exposing (Deck)
import Game exposing (Game)
import Page.Home exposing (HomePage)
import Page.Decks exposing (DecksPage)
import Page.Games
import Page.EditDeck exposing (EditDeckPage)
import Ports


main : Program Never Model Message
main =
    Navigation.program (HandleRouteChange << Route.fromLocation)
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type Model
    = Anonymous AnonymousModel
    | LoggedIn LoggedInModel


type alias AnonymousModel =
    { route : PublicRoute
    , homePage : HomePage
    }


type alias LoggedInModel =
    { user : User
    , route : Route
    , decks : Maybe (List Deck)
    , games : Maybe (List Game)
    , decksPage : DecksPage
    , editDeckPage : Maybe EditDeckPage
    }


init : Navigation.Location -> Return Message Model
init location =
    { route = Route.initialRoute location
    , homePage = Page.Home.init
    }
        |> Anonymous
        |> Return.singleton
        |> Return.command (User.fetchCurrentUser (Message.Anonymous << FetchUserResponse))


initLoggedInModel : User -> LoggedInModel
initLoggedInModel user =
    { user = user
    , route = Public Home
    , decks = Nothing
    , games = Nothing
    , decksPage = Page.Decks.init
    , editDeckPage = Nothing
    }



-- UPDATE


update : Message -> Model -> Return Message Model
update message model =
    case ( model, message ) of
        ( LoggedIn loggedInModel, Message.LoggedIn loggedInMessage ) ->
            updateLoggedIn loggedInMessage loggedInModel

        ( Anonymous anonymousModel, Message.Anonymous anonymousMessage ) ->
            updateAnonymous anonymousMessage anonymousModel

        ( LoggedIn loggedInModel, HandleRouteChange route ) ->
            { loggedInModel
                | route = route
                , editDeckPage =
                    case route of
                        Route.EditDeck deckId ->
                            Just <| Page.EditDeck.init deckId

                        _ ->
                            loggedInModel.editDeckPage
            }
                |> LoggedIn
                |> Return.singleton

        ( Anonymous anonymousModel, HandleRouteChange route ) ->
            case route of
                Public publicRoute ->
                    Return.singleton (Anonymous { anonymousModel | route = publicRoute })

                _ ->
                    Return.return model (Route.goTo (Public Home))

        ( _, NoOp ) ->
            Return.singleton model

        -- TODO: These situations should never happen.  Find a
        -- way to get rid of these.
        ( LoggedIn _, Message.Anonymous _ ) ->
            Return.singleton model

        ( Anonymous _, Message.LoggedIn _ ) ->
            Return.singleton model


updateAnonymous : AnonymousMessage -> AnonymousModel -> Return Message Model
updateAnonymous message model =
    case message of
        ChangePublicRoute route ->
            Return.return model (Route.goTo (Public route))
                |> Return.map Anonymous

        FetchUserRequest ->
            model
                |> Return.singleton
                |> Return.command (User.fetchCurrentUser (Message.Anonymous << FetchUserResponse))
                |> Return.map Anonymous

        FetchUserResponse result ->
            result
                |> Result.map
                    (\user ->
                        initLoggedInModel user
                            |> Return.singleton
                            |> Return.map LoggedIn
                            |> Return.command (Deck.fetchDecks (Message.LoggedIn << FetchDecksResponse))
                            |> Return.command (Game.fetchGames (Message.LoggedIn << FetchGamesResponse))
                    )
                |> Result.withDefault
                    (Return.return model (Route.goTo (Public Home))
                        |> Return.map Anonymous
                    )

        RegisterUserRequest ->
            Return.singleton model
                |> Return.map Anonymous
                |> Return.command (Signup.signup (Message.Anonymous << RegisterUserResponse) (Page.Home.getSignupForm model.homePage))

        RegisterUserResponse result ->
            Return.singleton model
                |> Return.map
                    (\model ->
                        result
                            |> Result.map (LoggedIn << initLoggedInModel)
                            |> Result.withDefault (Anonymous model)
                    )

        SetSignupUsername username ->
            Return.singleton { model | homePage = Page.Home.setSignupUsername username model.homePage }
                |> Return.map Anonymous

        SetSignupPassword password ->
            Return.singleton { model | homePage = Page.Home.setSignupPassword password model.homePage }
                |> Return.map Anonymous

        SetLoginUsername username ->
            Return.singleton { model | homePage = Page.Home.setLoginUsername username model.homePage }
                |> Return.map Anonymous

        SetLoginPassword password ->
            Return.singleton { model | homePage = Page.Home.setLoginPassword password model.homePage }
                |> Return.map Anonymous

        LoginRequest ->
            Return.singleton model
                |> Return.map Anonymous
                |> Return.command (Login.login (Message.Anonymous << LoginResponse) (Page.Home.getLoginForm model.homePage))

        LoginResponse result ->
            result
                |> Result.map
                    (\user ->
                        initLoggedInModel user
                            |> Return.singleton
                            |> Return.map LoggedIn
                            |> Return.command (Deck.fetchDecks (Message.LoggedIn << FetchDecksResponse))
                            |> Return.command (Game.fetchGames (Message.LoggedIn << FetchGamesResponse))
                    )
                |> Result.withDefault
                    (Return.return model (Route.goTo (Public Home))
                        |> Return.map Anonymous
                    )


updateLoggedIn : LoggedInMessage -> LoggedInModel -> Return Message Model
updateLoggedIn message model =
    (case message of
        ChangeRoute route ->
            Return.return model (Route.goTo route)

        SetCardSearchQuery query ->
            Return.singleton model
                |> Return.map
                    (\model ->
                        model.editDeckPage
                            |> Maybe.map (\editDeckPage -> { model | editDeckPage = Just <| Page.EditDeck.setCardSearchQuery query editDeckPage })
                            |> Maybe.withDefault model
                    )

        SearchForCardsRequest ->
            { model
                | editDeckPage =
                    Maybe.map Page.EditDeck.startSearchingForCards model.editDeckPage
            }
                |> Return.singleton
                |> Return.effect_
                    (\{ editDeckPage } ->
                        editDeckPage
                            |> Maybe.map (Page.EditDeck.getCardSearchQuery >> Card.getCardsByName SearchForCardsResponse)
                            |> Maybe.withDefault Cmd.none
                    )

        SearchForCardsResponse result ->
            Return.singleton model
                |> Return.map
                    (\model ->
                        case ( model.editDeckPage, result ) of
                            ( Just editDeckPage, Ok cards ) ->
                                { model | editDeckPage = Just <| Page.EditDeck.setCardSearchResults cards editDeckPage }

                            _ ->
                                model
                    )

        SelectMtgCard card ->
            Return.singleton model
                |> Return.map
                    (\model ->
                        model.editDeckPage
                            |> Maybe.map
                                (\editDeckPage ->
                                    { model
                                        | editDeckPage =
                                            editDeckPage
                                                |> Page.EditDeck.setSelectedCard (Card.getId card)
                                                |> Just
                                    }
                                )
                            |> Maybe.withDefault model
                    )

        SetAddNewDeckName name ->
            Return.singleton { model | decksPage = Page.Decks.setNewDeckName name model.decksPage }

        AddDeckRequest ->
            { model | decksPage = Page.Decks.setNewDeckName "" model.decksPage }
                |> Return.singleton
                |> Return.command
                    (model.decksPage
                        |> Page.Decks.getNewDeckName
                        |> Deck.addDeck AddDeckResponse
                    )

        AddDeckResponse result ->
            let
                allDecks =
                    model.decks
                        |> Maybe.withDefault []
            in
                result
                    |> Result.map
                        (\deck ->
                            { model | editDeckPage = Just <| Page.EditDeck.init (Deck.getId deck), decks = Just (deck :: allDecks) }
                                |> Return.singleton
                                |> Return.command (Route.goTo (Route.EditDeck (Deck.getId deck)))
                        )
                    |> Result.withDefault (Return.singleton model)

        FetchDecksResponse result ->
            Return.singleton model
                |> Return.map
                    (\model ->
                        result
                            |> Result.map
                                (\decks ->
                                    { model | decks = Just decks }
                                )
                            |> Result.withDefault model
                    )

        AddCardToMainDeck deckId card ->
            Return.singleton
                { model
                    | decks =
                        model.decks
                            |> Maybe.map (List.Extra.updateIf (\deck -> Deck.getId deck == deckId) (Deck.addCardToMainDeck card))
                }

        RemoveCardFromMainDeck deckId card ->
            Return.singleton
                { model
                    | decks =
                        model.decks
                            |> Maybe.map
                                (List.Extra.updateIf (\deck -> Deck.getId deck == deckId) (Deck.removeCardFromMainDeck card))
                }

        AddCardToSideboard deckId card ->
            Return.singleton
                { model
                    | decks =
                        model.decks
                            |> Maybe.map
                                (List.Extra.updateIf (\deck -> Deck.getId deck == deckId) (Deck.addCardToSideboard card))
                }

        RemoveCardFromSideboard deckId card ->
            Return.singleton
                { model
                    | decks =
                        model.decks
                            |> Maybe.map
                                (List.Extra.updateIf (\deck -> Deck.getId deck == deckId) (Deck.removeCardFromSideboard card))
                }

        SaveDeckRequest deckId ->
            let
                maybeDeck =
                    model.decks
                        |> Maybe.withDefault []
                        |> List.filter (\d -> Deck.getId d == deckId)
                        |> List.head
            in
                model
                    |> Return.singleton
                    |> Return.command
                        (maybeDeck
                            |> Maybe.map (Deck.saveDeck SaveDeckResponse)
                            |> Maybe.withDefault Cmd.none
                        )

        SaveDeckResponse result ->
            Return.singleton model

        DeleteDeckRequest deckId ->
            let
                updatedDecks =
                    model.decks
                        |> Maybe.withDefault []
                        |> List.filter (\d -> Deck.getId d /= deckId)
            in
                Return.singleton { model | decks = Just updatedDecks }
                    |> Return.command (Deck.deleteDeck DeleteDeckResponse deckId)

        DeleteDeckResponse result ->
            Return.singleton model

        JoinGame playerName gameId ->
            { model
                | games =
                    model.games
                        |> Maybe.map
                            (\games ->
                                List.Extra.updateIf (\game -> Game.getId game == gameId) (Game.addPlayer playerName) games
                            )
            }
                |> Return.singleton
                |> Return.command (Navigation.newUrl (Route.toUrl (Route.PlayGame gameId)))
                |> Return.command (Ports.broadcastGameJoined { username = playerName, gameId = gameId })

        HandleGameJoined playerName gameId ->
            { model
                | games =
                    model.games
                        |> Maybe.map
                            (\games ->
                                List.Extra.updateIf (\game -> Game.getId game == gameId) (Game.addPlayer playerName) games
                            )
            }
                |> Return.singleton

        FetchGamesRequest ->
            Return.return model (Game.fetchGames FetchGamesResponse)

        FetchGamesResponse result ->
            Return.singleton model
                |> Return.map
                    (\model ->
                        result
                            |> Result.map (\games -> { model | games = Just games })
                            |> Result.withDefault model
                    )
    )
        |> Return.mapBoth Message.LoggedIn LoggedIn



-- VIEW


view : Model -> Html Message
view model =
    case model of
        Anonymous data ->
            case data.route of
                Home ->
                    Page.Home.defaultView data.homePage

                NotFound url ->
                    Html.div
                        []
                        [ Html.text ("Not Found: " ++ url)
                        ]

        LoggedIn data ->
            case data.route of
                Public Home ->
                    Page.Home.loggedInView data.user

                Route.Decks ->
                    let
                        decks =
                            Maybe.withDefault [] data.decks
                    in
                        data.decksPage
                            |> Page.Decks.view decks
                            |> layout model

                Route.EditDeck deckId ->
                    let
                        decks =
                            Maybe.withDefault [] data.decks
                    in
                        data.editDeckPage
                            |> Maybe.map (Page.EditDeck.view decks)
                            |> Maybe.map (layout model)
                            |> Maybe.withDefault
                                (Html.text "No deck is currently being edited")

                Route.Games ->
                    data.games
                        |> Maybe.withDefault []
                        |> Page.Games.view data.user
                        |> layout model

                Route.PlayGame gameId ->
                    Html.text gameId

                Public (NotFound url) ->
                    Html.div
                        []
                        [ Html.text ("Not Found: " ++ url)
                        ]


layout : Model -> Html Message -> Html Message
layout model content =
    let
        username =
            case model of
                Anonymous _ ->
                    "log in"

                LoggedIn data ->
                    User.getUsername data.user
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Message
subscriptions model =
    Sub.batch
        [ Ports.handleGameJoined (\{ username, gameId } -> Message.LoggedIn <| HandleGameJoined username gameId)
        ]
