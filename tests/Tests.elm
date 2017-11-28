module Tests exposing (..)

import Bulb exposing (..)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)


suite : Test
suite =
    describe "The Bulb module"
        [ describe "getBulbCommand"
            [ describe "State off"
                [ test "returns the correct command" <|
                    \_ ->
                        Off
                            |> getBulbCommand
                            |> Expect.equal [ 0x56, 0, 0, 0, 0x00, 0xF0, 0xAA ]
                ]
            , describe "State red color"
                [ test "returns the correct command" <|
                    \_ ->
                        On Red
                            |> getBulbCommand
                            |> Expect.equal [ 0x56, 0xFF, 0, 0, 0x00, 0xF0, 0xAA ]
                ]
            ]
        ]
