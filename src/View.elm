module View exposing (view)

import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Helpers.View exposing (cappedWidth, when, whenAttr)
import Html exposing (Html)
import Maybe.Extra exposing (unwrap)
import Types exposing (Model, Msg, State)


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
        , [ boxM body1 True
          , [ lineImg 1
            , boxM body2 False
                |> bump
            ]
                |> row [ spacing 20, alignRight ]
          , [ boxM body3 True
                |> bump
            , lineImg 2
            ]
                |> row [ spacing 20, alignLeft ]
          , [ lineImg 3
            , boxM body4 False
                |> bump
            ]
                |> row [ spacing 20, alignRight ]
          , [ boxM body5 True
                |> bump
            , lineImg 4
            ]
                |> row [ spacing 20, alignLeft ]
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
        --{ onPress = Just Types.Connect
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
                    { src = "/roadmap.png"
                    , description = ""
                    }
              , [ viewBox body1 False
                    |> el
                        [ width <| px 424
                        , alignLeft
                        , image
                            [ height <| px 176
                            , width <| px 587
                            , moveRight 200
                            , moveUp 50
                            ]
                            { src = "/lines/1.png"
                            , description = ""
                            }
                            |> below
                        ]
                , viewBox body2 False
                    |> el
                        [ width <| px 424
                        , alignRight
                        , image
                            [ height <| px 185
                            , width <| px 550
                            , moveLeft 320
                            , moveUp 75
                            ]
                            { src = "/lines/2.png"
                            , description = ""
                            }
                            |> below
                        ]
                , viewBox body3 False
                    |> el
                        [ width <| px 424
                        , alignLeft
                        , image
                            [ height <| px 152
                            , width <| px 491
                            , moveRight 250
                            , moveUp 60
                            ]
                            { src = "/lines/3.png"
                            , description = ""
                            }
                            |> below
                        ]
                , viewBox body4 False
                    |> el
                        [ width <| px 424
                        , alignRight
                        , image
                            [ height <| px 127
                            , width <| px 478
                            , moveLeft 300
                            , moveUp 50
                            ]
                            { src = "/lines/4.png"
                            , description = ""
                            }
                            |> below
                        ]
                , viewBox body5 False
                    |> el [ width <| px 424, alignLeft ]
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


boxM : ( Int, Int, String ) -> Bool -> Element msg
boxM content left =
    image
        [ height <| px 204
        , width <| px 278
        , if left then
            alignLeft

          else
            alignRight
        , viewBox content True
            |> inFront
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
                ++ ".png"
        }
    , image [ width <| px sepW, height <| px sepH, centerX ]
        { src = "/sep.png"
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
    image [ height <| px 172, width <| px 70, alignTop ]
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
        { onPress = Just Types.Stake
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
