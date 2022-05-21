module View exposing (view)

import Array
import Duration
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import FormatNumber
import FormatNumber.Locales exposing (usLocale)
import Helpers.View exposing (cappedHeight, cappedWidth, style, when, whenAttr, whenJust)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode as JD
import Maybe.Extra exposing (isJust, unwrap)
import Ticks
import Types exposing (Model, Msg(..), Nft, Stake, Tier(..))
import View.Img as Img


view : Model -> Html Msg
view model =
    (if model.isMobile then
        viewMobile model

     else
        viewDesktop model
    )
        |> Element.layoutWith
            { options =
                Element.focusStyle
                    { borderColor = Nothing
                    , backgroundColor = Nothing
                    , shadow = Nothing
                    }
                    :: (if model.isMobile then
                            [ Element.noHover ]

                        else
                            []
                       )
            }
            [ width fill
            , height fill
            , Background.color bg
            , scrollbarY
            , JD.at [ "target", "scrollTop" ] JD.float
                |> JD.map (round >> Scroll)
                |> Html.Events.on "scroll"
                |> htmlAttribute
            , playButton (Ticks.get 0 model.ticks) model.playButtonPulse (Maybe.map .address model.wallet) model.themePlaying model.dropdown
                |> inFront
                |> whenAttr (not model.isMobile)
            , walletSelect model.isMobile
                |> inFront
                |> whenAttr model.walletSelect
            ]


viewMobile : Model -> Element Msg
viewMobile model =
    [ [ [ gooseIcon 50
        , connectButton (Ticks.get 0 model.ticks) model.isMobile (Maybe.map .address model.wallet) model.dropdown
        , musicButton model.playButtonPulse model.themePlaying
        ]
            |> row [ spaceEvenly, cappedWidth 450, centerX, padding 20 ]
      , [ [ image
                [ centerX
                , width fill
                ]
                { src = "/logo.png", description = "" }
          , image
                [ centerX
                , width fill
                ]
                { src = "/slogan.png", description = "" }
          ]
            |> column [ width fill, spacing 15 ]
        ]
            |> column
                [ cappedWidth 650
                , padding 50
                , centerX
                ]
      , image
            [ cappedWidth 381
            , height <| px 2198
            , centerX
            , [ el [ height <| px 100, width fill ] none
              , image
                    [ height <| px 480
                    , width <| px 355
                    , centerX
                    , infoText
                        |> column
                            [ Font.color wine
                            , Font.center
                            , meriendaBold
                            , spacing 5
                            , Font.size 14
                            , width <| px 308
                            , moveDown 150
                            , centerX
                            ]
                        |> inFront
                    ]
                    { src = "/parchment-mobile.svg"
                    , description = ""
                    }
              , el [ height <| px 10, width fill ] none
              , boxM body1
                    |> when (model.scrollIndex > 0)
              , [ lineImg 1
                    |> when (model.scrollIndex > 1)
                    |> el [ alignLeft, alignTop ]
                , boxM body2
                    |> bump
                    |> when (model.scrollIndex > 2)
                ]
                    |> row [ spacing 10, width fill ]
              , [ boxM body3
                    |> bump
                    |> when (model.scrollIndex > 4)
                    -- Prevent fadeIn bug
                    |> el []
                , lineImg 2
                    |> when (model.scrollIndex > 3)
                    |> el [ alignRight, alignTop ]
                ]
                    |> row [ spacing 10, width fill ]
              , [ lineImg 3
                    |> when (model.scrollIndex > 5)
                    |> el [ alignLeft, alignTop ]
                , boxM body4
                    |> bump
                    |> when (model.scrollIndex > 6)
                ]
                    |> row [ spacing 10, width fill ]
              , [ boxM body5
                    |> bump
                    |> when (model.scrollIndex > 8)
                    -- Prevent fadeIn bug
                    |> el []
                , lineImg 4
                    |> when (model.scrollIndex > 7)
                    |> el [ alignRight, alignTop ]
                ]
                    |> row
                        [ spacing 10
                        , width fill
                        , getEgg True
                            |> el [ moveRight 210, moveDown 140 ]
                            |> inFront
                        ]
              ]
                |> column
                    [ width fill
                    , paddingXY 20 0
                    , moveDown 260
                    , spacing 15
                    ]
                |> inFront
            , viewEggs model
                |> inFront
            , viewStats True
                |> el [ width fill, moveDown 280 ]
                |> inFront
            ]
            { src = "/world-mobile.png", description = "" }
      ]
        |> column
            [ spacing 20
            , width fill
            , height fill
            ]
    , viewFooter
    ]
        |> column
            [ width fill
            , height fill
            ]


