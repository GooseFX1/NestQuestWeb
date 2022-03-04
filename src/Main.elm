module Main exposing (main)

import Browser
import Ports
import Types exposing (Flags, Model, Msg)
import Update exposing (update)
import View exposing (view)


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { isMobile = flags.screen.width < 1024
      , wallet = Nothing
      , themePlaying = False
      , scrollIndex = 0
      , walletSelect = False
      , dropdown = False
      , time = flags.now // 1000
      , scrollStart = flags.screen.height
      , incubationSuccess = Nothing
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    [ Ports.connectResponse Types.ConnectResponse
    , Ports.stakeResponse Types.StakeResponse
    ]
        |> Sub.batch
