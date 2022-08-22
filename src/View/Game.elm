module View.Game exposing (view)

import Duration
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Helpers.View exposing (style, whenAttr, whenJust)
import Maybe.Extra exposing (unwrap)
import Ticks
import Types exposing (Model, Msg(..), Nft, Stake, Tier(..), Wallet)
import View.Shared exposing (..)


view : Model -> Element Msg
view model =
    [ [ gooseIcon 100
            |> el [ padding 20, alignLeft ]
      ]
        |> row
            [ width fill
            , Input.button [ centerX, padding 20, hover ]
                { onPress = Just <| SetView Types.ViewHome
                , label =
                    image [ height <| px 90 ]
                        { src = "/logo.png", description = "" }
                }
                |> inFront
            ]
    , image
        [ centerX
        , height <| px 800
        , fadeIn
        ]
        { src = "/world-crop.png", description = "" }
        |> el
            [ Border.width 3
            , width <| px 1220
            , centerX
            , Background.color <| rgb255 85 85 147
            , Border.color sand
            , Border.rounded 25
            , yellowButton False
                False
                (gradientText "Open Inventory")
                (Just ToggleInventory)
                |> el [ alignLeft, alignBottom, padding 10 ]
                |> inFront
                |> whenAttr (not model.inventoryOpen)
                |> whenAttr (model.wallet /= Nothing)
            , connectButton (Ticks.get 0 model.ticks)
                model.isMobile
                (Maybe.map .address model.wallet)
                model.dropdown
                |> el [ centerX, centerY ]
                |> inFront
                |> whenAttr (model.wallet == Nothing)
            , model.wallet
                |> whenJust (viewInventory model)
                |> el
                    [ padding 50
                    , centerX
                    ]
                |> inFront
                |> whenAttr model.inventoryOpen
            , model.selected
                |> whenJust (viewSelected (Ticks.get 1 model.ticks) False)
                |> inFront
            , Input.button
                [ centerX
                , moveDown 260
                , moveLeft 90
                , style "animation" "bob 2s infinite ease"
                , hover
                ]
                { onPress = Just ToggleTent
                , label =
                    image
                        [ height <| px 60
                        , width <| px 60
                        ]
                        { src = "/glo.png"
                        , description = ""
                        }
                }
                |> inFront
                |> whenAttr
                    (model.selected
                        |> unwrap False (.tier >> (==) Tier3)
                    )
            ]
    ]
        |> column
            [ spacing 20
            , width fill
            , height fill
            ]


viewInventory model wallet =
    [ gradientText "Inventory"
        |> el [ centerX, Font.size 28 ]
    , [ [ viewGeese wallet
        , viewItems wallet
        ]
            |> column [ width fill, spacing 20 ]
      , [ [ gradientText "Incubator"
                |> el [ centerX, Font.size 22, alignLeft ]
          , horizontalRule
          ]
            |> column [ width fill ]
        , viewIncubate model wallet
        ]
            |> column [ width <| px 240, spacing 20, alignTop ]
      ]
        |> row [ width fill, spacing 20 ]
    ]
        |> column [ centerX, fadeIn, width fill, spacing 20 ]
        |> el [ width <| px 800, height <| px 400 ]
        |> el
            [ Background.color sand
            , Border.width 3
            , Border.color white
            , Border.rounded 25
            , padding 40
            , Input.button
                [ alignTop
                , alignRight
                , padding 20
                , hover
                , Font.bold
                , Font.size 35
                ]
                { onPress = Just ToggleInventory
                , label = text "X"
                }
                |> inFront
            ]