viewDesktop : Model -> Element Msg
viewDesktop model =
    [ [ gooseIcon 100
            |> el [ padding 20 ]
      , [ image
            [ centerX
            , width <| px 276
            ]
            { src = "/logo.png", description = "" }
        , image
            [ centerX
            , width <| px 639
            ]
            { src = "/slogan.png", description = "" }
        ]
            |> column
                [ width fill
                , padding 50
                , spacing 40
                ]
      , image
            [ centerX
            , width <| px 1401
            , height <| px 3153
            , image
                [ centerX
                , moveDown 1048
                , width <| px 1311
                , height <| px 2029
                , [ image [ height <| px 97, width <| px 572, centerX ]
                        { src = "/prompt.png"
                        , description = ""
                        }
                  , infoText
                        |> column
                            [ Font.color wine
                            , Font.center
                            , cappedWidth 855
                            , centerX
                            , meriendaBold
                            , paddingXY 0 30
                            , spacing 5
                            , Font.size 22
                            ]
                  , image [ height <| px 69, width <| px 234, centerX ]
                        { src = "/roadmap.svg"
                        , description = ""
                        }
                  , [ viewBox body1 False
                        |> el
                            [ width <| px 424
                            , alignLeft
                            , fadeIn
                            , image
                                [ height <| px 176
                                , width <| px 587
                                , moveRight 200
                                , moveUp 50
                                , fadeIn
                                ]
                                { src = "/lines/1.png"
                                , description = ""
                                }
                                |> when (model.scrollIndex > 1)
                                |> below
                            ]
                        |> when (model.scrollIndex > 0)
                    , viewBox body2 False
                        |> el
                            [ width <| px 424
                            , alignRight
                            , fadeIn
                            , image
                                [ height <| px 185
                                , width <| px 550
                                , moveLeft 320
                                , moveUp 75
                                , fadeIn
                                ]
                                { src = "/lines/2.png"
                                , description = ""
                                }
                                |> when (model.scrollIndex > 3)
                                |> below
                            ]
                        |> when (model.scrollIndex > 2)
                    , viewBox body3 False
                        |> el
                            [ width <| px 424
                            , alignLeft
                            , fadeIn
                            , image
                                [ height <| px 152
                                , width <| px 491
                                , moveRight 250
                                , moveUp 60
                                , fadeIn
                                ]
                                { src = "/lines/3.png"
                                , description = ""
                                }
                                |> when (model.scrollIndex > 5)
                                |> below
                            ]
                        |> when (model.scrollIndex > 4)
                    , viewBox body4 False
                        |> el
                            [ width <| px 424
                            , alignRight
                            , fadeIn
                            , image
                                [ height <| px 127
                                , width <| px 478
                                , moveLeft 300
                                , moveUp 50
                                , fadeIn
                                ]
                                { src = "/lines/4.png"
                                , description = ""
                                }
                                |> when (model.scrollIndex > 7)
                                |> below
                            ]
                        |> when (model.scrollIndex > 6)
                    , viewBox body5 False
                        |> el
                            [ width <| px 424
                            , alignLeft
                            , fadeIn
                            , getEgg False
                                |> el [ moveRight 60, moveDown 20 ]
                                |> onRight
                            ]
                        |> when (model.scrollIndex > 8)
                    ]
                        |> column
                            [ spacing 20
                            , width fill
                            , paddingXY 100 0
                            ]
                  ]
                    |> column
                        [ width fill
                        , height fill
                        , paddingXY 0 150
                        , spacing 40
                        ]
                    |> inFront
                ]
                { src = "/parchment-desktop.svg", description = "" }
                |> inFront
            , viewEggs model
                |> inFront
            , viewStats False
                |> el [ centerX, width <| px 1000, moveDown 850 ]
                |> inFront
            ]
            { src = "/world-desktop.png", description = "" }
      ]
        |> column
            [ spacing 20
            , width fill
            , height fill
            ]
    , viewFooter
    ]
        |> column
            [ width fill
            , height fill
            ]


