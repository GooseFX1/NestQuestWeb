module Update exposing (update)

import Maybe.Extra exposing (unwrap)
import Ports
import Time
import Types exposing (Model, Msg(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick posix ->
            ( { model | time = Time.posixToMillis posix // 1000 }
            , Cmd.none
            )

        Connect ->
            ( { model | walletSelect = not model.walletSelect }
            , Cmd.none
            )

        Incubate ->
            ( model
            , model.wallet
                |> Maybe.andThen (.nfts >> List.head)
                |> unwrap Cmd.none (.mintId >> Ports.stake)
            )

        Withdraw mintId ->
            ( model
            , Ports.withdraw mintId
            )

        Disconnect ->
            ( { model
                | wallet = Nothing
                , dropdown = False
              }
            , Ports.disconnect ()
            )

        WithdrawResponse _ ->
            ( { model
                | wallet =
                    model.wallet
                        |> Maybe.map
                            (\state ->
                                { state
                                    | stake = Nothing
                                }
                            )
                , withdrawComplete = True
              }
            , Cmd.none
            )

        AlreadyStaked mintId ->
            ( { model
                | wallet =
                    model.wallet
                        |> Maybe.map
                            (\state ->
                                { state
                                    | nfts =
                                        state.nfts
                                            |> List.filter (.mintId >> (/=) mintId)
                                }
                            )
              }
            , Cmd.none
            )

        ChangeWallet ->
            ( { model
                | wallet = Nothing
                , dropdown = False
                , walletSelect = True
              }
            , Ports.disconnect ()
            )

        Select n ->
            ( model, Ports.connect n )

        Scroll scrollDepth ->
            ( { model
                | scrollIndex =
                    if model.isMobile then
                        mobileCheckpoints model.scrollStart model.scrollIndex scrollDepth

                    else
                        desktopCheckpoints model.scrollStart model.scrollIndex scrollDepth
              }
            , Cmd.none
            )

        ConnectResponse res ->
            ( { model
                | wallet =
                    res
                        |> Maybe.map
                            (\wallet ->
                                { wallet
                                    | stake =
                                        wallet.stake
                                            |> Maybe.map
                                                (\stake ->
                                                    { stake
                                                        | stakingStart =
                                                            stake.stakingStart + thirtyDaysSeconds
                                                    }
                                                )
                                }
                            )
                , walletSelect = False
                , nftIndex = 0
                , dropdown = False
                , withdrawComplete = False
              }
            , Cmd.none
            )

        StakeResponse val ->
            ( { model
                | wallet =
                    val
                        |> unwrap
                            model.wallet
                            (\stake ->
                                model.wallet
                                    |> Maybe.map
                                        (\wallet ->
                                            { wallet
                                                | stake =
                                                    Just
                                                        { stake
                                                            | stakingStart =
                                                                (stake.stakingStart // 1000)
                                                                    + thirtyDaysSeconds
                                                        }
                                            }
                                        )
                            )
              }
            , Cmd.none
            )

        SignTimestamp ->
            ( model, Ports.signTimestamp () )

        SignResponse _ ->
            ( model, Cmd.none )

        ToggleDropdown ->
            ( { model | dropdown = not model.dropdown }, Cmd.none )

        PlayTheme ->
            if model.themePlaying then
                ( { model | themePlaying = False }
                , Ports.stopTheme ()
                )

            else
                ( { model | themePlaying = True, playButtonPulse = False }
                , Ports.playTheme ()
                )

        NftSelect backwards ->
            ( { model
                | nftIndex =
                    model.wallet
                        |> unwrap model.nftIndex
                            (\wallet ->
                                let
                                    len =
                                        List.length wallet.nfts - 1
                                in
                                if backwards then
                                    if model.nftIndex <= 0 then
                                        len

                                    else
                                        model.nftIndex - 1

                                else if model.nftIndex >= len then
                                    0

                                else
                                    model.nftIndex + 1
                            )
              }
            , Cmd.none
            )


mobileCheckpoints : Int -> Int -> Int -> Int
mobileCheckpoints screenHeight currentIndex scrollVal =
    let
        start =
            1600

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


desktopCheckpoints : Int -> Int -> Int -> Int
desktopCheckpoints screenHeight currentIndex scrollVal =
    let
        start =
            2450

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


thirtyDaysSeconds : Int
thirtyDaysSeconds =
    2592000
