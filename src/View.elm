module View exposing (view)

import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
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
        [ width fill
        , [ box body1 True
          , box body2 False
          , box body3 True
          , box body4 False
          , box body5 True
          ]
            |> column [ width <| px 1000, centerX, moveDown 700, spacing 60 ]
            |> inFront
        ]
        { src = "/island.png", description = "" }
    ]
        |> column
            [ spacing 20
            , width fill
            , height fill
            , Font.family
                [ Font.serif
                ]
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


box ( quarter, year, body ) left =
    let
        h =
            300
    in
    [ [ "Q"
            ++ String.fromInt quarter
            |> text
            |> el [ Font.size 30, Font.bold ]
      , String.fromInt year
            |> text
            |> el [ Font.size 20, Font.bold ]
      ]
        |> row [ centerX, spacing 10 ]
    , [ hairline
      , "🥚"
            |> text
            |> el [ Font.size 30 ]
      , hairline
      ]
        |> row [ spacing 10, centerX, width <| px 300 ]
    , paragraph [ Font.center ] [ text body ]
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


hairline =
    el [ height <| px 3, width fill, Background.color black ] none


body1 =
    ( 4, 2021, "Mint Tier 1 egg NFTs and giveaway as many as possible through social channels to community participants." )


body2 =
    ( 1, 2022, "Goose Nest NFT marketplace launch, and the Tier 1 eggs are listed for sale on various marketplaces." )


body3 =
    ( 2, 2022, "NestQuest interactive tutorial and NFT staking released." )


body4 =
    ( 3, 2022, "In-game item store opens, PVP arena battles." )


body5 =
    ( 4, 2022, "Continued NestQuest metaverse development. Nest Citadel Stage, VR Art Gallery, and more!" )
