module Types exposing (Flags, Model, Msg(..), Nft, Stake, Wallet)

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


type alias Flags =
    { screen : Screen
    , now : Int
    }


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
    , tier : Int
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
    | WithdrawResponse ()
    | Tick Posix
    | NftSelect Bool
    | SignTimestamp
    | SignResponse { timestamp : Int, signature : String }
