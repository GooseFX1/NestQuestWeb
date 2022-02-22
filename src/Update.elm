module Update exposing (update)

import Maybe.Extra exposing (unwrap)
import Ports
import Types exposing (Model, Msg(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Connect ->
            ( model, Ports.connect () )

        Scroll scrollDepth ->
            ( { model
                | scrollIndex =
                    if model.isMobile then
                        mobileCheckpoints model.scrollIndex scrollDepth

                    else
                        desktopCheckpoints model.scrollIndex scrollDepth
              }
            , Cmd.none
            )

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


mobileCheckpoints : Int -> Int -> Int
mobileCheckpoints currentIndex scrollDepth =
    if scrollDepth > 1400 then
        max currentIndex 9

    else if scrollDepth > 1250 then
        max currentIndex 8

    else if scrollDepth > 1100 then
        max currentIndex 7

    else if scrollDepth > 950 then
        max currentIndex 6

    else if scrollDepth > 800 then
        max currentIndex 5

    else if scrollDepth > 650 then
        max currentIndex 4

    else if scrollDepth > 500 then
        max currentIndex 3

    else if scrollDepth > 350 then
        max currentIndex 2

    else if scrollDepth > 200 then
        max currentIndex 1

    else
        currentIndex


desktopCheckpoints : Int -> Int -> Int
desktopCheckpoints currentIndex scrollDepth =
    if scrollDepth > 1970 then
        max currentIndex 9

    else if scrollDepth > 1870 then
        max currentIndex 8

    else if scrollDepth > 1770 then
        max currentIndex 7

    else if scrollDepth > 1670 then
        max currentIndex 6

    else if scrollDepth > 1570 then
        max currentIndex 5

    else if scrollDepth > 1470 then
        max currentIndex 4

    else if scrollDepth > 1370 then
        max currentIndex 3

    else if scrollDepth > 1270 then
        max currentIndex 2

    else if scrollDepth > 1170 then
        max currentIndex 1

    else
        currentIndex
