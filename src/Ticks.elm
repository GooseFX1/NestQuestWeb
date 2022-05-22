module Ticks exposing (Ticks, empty, flip, get, member, set, tick, untick)

import Dict exposing (Dict)


type Ticks
    = Ticks (Dict Int Bool)


empty : Ticks
empty =
    Ticks Dict.empty


tick : Int -> Ticks -> Ticks
tick n =
    set n True


untick : Int -> Ticks -> Ticks
untick n =
    set n False


get : Int -> Ticks -> Bool
get n (Ticks xs) =
    Dict.get n xs
        |> Maybe.withDefault False


member : Int -> Ticks -> Bool
member n (Ticks xs) =
    Dict.member n xs


set : Int -> Bool -> Ticks -> Ticks
set n b (Ticks xs) =
    Dict.insert n b xs
        |> Ticks


flip : Int -> Ticks -> Ticks
flip n xs =
    set n
        (if member n xs then
            not (get n xs)

         else
            True
        )
        xs
