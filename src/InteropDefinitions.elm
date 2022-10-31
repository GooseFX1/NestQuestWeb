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
    | ClaimOrb String (List Int)


type ToElm
    = AlreadyStaked String
    | ConnectResponse (Maybe Types.Wallet)
    | StakeResponse (Maybe Types.Stake)
    | WithdrawResponse (Maybe Types.Nft)
    | SignResponse (Maybe Types.SignatureData)
    | ClaimOrbResponse (Maybe String)


type alias Flags =
    { screen : Types.Screen
    , now : Int
    , backendUrl : String
    }


fromElm : Encoder FromElm
fromElm =
    TsEncode.union
        (\vLog vAlert vPlayTheme vStopTheme vWithdraw vConnect vDisconnect vSignTimestamp vStake vClaim value ->
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

                ClaimOrb mintId sig ->
                    vClaim { mintId = mintId, sig = sig }
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
        |> TsEncode.variantTagged "claim"
            (TsEncode.object
                [ TsEncode.required "mintId" .mintId TsEncode.string
                , TsEncode.required "sig" .sig (TsEncode.list TsEncode.int)
                ]
            )
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
          , TsDecode.map4 Types.Wallet
                (TsDecode.field "address" TsDecode.string)
                (TsDecode.field "stake" (TsDecode.nullable decodeStake))
                (TsDecode.field "nfts" (TsDecode.list decodeNft))
                (TsDecode.field "orbs" TsDecode.int)
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
        , ( "claimResponse"
          , TsDecode.string
                |> TsDecode.nullable
                |> TsDecode.field "data"
                |> TsDecode.map ClaimOrbResponse
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
    TsDecode.map3
        (\mintId name tier ->
            { mintId = mintId
            , name = name
            , tier = tier
            , id =
                name
                    |> String.filter ((/=) nullByte)
                    |> String.split "#"
                    |> List.reverse
                    |> List.head
                    |> Maybe.andThen String.toInt
                    |> Maybe.withDefault 99999
            }
        )
        (TsDecode.field "mintId" TsDecode.string)
        (TsDecode.field "name" TsDecode.string)
        (TsDecode.field "tier" decodeTier)


nullByte : Char
nullByte =
    '\u{0000}'


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

                    3 ->
                        Types.Tier3

                    _ ->
                        Types.Tier4
            )


flags : Decoder Flags
flags =
    TsDecode.map3 Flags
        (TsDecode.field "screen" decodeScreen)
        (TsDecode.field "now" TsDecode.int)
        (TsDecode.field "backendUrl" TsDecode.string)
