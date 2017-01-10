module Main exposing (..)

import Html exposing (Html)
import Navigation
import Return exposing (Return)
import Login
import Signup
import User exposing (User)
import Route exposing (Route(..), PublicRoute(..))
import Message exposing (Message(..), AnonymousMessage(..), LoggedInMessage(..))
import Card
import Deck exposing (Deck)
import Decks exposing (Decks)
import Page.Home exposing (HomePage)
import Page.Decks exposing (DecksPage)
import Ports
import SelectableList
import Games exposing (Games)


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
    , decks : Maybe Decks
    , games : Maybe Games
    , decksPage : DecksPage
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
                , decks =
                    case route of
                        Route.EditDeck deckId ->
                            Maybe.map (SelectableList.select (\{ deck } -> Deck.getId deck == deckId)) loggedInModel.decks

                        _ ->
                            loggedInModel.decks
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
                            |> Return.command (Games.fetchGames (Message.LoggedIn << FetchGamesResponse))
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
                            |> Return.command (Games.fetchGames (Message.LoggedIn << FetchGamesResponse))
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
                        model.decks
                            |> Maybe.map (\decks -> { model | decks = Just <| Decks.setCardSearchQuery query decks })
                            |> Maybe.withDefault model
                    )

        SearchForCardsRequest ->
            { model
                | decks =
                    Maybe.map Decks.startSearchingForCards model.decks
            }
                |> Return.singleton
                |> Return.effect_
                    (\{ decks } ->
                        decks
                            |> Maybe.map (Decks.getCardSearchQuery >> Card.getCardsByName SearchForCardsResponse)
                            |> Maybe.withDefault Cmd.none
                    )

        SearchForCardsResponse result ->
            Return.singleton model
                |> Return.map
                    (\model ->
                        case ( model.decks, result ) of
                            ( Just decks, Ok cards ) ->
                                { model | decks = Just <| Decks.setCardSearchResults cards decks }

                            _ ->
                                model
                    )

        SelectMtgCard card ->
            Return.singleton model
                |> Return.map
                    (\model ->
                        model.decks
                            |> Maybe.map
                                (\decks ->
                                    { model
                                        | decks =
                                            decks
                                                |> Decks.setSelectedCard (Card.getId card)
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
            result
                |> Result.map
                    (\deck ->
                        { model | decks = Maybe.map (SelectableList.cons { deck = deck, editPage = Decks.initEditDeckPage }) model.decks }
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
                                    { model
                                        | decks =
                                            decks
                                                |> List.map (\deck -> { deck = deck, editPage = Decks.initEditDeckPage })
                                                |> SelectableList.fromList
                                                |> Just
                                    }
                                )
                            |> Result.withDefault model
                    )

        AddCardToMainDeck deckId card ->
            Return.singleton
                { model
                    | decks =
                        model.decks
                            |> Maybe.map
                                (SelectableList.updateIf (\deckData -> Deck.getId deckData.deck == deckId) (\deckData -> { deckData | deck = Deck.addCardToMainDeck card deckData.deck }))
                }

        RemoveCardFromMainDeck deckId card ->
            Return.singleton
                { model
                    | decks =
                        model.decks
                            |> Maybe.map
                                (SelectableList.updateIf (\deckData -> Deck.getId deckData.deck == deckId) (\deckData -> { deckData | deck = Deck.removeCardFromMainDeck card deckData.deck }))
                }

        AddCardToSideboard deckId card ->
            Return.singleton
                { model
                    | decks =
                        model.decks
                            |> Maybe.map
                                (SelectableList.updateIf (\deckData -> Deck.getId deckData.deck == deckId) (\deckData -> { deckData | deck = Deck.addCardToSideboard card deckData.deck }))
                }

        RemoveCardFromSideboard deckId card ->
            Return.singleton
                { model
                    | decks =
                        model.decks
                            |> Maybe.map
                                (SelectableList.updateIf (\deckData -> Deck.getId deckData.deck == deckId) (\deckData -> { deckData | deck = Deck.removeCardFromSideboard card deckData.deck }))
                }

        SaveDeckRequest deck ->
            model
                |> Return.singleton
                |> Return.command
                    (deck
                        |> Deck.saveDeck SaveDeckResponse
                    )

        SaveDeckResponse result ->
            Return.singleton model

        DeleteDeckRequest deckId ->
            let
                updatedDecks =
                    model.decks
                        |> Maybe.map (SelectableList.filter (\deckData -> Deck.getId deckData.deck /= deckId))
            in
                Return.singleton { model | decks = updatedDecks }
                    |> Return.command (Deck.deleteDeck DeleteDeckResponse deckId)

        DeleteDeckResponse result ->
            Return.singleton model

        JoinGame playerName gameId ->
            { model
                | games = Maybe.map (Games.joinGame gameId playerName) model.games
            }
                |> Return.singleton
                |> Return.command (Navigation.newUrl (Route.toUrl (Route.PlayGame gameId)))
                |> Return.command (Ports.broadcastGameJoined { username = playerName, gameId = gameId })

        HandleGameJoined playerName gameId ->
            { model
                | games = Maybe.map (Games.joinGame gameId playerName) model.games
            }
                |> Return.singleton

        FetchGamesRequest ->
            Return.return model (Games.fetchGames FetchGamesResponse)

        FetchGamesResponse result ->
            Return.singleton model
                |> Return.map
                    (\model ->
                        result
                            |> Result.map (\games -> { model | games = Just <| Games.fromList games })
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
                            data.decks
                                |> Maybe.map (\decks -> decks |> SelectableList.toList |> List.map .deck)
                                |> Maybe.withDefault []
                    in
                        data.decksPage
                            |> Page.Decks.view decks
                            |> layout model

                Route.EditDeck deckId ->
                    data.decks
                        |> Maybe.map Decks.view
                        |> Maybe.withDefault
                            (Html.text "No deck is currently being edited")

                Route.Games ->
                    data.games
                        |> Maybe.map
                            (\games ->
                                games
                                    |> (Games.view (\username gameId -> Message.LoggedIn <| JoinGame username gameId) data.user)
                                    |> layout model
                            )
                        |> Maybe.withDefault (Html.span [] [])

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
