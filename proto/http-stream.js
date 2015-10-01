#!/usr/bin/node

var express = require('express');
var http = require('http');
var posix = require('posix');

var app = express();

app.use(express.static('./static'));
app.use(express.json());
app.use(express.urlencoded());

app.get('/stream', function(req,res) {
    var timer;
    req.seq=0;

    res.header('Content-type','application/octet-stream');
    res.write('');
    timer=setInterval(function() {
	while(Math.random()<0.8) {
	    req.seq++;
	    res.write("Hello! "+req.seq+" ");
	    if(Math.random()<0.5) res.write("\n");
	}
	if(Math.random()<0.01) {
	    clearInterval(timer);
	    res.end();
	}
    },1000);
});

app.get('/icon/mime/:type/:subtype', function(req,res) {
    var type = req.params.type;
    var subtype = req.params.subtype;
    console.log('ICON',type,subtype);
    res.sendfile('./static/icon/mime/'+type+'/__DEFAULT__.png');
});

var port = 3000;
var server;
server = http.createServer(app);
server.listen(port);
console.log('LISTEN URL http://'+posix.gethostname()+'.local:'+port);
