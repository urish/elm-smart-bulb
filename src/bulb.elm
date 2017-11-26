module App exposing (..)

import Html exposing (Html, button, div, text, h1, h3, p, program)
import Html.Events exposing (onClick)
import RemoteData exposing (RemoteData(..))

import Bluetooth exposing (requestDevice, devices)

-- CONSTANTS

bulbService = "0xffe5"
bulbCharacteristic = "0xffe9"

-- MODEL

type alias Device = 
    { name : String
    , id : String
    }

type alias BluetoothError = 
    String

type alias BluetoothData = RemoteData BluetoothError Device

type alias Model = 
    { connection: BluetoothData
    }

init : ( Model, Cmd Msg )
init =
    (Model NotAsked, Cmd.none )

-- MESSAGES

type Msg
    = Disconnect
    | RequestDevice
    | SetColor Int Int Int
    | DeviceConnected Bluetooth.DeviceInfo
    | Error BluetoothError
    | Restart

-- VIEW

view : Model -> Html Msg
view model =
    case model.connection of
        Success device ->
            div []
                [   text "Connected to: "
                ,   text (device.name)

                ,   h3 [] [ text "Connection" ]
                ,   button [ onClick Disconnect ] [ text "Disconnect" ]

                ,   h3 [] [ text "Colors" ]
                ,   button [ onClick (SetColor 0xff 0 0)] [ text "Red"]
                ,   button [ onClick (SetColor 0 0xff 0)] [ text "Green"]
                ,   button [ onClick (SetColor 0 0 0xff)] [ text "Blue"]
                ,   button [ onClick (SetColor 0 0 0)] [ text "Off"]
                ]

        NotAsked ->
            div []
                [ button [ onClick RequestDevice ] [ text "Connect" ] ]

        Loading ->
            div []
                [ text "Connecting..."]

        Failure error ->
            div []
                [ h1 [] [text "Connection error"]
                , p [] [text error]
                , button [ onClick Restart ] [ text "Restart" ]
                ]

-- UPDATE

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model.connection of 
        NotAsked -> 
            case msg of 
                RequestDevice ->
                    ( Model Loading, Bluetooth.requestDevice bulbService )

                otherwise -> 
                    ( model, Cmd.none )

        Success device -> 
            case msg of
                Disconnect ->
                    ( Model NotAsked, Bluetooth.disconnect device.id )

                SetColor r g b ->
                    ( model, Bluetooth.writeValue (Bluetooth.WriteParams device.id bulbService bulbCharacteristic [0x56, r, g, b, 0x00, 0xf0, 0xaa]))

                Error err ->
                    ( Model (Failure err), Cmd.none )

                otherwise -> 
                    ( model, Cmd.none )

        otherwise ->
            case msg of 
                DeviceConnected deviceInfo ->
                    ( Model (Success (Device deviceInfo.name deviceInfo.id)), Cmd.none)

                Error err ->
                    ( Model (Failure err), Cmd.none )
                
                Restart ->
                    ( Model NotAsked, Cmd.none )

                otherwise ->
                    ( model, Cmd.none)
        
-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ (Bluetooth.devices DeviceConnected)
        , (Bluetooth.error Error)
    ]

-- MAIN

main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
