module Update exposing (update)

import Helpers.Http exposing (parseError)
import Http
import InteropDefinitions
import InteropPorts
import Json.Decode as JD
import Json.Encode as JE
import Maybe.Extra exposing (unwrap)
import Result.Extra exposing (unpack)
import Ticks
import Time
import Types exposing (Model, Msg(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick posix ->
            ( { model | time = Time.posixToMillis posix // 1000 }
            , Cmd.none
            )

        PortFail err ->
            ( model
            , err
                |> JD.errorToString
                |> InteropDefinitions.Log
                |> InteropPorts.fromElm
            )

        ToggleWalletSelect ->
            ( { model
                | walletSelect = not model.walletSelect
              }
            , Cmd.none
            )

        Incubate mintId ->
            ( { model
                | ticks =
                    model.ticks
                        |> Ticks.tick 1
              }
            , mintId
                |> InteropDefinitions.Stake
                |> InteropPorts.fromElm
            )

        Withdraw mintId ->
            ( { model
                | ticks =
                    model.ticks
                        |> Ticks.tick 1
              }
            , mintId
                |> InteropDefinitions.Withdraw
                |> InteropPorts.fromElm
            )

        Disconnect ->
            ( { model
                | wallet = Nothing
                , dropdown = False
              }
            , InteropDefinitions.Disconnect
                |> InteropPorts.fromElm
            )

        WithdrawResponse res ->
            let
                ticks =
                    model.ticks
                        |> Ticks.untick 0
            in
            res
                |> unwrap ( { model | ticks = ticks }, Cmd.none )
                    (\nft ->
                        ( { model
                            | ticks = ticks
                            , wallet =
                                model.wallet
                                    |> Maybe.map
                                        (\wallet ->
                                            { wallet
                                                | stake = Nothing
                                                , nfts = nft :: wallet.nfts
                                            }
                                        )
                            , nftIndex = 0
                          }
                        , InteropDefinitions.Alert "Your NFT withdraw was successful."
                            |> InteropPorts.fromElm
                        )
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
            , InteropDefinitions.Disconnect
                |> InteropPorts.fromElm
            )

        ConnectWallet walletId ->
            ( { model
                | ticks =
                    model.ticks
                        |> Ticks.tick 0
                , walletSelect = False
              }
            , walletId
                |> InteropDefinitions.Connect
                |> InteropPorts.fromElm
            )

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
            let
                ticks =
                    model.ticks
                        |> Ticks.untick 0
            in
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
                , ticks = ticks
              }
            , Cmd.none
            )

        StakeResponse val ->
            let
                ticks =
                    model.ticks
                        |> Ticks.untick 1
            in
            val
                |> unwrap
                    ( { model | ticks = ticks }, Cmd.none )
                    (\stake ->
                        ( { model
                            | ticks = ticks
                            , wallet =
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
                          }
                        , InteropDefinitions.Log "Your egg was staked successfully."
                            |> InteropPorts.fromElm
                        )
                    )

        SignTimestamp mintId ->
            ( { model
                | ticks =
                    model.ticks
                        |> Ticks.tick 1
              }
            , InteropDefinitions.SignTimestamp mintId
                |> InteropPorts.fromElm
            )

        SignResponse res ->
            Maybe.map2
                (\wallet signData ->
                    ( model, upgradeTier2 wallet.address signData )
                )
                model.wallet
                res
                |> Maybe.withDefault
                    ( { model
                        | ticks =
                            model.ticks
                                |> Ticks.untick 1
                      }
                    , Cmd.none
                    )

        UpgradeCb res ->
            let
                ticks =
                    model.ticks
                        |> Ticks.untick 1
            in
            res
                |> unpack
                    (\err ->
                        ( { model | ticks = ticks }
                        , InteropDefinitions.Log (parseError err)
                            |> InteropPorts.fromElm
                        )
                    )
                    (\mintId ->
                        ( { model
                            | ticks = ticks
                            , wallet =
                                model.wallet
                                    |> Maybe.map
                                        (\wallet ->
                                            { wallet
                                                | nfts =
                                                    wallet.nfts
                                                        |> List.map
                                                            (\nft ->
                                                                if nft.mintId == mintId then
                                                                    { nft | tier = Types.Tier3 }

                                                                else
                                                                    nft
                                                            )
                                            }
                                        )
                          }
                        , InteropDefinitions.Alert "Your hatchling has been successfully upgraded."
                            |> InteropPorts.fromElm
                        )
                    )

        ToggleDropdown ->
            ( { model | dropdown = not model.dropdown }, Cmd.none )

        PlayTheme ->
            if model.themePlaying then
                ( { model | themePlaying = False }
                , InteropDefinitions.StopTheme
                    |> InteropPorts.fromElm
                )

            else
                ( { model | themePlaying = True, playButtonPulse = False }
                , InteropDefinitions.PlayTheme
                    |> InteropPorts.fromElm
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


upgradeTier2 : String -> Types.SignatureData -> Cmd Msg
upgradeTier2 address data =
    Http.post
        { url = "https://nestquest-api.goosefx.io/tier3"
        , body =
            [ ( "address", JE.string address )
            , ( "mint_id", JE.string data.mintId )
            , ( "signature", JE.string data.signature )
            ]
                |> JE.object
                |> Http.jsonBody
        , expect = Http.expectJson UpgradeCb JD.string
        }
