module SelectableList
    exposing
        ( SelectableList
        , toList
        , fromList
        , select
        , deselect
        , getSelected
        )

import List.Extra


type SelectableList a
    = SelectableList
        { previous : List a
        , selected : Maybe a
        , next : List a
        }


toList : SelectableList a -> List a
toList (SelectableList { previous, selected, next }) =
    previous ++ Maybe.withDefault [] (Maybe.map (\s -> [ s ]) selected) ++ next


fromList : List a -> SelectableList a
fromList list =
    SelectableList
        { previous = list
        , selected = Nothing
        , next = []
        }


getSelected : SelectableList a -> Maybe a
getSelected (SelectableList { selected }) =
    selected


select : (a -> Bool) -> SelectableList a -> SelectableList a
select function selectableList =
    case findIndex function selectableList of
        Just index ->
            selectableList
                |> toList
                |> List.Extra.splitAt index
                |> (\( firstHalf, secondHalf ) ->
                        SelectableList
                            { previous = firstHalf
                            , selected = List.head secondHalf
                            , next =
                                List.tail secondHalf
                                    |> Maybe.withDefault []
                            }
                   )

        Nothing ->
            selectableList


deselect : SelectableList a -> SelectableList a
deselect selectableList =
    SelectableList
        { selected = Nothing
        , previous = toList selectableList
        , next = []
        }


find : (a -> Bool) -> SelectableList a -> Maybe a
find function selectableList =
    selectableList
        |> toList
        |> List.Extra.find function


findIndex : (a -> Bool) -> SelectableList a -> Maybe Int
findIndex function selectableList =
    selectableList
        |> toList
        |> List.Extra.findIndex function
