var app = require('express').createServer();

app.get('/', function(req, res){
    res.send('hello world'+"\n");
});

app.listen(3000);

