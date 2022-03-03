module Update exposing (update)

import Maybe.Extra exposing (unwrap)
import Ports
import Types exposing (Model, Msg(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Connect ->
            ( { model | walletSelect = not model.walletSelect }
            , Cmd.none
            )

        Incubate ->
            ( model
            , model.wallet
                |> Maybe.andThen (.nfts >> List.head)
                |> unwrap Cmd.none Ports.stake
            )

        Withdraw mintId ->
            ( model
            , Ports.withdraw mintId
            )

        Disconnect ->
            model.wallet
                |> unwrap ( model, Cmd.none )
                    (\state ->
                        ( { model
                            | wallet = Nothing
                            , dropdown = False
                          }
                        , Ports.disconnect ()
                        )
                    )

        ChangeWallet ->
            model.wallet
                |> unwrap ( model, Cmd.none )
                    (\state ->
                        ( { model
                            | wallet = Nothing
                            , dropdown = False
                            , walletSelect = True
                          }
                        , Ports.disconnect ()
                        )
                    )

        Select n ->
            --( model, Ports.connect () )
            ( model, Ports.connect n )

        Scroll scrollDepth ->
            ( { model
                | scrollIndex =
                    if model.isMobile then
                        mobileCheckpoints model.scrollStart model.scrollIndex scrollDepth

                    else
                        desktopCheckpoints model.scrollIndex scrollDepth
              }
            , Cmd.none
            )

        ConnectResponse val ->
            ( { model | wallet = val, walletSelect = False }, Cmd.none )

        StakeResponse val ->
            ( { model | incubationSuccess = Just val }, Cmd.none )

        Convert ->
            ( { model | dropdown = not model.dropdown }, Cmd.none )

        PlayTheme ->
            if model.themePlaying then
                ( { model | themePlaying = False }
                , Ports.stopTheme ()
                )

            else
                ( { model | themePlaying = True }
                , Ports.playTheme ()
                )


mobileCheckpoints : Int -> Int -> Int -> Int
mobileCheckpoints screenHeight currentIndex scrollVal =
    let
        start =
            1400

        scrollDepth =
            screenHeight + scrollVal

        gap =
            120
    in
    if scrollDepth > (start + gap * 8) then
        max currentIndex 9

    else if scrollDepth > (start + gap * 7) then
        max currentIndex 8

    else if scrollDepth > (start + gap * 6) then
        max currentIndex 7

    else if scrollDepth > (start + gap * 5) then
        max currentIndex 6

    else if scrollDepth > (start + gap * 4) then
        max currentIndex 5

    else if scrollDepth > (start + gap * 3) then
        max currentIndex 4

    else if scrollDepth > (start + gap * 2) then
        max currentIndex 3

    else if scrollDepth > (start + gap) then
        max currentIndex 2

    else if scrollDepth > start then
        max currentIndex 1

    else
        currentIndex


desktopCheckpoints : Int -> Int -> Int
desktopCheckpoints currentIndex scrollDepth =
    let
        start =
            1570

        gap =
            120
    in
    if scrollDepth > (start + gap * 8) then
        max currentIndex 9

    else if scrollDepth > (start + gap * 7) then
        max currentIndex 8

    else if scrollDepth > (start + gap * 6) then
        max currentIndex 7

    else if scrollDepth > (start + gap * 5) then
        max currentIndex 6

    else if scrollDepth > (start + gap * 4) then
        max currentIndex 5

    else if scrollDepth > (start + gap * 3) then
        max currentIndex 4

    else if scrollDepth > (start + gap * 2) then
        max currentIndex 3

    else if scrollDepth > (start + gap) then
        max currentIndex 2

    else if scrollDepth > start then
        max currentIndex 1

    else
        currentIndex
