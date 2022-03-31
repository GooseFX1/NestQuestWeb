port module Ports exposing (connect, connectResponse, disconnect, log, playTheme, stake, stakeResponse, stopTheme, withdraw, withdrawResponse)

import Types



-- OUT


port playTheme : () -> Cmd msg


port stopTheme : () -> Cmd msg


port log : String -> Cmd msg


port withdraw : String -> Cmd msg


port connect : Int -> Cmd msg


port disconnect : () -> Cmd msg


port stake : String -> Cmd msg



-- IN


port connectResponse : (Maybe Types.State -> msg) -> Sub msg


port stakeResponse : (Maybe Types.Stake -> msg) -> Sub msg


port withdrawResponse : (Maybe String -> msg) -> Sub msg