viewEggs : Model -> Element Msg
viewEggs model =
    model.wallet
        |> unwrap
            (viewStack model.isMobile
                (connectButton (Ticks.get 0 model.ticks)
                    model.isMobile
                    (Maybe.map .address model.wallet)
                    model.dropdown
                )
            )
            (\wallet ->
                let
                    inProgress =
                        Ticks.get 1 model.ticks
                in
                wallet.stake
                    |> unwrap
                        (wallet.nfts
                            |> Array.fromList
                            |> Array.get model.nftIndex
                            |> unwrap
                                (yellowButton False
                                    model.isMobile
                                    (gradientText "...")
                                    Nothing
                                    |> viewStack model.isMobile
                                )
                                (viewIncubate inProgress
                                    (List.length wallet.nfts > 1)
                                    model.isMobile
                                )
                        )
                        (withdrawButton inProgress model.isMobile model.time
                            >> viewStack model.isMobile
                        )
            )


infoText : List (Element msg)
infoText =
    [ [ text "NestQuest is an interactive platform tutorial designed to reward participants for using the "
      , newTabLink [ hover, Font.underline ]
            { url = "https://www.goosefx.io"
            , label = text "GooseFX"
            }
      , text " platform. There will be six total levels and tiers of NFTs as you evolve through the process. Higher tier NFTs will be extremely limited and the rewards will be vast. The first step is to connect your Tier 1 Egg NFT and incubate it for 30 days. We will be tracking usage amongst our platform with on-chain analytics."
      ]
        |> paragraph []
    , [ text "For more detailed information, check out our documentation "
      , newTabLink [ Font.underline, hover ]
            { url = docsLink
            , label = text "here"
            }
      , text "."
      ]
        |> paragraph []
    ]


viewStack : Bool -> Element Msg -> Element Msg
viewStack isMobile elem =
    [ image
        [ height <|
            px
                (if isMobile then
                    120

                 else
                    203
                )
        , centerX
        ]
        { src = "/egg-pending.png"
        , description = ""
        }
    , elem
        |> el
            [ centerX
            ]
    ]
        |> positionNFTWidget isMobile


positionNFTWidget : Bool -> List (Element msg) -> Element msg
positionNFTWidget isMobile =
    let
        down =
            if isMobile then
                80

            else
                395

        left =
            if isMobile then
                0

            else
                120
    in
    column
        [ alignRight
        , moveDown down
        , moveLeft left
        ]


