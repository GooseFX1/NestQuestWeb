module View exposing (view)

import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Helpers.View exposing (cappedWidth)
import Html exposing (Html)
import Types exposing (Model, Msg)


view : Model -> Html Msg
view _ =
    [ [ image [ centerX, width <| px 500 ] { src = "/logo.png", description = "" }
      , image [ centerX, width <| px 500 ] { src = "/slogan.png", description = "" }
      ]
        |> column
            [ width fill
            , padding 50
            ]
    , image
        [ cappedWidth 1200
        , centerX
        , [ box body1 True
          , [ lineImg 1
            , box body2 False
                |> bump
            ]
                |> row [ spacing 20, alignRight ]
          , [ box body3 True
                |> bump
            , lineImg 2
            ]
                |> row [ spacing 20, alignLeft ]
          , [ lineImg 3
            , box body4 False
                |> bump
            ]
                |> row [ spacing 20, alignRight ]
          , [ box body5 True
                |> bump
            , lineImg 4
            ]
                |> row [ spacing 20, alignLeft ]
          ]
            |> column
                [ cappedWidth 900
                , centerX
                , moveDown 600
                , spacing 15
                ]
            |> inFront
        ]
        { src = "/island.png", description = "" }
    ]
        |> column
            [ spacing 20
            , width fill
            , height fill
            ]
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


box : ( Int, Int, String ) -> Bool -> Element msg
box ( quarter, year, body ) left =
    let
        h =
            300
    in
    [ image [ centerX, width <| px 120 ]
        { description = ""
        , src =
            "/headers/q"
                ++ String.fromInt quarter
                ++ "-"
                ++ String.fromInt year
                ++ ".png"
        }
    , [ hairline
      , "🥚"
            |> text
            |> el [ Font.size 30 ]
      , hairline
      ]
        |> row [ spacing 10, centerX, width <| px 300 ]
    , paragraph [ Font.center, meriendaBold, Font.color gold ] [ text body ]
    ]
        |> column
            [ Background.image "/parchment.png"
            , if left then
                alignLeft

              else
                alignRight
            , width <| px <| round (h * 1.8)
            , height <| px h
            , padding 40
            , spacing 30
            ]


hairline : Element msg
hairline =
    el [ height <| px 3, width fill, Background.color black ] none


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
    ( 3
      --4
    , 2022
    , "Continued NestQuest metaverse development. Nest Citadel Stage, VR Art Gallery, and more!"
    )


lineImg : Int -> Element msg
lineImg n =
    image [ height <| px 200, alignTop ]
        { src = "/headers/line" ++ String.fromInt n ++ ".png"
        , description = ""
        }


bump : Element msg -> Element msg
bump elem =
    [ el [ height <| px 20 ] none
    , elem
    ]
        |> column []
