port module Ports exposing (connect, connectResponse, disconnect, log, playTheme, stake, stopTheme)

import Types



-- OUT


port playTheme : () -> Cmd msg


port stopTheme : () -> Cmd msg


port log : String -> Cmd msg


port connect : () -> Cmd msg


port disconnect : () -> Cmd msg


port stake : String -> Cmd msg



-- IN


port connectResponse : (Maybe Types.State -> msg) -> Sub msg