viewIncubate : Model -> Wallet -> Element Msg
viewIncubate model wallet =
    let
        inProgress =
            Ticks.get 1 model.ticks
    in
    wallet.stake
        |> unwrap
            (image
                [ height <| px 140
                , centerX
                ]
                { src = "/egg-pending.png"
                , description = ""
                }
            )
            (\stake ->
                [ Input.button [ centerX ]
                    { onPress = Nothing
                    , label =
                        image
                            [ height <| px 140
                            ]
                            { src = "/egg-present.png"
                            , description = ""
                            }
                    }
                , withdrawButton inProgress model.isMobile model.time stake
                ]
                    |> column []
            )


withdrawButton : Bool -> Bool -> Int -> Stake -> Element Msg
withdrawButton inProgress isMobile time stake =
    let
        stakingEnd =
            stake.stakingStart

        diff =
            Duration.seconds (toFloat (max 0 (stakingEnd - time)))

        canWithdraw =
            time >= stake.stakingStart
    in
    yellowButton inProgress
        isMobile
        (if canWithdraw then
            gradientText "Evolve"

         else
            calcCountdown diff
                |> gradientText
        )
        (if canWithdraw then
            Just <| Withdraw stake.mintId

         else
            Nothing
        )


viewSelected : Bool -> Bool -> Nft -> Element Msg
viewSelected inProgress isMobile nft =
    [ image
        [ height <|
            px
                (if isMobile then
                    120

                 else
                    203
                )
        , centerX
        , nft.name
            |> String.filter ((/=) nullByte)
            |> String.split "#"
            |> List.reverse
            |> List.head
            |> Maybe.andThen String.toInt
            |> whenJust
                (formatInt
                    >> text
                    >> el
                        [ Font.color white
                        , centerX
                        , Font.size
                            (if isMobile then
                                15

                             else
                                18
                            )
                        , meriendaRegular
                        , moveDown
                            (if isMobile then
                                70

                             else
                                130
                            )
                        , Font.bold
                        ]
                )
            |> inFront
        ]
        { src =
            case nft.tier of
                Tier1 ->
                    "/egg-present.png"

                Tier2 ->
                    "/tier2.png"

                Tier3 ->
                    "/tier3.png"
        , description = ""
        }
        |> (\x ->
                let
                    ( hd, content ) =
                        case nft.tier of
                            Tier1 ->
                                ( "Tier 1"
                                , text "This egg will need to be staked for 30 days to upgrade."
                                )

                            Tier2 ->
                                ( "Tier 2"
                                , [ text "You will need to "
                                  , newTabLink [ Font.underline, hover, Font.bold ]
                                        { url = "https://app.goosefx.io/farm"
                                        , label = text "stake 25 GOFX"
                                        }
                                  , text " with this wallet for "
                                  , text "7 days"
                                        |> el [ Font.bold ]
                                  , text " before upgrading this NFT."
                                  ]
                                    |> paragraph []
                                )

                            Tier3 ->
                                ( "Tier 3"
                                , text "Your Gosling is growing stronger."
                                )
                in
                [ Input.button [ hover, fadeIn ]
                    { onPress = Just <| SelectNft Nothing
                    , label = x
                    }
                , yellowButton inProgress
                    isMobile
                    (gradientText
                        (case nft.tier of
                            Tier1 ->
                                "Incubate Egg"

                            Tier2 ->
                                "Upgrade"

                            Tier3 ->
                                "..."
                        )
                    )
                    (case nft.tier of
                        Tier1 ->
                            Just <| Incubate nft.mintId

                        Tier2 ->
                            Just <| SignTimestamp nft.mintId

                        Tier3 ->
                            Nothing
                    )
                    |> el [ centerX ]
                , [ gradientText hd
                        |> el [ centerX, Font.size 22 ]
                  , [ content ]
                        |> paragraph [ meriendaRegular, Font.italic, Font.color brown, Font.center, Font.size 17 ]
                  ]
                    |> column
                        [ Background.color sand
                        , Border.width 3
                        , Border.color white
                        , Border.rounded 25
                        , padding 15
                        , moveDown 10
                        , centerX
                        , spacing 15
                        , width <| px 240
                        ]
                ]
                    |> column [ fadeIn, spacing 0 ]
           )
    ]
        |> column
            (case nft.tier of
                Tier1 ->
                    [ alignRight, moveLeft 190, moveDown 350 ]

                Tier2 ->
                    [ alignRight, moveLeft 295 ]

                Tier3 ->
                    [ alignRight, moveLeft 600, moveDown 370 ]
            )


