module Types exposing (Flags, Model, Msg(..), Stake, State)

import Time exposing (Posix)


type alias Model =
    { isMobile : Bool
    , wallet : Maybe State
    , themePlaying : Bool
    , scrollIndex : Int
    , walletSelect : Bool
    , dropdown : Bool
    , time : Int
    , scrollStart : Int
    , playButtonPulse : Bool
    , withdrawComplete : Bool
    }


type alias Flags =
    { screen : Screen
    , now : Int
    }


type alias Screen =
    { width : Int
    , height : Int
    }


type alias State =
    { address : String
    , stake : Maybe Stake
    , nfts : List String
    }


type alias Stake =
    { mintId : String
    , stakingStart : Int
    }


type Msg
    = Connect
    | ConnectResponse (Maybe State)
    | PlayTheme
    | Scroll Int
    | Select Int
    | Convert
    | Disconnect
    | ChangeWallet
    | Incubate
    | Withdraw String
    | AlreadyStaked String
    | StakeResponse (Maybe Stake)
    | WithdrawResponse ()
    | Tick Posix
