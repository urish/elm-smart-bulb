module App exposing (..)

import Bluetooth exposing (devices, requestDevice)
import Html exposing (Html, button, div, h1, h3, p, program, text)
import Html.Events exposing (onClick)
import RemoteData exposing (RemoteData(..))


-- CONSTANTS


bulbService : String
bulbService =
    "0xffe5"


bulbCharacteristic : String
bulbCharacteristic =
    "0xffe9"



-- MODEL


type alias Device =
    { name : String
    , id : String
    }


type alias BluetoothError =
    String


type alias BluetoothData =
    RemoteData BluetoothError Device


type alias Model =
    { connection : BluetoothData
    }


isNotAsked : BluetoothData -> Bool
isNotAsked data =
    case data of
        NotAsked ->
            True

        otherwise ->
            False


getDevice : BluetoothData -> Maybe Device
getDevice data =
    case data of
        Success device ->
            Just device

        otherwise ->
            Nothing


type Color
    = Red
    | Green
    | Blue


type alias Rgb =
    ( Int, Int, Int )


type BulbState
    = On Color
    | Off


getColorFromBulbState : BulbState -> Rgb
getColorFromBulbState state =
    case state of
        On Red ->
            ( 255, 0, 0 )

        On Green ->
            ( 0, 255, 0 )

        On Blue ->
            ( 0, 0, 255 )

        Off ->
            ( 0, 0, 0 )


getBulbCommand : BulbState -> List Int
getBulbCommand state =
    let
        ( r, g, b ) =
            getColorFromBulbState state
    in
    [ 0x56, r, g, b, 0x00, 0xF0, 0xAA ]


init : ( Model, Cmd Msg )
init =
    ( Model NotAsked, Cmd.none )



-- MESSAGES


type Msg
    = Disconnect
    | RequestDevice
    | SetBulbState BulbState
    | DeviceConnected Bluetooth.DeviceInfo
    | Error BluetoothError
    | Restart



-- VIEW


view : Model -> Html Msg
view model =
    case model.connection of
        Success device ->
            div []
                [ text "Connected to: "
                , text device.name
                , h3 [] [ text "Connection" ]
                , button [ onClick Disconnect ] [ text "Disconnect" ]
                , h3 [] [ text "Colors" ]
                , button [ onClick (SetBulbState (On Red)) ] [ text "Red" ]
                , button [ onClick (SetBulbState (On Green)) ] [ text "Green" ]
                , button [ onClick (SetBulbState (On Blue)) ] [ text "Blue" ]
                , button [ onClick (SetBulbState Off) ] [ text "Off" ]
                ]

        NotAsked ->
            div []
                [ button [ onClick RequestDevice ] [ text "Connect" ] ]

        Loading ->
            div []
                [ text "Connecting..." ]

        Failure error ->
            div []
                [ h1 [] [ text "Connection error" ]
                , p [] [ text error ]
                , button [ onClick Restart ] [ text "Restart" ]
                ]



-- UPDATE


setColorMessage : Device -> BulbState -> Cmd Msg
setColorMessage device state =
    Bluetooth.writeValue (Bluetooth.WriteParams device.id bulbService bulbCharacteristic (getBulbCommand state))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        noChange =
            ( model, Cmd.none )

        device =
            getDevice model.connection
    in
    case msg of
        RequestDevice ->
            if isNotAsked model.connection then
                ( Model Loading, Bluetooth.requestDevice bulbService )
            else
                noChange

        DeviceConnected deviceInfo ->
            ( Model (Success (Device deviceInfo.name deviceInfo.id)), Cmd.none )

        Disconnect ->
            device
                |> Maybe.map (\device -> ( Model NotAsked, Bluetooth.disconnect device.id ))
                |> Maybe.withDefault noChange

        SetBulbState state ->
            device
                |> Maybe.map (\device -> ( model, setColorMessage device state ))
                |> Maybe.withDefault noChange

        Error err ->
            ( Model (Failure err), Cmd.none )

        Restart ->
            ( Model NotAsked, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Bluetooth.devices DeviceConnected
        , Bluetooth.error Error
        ]



-- MAIN


main : Program Never Model Msg
main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
