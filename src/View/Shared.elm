module View.Shared exposing (..)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import FormatNumber
import FormatNumber.Locales exposing (usLocale)
import Helpers.View exposing (cappedHeight, cappedWidth, style, when, whenAttr, whenJust)
import Html
import Html.Attributes
import Maybe.Extra exposing (isJust, unwrap)
import Types
import View.Img as Img


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


formatAddress : String -> String
formatAddress addr =
    String.left 4 addr
        ++ "..."
        ++ String.right 4 addr


spin : Attribute msg
spin =
    style "animation" "rotation 0.7s infinite linear"


spinner : Int -> Element msg
spinner n =
    Img.notchedCircle black n
        |> el [ spin ]


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


connectButton : Bool -> Bool -> Maybe String -> Bool -> Element Types.Msg
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
            Just Types.ToggleWalletSelect

         else
            Just Types.ToggleDropdown
        )
    , el
        [ [ Input.button [ centerX, hover ]
                { onPress = Just Types.ChangeWallet
                , label = gradientText "Change Wallet"
                }
          , Input.button [ centerX, hover ]
                { onPress = Just Types.Disconnect
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


nullByte : Char
nullByte =
    '\u{0000}'


formatInt : Int -> String
formatInt =
    toFloat
        >> FormatNumber.format
            { usLocale
                | decimals =
                    FormatNumber.Locales.Exact 0
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


fadeIn : Attribute msg
fadeIn =
    style "animation" "fadeIn 1s"


hover : Attribute msg
hover =
    Element.mouseOver [ fade ]


fade : Element.Attr a b
fade =
    Element.alpha 0.7


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
