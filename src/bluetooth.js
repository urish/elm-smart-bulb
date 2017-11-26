(function () {
    let gattServers = new Map();

    function parseUuid(uuid) {
        if (uuid && uuid.toLowerCase().indexOf('0x') === 0) {
            return parseInt(uuid);
        }
        return uuid;
    }

    app.ports.requestDevice.subscribe(async (service) => {
        try {
            const device = await navigator.bluetooth.requestDevice({
                filters: [{ services: [parseUuid(service)] }]
            })
            await device.gatt.connect();
            gattServers.set(device.id, device.gatt);
            app.ports.devices.send({
                id: device.id,
                name: device.name
            });
        } catch (err) {
            app.ports.error.send(err.toString());
        }
    });

    app.ports.writeValue.subscribe(async (writeParams) => {
        try {
            if (gattServers.has(writeParams.device)) {
                const service = await gattServers.get(writeParams.device).getPrimaryService(parseUuid(writeParams.service));
                const characteristic = await service.getCharacteristic(parseUuid(writeParams.characteristic));
                await characteristic.writeValue(new Uint8Array(writeParams.value));
            } else {
                app.ports.error.send(`Device ${writeParams.device} not found!`);
                console.error(`Device ${writeParams.device} not found!`);
            }
        } catch (err) {
            app.ports.error.send(err.toString());
        }
    });

    app.ports.disconnect.subscribe(deviceId => {
        if (gattServers.has(deviceId)) {
            gattServers.get(deviceId).disconnect();
            gattServers.delete(deviceId);
        } else {
            app.ports.error.send(`Device ${deviceId} not found!`);
        }
    });
})();
