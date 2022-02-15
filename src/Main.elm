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
init model =
    ( { isMobile = model.screen.width < 688
      , wallet = Nothing
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    [ Ports.connectResponse Types.ConnectResponse
    ]
        |> Sub.batch
