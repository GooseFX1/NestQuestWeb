port module Ports exposing (connect, connectResponse, disconnect, log)

import Types



-- OUT


port log : String -> Cmd msg


port connect : () -> Cmd msg


port disconnect : () -> Cmd msg



-- IN


port connectResponse : (Maybe Types.State -> msg) -> Sub msg
