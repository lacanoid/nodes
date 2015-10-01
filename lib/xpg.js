// v 20140813
var xpg = {};

xpg.pg = require('pg');

// run a query
xpg.run = function(conString, query, args, callback) {
  if(typeof(args)=='function') { callback=args; args=null; }
  if(!args) args=[];
  xpg.pg.connect(conString, function(err,client,done) {
    if(err) { return  done && done(); console.error('error fetching DB client from pool', err); }
    client.query(query, args, function(err, result) {
        if(err) { done && done(); return console.error('error running query', err); }
        callback && callback(err,result);
        done && done();
    });
  });
};

xpg.fail = function(res,code,msg,err) {
    console.log('FAIL',code,msg,err);
    res.writeHead(code, { 'Content-Type': 'text/plain' });
    msg && res.end(msg.toString());
    return;
}

// run a query
xpg.query = function(conString, query, args, callback) {
    if(typeof(args)=='function') { callback=args; args=null; }
    if(!args) args=[];
    xpg.pg.connect(conString, function(err,client,done) {
        if(err) { 
	    console.error('Error fetching DB client from pool', err); 
	    return;
	}
        client.query(query, args, function(err, result) {
	    if(err) console.error('DB '+err.severity,err.toString(),err);
            callback && callback(err,result);
            done && done();});});};

// call a procedure
xpg.call = function(conString, req,res) {
    if(!conString) { 
	xpg.fail(res,500,"Database connection string is empty."); 
	return;
    }
    console.log('REQ QUERY',req.query);
    console.log('ROUTE PARAMS',req.route.params);
    if(!req.route.params.function) {
	// res.writeHead(400, { 'Content-Type': 'text/plain' });
	res.end('Database function not specified');
    }
    xpg.query(conString,"select * from oordbms.get_proc_info($1,$2)",[req.route.params.schema,req.route.params.function],
	      function(err,result) {
		  if(err) { xpg.fail(res,500,"No function oordbms.get_proc_info() in database",err); }
		  else {
		      var info = result.rows[0];
		      // console.log('INFO',info);
		      if(info && info.sysid) {
			  var args=[]; var j=1;
			  if(info.argnames) {
			      for(var i=0;i<info.argnames.length;i++) {
				  if(info.argnames[i] in req.query) {args.push(req.query[info.argnames[i]]);} 
				  else {args.push(null);}
			      }
			  }
			  var argst = []; 
			  for(var i=1;i<=args.length;i++) argst.push('$'+i);
			  argst = argst.join(',');
			  var query = 'select * from '+info.sql_identifier+'('+argst+')';
			  console.log('Q:',query,'A:',args);
			  xpg.query(conString,query,args,
				    function(err1,result1) {
					if(err1) {
					    err1.error=err1.toString();
					    err1.query=query;
					    console.log(err1);
					    res.json(err1);
					} else {
					    // res.writeHead(200, { 'Content-Type': 'text/json' });
					    res.json(result1);
					}
				    });
		      } else {
			  res.status(404);
			  // res.writeHead(404, { 'Content-Type': 'text/plain' });
			  res.end('Database function not found');
		      }
		  }
	      });
}

exports.pg = xpg.pg;
exports.run = xpg.run;
exports.query = xpg.query;
exports.call = xpg.call;

/*
app.all('/api/session',function(req, res) {
    var s = {
	auth: (req.session.auth,false),
	username: req.session.username,
	userID: 0,
	sessionID: res.sessionID,
//	haveDSN: req.session.dbh()!==undefined?true:false
    };
    res.end(JSON.stringify(s));
});

app.get('/api/version', function(req,res) {
    if (! (req.session && req.session.auth == true)) {
	res.writeHead(403, { 'Content-Type': 'text/html' });
    	res.end('Sorry you are unauthorized.\n\nFor a login <a href="/app/login/">click here</a>');
    }
    var dbh = role.get(req.session.key);

    dbh.query("select pg_backend_pid(),user,now(),version() ", function(err, result) {
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
*/

/* article */
/*
app.get(/^\/(?:[^\/]+)/, function(req, res){
	res.sendfile('article.html');
});
*/

/*
app.all('/api/db/request',function(req, res) {
	var json_req=req.rawBody;
	console.log('REQUEST',json_req);
	if(req.body.action=='commit') {
	    var dbh = role.get(req.session.key);

	    dbh.query("select rdf.request_json(model(),$1) as json",[json_req],
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
*/


var role = {
    client: {},
    dsn: {},
    get: function(key) {
	var client = this.client[key];
	return client;

	if(!client) {
	    client = new pg.Client(dsn);
	    client.connect();
	    /*
	    pg.connect(dsn, function(err, dbh) {
		if(err) {
		    console.log('DB Login failed!',err);
		} else {
		    console.log('DB Login suxess!');
		    this.dsn[dsn]=dbh;
		    client = dbh;
		}
	    });
	    */
	}
	return client;
    },
    set: function(key,dsn,dbh) {
	this.client[key]=dbh;
	this.dsn[key]=dsn;
    }
}; // hash of active roles
