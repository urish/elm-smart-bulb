port module Bluetooth exposing (..)

port requestDevice: (String) -> Cmd cmd

type alias DeviceInfo = 
    { id: String
    , name: String
    }

port devices : (DeviceInfo -> msg) -> Sub msg

type alias WriteParams =
    { device : String
    , service : String
    , characteristic : String
    , value: List Int
    }


port writeValue : WriteParams -> Cmd cmd

port disconnect : String -> Cmd cmd

port error : (String -> msg) -> Sub msg