viewIncubate : Bool -> Bool -> Bool -> Nft -> Element Msg
viewIncubate inProgress hasMultiple isMobile nft =
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
        , Input.button
            [ moveDown
                (if isMobile then
                    42

                 else
                    80
                )
            , alignLeft
            , moveLeft
                (if isMobile then
                    14

                 else
                    5
                )
            , hover
            ]
            { onPress =
                if inProgress then
                    Nothing

                else
                    Just <| NftSelect True
            , label =
                image
                    [ height <| px 60
                    ]
                    { src = "/back.png", description = "" }
            }
            |> when hasMultiple
            |> inFront
        , Input.button
            [ moveDown
                (if isMobile then
                    40

                 else
                    80
                )
            , alignRight
            , moveRight
                (if isMobile then
                    15

                 else
                    5
                )
            , hover
            ]
            { onPress =
                if inProgress then
                    Nothing

                else
                    Just <| NftSelect False
            , label =
                image
                    [ height <| px 60
                    ]
                    { src = "/next.png", description = "" }
            }
            |> when hasMultiple
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
        |> el
            [ centerX
            , let
                ( hd, txt ) =
                    case nft.tier of
                        Tier1 ->
                            ( "Tier 1"
                            , "This egg will need to be staked for 30 days to upgrade."
                            )

                        Tier2 ->
                            ( "Tier 2"
                            , "You will need to stake GOFX for 7 days to upgrade this NFT."
                            )

                        Tier3 ->
                            ( "Tier 3"
                            , "Your Gosling is growing stronger."
                            )
              in
              [ gradientText hd
                    |> el [ centerX, Font.size 22 ]
              , [ text txt ]
                    |> paragraph [ meriendaRegular, Font.italic, Font.color brown, Font.center, Font.size 17 ]
              ]
                |> column
                    [ Background.color sand, Border.width 3, Border.color white, Border.rounded 25, padding 15, moveDown 10, centerX, spacing 15 ]
                |> when (not isMobile)
                |> below
            ]
    ]
        |> positionNFTWidget isMobile


getEgg : Bool -> Element msg
getEgg isMobile =
    let
        w =
            if isMobile then
                150

            else
                230

        h =
            if isMobile then
                35

            else
                58

        fnt =
            if isMobile then
                14

            else
                22
    in
    newTabLink [ hover ]
        { url = "https://form.nestquest.io/"
        , label =
            [ image
                [ width <|
                    px
                        (if isMobile then
                            120

                         else
                            243
                        )
                , centerX
                ]
                { src = "/egg-present.png"
                , description = ""
                }
            , gradientText "Get an egg"
                |> el [ centerX, centerY ]
                |> el
                    [ height <| px h
                    , width <| px w
                    , Border.width 3
                    , Border.color wine
                    , Border.rounded 30
                    , Background.color sand
                    , Font.size fnt
                    ]
            ]
                |> column []
        }
        |> when False


bg : Color
bg =
    rgb255 42 42 42


brown : Color
brown =
    rgb255 139 86 10


wine : Color
wine =
    rgb255 118 78 1


sand : Color
sand =
    rgb255 233 211 148


white : Color
white =
    rgb255 255 255 255


black : Color
black =
    rgb255 0 0 0


gold : Color
gold =
    rgb255 148 98 2


meriendaRegular : Attribute msg
meriendaRegular =
    Font.family
        [ Font.typeface "Merienda Regular"
        ]


meriendaBold : Attribute msg
meriendaBold =
    Font.family
        [ Font.typeface "Merienda Bold"
        ]


boxM : ( Int, Int, String ) -> Element msg
boxM content =
    image
        [ height <| px 204
        , width <| px 278
        , viewBox content True
            |> inFront
        , fadeIn
        ]
        { src =
            "/parchment.png"
        , description = ""
        }


viewBox : ( Int, Int, String ) -> Bool -> Element msg
viewBox ( quarter, year, body ) mobile =
    let
        font =
            if mobile then
                13

            else
                20

        ( sepW, sepH ) =
            if mobile then
                ( 135, 18 )

            else
                ( 259, 35 )

        ( headW, headH ) =
            if mobile then
                ( 83, 26 )

            else
                ( 129, 50 )
    in
    [ image [ centerX, width <| px headW, height <| px headH ]
        { description = ""
        , src =
            "/headers/q"
                ++ String.fromInt quarter
                ++ "-"
                ++ String.fromInt year
                ++ ".svg"
        }
    , image [ width <| px sepW, height <| px sepH, centerX ]
        { src = "/seperator.svg"
        , description = ""
        }
    , paragraph
        [ Font.center
        , meriendaBold
        , Font.color gold
        , Font.size font
        ]
        [ text body ]
    ]
        |> column
            [ padding 30
            , spacing 10
            ]


