module Types exposing (Model, Msg(..), Nft, Screen, SignatureData, Stake, Tier(..), Wallet)

import Http
import Json.Decode
import Time exposing (Posix)


type alias Model =
    { isMobile : Bool
    , wallet : Maybe Wallet
    , themePlaying : Bool
    , scrollIndex : Int
    , walletSelect : Bool
    , dropdown : Bool
    , time : Int
    , scrollStart : Int
    , playButtonPulse : Bool
    , withdrawComplete : Bool
    , nftIndex : Int
    }


type Msg
    = Connect
    | ConnectResponse (Maybe Wallet)
    | PlayTheme
    | Scroll Int
    | Select Int
    | ToggleDropdown
    | Disconnect
    | ChangeWallet
    | Incubate
    | Withdraw String
    | AlreadyStaked String
    | StakeResponse (Maybe Stake)
    | WithdrawResponse
    | Tick Posix
    | NftSelect Bool
    | SignTimestamp String
    | SignResponse SignatureData
    | PortFail Json.Decode.Error
    | UpgradeCb (Result Http.Error String)


type alias Screen =
    { width : Int
    , height : Int
    }


type alias Wallet =
    { address : String
    , stake : Maybe Stake
    , nfts : List Nft
    }


type alias Stake =
    { mintId : String
    , stakingStart : Int
    }


type alias Nft =
    { mintId : String
    , name : String
    , tier : Tier
    }


type alias SignatureData =
    { mintId : String
    , signature : String
    }


type Tier
    = Tier1
    | Tier2
    | Tier3
