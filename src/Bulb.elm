module App exposing (..)

import Bluetooth exposing (devices, requestDevice)
import Html exposing (Html, button, div, h1, h3, p, program, text)
import Html.Events exposing (onClick)
import RemoteData exposing (RemoteData(..))


-- CONSTANTS


bulbService =
    "0xffe5"


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

                SetBulbState state ->
                    ( model, Bluetooth.writeValue (Bluetooth.WriteParams device.id bulbService bulbCharacteristic (getBulbCommand state)) )

                Error err ->
                    ( Model (Failure err), Cmd.none )

                otherwise ->
                    ( model, Cmd.none )

        otherwise ->
            case msg of
                DeviceConnected deviceInfo ->
                    ( Model (Success (Device deviceInfo.name deviceInfo.id)), Cmd.none )

                Error err ->
                    ( Model (Failure err), Cmd.none )

                Restart ->
                    ( Model NotAsked, Cmd.none )

                otherwise ->
                    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Bluetooth.devices DeviceConnected
        , Bluetooth.error Error
        ]



-- MAIN


main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
