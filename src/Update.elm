module Update exposing (update)

import Maybe.Extra exposing (unwrap)
import Ports
import Types exposing (Model, Msg(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Connect ->
            ( model, Ports.connect () )

        ConnectResponse val ->
            ( { model | wallet = val }, Cmd.none )

        PlayTheme ->
            if model.themePlaying then
                ( { model | themePlaying = False }
                , Ports.stopTheme ()
                )

            else
                ( { model | themePlaying = True }
                , Ports.playTheme ()
                )

        Stake ->
            ( model
            , model.wallet
                |> Maybe.andThen
                    (.nfts >> List.head)
                |> unwrap Cmd.none Ports.stake
            )
