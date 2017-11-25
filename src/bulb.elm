module App exposing (..)

import Html exposing (Html, button, div, text, h3, program)
import Html.Events exposing (onClick)

import Bluetooth exposing (requestDevice, devices)

-- CONSTANTS

bulbService = "0xffe5"
bulbCharacteristic = "0xffe9"

-- MODEL

type alias Model =
    { connected: Bool
    , deviceName: String
    , deviceId: String
    }

init : ( Model, Cmd Msg )
init =
    (Model False "" "", Cmd.none )

-- MESSAGES

type Msg
    = Disconnect
    | RequestDevice
    | SetColor Int Int Int
    | Connected Bluetooth.DeviceInfo

-- VIEW

view : Model -> Html Msg
view model =
    if model.connected then
        div []
            [   text "Connected to: "
            ,   text (model.deviceName)

            ,   h3 [] [ text "Connection" ]
            ,   button [ onClick Disconnect ] [ text "Disconnect" ]

            ,   h3 [] [ text "Colors" ]
            ,   button [ onClick (SetColor 0xff 0 0)] [ text "Red"]
            ,   button [ onClick (SetColor 0 0xff 0)] [ text "Green"]
            ,   button [ onClick (SetColor 0 0 0xff)] [ text "Blue"]
            ,   button [ onClick (SetColor 0 0 0)] [ text "Off"]
            ]
    else
        div []
            [ button [ onClick RequestDevice ] [ text "Connect" ] ]

-- UPDATE

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Disconnect ->
            ( Model False "" "", Bluetooth.disconnect model.deviceId )

        RequestDevice ->
            ( model, Bluetooth.requestDevice bulbService )

        Connected deviceInfo ->
            ( Model True deviceInfo.name deviceInfo.id, Cmd.none)

        SetColor r g b ->
            ( model, Bluetooth.writeValue (Bluetooth.WriteParams model.deviceId bulbService bulbCharacteristic [0x56, r, g, b, 0x00, 0xf0, 0xaa]))

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
    (Bluetooth.devices Connected)

-- MAIN

main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
