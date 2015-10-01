/* script for preview */

var app;

wb.PiTubeController = wb.ListViewController.extend({
    init: function(options) {
	var me = this;
	this.title = "&pi;Tube";
	this.listView.style = "grouped";
	this.css({background:'#ddd'});

	this.q = sessionStorage["app:piTube/q"];

	var v = new wb.View();

	this.playerStatus = new wb.Label({parent:v});

	this.ai = new wb.ActivityIndicator({parent:v,title:"Searching..."});
	this.ai.hidden = true;
					  
	this.state = 0;

	this.listView.listFooterView = v;

    },
    viewDidAppear: function() {
	this.inputView.$.focus();
    },
    setTitleText: function(string) { 
	var label = this.model.info.name;
	this.navigationItem.title=string || label || this.iri;
	document.title=label+
	    ((this.delegate && this.delegate.label)?
	     (" - "+this.delegate.label):""); 
    },
    actionPlay: function() {
	var me = this;
	var url = this.dataSrc;
	if(url) {
	    me.ai.hidden = false;
	    me.ai.title  = "";
	    url = '"'+url+'"'; 
	    $.ajax({url:'/api/os/run', 
		    data:{iri:"file:/home",q:'killall omxplayer.bin ; omxplayer -b --live '+url,pid:"omxplayer"},
		    success:function(data) {
			me.ai.hidden = true;
			console.log("OMXDATA",data);
			me.playerStatus.text=data.stderr;
		    },
		    error:function(err) {
			me.ai.hidden = true;
			console.log("OMXERR",data);
		    },
		    dataType: "json"
		   });
	} else {
	    console.log("No stream url");
	}
    },
    action: function(w) {
	var me = this;
	me.q = w.getValue();
	if(me.q) {
	    console.log("Q",me.q);
	    sessionStorage["app:piTube/q"] = me.q;
	}
	var url = '"'+me.q+'"'; 

	console.log("ACTION",url);
	me.state = 0;
	me.setBusy(true);
	me.ai.hidden = false;
        me.ai.title  = "Searching...";
	me.playerStatus.text="";
	$.ajax({url:'/api/os/run', 
		data:{iri:"file:/home",q:'youtube-dl -j '+url,pid:"youtube-dl"},
		success:function(data) {
		    var d = JSON.parse(data.stdout);
		    me.setBusy(false);
		    me.ai.hidden = true;
		    
		    me.state = 1; me.listView.reloadData();
		    
		    console.log("INFODATA",d);
		    me.setInfoText(d.stitle,d.url);
		    me.dataSrc = d.url;
		},
		error:function(err) {
		    console.log
		    me.setBusy(false);
		    me.playerStatus.text=err.toString();
		},
		dataType: "json"
	       });

	me.listView.reloadData();
    },

    setInfoText: function(text,src) {
	this.infoView.setValue(text);
	this.dataSrc=src;
    },

    numberOfSectionsInListView: function(listView) {
	switch(this.state||0) {
	case 1:
	    return 2;
	};
	return 1;
    },
    numberOfRowsInSection: function(listView,section) {
	switch(section) {
	case 0:
	    switch(this.state||0) {
	    case 0:
		return 1;
	    case 1:
		return 3;
	    };
	    return 0;
	case 1:
	    return 1;
	}
    },
    titleForListViewSection: function(listView,section) { return null; },
    didSelectCell: function(cell) {
	switch(cell.indexPath.section) {
	case 1:
	    this.actionPlay();
	}
    },
    cellForRowAtIndexPath: function(indexPath) {
	var c;
	switch(indexPath.section) {
	case 0:
	    c = new wb.ListViewCell({style:'widget'});
	    switch(indexPath.row) {
	    case 0:
		c.textLabel.text = 'Query';
                this.inputView = new wb.TextWidget({parent:c.contentView, value:this.q,  delegate:this});
		break;
	    case 1:
		c.textLabel.text = 'Title';
		this.infoView = new wb.TextWidget({parent:c.contentView});
		break;
	    case 2:
		c.textLabel.text = 'Data URL';
		this.dataSrcView = new wb.TextWidget({parent:c.contentView});
		break;
	    }
	    break;
	case 1:
	    c = new wb.ListViewCell({style:'button',title:'<i class="fa fa-play"> Play</i>'});
	    break;
	case 2:
	    break;
	}
	return c;
    },
},{
//    title: { get: function() { return this.model.title; }}
    dataSrc: { 
	get: function() { 
	    if(this.dataSrcView) return this.dataSrcView.getValue(); 
	    else return this._dataSrc;
	},
	set: function(v) { 
	    if(this.dataSrcView) this.dataSrcView.setValue(v); 
	    else this._dataSrc = v;
	}
    }
});

var PiTubeApplication = wb.Application.extend({
    init: function(options) {
	var me = this;
	me.label = "PiTube";
	// this.splitViewController = new wb.SplitViewController({parent:this});
	var nc = new wb.NavigationController({parent:this});
	this.css({background: "white"});
	this.root = new wb.PiTubeController({delegate:this}).maximize();
	nc.pushViewControllerAnimated(this.root,false);
	this.navigationController = nc;

	this.screen = wb.getSharedScreen();
	this.setParent(this.screen);

	var me = this;
    },
});

function init() {
    app = new PiTubeApplication();
}

$(window).load(init);
