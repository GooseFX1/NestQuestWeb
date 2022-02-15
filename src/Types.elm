module Types exposing (Flags, Model, Msg(..))


type alias Model =
    { isMobile : Bool
    , wallet : Maybe String
    }


type alias Flags =
    { screen : Screen
    }


type alias Screen =
    { width : Int
    , height : Int
    }


type Msg
    = Connect
    | ConnectResponse (Maybe String)
