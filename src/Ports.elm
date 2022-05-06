port module Ports exposing (alreadyStaked, connect, connectResponse, disconnect, log, playTheme, signResponse, signTimestamp, stake, stakeResponse, stopTheme, withdraw, withdrawResponse)

import Types



-- OUT


port playTheme : () -> Cmd msg


port stopTheme : () -> Cmd msg


port log : String -> Cmd msg


port withdraw : String -> Cmd msg


port connect : Int -> Cmd msg


port disconnect : () -> Cmd msg


port signTimestamp : () -> Cmd msg


port stake : String -> Cmd msg



-- IN


port alreadyStaked : (String -> msg) -> Sub msg


port connectResponse : (Maybe Types.Wallet -> msg) -> Sub msg


port stakeResponse : (Maybe Types.Stake -> msg) -> Sub msg


port signResponse : ({ timestamp : Int, signature : String } -> msg) -> Sub msg


port withdrawResponse : (() -> msg) -> Sub msg
