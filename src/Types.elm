module Types exposing (Model, Msg(..), Nft, PrizeStatus(..), Screen, SignatureData, Stake, Tier(..), Wallet)

import Http
import Json.Decode
import Ticks exposing (Ticks)
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
    , nftIndex : Int

    -- Spinners:
    -- 0: wallet connect
    -- 1: NFT stake/withdraw/upgrade
    , ticks : Ticks
    , selected : Maybe Nft
    , tentOpen : Bool
    , prizeStatus : PrizeStatus
    , backendUrl : String
    }


type Msg
    = ToggleWalletSelect
    | ConnectResponse (Maybe Wallet)
    | PlayTheme
    | Scroll Int
    | ConnectWallet Int
    | ToggleDropdown
    | Disconnect
    | ChangeWallet
    | Incubate String
    | Withdraw String
    | AlreadyStaked String
    | StakeResponse (Maybe Stake)
    | WithdrawResponse (Maybe Nft)
    | Tick Posix
    | NftSelect Bool
    | SignTimestamp String
    | SignResponse (Maybe SignatureData)
    | PortFail Json.Decode.Error
    | UpgradeCb (Result Http.Error (Result String String))
    | StatusCb (Result Http.Error Int)
    | SelectNft (Maybe Nft)
    | ToggleTent
    | SelectChest Int
    | SelectChestCb (Result Http.Error (Result String (Maybe (List Int))))
    | ClaimOrb (List Int)
    | ClaimOrbResponse (Maybe String)


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


type PrizeStatus
    = Checking
    | ReadyToChoose
    | Choosing Int
    | WaitUntilTomorrow
    | AlreadyClaimed
    | ClaimYourPrize (List Int)
