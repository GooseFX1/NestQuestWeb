port module Ports exposing (connect, connectResponse, disconnect, log)

-- OUT


port log : String -> Cmd msg


port connect : () -> Cmd msg


port disconnect : () -> Cmd msg



-- IN


port connectResponse : (Maybe String -> msg) -> Sub msg
