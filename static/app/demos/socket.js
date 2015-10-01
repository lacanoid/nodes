// search implemented with socket.io

var Searcher = wb.ListViewController.extend({
    init: function(options) {
	var me = this;

	this.listView.style = "grouped";
	this.css({background:'#ddd'});
	this.title = "Search";
	this.w = new wb.TextWidget({value:".jpg",type:"search",delegate:this}).css({margin:"9px"});
	this.navigationItem.titleView = this.w;
	this.w.focus();
	this.w.input.setAttribute('name','q');

	$(this.w.input).keypress(function(event) {
	    if (event.which == 13) {
		event.preventDefault();
		me.action();
	    }
	});
    },

    setupSocket: function() {
	var me = this;
	if(!this.socket) {
	    this.socket = io.connect(window.location.origin);
	    this.socket.on('hello', function() {
		console.log('socket ready');
	    });
	    this.socket.on('output', function(data) {
		console.log('socket data',data);
		me.listData.addObject({label:data});
	    });
	    this.socket.on('end', function(data) {
		console.log('search end');
		me.listView.reloadData();
	    });
	}
	return this.socket;
    },

    action: function() {
	var me = this;
	var q = this.w.getValue();
	console.log(q);
	this.setupSocket();
	this.listData = new wb.ResultSet({});
	this.listData.selectSectionByTitle("Results");
	this.socket.emit('run',{action:'find',q:q,p:this.path});
	this.listView.reloadData();
    },

    widgetValueDidChange: function(w) {
	this.action();
    },

    viewWillAppear: function() {
	console.log("ViewWillAppear");
	this.setupSocket();
	this.action();
    },

    viewDidAppear: function() {
	console.log("ViewDidAppear");
	this.w.input.focus();
    },

    cellForRowAtIndexPath: function(indexPath) {
	var c = new wb.ListViewCell().initWithStyle('title');
	var item = this.listData.objectForIndexPath(indexPath);
	console.log(item);
	
	c.textLabel.text = item.label;
//	c.detailTextLabel.text = item.comment;
	return c;
    },

});
