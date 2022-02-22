module Types exposing (Flags, Model, Msg(..), State)


type alias Model =
    { isMobile : Bool
    , wallet : Maybe State
    , themePlaying : Bool
    , scrollIndex : Int
    }


type alias Flags =
    { screen : Screen
    }


type alias Screen =
    { width : Int
    , height : Int
    }


type alias State =
    { address : String
    , nfts : List String
    }


type Msg
    = Connect
    | ConnectResponse (Maybe State)
    | Stake
    | PlayTheme
    | Scroll Int
