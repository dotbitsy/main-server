function blobToJson(blob) {
    return new Promise((resolve, reject) => {
        let fr = new FileReader();
        fr.onload = () => {
            resolve(JSON.parse(fr.result));
        };
        fr.readAsText(blob);
    });
}

function uuidv4() {
    return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c => (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16));
}

WebSocket.prototype.sendJsonBlob = function(data) {
    const string = JSON.stringify({ client: uuid, data: data })
    const blob = new Blob([string], {type: "application/json"});
    this.send(blob)
};

const uuid = uuidv4()
let ws = undefined

function WebSocketStart() {
    ws = new WebSocket("ws://" + window.location.host + "/bitsys")
    ws.onopen = () => {
        console.log("Socket is opened.");
        ws.sendJsonBlob({ connect: true })
        ws.sendJsonBlob({ data: 'Disco lives.' })
        ws.sendJsonBlob({ state: true })
    }

    ws.onmessage = (event) => {
        blobToJson(event.data).then((obj) => {
            if ( obj.data.connect !== undefined ) {
                console.log("Connected : " + obj.data.connect);
            } else if ( obj.data.data !== undefined ) {
                console.log("Client: " + obj.client + ' : ' + obj.data.data);
            }
            console.log("Message received.");
        })
    };

    ws.onclose = () => {
        console.log("Socket is closed.");
    };
}

function WebSocketStop() {
    if ( ws !== undefined ) {
        ws.close()
    }
}
