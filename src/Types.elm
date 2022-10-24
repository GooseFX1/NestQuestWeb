module Types exposing (AltarState(..), Modal(..), Model, Msg(..), Nft, PrizeStatus(..), Screen, SignatureData, Stake, Tier(..), View(..), Wallet)

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
    , selected : Maybe Int
    , prizeStatus : PrizeStatus
    , backendUrl : String
    , view : View
    , modal : Maybe Modal
    , altarState : AltarState

    -- Spinners:
    -- 0: wallet connect
    -- 1: NFT stake/withdraw/upgrade/claim orb
    , ticks : Ticks
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
    | Tier3UpgradeCb (Result Http.Error (Result String String))
    | Tier4UpgradeCb String (Result Http.Error (Result String ()))
    | StatusCb (Result Http.Error Int)
    | SelectNft (Maybe Int)
    | ToggleTent
    | ToggleInventory
    | ToggleAltar
    | SelectChest Int
    | SelectChestCb (Result Http.Error (Result String (Maybe (List Int))))
    | ClaimOrb (List Int)
    | ClaimOrbResponse (Maybe String)
    | SetView View
    | ProgressAltar


type alias Screen =
    { width : Int
    , height : Int
    }


type alias Wallet =
    { address : String
    , stake : Maybe Stake
    , nfts : List Nft
    , orbs : Int
    }


type alias Stake =
    { mintId : String
    , stakingStart : Int
    }


type alias Nft =
    { mintId : String
    , name : String
    , tier : Tier
    , id : Int
    }


type alias SignatureData =
    { mintId : String
    , signature : String
    }


type View
    = ViewHome
    | ViewGame


type Tier
    = Tier1
    | Tier2
    | Tier3
    | Tier4


type PrizeStatus
    = Checking
    | ReadyToChoose
    | Choosing Int
    | WaitUntilTomorrow
    | AlreadyClaimed
    | ClaimYourPrize (List Int)


type Modal
    = ModalInventory
    | ModalTent
    | ModalAltar


type AltarState
    = AltarStage1
    | AltarStage2
    | AltarSuccess
    | AltarError String
