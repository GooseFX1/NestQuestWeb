module Update exposing (update)

import Ports
import Types exposing (Model, Msg(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Connect ->
            ( model, Ports.connect () )

        ConnectResponse val ->
            ( { model | wallet = val }, Cmd.none )
