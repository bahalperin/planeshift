module Main exposing (..)

import Html exposing (Html)
import Navigation
import List.Extra
import Return exposing (Return)
import Login
import Signup
import User exposing (User)
import Route exposing (Route(..))
import Message exposing (Message(..))
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


type alias Model =
    { user : Maybe User
    , route : Route
    , decks : Maybe (List Deck)
    , games : Maybe (List Game)
    , homePage : HomePage
    , decksPage : DecksPage
    , editDeckPage : Maybe EditDeckPage
    }


init : Navigation.Location -> Return Message Model
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
        { user = Nothing
        , route = route
        , decks = Nothing
        , games = Nothing
        , homePage = Page.Home.init
        , decksPage = Page.Decks.init
        , editDeckPage = editDeckPage
        }
            |> Return.singleton
            |> Return.command (User.fetchCurrentUser FetchUserResponse)



-- UPDATE


update : Message -> Model -> Return Message Model
update message model =
    case message of
        ChangeRoute route ->
            Return.return model (Route.goTo route)

        HandleRouteChange route ->
            Return.singleton { model | route = route }
                |> Return.map
                    (\model ->
                        case ( model.user, route ) of
                            ( Just user, Authorized (Route.EditDeck deckId) ) ->
                                { model | editDeckPage = Just <| Page.EditDeck.init deckId }

                            _ ->
                                model
                    )
                |> Return.effect_
                    (\model ->
                        case ( model.user, route ) of
                            ( Nothing, Authorized _ ) ->
                                Route.goTo Home

                            _ ->
                                Cmd.none
                    )

        FetchUserRequest ->
            model
                |> Return.singleton
                |> Return.command (User.fetchCurrentUser FetchUserResponse)

        FetchUserResponse result ->
            result
                |> Result.map
                    (\user ->
                        Return.singleton { model | user = Just user }
                            |> Return.command (Deck.fetchDecks FetchDecksResponse)
                            |> Return.command (Game.fetchGames FetchGamesResponse)
                    )
                |> Result.withDefault (Return.return model (Route.goTo Home))

        SetCardSearchQuery query ->
            Return.singleton model
                |> Return.map
                    (\model ->
                        model.editDeckPage
                            |> Maybe.map (\editDeckPage -> { model | editDeckPage = Just <| Page.EditDeck.setCardSearchQuery query editDeckPage })
                            |> Maybe.withDefault model
                    )

        SearchForCardsRequest ->
            Return.singleton model
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
                                |> Return.command (Route.goTo (Authorized <| Route.EditDeck (Deck.getId deck)))
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

        RegisterUserRequest ->
            Return.singleton model
                |> Return.command (Signup.signup RegisterUserResponse (Page.Home.getSignupForm model.homePage))

        RegisterUserResponse result ->
            Return.singleton model
                |> Return.map
                    (\model ->
                        result
                            |> Result.map
                                (\user ->
                                    { model | user = Just user }
                                )
                            |> Result.withDefault model
                    )

        SetSignupUsername username ->
            Return.singleton { model | homePage = Page.Home.setSignupUsername username model.homePage }

        SetSignupPassword password ->
            Return.singleton { model | homePage = Page.Home.setSignupPassword password model.homePage }

        SetLoginUsername username ->
            Return.singleton { model | homePage = Page.Home.setLoginUsername username model.homePage }

        SetLoginPassword password ->
            Return.singleton { model | homePage = Page.Home.setLoginPassword password model.homePage }

        LoginRequest ->
            Return.singleton model
                |> Return.command (Login.login LoginResponse (Page.Home.getLoginForm model.homePage))

        LoginResponse result ->
            result
                |> Result.map
                    (\user ->
                        Return.singleton { model | user = Just user }
                            |> Return.command (Deck.fetchDecks FetchDecksResponse)
                            |> Return.command (Game.fetchGames FetchGamesResponse)
                    )
                |> Result.withDefault (Return.return model (Route.goTo Home))

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
                |> Return.command (Navigation.newUrl (Route.toUrl (Authorized <| Route.PlayGame gameId)))
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

        NoOp ->
            Return.singleton model



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

                Route.Games ->
                    model.games
                        |> Maybe.withDefault []
                        |> Page.Games.view model.user
                        |> layout model

                Route.PlayGame gameId ->
                    Html.text gameId

        NotFound url ->
            Html.div
                []
                [ Html.text ("Not Found: " ++ url)
                ]


layout : Model -> Html Message -> Html Message
layout model content =
    let
        username =
            model.user
                |> Maybe.map User.getUsername
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Message
subscriptions model =
    Sub.batch
        [ Ports.handleGameJoined (\{ username, gameId } -> HandleGameJoined username gameId)
        ]
