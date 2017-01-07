module SelectableList
    exposing
        ( SelectableList
        , toList
        , fromList
        , select
        , deselect
        , getSelected
        , cons
        , updateIf
        , updateSelected
        , find
        , filter
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


cons : a -> SelectableList a -> SelectableList a
cons item (SelectableList selectableList) =
    SelectableList
        { selectableList | previous = item :: selectableList.previous }


updateIf : (a -> Bool) -> (a -> a) -> SelectableList a -> SelectableList a
updateIf condition update (SelectableList { previous, selected, next }) =
    SelectableList
        { previous = List.Extra.updateIf condition update previous
        , selected =
            Maybe.map
                (\s ->
                    if condition s then
                        update s
                    else
                        s
                )
                selected
        , next = List.Extra.updateIf condition update next
        }


updateSelected : (a -> a) -> SelectableList a -> SelectableList a
updateSelected update (SelectableList selectableList) =
    SelectableList
        { selectableList | selected = Maybe.map update selectableList.selected }


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


filter : (a -> Bool) -> SelectableList a -> SelectableList a
filter condition (SelectableList { previous, selected, next }) =
    SelectableList
        { previous = List.filter condition previous
        , selected =
            case selected of
                Just s ->
                    if condition s then
                        Just s
                    else
                        Nothing

                Nothing ->
                    Nothing
        , next = List.filter condition previous
        }
