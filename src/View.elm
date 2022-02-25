module View exposing (view)

import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Helpers.View exposing (style, when)
import Html exposing (Html)
import Html.Events
import Json.Decode as JD
import Types exposing (Model, Msg(..), State)


view : Model -> Html Msg
view model =
    (if model.isMobile then
        viewMobile model

     else
        viewDesktop model
    )
        |> Element.layoutWith
            { options =
                [ Element.focusStyle
                    { borderColor = Nothing
                    , backgroundColor = Nothing
                    , shadow = Nothing
                    }
                ]
            }
            [ width fill
            , height fill
            , Background.color bg
            , scrollbarY
            , JD.at [ "target", "scrollTop" ] JD.float
                |> JD.map (round >> Scroll)
                |> Html.Events.on "scroll"
                |> htmlAttribute
            , playButton model.themePlaying
                |> inFront
            ]


viewMobile : Model -> Element Msg
viewMobile model =
    [ [ image
            [ centerX
            , width <|
                if model.isMobile then
                    fill

                else
                    px 500
            ]
            { src = "/logo.png", description = "" }
      , [ image
            [ centerX
            , width <|
                if model.isMobile then
                    fill

                else
                    px 500
            ]
            { src = "/slogan.png", description = "" }
        ]
            |> column [ width fill, spacing 15 ]
      ]
        |> column
            [ width fill
            , padding 50
            ]
    , image
        [ width <| px 390
        , height <| px 1732
        , centerX
        , [ boxM body1
                |> when (model.scrollIndex > 0)
          , [ lineImg 1
                |> when (model.scrollIndex > 1)
                |> el [ alignLeft, alignTop ]
            , boxM body2
                |> bump
                |> when (model.scrollIndex > 2)
            ]
                |> row [ spacing 20, width fill ]
          , [ boxM body3
                |> bump
                |> when (model.scrollIndex > 4)
                -- Prevent fadeIn bug
                |> el []
            , lineImg 2
                |> when (model.scrollIndex > 3)
                |> el [ alignRight, alignTop ]
            ]
                |> row [ spacing 20, width fill ]
          , [ lineImg 3
                |> when (model.scrollIndex > 5)
                |> el [ alignLeft, alignTop ]
            , boxM body4
                |> bump
                |> when (model.scrollIndex > 6)
            ]
                |> row [ spacing 20, width fill ]
          , [ boxM body5
                |> bump
                |> when (model.scrollIndex > 8)
                -- Prevent fadeIn bug
                |> el []
            , lineImg 4
                |> when (model.scrollIndex > 7)
                |> el [ alignRight, alignTop ]
            ]
                |> row [ spacing 20, width fill ]
          ]
            |> column
                [ width fill
                , paddingXY 20 0
                , moveDown 260
                , spacing 15
                ]
            |> inFront
        ]
        { src = "/world-mobile.png", description = "" }
    ]
        |> column
            [ spacing 20
            , width fill
            , height fill
            ]


viewDesktop : Model -> Element Msg
viewDesktop model =
    [ [ image
            [ centerX
            , width <|
                if model.isMobile then
                    fill

                else
                    px 500
            ]
            { src = "/logo.png", description = "" }
      , [ image
            [ centerX
            , width <|
                if model.isMobile then
                    fill

                else
                    px 500
            ]
            { src = "/slogan.png", description = "" }

        --, model.wallet
        --|> unwrap
        --(Input.button
        --[ Font.underline
        --, Font.color gold
        --, blackChancery
        --, Font.size 30
        --, centerX
        --, hover
        --]
        --{ onPress = Just Connect
        --, label = text "Connect wallet"
        --}
        --)
        --viewState
        ]
            |> column [ width fill, spacing 15 ]
      ]
        |> column
            [ width fill
            , padding 50
            ]
    , image
        [ centerX
        , width <| px 1401
        , height <| px 3155
        , image
            [ centerX
            , moveDown 1048
            , width <| px 1199
            , height <| px 1641
            , [ image [ height <| px 69, width <| px 234, centerX ]
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
                        ]
                    |> when (model.scrollIndex > 8)
                ]
                    |> column
                        [ spacing 20
                        , width fill
                        , paddingXY 100 50
                        ]
              ]
                |> column [ width fill, height fill, paddingXY 0 150 ]
                |> inFront
            ]
            { src = "/parchment-large.png", description = "" }
            |> inFront
        ]
        { src = "/world-desktop.png", description = "" }
    ]
        |> column
            [ spacing 20
            , width fill
            , height fill
            ]


bg : Color
bg =
    rgb255 42 42 42


black : Color
black =
    rgb255 0 0 0


gold : Color
gold =
    rgb255 148 98 2


meriendaBold : Attribute msg
meriendaBold =
    Font.family
        [ Font.typeface "Merienda Bold"
        ]


blackChancery : Attribute msg
blackChancery =
    Font.family
        [ Font.typeface "Black Chancery"
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
    [ el [ height <| px 65 ] none
    , elem
    ]
        |> column []


hover : Attribute msg
hover =
    Element.mouseOver [ fade ]


fade : Element.Attr a b
fade =
    Element.alpha 0.7


viewState : State -> Element Msg
viewState state =
    [ Input.button []
        { onPress = Just Stake
        , label = formatAddress state.address
        }
    , paragraph [ Font.color gold, Font.italic, Font.center ]
        [ "You have "
            ++ String.fromInt (List.length state.nfts)
            ++ " NestQuest NFT(s)."
            |> text
        ]
    ]
        |> column [ spacing 10, centerX ]


formatAddress : String -> Element msg
formatAddress addr =
    (String.left 6 addr
        ++ "..."
        ++ String.right 6 addr
    )
        |> text
        |> el [ Font.color gold, centerX, Font.bold ]


playButton : Bool -> Element Msg
playButton playing =
    Input.button
        [ alignTop
        , alignRight
        , hover
        , paddingEach
            { left = 30
            , right =
                if playing then
                    50

                else
                    30
            , top = 30
            , bottom = 30
            }
        ]
        { onPress = Just PlayTheme
        , label =
            image []
                { src =
                    if playing then
                        "/stop.svg"

                    else
                        "/play.svg"
                , description = ""
                }
        }


fadeIn : Attribute msg
fadeIn =
    style "animation" "fadeIn 1s"
