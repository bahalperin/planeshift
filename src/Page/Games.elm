module Page.Games exposing (view)

import Game exposing (Game)
import Message exposing (Message(..))
import User exposing (User)
import Html
    exposing
        ( Html
        , ul
        , li
        , text
        , table
        , tr
        , th
        , td
        , button
        )
import Html.Attributes
import Html.Events


view : User -> List Game -> Html Message
view user games =
    let
        username =
            user
                |> User.getUsername
                |> Maybe.withDefault ""
    in
        table
            []
            (List.append
                [ tr
                    []
                    [ th [] [ text "Game" ]
                    , th [] [ text "Players" ]
                    ]
                ]
                (games
                    |> List.sortBy (Game.getName >> String.toLower)
                    |> List.map
                        (\game ->
                            tr
                                []
                                [ td [] [ text (Game.getName game) ]
                                , td [] [ text <| (Game.getPlayers game |> List.length |> toString) ++ "/" ++ (Game.getMaxPlayers game |> toString) ]
                                , td
                                    []
                                    [ button
                                        [ Html.Events.onClick (JoinGame username (Game.getId game))
                                        , Html.Attributes.disabled (Game.getMaxPlayers game == (List.length <| Game.getPlayers game))
                                        ]
                                        [ Html.text "Join Game" ]
                                    ]
                                ]
                        )
                )
            )