body1 : ( Int, Int, String )
body1 =
    ( 4, 2021, "Mint Tier 1 egg NFTs and giveaway as many as possible through social channels to community participants." )


body2 : ( Int, Int, String )
body2 =
    ( 1, 2022, "Goose Nest NFT marketplace launch, and the Tier 1 eggs are listed for sale on various marketplaces." )


body3 : ( Int, Int, String )
body3 =
    ( 2, 2022, "NestQuest interactive tutorial and NFT staking released." )


body4 : ( Int, Int, String )
body4 =
    ( 3, 2022, "In-game item store opens, PVP arena battles." )


body5 : ( Int, Int, String )
body5 =
    ( 4
    , 2022
    , "Continued NestQuest metaverse development. Nest Citadel Stage, VR Art Gallery, and more!"
    )


lineImg : Int -> Element msg
lineImg n =
    image [ height <| px 172, width <| px 50, fadeIn ]
        { src = "/headers/line" ++ String.fromInt n ++ ".png"
        , description = ""
        }


bump : Element msg -> Element msg
bump elem =
    [ el [ height <| px 45 ] none
    , elem
    ]
        |> column []


hover : Attribute msg
hover =
    Element.mouseOver [ fade ]


fade : Element.Attr a b
fade =
    Element.alpha 0.7


formatAddress : String -> String
formatAddress addr =
    --|> text
    --|> el [ Font.color gold, centerX, Font.bold ]
    String.left 4 addr
        ++ "..."
        ++ String.right 4 addr


playButton : Bool -> Bool -> Maybe String -> Bool -> Bool -> Element Msg
playButton connectInProgress pulse addr playing dropdown =
    [ connectButton connectInProgress False addr dropdown
    , musicButton pulse playing
    ]
        |> row
            [ alignTop
            , alignRight
            , spacing 30
            , paddingEach
                { left = 30
                , right =
                    if playing then
                        40

                    else
                        60
                , top = 30
                , bottom = 30
                }
            ]


musicButton : Bool -> Bool -> Element Msg
musicButton pulse playing =
    Input.button
        [ hover
        , style "animation" "pulse 0.6s ease-in-out infinite alternate"
            |> whenAttr pulse
        ]
        { onPress = Just PlayTheme
        , label =
            image []
                { src =
                    if playing then
                        "/play.svg"

                    else
                        "/stop.svg"
                , description = ""
                }
        }


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
    yellowButton False
        isMobile
        (if canWithdraw then
            gradientText "Evolve"

         else
            calcCountdown diff
                |> gradientText
        )
        (if canWithdraw && not inProgress then
            Just <| Withdraw stake.mintId

         else
            Nothing
        )


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


connectButton : Bool -> Bool -> Maybe String -> Bool -> Element Msg
connectButton inProgress isMobile addr dropdown =
    [ yellowButton inProgress
        isMobile
        (addr
            |> unwrap
                (gradientText "Connect Wallet")
                (\val ->
                    [ gradientText (formatAddress val)
                    , image
                        [ height <| px 30, width <| px 30 ]
                        { src = "/caret.svg", description = "" }
                    ]
                        |> row [ spacing 10 ]
                )
        )
        (if addr == Nothing then
            Just ToggleWalletSelect

         else
            Just ToggleDropdown
        )
    , el
        [ [ Input.button [ centerX, hover ]
                { onPress = Just ChangeWallet
                , label = gradientText "Change Wallet"
                }
          , Input.button [ centerX, hover ]
                { onPress = Just Disconnect
                , label = gradientText "Disconnect Wallet"
                }
          ]
            |> column
                [ spacing 20
                , Background.color sand
                , width fill
                , padding 20
                , Border.rounded 10
                , Border.width 3
                , Border.color wine
                , Font.size
                    (if isMobile then
                        14

                     else
                        19
                    )
                ]
            |> below
            |> whenAttr dropdown
        , width fill
        ]
        none
    ]
        |> column [ spacing 10 ]


