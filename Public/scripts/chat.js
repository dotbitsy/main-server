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

function Chat(host) {
    var chat = this;
    var self = ""
    chat.ws = new WebSocket(host)
    chat.ws.onopen = function() {
        chat.askUsername();
    };
    
    chat.askUsername = function() {
        var name = prompt('Init Bit');
        self = name	
        chat.ws.sendJsonBlob({ connect: true })
        chat.ws.sendJsonBlob({ state: true })
        chat.ws.sendJsonBlob({ name: self })
    }

    
    chat.imageCache = {};
    
    $('form').on('submit', function(e) {
                 e.preventDefault();
                 
                 var message = $('.message-input').val();
                 
                 if (message.length == 0 || message.length >= 512) {
                 return;
                 }
                 
                chat.send({ data: message });
                chat.send({ state: true })
                 $('.message-input').val('');
                 });
    
    
    chat.send = function(blob) {
        chat.ws.sendJsonBlob(blob)
    };

    
    chat.ws.onmessage = function(event) {
        blobToJson(event.data).then((obj) => {
            if ( obj.data.connect !== undefined ) {
                console.log("Connected : " + obj.data.connect);
            } else if ( obj.data !== undefined ) {
                console.log("Client: " + obj.client + ' : ' + uuid);
                if (obj.client.toLocaleLowerCase() == uuid.toLocaleLowerCase()) {
                    chat.bubble(self, obj.data.data)
                } else {
                    if ( obj.data.bytes !== undefined) {
                        console.log("Client Data: " + obj.client + ' : ' + obj.data.bytes.length);
                        chat.bubble("Machine Bytes", obj.data.bytes.length)
                    } else if ( obj.data.connect !== undefined) {
                        console.log("Client: " + obj.client + ' : ' + obj.data.connect);
                        chat.bubble("Machine", obj.data.connect)
                    }else {
                        console.log("Client Data: " + obj.client + ' : ' + obj.data.data);
                        chat.bubble("Machine", obj.data.data)
                    }
                }
            }
            console.log("Message received.");
        })
       
    }
    
    chat.bubble = function(client, data) {
        var bubble = $('<div>')
        .addClass('message')
        .addClass('new');
        
        var src = "/images/spider_black.png"
        var image = $('<img>')
        .addClass('avatar')
        .attr('src', src);
        
        
        var text = $('<span>')
        .addClass('text');
        bubble.append(image);
        bubble.append(text);
        text.text( '[ ' + client + ' ] ' + data );
        var d = new Date()
        var m = '00'
        if (m != d.getMinutes()) {
            m = d.getMinutes();
        }
        
        if (m < 10) { m = '0' + m; }
        var time = $('<span class="timestamp">' + d.getHours() + ':' + m + '  [ ' + ' ] ' + ' ' + '</div>');
        bubble.append(time);
        
        var bottom = $('<div>')
        .addClass('bottom-div')
        
        $('.messages').append(bubble);
        var objDiv = $('.messages')[0];
        objDiv.scrollTop = objDiv.scrollHeight;
    }
};
