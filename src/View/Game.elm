module View.Game exposing (view)

import Duration
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Helpers.View exposing (style, when, whenAttr, whenJust)
import Maybe.Extra exposing (isJust, unwrap)
import Ticks
import Types exposing (AltarState(..), Modal(..), Model, Msg(..), Nft, PrizeStatus(..), Stake, Tier(..), Wallet)
import View.Shared exposing (..)


view : Model -> Element Msg
view model =
    [ [ gooseIcon
            (if model.isMobile then
                55

             else
                100
            )
            |> el
                [ padding
                    (if model.isMobile then
                        10

                     else
                        20
                    )
                , alignLeft
                ]
      ]
        |> row
            [ width fill
            , Input.button [ centerX, padding 20, hover ]
                { onPress = Just <| SetView Types.ViewHome
                , label =
                    image
                        [ height <|
                            px
                                (if model.isMobile then
                                    40

                                 else
                                    90
                                )
                        ]
                        { src = "/logo.png", description = "" }
                }
                |> inFront
            ]
    , image
        [ centerX
        , if model.isMobile then
            width fill

          else
            height <| px 800
        , fadeIn
        ]
        { src = "/world-crop.png", description = "" }
        |> el
            [ Border.width 3
            , width
                (if model.isMobile then
                    fill

                 else
                    px 1220
                )
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
                |> whenAttr (model.modal == Nothing)
                |> whenAttr (model.wallet /= Nothing)
                |> whenAttr (not model.isMobile)
            , connectButton (Ticks.get 0 model.ticks)
                model.isMobile
                (Maybe.map .address model.wallet)
                model.dropdown
                |> el [ centerX, centerY ]
                |> inFront
                |> whenAttr (model.wallet == Nothing)
            , findNft
                model.selected
                model.wallet
                |> whenJust (viewSelected (Ticks.get 1 model.ticks) model.isMobile)
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
                    (findNft
                        model.selected
                        model.wallet
                        |> unwrap False (.tier >> (==) Tier3)
                    )
            , Input.button
                [ centerX
                , moveDown 390
                , moveLeft 240
                , style "animation" "bob 1.5s infinite ease"
                , hover
                ]
                { onPress = Just ToggleAltar
                , label =
                    image
                        [ height <| px 60
                        , width <| px 60
                        ]
                        { src = "/shimmer.png"
                        , description = ""
                        }
                }
                |> inFront
                |> whenAttr
                    ((findNft
                        model.selected
                        model.wallet
                        |> unwrap False (.tier >> (==) Tier3)
                     )
                        && (model.wallet
                                |> unwrap False (.orbs >> (<) 0)
                           )
                    )
            , model.modal
                |> whenJust (viewModal model)
                |> inFront
            ]
    , model.wallet
        |> whenJust (viewInventory model)
        |> when model.isMobile
    ]
        |> column
            [ spacing 20
            , paddingXY 20 0
                |> whenAttr model.isMobile
            , width fill
            , height fill
            ]


