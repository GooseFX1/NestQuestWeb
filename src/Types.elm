module Types exposing (Flags, Model, Msg(..), State)


type alias Model =
    { isMobile : Bool
    , wallet : Maybe State
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
    , count : Int
    }


type Msg
    = Connect
    | ConnectResponse (Maybe State)
