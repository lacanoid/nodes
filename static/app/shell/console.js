var ConsoleCell = wb.View.extend({
    init: function(options) {
	var me = this;
	this.setClass('ConsoleCell');
	this.view = new wb.View({parent:this});
	
	// make unique process id
	this.pid = Date.now()*1000000+Math.floor(Math.random()*1000000);
	
	var bv = new wb.Toolbar({parent:this.view}).
	    css({background:"#ddd"}).
	    html('<table><tr><th/><td class="input"/><td class="controls"/></tr></table>');
	
	bv.$.find('.input').html('<input type="text" autocapitalize="off" autocorrect="off"/>');
	
	bv.$.find('table').css({width:"100%"});
	bv.$.find('table td.input').css({width:"100%"});
	bv.$.find('table td.controls').css({minWidth:320,whiteSpace:"nowrap"});
	bv.$.find('th').html('$');
	this.$input = this.view.$.find('input');
	this.$input.css({width:"100%"});
	this.$input.keydown(function(e) {
	    switch(e.keyCode) {
	    case 13: // return
		me.action(); break;
	    case 38: // up
		me.focusPrev(); break;
	    case 40: // down
		me.focusNext(false); break;
	    }
	    
	});
	this.$input.focus(function(){ me.inputDidFocus(); });
	this.error = new wb.View({parent:this,HTMLtag:'pre'});
	this.error.css({color: 'red'});
	this.output = new wb.View({parent:this,HTMLtag:'pre'});
	var $controls = this.view.$.find('.controls');
	
	this.controls = new wb.Toolbar({parent:$controls});
	
/*	this.loopButton = new wb.SwitchWidget({
	    parent:this.controls
	}); */
	this.runButton = new wb.Button({ 
	    parent:this.controls, 
	    label:'<i class="fa fa-play" title="Run command"/> Run', 
	    callback: function() { me.action() }
	}).css({minWidth:80});
	this.stopButton = new wb.Button({ 
	    parent:this.controls, 
	    label:'<i class="fa fa-stop" title="Stop currently running command"/> Stop', 
	    callback: function() { 
		me.run(null) 
	    }
	}).css({minWidth:80});
	this.stopButton.hide();
	this.statusView = new wb.View({parent:this.controls}).css({display:"inline-block"});
	if(options.text) { this.q = options.text; }
    },
    inputDidFocus: function() {
	var e = this.$input.get(0);
	e.select();
    },
    action: function() {
	var q = this.q;
	var next = this.$.next();
	if(!q) {
	    if(next && next.length>0) {
		// delete this cell
		this.delegate.deleteCell(this);
	    } else {
		return;
	    };
	}
	if(q) this.run(q);
	this.delegate.save();
	if(q) this.focusNext(true);
    },
    focusPrev: function() {
	var prev = this.$.prev();
	if(prev && prev.length>0) {
	    prev.find('input').focus();
	    //		prev.get(0).scrollIntoView(true);
	}
    },
    focusNext: function(extend) {
	var next = this.$.next();
	if(next && next.length>0) {
	    next.find('input').focus();
	    //		next.get(0).scrollIntoView(false);
	} else {
	    if(extend) {
		this.delegateCall('newCell');
	    }
	}
    },
    setOutputText: function(data) {
	this.output.$.text(data.stdout);
	this.error.$.text(data.stderr);
    },
    setBusy: function(b) {
	if(b) {
	    this.t0 = new Date();
	    this.runButton.hide();
	    this.stopButton.show();
	    this.statusView.html('Running...');
	} else {
	    var t1 = new Date();
	    var dt = (t1 - this.t0)/1000;
	    this.runButton.show();
	    this.stopButton.hide();
	    this.statusView.html(sprintf("%.2f",dt));
	}
    },
    focus: function() {
	this.$input.focus();
    },
    run: function(q) {
	var command;
	var args;

	if(q) {
	    command=q.trim().split(/\s+/).shift();
	    args=q.trim().replace(/^\S+\s*/,""); 
	} else {
	    command='';
	    args='';
	}

	console.log('RUN',this.pid,command,args);

	// remove 1st word

	if(args.length>0) {
	    var u = new URL(this.delegate.iri);
	    var iri = URI(args).absoluteTo(u.pathname+"/").toString().replace(/\/$/,'');
	    iri = 'file:'+iri;

	    var url;

	    console.log(iri);

	    switch(command) {
	    case 'cd':
		var url = window.location.origin+window.location.pathname+'?iri='+encodeIRI(iri)+'#console';
		window.location = url;
		return;
	    }

	}

	var me=this;
	me.setBusy(true);
	$.ajax({url:'/api/os/run', 
		data:{iri:this.delegate.iri,q:q?q:'',pid:this.pid},
		success:function(data) {
		    me.setBusy(false);
		    me.setOutputText(data);
		    me.element.scrollIntoView(true);
		},
		error:function(data) {
		    console.log
		    me.setBusy(false);
		    me.setOutputText({stdout:'', stderr:data.responseText});
		    me.element.scrollIntoView(true);
		},
		dataType: "json"
	       });
    },
},{
    q: {
	get: function() {
	    var q = this.$input.val();
	    return q;
	},
	set: function(val) {
	    this.$input.val(val);
	},
    }
}
				);