walletSelect : Bool -> Element Msg
walletSelect isMobile =
    [ gradientText "Connect to a Wallet"
        |> el [ centerX, Font.size 30 ]
    , [ text "By connecting a wallet, you agree to Goose Labs, Inc, Terms of Service and acknowledge that you have read and understand the NestQuest disclaimer."
      ]
        |> paragraph
            [ Font.center
            , meriendaRegular
            , Font.size 17
            ]
    , [ walletPill 0 isMobile
      , walletPill 1 isMobile
      , walletPill 2 isMobile
      , walletPill 3 isMobile
      ]
        |> column
            [ width fill
            , height fill
            , scrollbarY
            , spacing
                (if isMobile then
                    15

                 else
                    35
                )
            ]
    ]
        |> column
            [ centerX
            , Background.color sand
            , cappedWidth 500
            , spacing
                (if isMobile then
                    15

                 else
                    35
                )
            , padding 40
            , Border.rounded 30
            , Border.width 5
            , Border.color wine
            , cappedHeight
                (if isMobile then
                    600

                 else
                    850
                )
            , Input.button
                [ alignTop
                , alignRight
                , padding 20
                , hover
                , Font.bold
                , Font.size
                    (if isMobile then
                        25

                     else
                        35
                    )
                ]
                { onPress = Just ToggleWalletSelect
                , label = text "X"
                }
                |> inFront
            ]
        |> el
            [ width fill
            , height fill
            , paddingXY 20 50
            ]
        |> el
            [ width fill
            , height fill
            , Background.color <| rgba255 0 0 0 0.65
            ]


walletPill : Int -> Bool -> Element Msg
walletPill n isMobile =
    let
        name =
            case n of
                0 ->
                    "Phantom"

                1 ->
                    "Solflare"

                2 ->
                    "Slope"

                _ ->
                    "Ledger"

        img =
            case n of
                0 ->
                    Img.phantom

                1 ->
                    Img.solflare

                2 ->
                    Img.slope

                _ ->
                    Img.ledger
    in
    Input.button
        [ Border.rounded 60
        , Background.color <| rgb255 118 78 1
        , width fill
        , padding
            (if isMobile then
                20

             else
                40
            )
        , hover
        ]
        { onPress = Just <| ConnectWallet n
        , label =
            [ text name
                |> el [ Font.color white, meriendaRegular, Font.size 27 ]
            , image
                [ height <| px 30, width <| px 30 ]
                { src = img, description = "" }
            ]
                |> row [ spaceEvenly, width fill ]
        }


gradientText : String -> Element msg
gradientText =
    gradientTextHelper 1.2


gradientTextHelper : Float -> String -> Element msg
gradientTextHelper stroke txt =
    [ Html.text txt ]
        |> Html.div
            [ Html.Attributes.style
                "-webkit-text-stroke"
                (String.fromFloat stroke ++ "px rgb(118, 78, 1)")
            , Html.Attributes.style
                "background-image"
                """linear-gradient(
                    to bottom,
                    rgb(255, 214, 0) 26%,
                    rgb(185, 117, 14) 78%
                )"""
            , Html.Attributes.style "-webkit-background-clip" "text"
            , Html.Attributes.style "background-clip" "text"
            , Html.Attributes.style "-webkit-text-fill-color" "transparent"
            ]
        |> html
        |> el [ meriendaRegular ]


fadeIn : Attribute msg
fadeIn =
    style "animation" "fadeIn 1s"


