function Verify(data) {
    var chat = this;
    var self = ""
    
    chat.verify = function(something) {
        var bubble = $('<div>')
            .addClass('message')
            .addClass('new');
        
        var src = "/images/dna.png"
        var image = $('<img>')
            .addClass('avatar')
            .attr('src', src);
        bubble.append(image)
        
        
        var text = $('<span>')
            .addClass('text');
        bubble.addClass('personal');
        text.text( something );
        bubble.append(text);
        $('.message-box').append(bubble);
        var objDiv = $('.messages')[0];
        objDiv.scrollTop = objDiv.scrollHeight;
    }
};