var ConsoleSession = wb.ViewController.extend({
    init: function(options) {
	var me = nu.args(this);
	var uri = new URI(me.iri);
	this.title = "Console - "+uri.path();

	this.setClass('Console');
	this.view = new wb.View({parent:this,HTMLtag:"section"}).maximize().css({overflowY:'auto'});
	this.view.element.setAttribute('width','100%');
	this.view.element.setAttribute('height','100%');
	new ConsoleCell({parent:this.view, delegate:this}).focus();
	this.navigationItem.rightItem = new wb.Button({
	    label:'<i class="fa fa-plus" title="Create new input cell"/>',
	    callback: function() { me.newCell(); }
	});
	this.load();
    },
    newCell: function(text,save) {
	new ConsoleCell({parent:this.view, delegate:this, text:text}).focus();
	if(save) this.save();
    },
    deleteCell: function(cell) {
	cell && cell.destroy();
	this.save();
    },
    log: function(html) {
	this.output.append('<div>'+html+'</div>');
    },
    load: function() {
	var me = this;
	wb.ajax({
	    url: '/api/filer/getinfo/', 
	    data: { iri: this.iri },
	    success:function(data) {
		if(data.history) {
		    me.view.$.find('.wbConsoleCell').each(function(i,e) {
			var q = $(e).data('wbView').destroy();
		    });
		    for(var i in data.history) {
			me.newCell(data.history[i],false);
		    }
		    new ConsoleCell({parent:me.view, delegate:me}).focus();
		}
	    },
	});
    },
    save: function() {
	var m = this.model;
	$.ajax({
	    url: '/api/filer/setinfo/', 
	    data: { iri: this.iri, info: JSON.stringify(m) },
	});
    },
    lastCell: function() {
	var v=this.view.$.find('.wbConsoleCell').last().data('wbView');
	return v;
    },
    focus: function() {
	var v=this.lastCell();
	v.element.scrollIntoView(false);
    },
    openURL: function(url) {
	console.log('CD',url);
	this.delegate.setURL(url);
    },
},
{
	  model: {
	      get: function() {
		  var m = [];
		  this.view.$.find('.wbConsoleCell').each(function(i,e) {
		      var q = $(e).data('wbView').q;
		      if(q) m.push(q);
		  });
		  return { history: m, lastUpdate: new Date().toString() };
	      },
	      set: function() {
	      },
	  }
}
					     );
var Console = wb.TabController.extend({
    init: function(options) {
	var me = this;
	this.title = "Console";
	this.sessions = {};
    },
    setURL: function(url) {
	if(!url) return;
	if(this.sessions[url]) { this.raiseViewController(this.sessions[url]); }
	else {
	    var cs = new ConsoleSession({iri:url,delegate:this});
	    this.sessions[url] = cs;
	    this.pushViewController(this.sessions[url]);
	}
	this.navigationItem.title = this.topViewController.title;
	this.topViewController.focus();
    },
    viewWillAppear: function() {
	app.setHash('#console');
    },
    viewDidAppear: function() {
	this.topViewController.lastCell().focus();
    }
});
