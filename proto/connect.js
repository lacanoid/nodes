var express = require('express'),
    urlpaser = require('url'),
    pg = require('pg');

var connectionString0 = "postgres:";
var username = 'rdf';
var password = 'myrdf';
var client;

function login() {
	var connectionString = 'pg://'+username+':'+password+'@'+connectionString0;
	if(username && password) {
	        pg.connect(connectionString, function(err, client1) {
		  if(err) {
			console.log('DB Login failed!',err);
		  } else {
			client=client1;
		  }
		});
	}
}
login();

var app = express.createServer(
	  express.logger({ format: ':method :url' }),
	  express.cookieDecoder(),
          express.session({ secret: 'foobar' }),
          express.bodyDecoder()
);

app.use(express.staticProvider(__dirname + '/static'));
console.log('DIR',__dirname);

app.get('/logout', function(req,res) {
	req.session.destroy();
	res.redirect('home');
});

app.get('/login', function(req,res) {
	url = req.urlp = urlpaser.parse(req.url, true);

/*
	username=url.query.username;
	password=url.query.password;
*/

	var connectionString = 'pg://'+username+':'+password+'@'+connectionString0;

	if(username && password) {
	        pg.connect(connectionString, function(err, client) {
		  if(err) {
			console.log('Login failed!',err);
			req.session.destroy();
			res.writeHead(403, { 'Content-Type': 'text/html' });
		    	res.end('Login failed!');
		  }
		  else {
			req.session.username=username;
			req.session.client=client;
			req.session.auth=true;
			res.redirect('home');
		  }
		});
	} else { res.sendfile('login.html'); }
});

app.get('/info',function(req, res) {
	res.sendfile('index.html');
});

app.all('/wb/api/request',function(req, res) {
	var json_req=req.rawBody;
	console.log('REQUEST',json_req);
	if(req.body.action=='commit') {
		var client = req.session.client;

		client.query("select rdf.request_json(model(),$1) as json",[json_req],
			function(err, result) {
    			if(err) {
				console.log(err);
				res.writeHead(500, { 'Content-Type': 'text/html' });
				res.send('DB error');
			}
			else {
				var json = result.rows[0].json;
				console.log('RESULT',json);
				res.end(json);
			}
		    });
		
	}
//	res.end(JSON.stringify(req.body));
});

app.get('/version', function(req,res) {
    if (! (req.session && req.session.auth == true)) {
	res.writeHead(403, { 'Content-Type': 'text/html' });
    	res.end('Sorry you are unauthorized.\n\nFor a login <a href="/login">click here</a>');
    }
    var client = req.session.client;

    client.query("select pg_backend_pid(),user,now(),version() ", function(err, result) {
    	if(err) {
		console.log(err);
		res.send('error');
	}
	else {
		console.log(result);
		res.end(JSON.stringify(result));
	}
    });
});

/* article */
app.get(/^\/(?:[^\/]+)/, function(req, res){
	res.sendfile('article.html');
});


app.listen(3000);

