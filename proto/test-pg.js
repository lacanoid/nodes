var express = require('express'),
    urlpaser = require('url'),
    sys = require('sys'),
    pg = require('pg');

var dsn = 'postgres:';
var client;

pg.connect(dsn, function(err, dbh) {
    if(err) {
	console.log('DB Login failed!',err);
    } else {
	console.log('DB Login suxess!');
	dbh.query("select * from pg_namespace where nspname = $1",["pg_catalog"], function(err,res) {
	    if(err) {
		console.log("Query error",err);
	    } else {
		console.log(res);
	    }
	});
    }
});
