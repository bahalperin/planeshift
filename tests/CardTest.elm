module CardTest exposing (all)

import List.Extra
import Expect
import Fuzz exposing (Fuzzer)
import Test exposing (Test, describe)
import Card exposing (Card)


all : Test
all =
    describe "Card"
        [ groupByName
        ]


groupByName : Test
groupByName =
    describe "groupByName"
        [ Test.fuzz fuzzer "Should have same number of elements as unique list of card names" <|
            \cards ->
                Expect.equal
                    (cards
                        |> Card.groupByName
                        |> List.length
                    )
                    (cards
                        |> List.map Card.getName
                        |> List.Extra.unique
                        |> List.length
                    )
        ]


fuzzer : Fuzzer (List Card)
fuzzer =
    Fuzz.map2 Card.new Fuzz.int Fuzz.string
        |> Fuzz.list
