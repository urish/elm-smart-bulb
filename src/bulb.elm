module App exposing (..)

import Html exposing (Html, button, div, text, h3, program)
import Html.Events exposing (onClick)

import Bluetooth exposing (requestDevice, devices)

-- CONSTANTS

bulbService = "0xffe5"
bulbCharacteristic = "0xffe9"

-- MODEL

type alias Device = 
    { name : String
    , id : String
    }

type Connection = 
    NotConnected
    | Connected Device

type alias Model = 
    { connection: Connection 
    }

init : ( Model, Cmd Msg )
init =
    (Model NotConnected, Cmd.none )

-- MESSAGES

type Msg
    = Disconnect
    | RequestDevice
    | SetColor Int Int Int
    | DeviceConnected Bluetooth.DeviceInfo

-- VIEW

view : Model -> Html Msg
view model =
    case model.connection of
        Connected device ->
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

        NotConnected ->
            div []
                [ button [ onClick RequestDevice ] [ text "Connect" ] ]

-- UPDATE

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model.connection of 
        NotConnected -> 
            case msg of 
                RequestDevice ->
                    ( model, Bluetooth.requestDevice bulbService )

                DeviceConnected deviceInfo ->
                    ( Model (Connected (Device deviceInfo.name deviceInfo.id)), Cmd.none)

                otherwise -> 
                    ( model, Cmd.none )

        Connected device -> 
            case msg of
                Disconnect ->
                    ( Model NotConnected, Bluetooth.disconnect device.id )

                SetColor r g b ->
                    ( model, Bluetooth.writeValue (Bluetooth.WriteParams device.id bulbService bulbCharacteristic [0x56, r, g, b, 0x00, 0xf0, 0xaa]))

                otherwise -> 
                    ( model, Cmd.none )

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
    (Bluetooth.devices DeviceConnected)

-- MAIN

main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
