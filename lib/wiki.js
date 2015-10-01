#!/usr/bin/node
////////////////////////////////////////////////////////////////////////////////
// CONFIG

var fs = require('fs');

var config = {
    mainPageTitle : "Main Page",
    conString : "postgres://user:****@host.domain.org:5432/catalog"
};
process.env['PGAPPNAME']="pgwiki";

////////////////////////////////////////////////////////////////////////////////
// LIBS

var express = require('express'),
    http = require('http'),
    https = require('https'),
    sys = require('sys'),
    pg = require('pg'),
    child_process = require('child_process'),
    posix = require('posix'),
    mime = require('mime'),
    path = require('path'),
    url = require('url'),
    jf = require('jsonfile'),
    handlebars = require('handlebars'),
    multipart = require('connect-multiparty');

////////////////////////////////////////////////////////////////////////////////
// xpg.js

var xpg = {};
xpg.run = function(query, args, callback) {
    if(typeof(args)=='function') { callback=args; args=null; }
    if(!args) args=[];
    pg.connect(config.conString, function(err,client,done) {
        if(err) { 
	    console.error('Error fetching DB client from pool', err); 
	    return;
	}
        client.query(query, args, function(err, result) {
	    if(err) console.error('DB '+err.severity,err.toString(),err);
            callback && callback(err,result);
            done && done();});});};


////////////////////////////////////////////////////////////////////////////////
// nu.js

function keys(a) {  var b=[];  for(var i in a) b.push(i);  return b; }
function to_json(a) { return JSON.stringify(a); }

var template={};

var nu = {
    sys: {
	ego: function() { posix.getpwnam(posix.geteuid()); },
    }
};

//----------------------------------------------------------------------

function nuFail(res,code,msg,err) {
    console.log('FAIL',code,msg,err);
    res.writeHead(code, { 'Content-Type': 'text/plain' });
    msg && res.end(msg.toString());
    //    err && res.send(err);
    //    res.end('');
    return;
}

function nuJSON(res,object) {
    res.json(object);
}

////////////////////////////////////////////////////////////////////////////////
// nu.js

var auth = {
    requireLogin: function(req, res, next) {
	var sid = req.cookies.sid;
	if(sid && sid==process.env['NODEX_SID']) next();
        else {
	    res.writeHead(403, { 'Content-Type': 'text/plain' });
	    res.end('Not logged in');
	}
    },
    genkey: function() {
	return Date.now()*1000000+Math.floor(Math.random()*1000000);
    },

};

////////////////////////////////////////////////////////////////////////////////
// express

var app = express();

app.use(express.cookieParser('ClearRatherThanDeep'));
app.use(express.static(__dirname + '/static'));
app.use(express.json());
app.use(express.urlencoded());