viewGeese wallet =
    [ gradientText "NestQuest NFTs"
        |> el [ centerX, Font.size 22, alignLeft ]
    , horizontalRule
    , if List.isEmpty wallet.nfts then
        newTabLink [ hover ]
            { url = "https://app.goosefx.io/NFTs"
            , label =
                [ image
                    [ height <| px 100
                    , centerX
                    ]
                    { src = "/egg-pending.png"
                    , description = ""
                    }
                , "Get an egg 🡕"
                    |> text
                    |> el
                        [ Font.color black
                        , Font.size 17
                        , meriendaRegular
                        ]
                ]
                    |> column []
            }

      else
        wallet.nfts
            |> List.map
                (\nft ->
                    [ Input.button [ hover ]
                        { onPress = Just <| SelectNft <| Just nft
                        , label =
                            image
                                [ height <| px 100
                                ]
                                { src =
                                    case nft.tier of
                                        Types.Tier1 ->
                                            "/egg-present.png"

                                        Types.Tier2 ->
                                            "/tier2.png"

                                        Types.Tier3 ->
                                            "/tier3.png"
                                , description = ""
                                }
                        }
                    , nft.id
                        |> formatInt
                        |> text
                        |> el
                            [ Font.color black
                            , centerX
                            , Font.size 20
                            , meriendaRegular
                            , Font.bold
                            ]
                    ]
                        |> column [ spacing 10 ]
                )
            --|> row [ width fill, scrollbarX, height <| px 160 ]
            --|> row [ width fill, height fill ]
            --|> List.singleton
            --|> el [ width fill, scrollbarX, height <| px 160 ]
            |> wrappedRow [ width fill, scrollbarY, height <| px 160 ]
    ]
        |> column [ width fill ]


viewItems wallet =
    [ gradientText "Items"
        |> el [ centerX, Font.size 22, alignLeft ]
    , horizontalRule
    , newTabLink [ hover ]
        { url = "https://explorer.solana.com/address/orbs7FDskYc92kNer1M9jHBFaB821iCmPJkumZA4yyd"
        , label =
            [ image
                [ height <| px 70
                , padding 20
                ]
                { src = "/orb.png"
                , description = ""
                }
            , "x"
                ++ String.fromInt wallet.orbs
                |> text
                |> el
                    [ Font.color black
                    , centerX
                    , Font.size 20
                    , meriendaRegular
                    , Font.bold
                    ]
            ]
                |> column [ spacing 30 ]
        }
    ]
        |> column [ width fill ]


calcCountdown : Duration.Duration -> String
calcCountdown diff =
    let
        days =
            Duration.inDays diff

        daysMins =
            days
                |> floor
                |> toFloat
                |> Duration.days
                |> Duration.inMinutes

        daysSeconds =
            days
                |> floor
                |> toFloat
                |> Duration.days
                |> Duration.inSeconds

        hours =
            Duration.inMinutes diff
                - daysMins
                |> Duration.minutes
                |> Duration.inHours

        hoursSeconds =
            hours
                |> floor
                |> toFloat
                |> Duration.hours
                |> Duration.inSeconds

        mins =
            Duration.inSeconds diff
                - daysSeconds
                - hoursSeconds
                |> Duration.seconds
                |> Duration.inMinutes
    in
    [ String.fromInt <| floor days
    , "d: "
    , String.fromInt <| floor hours
    , "h: "
    , String.fromInt <| floor mins
    , "m"
    ]
        |> String.concat


horizontalRule =
    el [ width fill, height <| px 1, Background.color black ] none
