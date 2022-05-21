module InteropDefinitions exposing (Flags, FromElm(..), ToElm(..), interop)

import TsJson.Decode as TsDecode exposing (Decoder)
import TsJson.Encode as TsEncode exposing (Encoder)
import Types


interop :
    { toElm : Decoder ToElm
    , fromElm : Encoder FromElm
    , flags : Decoder Flags
    }
interop =
    { toElm = toElm
    , fromElm = fromElm
    , flags = flags
    }


type FromElm
    = Log String
    | Alert String
    | PlayTheme
    | StopTheme
    | Withdraw String
    | Connect Int
    | Disconnect
    | SignTimestamp String
    | Stake String


type ToElm
    = AlreadyStaked String
    | ConnectResponse (Maybe Types.Wallet)
    | StakeResponse (Maybe Types.Stake)
    | WithdrawResponse (Maybe Types.Nft)
    | SignResponse (Maybe Types.SignatureData)


type alias Flags =
    { screen : Types.Screen
    , now : Int
    }


fromElm : Encoder FromElm
fromElm =
    TsEncode.union
        (\vLog vAlert vPlayTheme vStopTheme vWithdraw vConnect vDisconnect vSignTimestamp vStake value ->
            case value of
                Log string ->
                    vLog string

                Alert string ->
                    vAlert string

                PlayTheme ->
                    vPlayTheme ()

                StopTheme ->
                    vStopTheme ()

                Withdraw string ->
                    vWithdraw string

                Connect id ->
                    vConnect id

                Disconnect ->
                    vDisconnect ()

                SignTimestamp mintId ->
                    vSignTimestamp mintId

                Stake string ->
                    vStake string
        )
        |> TsEncode.variantTagged "log" TsEncode.string
        |> TsEncode.variantTagged "alert" TsEncode.string
        |> TsEncode.variantTagged "playTheme" TsEncode.null
        |> TsEncode.variantTagged "stopTheme" TsEncode.null
        |> TsEncode.variantTagged "withdraw" TsEncode.string
        |> TsEncode.variantTagged "connect" TsEncode.int
        |> TsEncode.variantTagged "disconnect" TsEncode.null
        |> TsEncode.variantTagged "signTimestamp" TsEncode.string
        |> TsEncode.variantTagged "stake" TsEncode.string
        |> TsEncode.buildUnion


toElm : Decoder ToElm
toElm =
    TsDecode.discriminatedUnion "tag"
        [ ( "alreadyStaked"
          , TsDecode.string
                |> TsDecode.field "data"
                |> TsDecode.map AlreadyStaked
          )
        , ( "connectResponse"
          , TsDecode.map3 Types.Wallet
                (TsDecode.field "address" TsDecode.string)
                (TsDecode.field "stake" (TsDecode.nullable decodeStake))
                (TsDecode.field "nfts" (TsDecode.list decodeNft))
                |> TsDecode.nullable
                |> TsDecode.field "data"
                |> TsDecode.map ConnectResponse
          )
        , ( "stakeResponse"
          , decodeStake
                |> TsDecode.nullable
                |> TsDecode.field "data"
                |> TsDecode.map StakeResponse
          )
        , ( "withdrawResponse"
          , decodeNft
                |> TsDecode.nullable
                |> TsDecode.field "data"
                |> TsDecode.map WithdrawResponse
          )
        , ( "signResponse"
          , decodeTs
                |> TsDecode.nullable
                |> TsDecode.field "data"
                |> TsDecode.map SignResponse
          )
        ]


decodeTs : Decoder Types.SignatureData
decodeTs =
    TsDecode.map2 Types.SignatureData
        (TsDecode.field "mintId" TsDecode.string)
        (TsDecode.field "signature" TsDecode.string)


decodeStake : Decoder Types.Stake
decodeStake =
    TsDecode.map2 Types.Stake
        (TsDecode.field "mintId" TsDecode.string)
        (TsDecode.field "stakingStart" TsDecode.int)


decodeScreen : Decoder Types.Screen
decodeScreen =
    TsDecode.map2 Types.Screen
        (TsDecode.field "width" TsDecode.int)
        (TsDecode.field "height" TsDecode.int)


decodeNft : Decoder Types.Nft
decodeNft =
    TsDecode.map3 Types.Nft
        (TsDecode.field "mintId" TsDecode.string)
        (TsDecode.field "name" TsDecode.string)
        (TsDecode.field "tier" decodeTier)


decodeTier : Decoder Types.Tier
decodeTier =
    TsDecode.int
        |> TsDecode.map
            (\n ->
                case n of
                    1 ->
                        Types.Tier1

                    2 ->
                        Types.Tier2

                    _ ->
                        Types.Tier3
            )


flags : Decoder Flags
flags =
    TsDecode.map2 Flags
        (TsDecode.field "screen " decodeScreen)
        (TsDecode.field "now" TsDecode.int)