////////////////////////////////////////////////////////////////////////////////
// wiki.js
var wiki = {
    // split full title/path into namespace and short title
    title_parse: function(full_title) {
	var a;
	if(a=full_title.match(/^(.+?)[:/](.+)$/)) { 
  	  return {namespace:a[1].toLowerCase(),title:a[2]};
        }
	return {namespace:'main',title:full_title};
    },
    proc_get_info: function(proc_name,callback) {
	xpg.run('select * from wiki.proc_get_info($1)',[proc_name],
		function(err,result) {
		    if(result && result.rows && result.rows[0])
			callback && callback(result.rows[0]);
		    else callback();
		});
    },
    page_get_body: function(title, rev_id, callback) {
	xpg.run('select wiki.page_get($1,$2) as body', [title, rev_id], 
		function(err, data) {
		    if(data) {
			var body = data.rows[0].body;
			callback && callback(body,err);
		    }
		});
    },
    page_get_data: function(req,res) {
	var title = req.query.title;
	var rev_id = req.query.rev_id;
	
	console.log('PAGE GET DATA',title,rev_id);
	xpg.run('select wiki.page_get_data($1,$2) as json', [title, rev_id], 
		function(err, data) {
		    if(err) { 
			res.json({message:err.toString(),err:err,success:false});
		    } else {
			if(data && data.rows && data.rows[0]) {
			    try {
				var j = JSON.parse(data.rows[0].json);
			    } catch(e) {
				res.json({err:e, success:false});
			    }
			    res.json({data:j, success:true});
			} else {
			    res.writeHead(404, { 'Content-Type': 'text/plain' });
			    res.json({message:"Page not found",err:{},success:false});
			}
		}
		});
    },
    page_set_data: function(req,res) {
	var title=req.body.title;
	var body=req.body.body;
	/*
	  var title = req.query.title;
	  var body = req.query.body;
	*/
	if(!title) { nuFail(res,400,'Bad request (no title)'); return; }
	
	var options = {remote_ip:req.connection.remoteAddress};
	
	console.log('SET DATA',title);
	xpg.run('select wiki.page_set_with_options($1,$2,$3) as result', [title,body,to_json(options)], 
		function(err, data) {
		    if(err) { 
			res.json({message:err.toString(),err:err,success:false});
		    } else {
			if(data && data.rows && data.rows[0]) {
			    res.json({data:data.rows[0], success:true});
			} else {
			    res.writeHead(404, { 'Content-Type': 'text/plain' });
			    res.json({message:"Page not found",err:{},success:false});
			}
		    }
		});
    },
    // finalize wiki page
    finalize: function(res, page) {
	var response_code = page.response_code || page.err?500:200;
	
	res.writeHead(response_code, { 'Content-Type': 'text/html' });
	var err = page.err;
	if(err) {
	    var c='';
	    c += err.toString && '<div class="error">'+err.toString()+"</div>\n"
	    page.message = c;
	}
	res.end(template(page));
    }
}


////////////////////////////////////////////////////////////////////////////////
// bios.js

var children = {};

app.get('/', function(req,res) { res.redirect('/'+config.mainPageTitle); });

app.get('/api/wiki/getPageData?',wiki.page_get_data);
app.post('/api/wiki/setPageData?', wiki.page_set_data);

// main render 
app.get('/:title', function(req,res) {
    var title = req.params.title;
    var rev_id = req.query.rev_id;

    if(!title) return;
    var t = wiki.title_parse(title);
    console.log('GET',t,rev_id);

    wiki.page_get_body(title, rev_id, function(body, err) {
	var page = {};
	page.err = err;
	if(err) { 
	    console.log('GET ERROR',err);
	    wiki.finalize(res,{err:err}); 
	} 

	if(t.namespace=='special') {
	    wiki.proc_get_info('wiki.special_'+t.title, function(r) {
		if(r.sql_identifier) {
		    xpg.run('select * from '+r.sql_identifier+'()',
			    function(err,result) {
				var r = [];
				if(result && result.rows)
				    for(var i in result.rows) {
					var content = result.rows[i].content;
					if(content) r.push('<div>'+content+'</div>');
				    }
				wiki.finalize(res,{title:title,err:err,body:body,data:r.join('\n')});
			    });
		} else {
		    wiki.finalize(res,{title:title,body:body});
		}
	    });
	} else {
	    if(body) {
		wiki.finalize(res,{title:title, body:body});
	    } else {
		wiki.finalize(res,{title:title, response_code:404,
				   err:'<div class="wikiPageNotFound">'+
                                       '<div class="message">Page <b>"'+title+'"</b> not found</div>'+
				       '<div class="actions"><button type="button" class="btn btn-primary" onclick="app.edit()">Create this page</button></div>'+
                                       '</div>'
				  });
	    }
	}
    });


});

////////////////////////////////////////////////////////////////////////////////

function compileTemplates() {
    try {
	var s = fs.readFileSync("./static/app/wiki/index.html","utf8");
	template = handlebars.compile(s);
    }
    catch(e) {
	console.error('Error compiling template. ',e);
    }
}

function init() {
    compileTemplates();

    var xurl = url.parse(process.env['URL'] || 'http:');
    if(!xurl.port) { xurl.port=3000; }

    var server;
    server = http.createServer(app);
    
    try {
	server.on('error',function(e) {
	    console.error(e);
	});
	server.listen(xurl.port,xurl.hostname);
	console.log('LISTEN URL '+xurl.protocol+'//'+xurl.hostname+':'+xurl.port);
    } 
    catch(err) {
	console.log("LISTEN ERROR",err);
    }
}

init();