viewInventory model wallet =
    [ gradientText "Inventory"
        |> el [ centerX, Font.size 28 ]
    , [ [ viewGeese wallet
        , viewItems wallet
        ]
            |> column
                [ width fill
                , spacing
                    (if model.isMobile then
                        40

                     else
                        20
                    )
                ]
      , [ [ gradientText "Incubator"
                |> el [ centerX, Font.size 22, alignLeft ]
          , horizontalRule
          ]
            |> column [ width fill ]
        , viewIncubate model wallet
        ]
            |> column [ width <| px 240, spacing 20, alignTop ]
      ]
        |> (if model.isMobile then
                column [ width fill, spacing 40 ]

            else
                row [ width fill, spacing 20 ]
           )
    ]
        |> column [ centerX, fadeIn, width fill, spacing 20 ]
        |> (if model.isMobile then
                el [ width fill, height fill ]

            else
                el [ width <| px 800, height <| px 400 ]
           )
        |> el
            [ Background.color sand
            , Border.width 3
            , Border.color white
            , Border.rounded 25
            , width fill
                |> whenAttr model.isMobile
            , height fill
                |> whenAttr model.isMobile
            , scrollbarY
                |> whenAttr model.isMobile
            , padding
                (if model.isMobile then
                    20

                 else
                    40
                )
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
                |> whenAttr (not model.isMobile)
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
    let
        ( header, content ) =
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
                    , text "Acquire an orb, and find the altar to continue your journey."
                    )

                Tier4 ->
                    ( "Tier 4"
                    , newTabLink [ hover ]
                        { url = "https://twitter.com/hashtag/GooseGang"
                        , label = styledText "#GooseGang"
                        }
                    )

        img =
            image
                [ height <|
                    px
                        (if isMobile then
                            120

                         else
                            203
                        )
                , centerX
                , formatInt nft.id
                    |> text
                    |> el
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
                    |> inFront
                ]
                { src = nftImage nft.tier
                , description = ""
                }
    in
    [ img
    , (case nft.tier of
        Tier1 ->
            Just
                ( "Incubate Egg"
                , Incubate nft.mintId
                )

        Tier2 ->
            Just
                ( "Upgrade"
                , SignTimestamp nft.mintId
                )

        Tier3 ->
            Nothing

        Tier4 ->
            Nothing
      )
        |> whenJust
            (\( txt, msg ) ->
                yellowButton inProgress
                    isMobile
                    (gradientText
                        txt
                    )
                    (Just msg)
                    |> el [ centerX ]
            )
    , [ gradientText header
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
        |> when (not isMobile)
    ]
        |> column [ fadeIn, spacing 0 ]
        |> el
            (if isMobile then
                [ centerX ]

             else
                case nft.tier of
                    Tier1 ->
                        [ alignRight, moveLeft 190, moveDown 350 ]

                    Tier2 ->
                        [ alignRight, moveLeft 295 ]

                    Tier3 ->
                        [ alignRight, moveLeft 555, moveDown 370 ]

                    Tier4 ->
                        [ alignLeft, moveRight 130, moveDown 120 ]
            )


viewGeese wallet =
    [ gradientText "NestQuest NFTs"
        |> el [ centerX, Font.size 22, alignLeft ]
    , horizontalRule
    , if List.isEmpty wallet.nfts then
        newTabLink [ hover ]
            { url = "https://app.goosefx.io/NFTs/NestQuest"
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
                        { onPress = Just <| SelectNft <| Just nft.id
                        , label =
                            image
                                [ height <| px 100
                                ]
                                { src = nftImage nft.tier
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


viewChests : Ticks.Ticks -> Bool -> PrizeStatus -> Element Msg
viewChests ticks isMobile status =
    let
        chooser curr =
            [ gradientText "Try your luck..."
                |> el [ centerX, Font.size 36 ]
            , [ List.range 0 3
                    |> List.map (viewChest curr)
                    |> row [ spacing 20 ]
              , List.range 0 2
                    |> List.map ((+) 4 >> viewChest curr)
                    |> row [ spacing 20, centerX ]
              ]
                |> column [ centerX ]
            ]
                |> column
                    [ spacing 10
                    ]
    in
    case status of
        ReadyToChoose ->
            chooser Nothing

        Choosing n ->
            chooser (Just n)

        WaitUntilTomorrow ->
            [ chest False 200
                |> el [ centerX ]
            , [ gradientText "The wind has not blown in your favour."
                    |> el [ centerX, Font.size 26 ]
              , text "Try again tomorrow."
                    |> el
                        [ centerX
                        , Font.italic
                        , Font.size 23
                        , Font.color wine
                        , meriendaBold
                        ]
              , yellowButton False
                    isMobile
                    (gradientText "Continue")
                    (Just ToggleTent)
                    |> el [ centerX ]
              ]
                |> column [ spacing 20 ]
            ]
                |> column [ centerY, centerX, fadeIn ]
                |> el [ width <| px 800, height <| px 400 ]

        ClaimYourPrize sig ->
            [ chest True 200
                |> el [ centerX ]
            , [ gradientText "You can claim your reward."
                    |> el [ centerX, Font.size 26 ]
              , yellowButton (Ticks.get 1 ticks)
                    isMobile
                    (gradientText "Claim")
                    (Just <| ClaimOrb sig)
                    |> el [ centerX ]
              ]
                |> column [ spacing 20 ]
            ]
                |> column [ centerY, centerX, fadeIn ]
                |> el [ width <| px 800, height <| px 400 ]

        Checking ->
            spinner 50
                |> el [ centerY, centerX, fadeIn ]
                |> el [ width <| px 800, height <| px 400 ]

        AlreadyClaimed ->
            [ image [ width <| px 175 ]
                { src = "/orb.png"
                , description = ""
                }
                |> el [ centerX ]
            , gradientText "You have claimed your reward successfully."
                |> el [ centerX, Font.size 26 ]
            , yellowButton False
                isMobile
                (gradientText "Continue")
                (Just ToggleTent)
                |> el [ centerX ]
            ]
                |> column [ centerY, centerX, fadeIn, spacing 20 ]
                |> el [ width <| px 800, height <| px 400 ]


viewChest curr n =
    Input.button
        [ if isJust curr then
            fade

          else
            hover
        , spinner 30
            |> el [ centerX, centerY ]
            |> inFront
            |> whenAttr (curr == Just n)
        ]
        { onPress =
            if isJust curr then
                Nothing

            else
                Just <| SelectChest n
        , label =
            image [ width <| px 200 ]
                { src = "/chest_closed.png"
                , description = ""
                }
        }


viewAltar : Model -> Nft -> Element Msg
viewAltar model nft =
    image [ width <| px 600 ]
        { src = "/altar.jpg"
        , description = ""
        }
        |> el
            [ Background.color sand
            , Border.width 3
            , Border.color sand
            , Border.rounded 25
            , clip
            , fadeIn
            , Input.button
                [ alignTop
                , alignRight
                , width <| px 45
                , height <| px 45
                , hover
                , Font.bold
                , Font.size 35
                , Background.color sand
                , Border.rounded 30
                , moveLeft 10
                , moveDown 10
                ]
                { onPress = Just ToggleAltar
                , label =
                    text "X"
                        |> el [ centerX, centerY ]
                }
                |> inFront
            , (case model.altarState of
                AltarStage1 ->
                    yellowButtonExpand False
                        (styledText "Investigate the Altar")
                        (Just ProgressAltar)
                        |> el [ centerX ]

                AltarStage2 ->
                    [ [ styledText "You approach the altar and the orb in your inventory is sucked out of your pack towards the altar."
                      , styledText "The orb seems to have a magnetic connection to the altar as it levitates on the center of the pedestal."
                      , styledText "As you approach the orb, the elemental maelstrom within shines ever brighter."
                      ]
                        |> textStack
                    , yellowButton (Ticks.get 1 model.ticks)
                        True
                        (styledText "Touch orb")
                        (Just (SignTimestamp nft.mintId))
                        |> el [ centerX ]
                    ]
                        |> column [ spacing 20, fadeIn ]

                AltarSuccess ->
                    [ [ image
                            [ width <| px 150
                            , centerX
                            ]
                            { src = "/tier4.png"
                            , description = ""
                            }
                      , styledText "Your Gosling has absorbed the elemental energy from within the orb and has evolved to an Armored Goose."
                      , styledText "This Goose is dangerous and prepared for the challenges that await it on the journey ahead."
                      ]
                        |> textStack
                    , yellowButton False
                        True
                        (styledText "Continue")
                        (Just ToggleAltar)
                        |> el [ centerX ]
                    ]
                        |> column [ spacing 20 ]

                AltarError err ->
                    [ styledText "Error"
                        |> el [ centerX ]
                    , styledText err
                        |> el [ centerX ]
                    , yellowButton False
                        True
                        (styledText "Continue")
                        (Just ToggleAltar)
                        |> el [ centerX ]
                    ]
                        |> textStack
              )
                |> el [ padding 20, centerX, alignBottom ]
                |> inFront
            ]
        |> el
            [ padding 50
            , centerX
            ]


chest orb n =
    image [ width <| px n ]
        { src =
            if orb then
                "/chest_open_stone.png"

            else
                "/chest_open_empty.png"
        , description = ""
        }


styledText =
    text
        >> List.singleton
        >> paragraph
            [ meriendaRegular
            , Font.italic
            , Font.color brown
            , Font.size 20
            ]


viewModal : Model -> Modal -> Element Msg
viewModal model modal =
    case modal of
        ModalTent ->
            viewChests model.ticks model.isMobile model.prizeStatus
                |> el
                    [ Background.color sand
                    , Border.width 3
                    , Border.color white
                    , Border.rounded 25
                    , padding 40
                    , fadeIn
                    , Input.button
                        [ alignTop
                        , alignRight
                        , padding 20
                        , hover
                        , Font.bold
                        , Font.size 35
                        ]
                        { onPress = Just ToggleTent
                        , label = text "X"
                        }
                        |> inFront
                    ]
                |> el
                    [ padding 50
                    , centerX
                    , centerY
                    ]

        ModalAltar ->
            findNft
                model.selected
                model.wallet
                |> whenJust
                    (viewAltar model)

        ModalInventory ->
            model.wallet
                |> whenJust (viewInventory model)
                |> el
                    [ padding 50
                    , centerX
                    ]


textStack =
    column
        [ Background.color sand
        , Border.rounded 30
        , Border.width 3
        , Border.color white
        , padding 20
        , Font.size 15
        , spacing 10
        , Font.center
        ]


nftImage tier =
    case tier of
        Types.Tier1 ->
            "/egg-present.png"

        Types.Tier2 ->
            "/tier2.png"

        Types.Tier3 ->
            "/tier3.png"

        Types.Tier4 ->
            "/tier4.png"