gooseIcon : Int -> Element msg
gooseIcon n =
    newTabLink [ hover ]
        { url = "https://www.goosefx.io"
        , label =
            image
                [ width <| px n
                ]
                { src = "/brand.svg", description = "" }
        }


viewStats : Bool -> Element msg
viewStats isMobile =
    let
        fnt =
            if isMobile then
                12

            else
                30

        pd =
            if isMobile then
                20

            else
                30

        sp =
            if isMobile then
                10

            else
                30

        col =
            column
                [ Background.color sand
                , Border.width 3
                , Border.color white
                , Border.rounded 25
                , padding pd
                , spacing sp
                ]
    in
    [ [ gradientText "Total Minted NFTs"
      , text "12,366 / 25,000" |> el [ meriendaBold, Font.color brown, centerX ]
      ]
        |> col
        |> el
            [ moveUp
                (if isMobile then
                    80

                 else
                    200
                )
            ]
    , [ gradientText "NFTs In-Play"
            |> el [ centerX ]
      , text "1,167 / 12,366" |> el [ meriendaBold, Font.color brown, centerX ]
      ]
        |> col
    ]
        |> row [ width fill, spaceEvenly, Font.size fnt ]


viewSocials : Element msg
viewSocials =
    [ ( "Discord", "https://discord.gg/cDEPXpY26q" )
    , ( "Medium", "https://medium.com/goosefx" )
    , ( "Telegram", "https://www.t.me/goosefx" )
    , ( "Twitter", "https://www.twitter.com/GooseFX1" )
    ]
        |> List.map
            (\( tag, url ) ->
                newTabLink
                    [ hover
                    , Html.Attributes.title tag
                        |> htmlAttribute
                    ]
                    { url = url
                    , label =
                        image [ width <| px 40, height <| px 40 ]
                            { src = "/icons/" ++ String.toLower tag ++ ".svg"
                            , description = ""
                            }
                    }
            )
        |> row [ spacing 20 ]


viewFooter : Element msg
viewFooter =
    [ el [ width fill, height <| px 1, Background.color white ] none
    , [ gradientTextHelper 0.9 "Follow us on:"
            |> el [ centerX, Font.size 24 ]
      , viewSocials
            |> el [ centerX ]
      , text "Copyright © 2022 Goose Labs, Inc. All rights reserved."
            |> el
                [ centerX
                , meriendaRegular
                , Font.size 11
                , Font.color white
                ]
      ]
        |> column [ spacing 20, centerX, padding 30 ]
    ]
        |> column [ width fill ]


formatInt : Int -> String
formatInt =
    toFloat
        >> FormatNumber.format
            { usLocale
                | decimals =
                    FormatNumber.Locales.Exact 0
            }


yellowButton : Bool -> Bool -> Element msg -> Maybe msg -> Element msg
yellowButton inProgress isMobile elem msg =
    let
        w =
            if isMobile then
                150

            else
                230

        fnt =
            if isMobile then
                14

            else
                22
    in
    Input.button
        [ height <| px 58
        , width <| px w
        , Border.width 3
        , Border.color wine
        , Border.rounded 30
        , Background.color sand
        , Font.size fnt
        , if isJust msg then
            hover

          else
            fade
        , spinner 20
            |> el [ alignRight, paddingXY 5 0, centerY ]
            |> inFront
            |> whenAttr inProgress
        , style "cursor" "wait"
            |> whenAttr inProgress
        ]
        { onPress =
            if inProgress then
                Nothing

            else
                msg
        , label =
            elem
                |> el [ centerX ]
        }


nullByte : Char
nullByte =
    '\u{0000}'


spinner : Int -> Element msg
spinner n =
    Img.notchedCircle black n
        |> el [ spin ]


docsLink : String
docsLink =
    "https://docs.goosefx.io/tutorials/nestquest"


spin : Attribute msg
spin =
    style "animation" "rotation 0.7s infinite linear"
