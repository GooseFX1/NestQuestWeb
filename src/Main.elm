module Main exposing (main)

import Browser
import InteropDefinitions exposing (Flags, ToElm(..))
import InteropPorts
import Result.Extra exposing (unpack)
import Ticks
import Time
import Types exposing (Model, Msg)
import Update exposing (update)
import View exposing (view)


main : Program InteropDefinitions.Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { isMobile = flags.screen.width < 1410
      , wallet = Nothing
      , themePlaying = False
      , scrollIndex = 0
      , walletSelect = False
      , dropdown = False
      , time = flags.now // 1000
      , scrollStart = flags.screen.height
      , playButtonPulse = True
      , nftIndex = 0
      , ticks = Ticks.empty
      , selected = Nothing
      , tentOpen = False
      , prizeStatus = Types.ReadyToChoose
      , backendUrl = flags.backendUrl
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    [ Time.every 10000 Types.Tick
    , InteropPorts.toElm
        |> Sub.map
            (unpack
                Types.PortFail
                (\msg ->
                    case msg of
                        AlreadyStaked val ->
                            Types.AlreadyStaked val

                        ConnectResponse val ->
                            Types.ConnectResponse val

                        StakeResponse val ->
                            Types.StakeResponse val

                        WithdrawResponse val ->
                            Types.WithdrawResponse val

                        SignResponse val ->
                            Types.SignResponse val

                        ClaimOrbResponse val ->
                            Types.ClaimOrbResponse val
                )
            )
    ]
        |> Sub.batch
