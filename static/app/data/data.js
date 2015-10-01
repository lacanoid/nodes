var app;

wb.Model = nu.Object.extend({
    init: function(options) {
	var me = nu.args(this);
	me.info={};
    },
    getInfo: function(url, iri, callback) {
	var me=this;
	var path = iri.path().split('/').filter(function(e){return e}).reverse();
	var args = {name:path[0], namespace:path[1], catalog:path[2]};
	me.info = null;
	wb.ajax({ url: url, data: args,
	    success:function(data) { 
		if(data.rowCount>0) {
		    me.iri  = iri;
		    me.dbInfo = data.rows[0]; 
		    me.info = args;
		    me.info.comment = me.dbInfo.comment;
		    me._adef = {};
		    for(var i in me.names) {
			var n = me.names[i];
			me._adef[n]={
			    name:n,
			    type:me.types[i],
			    // widgetClass:"text"
			};
		    }
		}
		callback && callback(me); 
	    },
	    dataType: "json"
	});
    },
    getInfoQuery: function(iri, callback) {
	this.getInfo('/api/data/call/oordbms/get_proc_info', iri, callback);
    },
    getInfoClass: function(iri, callback) {
	this.getInfo('/api/data/call/oordbms/get_class_info', iri, callback);
    },
    loadData: function(callback) {
	var me = this;
	var procName = 'data_get_json_values';
	if(!me.iri) return;
	if(!me.info) return;
	if(!me.dbInfo) return;

	var args = { name:me.info.name, namespace:me.info.namespace,
		     key: JSON.stringify(decodeURIParams(me.iri.query()))
		   };
	var url = '/api/data/call/oordbms/'+procName;
	wb.ajax({ url: url, data: args,
	    success:function(result) { 
		if(result.rows && result.rows[0]) {
		    me.values=JSON.parse(result.rows[0][procName]);
		} else me.values = null;
		callback && callback(me,result); 
	    },
	    dataType: "json"
	});
    },
    saveData: function(mode,callback) {
	var me = this;
	var procName = 'data_set_json_values';
	if(!me.iri) return;
	if(!me.info) return;
	if(!me.dbInfo) return;

	var args = { name:me.info.name, namespace:me.info.namespace,
		     key: JSON.stringify(decodeURIParams(me.iri.query())),
		     data: JSON.stringify(me.values), mode: mode
		   };
	var url = '/api/data/call/oordbms/'+procName;
	wb.ajax({ url: url, data: args,
	    success:function(result) { 
		if(result.rows && result.rows[0]) {
		    me.values=JSON.parse(result.rows[0][procName]);
		} else me.values = null;
		callback && callback(me,result); 
	    },
	    dataType: "json"
	});
    },
},{
    argnames: { get: function() { return (this.dbInfo && this.dbInfo.argnames) || []; }},
    names: { get: function() { return (this.dbInfo && this.dbInfo.names) || []; }},
    types: { get: function() { return (this.dbInfo && this.dbInfo.types) || []; }},
    adef: { get: function() { return this._adef; }}
});

////////////////////////////////////////////////////////////////
// ATOM (common)
////////////////////////////////////////////////////////////////

wb.AtomViewController = wb.ListViewController.extend({
    init: function(options) {
	var me = this;

	this.model = new wb.Model({delegate:this});
	this.listView.style = "grouped";
//	this.css({background:'#ddd'});
	this.inputs = {}; // widgets

	var v = new wb.View();
	this.statusView = new wb.Label({parent:v});
	this.statusView.$.addClass('QueryErrorView');
	this.listView.listHeaderView = v;
    },

    setTitleText: function(string) { 
	var label = this.model && this.model.info && this.model.info.name;
	this.navigationItem.title=string || label || this.iri;
	this.delegateCall('setTitleText',label);
    },

    statusError: function(result) {
	var me = this;
	me.setTitleText("Error...");
	if(typeof(result)=="object") {
	    var box = JSON.toHTML(result).replace(/<details open>/,"<details>");
	    result = '<div>'+result.error+'</div>'+box;
	}
	me.statusView.text = result;
	me.statusView.setStyleName("Error");
    },

    statusNotice: function(string) {
	var me = this;
	me.setTitleText();
	me.statusView.text = string;
	me.statusView.setStyleName("Notice");
    },

    statusWarning: function(string) {
	var me = this;
	me.setTitleText();
	me.statusView.text = string;
	me.statusView.setStyleName("Warning");
    },

    statusSuccess: function(string) {
	var me = this;
	me.setTitleText();
	me.statusView.text = string;
	me.statusView.setStyleName("Success");
    },

    statusOk: function(string) {
	var me = this;
	me.setTitleText();
	me.statusView.text = string;
	me.statusView.setStyleName("Ok");
    },

});

////////////////////////////////////////////////////////////////
// QUERY
////////////////////////////////////////////////////////////////

wb.QueryViewController = wb.AtomViewController.extend({
    init: function(options) {
	var me = this;

	this.title = "Query";
	this.setClass('Query');

	var v2 = new wb.View();
	this.listView.listFooterView = v2;
	this.errorView = new wb.Label({parent:v2}).css({textAlign:'left'});
	this.errorView.$.addClass('QueryErrorView');

	this.navigationItem.backItem = 
	    new wb.Button({
		label:'<i class="fa fa-chevron-left"> Query</i>',
		callback: function() {
		    app.navigationController.popViewControllerAnimated(true);
		}
	    });

	
	this.bigButton = {};

	this.state = 0;
    },
    viewDidAppear: function() {
    },

    loadIRI: function(iri) {
	var me = this;
	if(!iri) {
	    me.statusError("Please specify query as iri URL parameter");
	    return;
	}
	me.setTitleText("Inspecting...");
	me.model.getInfoQuery(iri, function(model) {
	    if(model.info) {

		me.values = {};
		var argnames = me.model.argnames; 
		for(var i in argnames) {
		    me.values[argnames[i]]=wb.urlParams[argnames[i]];
		}
		me.setTitleText();

		me.sections = ["main"];

		me.listView.reloadData();
		if(defined(me.autostart)) { 
		    setTimeout(function() { me.action(); },1);
		}
	    } else {
		me.setTitleText("Not found!");
	    }
	    this.inputs = {}; // widgets
	    me.listView.reloadData();
	});
    },

    actionRun: function() {
	var me = this;
	var model = me.model;
	me.busy = true;
	me.bigButton.selected = true;
	me.setTitleText("Searching...");

	// make busy button
	me.bigButton.contentView.$.css({'background':'url(/lib/images/busy.gif)',
				       'color':'yellow',
				       'font-weight': 'bold',
				       'text-shadow': "4px 4px 4px #444444"});
	me.bigButton.textLabel.text = "WORKING";
	
	var argnames = me.model.argnames; 
	for(var i in argnames) {
	    me.values[argnames[i]]=me.inputs[argnames[i]].getValue();
	}
	var url = '/api/data/call/'+model.info.namespace+'/'+model.info.name;
	wb.ajax({ url: url, data: me.values,
	    success:function(result) { 
		me.setTitleText();
		me.bigButton.selected = false;

		if(result.name=='error') {
		    me.statusError(result);
		} else {
		    model.rows = result.rows;
		    me.statusOk();
		}
		me.listView.reloadData();
		me.autostart = false;
		me.busy = false;
		me.focus();
	    },
	    dataType: "json"
	});
    },

    action: function() {
	var me = this;
	me.actionRun();
    },

    focus: function() {
	$('input:first').focus();
    },

    // list view stuff

    numberOfSectionsInListView: function(listView) {
	var me = this;
	if (!me.model || !me.model.info) return 0;
	if (!me.model.rows || !me.model.rows.length) return 2;
	return 3;
    },
    numberOfRowsInSection: function(listView,section) {
	var me = this;
	switch(section) {
	case 0:
	    if(me.model && me.model.info) {
		return me.model.argnames.length;
	    }
	case 1:
	    return 1;
	case 2:
	    return me.model.rows.length;
	}
    },
    titleForListViewSection: function(listView,section) { return null; },
    didSelectCell: function(cell) {
	var me = this;
	switch(cell.indexPath.section) {
	case 1:
	    this.actionRun();
	    break;
	case 2:
	    var item = cell.item;
	    console.log(me,item);
	    if(item.iri) me.delegateCall('loadIRI',new URI(item.iri));
	    break;
	}
    },
    cellForRowAtIndexPath: function(indexPath) {
	var c;
	var me = this;
	switch(indexPath.section) {
	case 0:
	    var argname =  me.model.argnames[indexPath.row];;
	    c = new wb.ListViewCell({style:'widget'});
	    c.textLabel.text = argname;
            me.inputs[argname] = new wb.TextWidget({parent:c.contentView, delegate:me});
	    me.inputs[argname].setValue(me.values[argname]);
	    break;
	case 1:
	    me.bigButton = new wb.ListViewCell({style:'button',title:'<i class="fa fa-play"> Query</i>'});
	    return me.bigButton;
	    break;
	case 2:
	    var item = me.model.rows[indexPath.row];
	    if(item) {
		var c = new wb.ListViewCell().initWithStyle(coalesce(item.cell_style,'subtitle'));
		var detailText = coalesce(item.detail_text,item.description,'');
		c.delegate = this;
		c.textLabel.text = coalesce(item.label,item.title,item.name,item.text,'Row '+indexPath.row);
		c.detailTextLabel.hidden = !detailText.length>0;
		c.detailTextLabel.text = detailText;
		c.item = item;
		return c;
	    }
	    break;
	}
	return c;
    },
},{
//    title: { get: function() { return this.model.title; }}
});

////////////////////////////////////////////////////////////////
// FORM
////////////////////////////////////////////////////////////////

wb.FormViewController = wb.AtomViewController.extend({
    init: function(options) {
	var me = this;

	this.model = new wb.Model({delegate:this}); 
	this.title = "Form";
	this.setClass('Form');
	this.formMode = 'edit';
	
	this.navigationItem.rightItem = new wb.Button({
	    label:"Done", 
	    callback: function() {
		var values = me.getChangedValues();
		if(keys(values).length>0) {
		    me.actionSave(function() {
			setTimeout(function() {
			    app.navigationController.popViewControllerAnimated(true);
			}, 500);
		    });
		} else {
		    app.navigationController.popViewControllerAnimated(true);
		}
	    }
	});

	if(options && options.model) this.setFormDef(options.model);
	var v = new wb.View();
	this.listView.listFooterView = v;
	var t = new wb.Toolbar({parent:v});
	new wb.Button({
	    parent: t,
	    label:"Save", 
	    callback: function() { me.actionSave(); }
	});
    },

    actionSave: function(cb) {
	var me = this;
	var values = me.getChangedValues();
	if(keys(values).length==0) {
	    me.statusNotice("No change");
	    return;
	}
	me.busy = true;
	me.setTitleText("Saving "+iri.toString()+" ...");
	me.model.values = values;
	me.model.saveData('UPDATE', function(model,result) {
	    me.busy = false;
	    console.log('saveData',result);
	    if(result.name=='error') me.statusError(result)
	    else {
		var values = me.model.values;
		if(values) {
		    me.statusSuccess("Saved.");
		    me.setValues(values);
		    if(cb) cb(result);
		} else {
		    console.log("ERROR",result);
		    // me.statusError(result);
		}
	    }
	});
    },

    setTitleText: function(string) { 
	var label = this.model && this.model.info && this.model.info.name;
	this.navigationItem.title=this.formMode + ' ' + (string || label || this.iri);
	this.delegateCall('setTitleText',label);
    },

    loadIRI: function(iri) {
	var me = this;
	if(!iri) {
	    me.statusError("Please specify query as iri URL parameter");
	    return;
	}
	me.busy = true;
	me.setTitleText("Inspecting "+iri.toString()+" ...");
	me.model.getInfoClass(iri, function(model) {
	    if(model.info) {
		me.statusView.text = model.info.comment;
		me.values = {};
		var argnames = me.model.argnames; 
		for(var i in argnames) {
		    me.values[argnames[i]]=wb.urlParams[argnames[i]];
		}
		me.setTitleText();
		me.listView.reloadData();
		me.clearValues();
		me.model.loadData( function(model,result) {
		    me.busy = false;
		    console.log('loadData',result);
		    if(result.name=='error') me.statusError(result);
		    else {
			var values = model.values;
			if(values) {
			    me.statusOk();
			    me.setValues(values);
			} else {
			    me.statusError("Record not found!");
			}
		    }
		});
	    } else {
		me.setTitleText("Not found!");
		me.resetValues();
	    }
	    this.inputs = {}; // widgets
	    me.listView.reloadData();
	});
    },

    widgetValueDidChange: function(widget) {
	var me = this;
	me.statusOk();
    },

    setTitleText: function(string) { 
	var label = this.model && this.model.info && this.model.info.name;
	this.navigationItem.title=string || label || this.iri;
	this.delegateCall('setTitleText',label);
    },

    // form delegate methods
    getChangedValues: function() {
	var values = {};
	if(this.model && this.inputs) {
	    for(var i in this.model.adef) {
		if(this.inputs[i] && this.inputs[i].changed)
		    values[i]=this.inputs[i].getValue();
	    }
	}
	return values;
    },
    getValues: function() {
	var values = {};
	if(this.model && this.inputs) {
	    for(var i in this.model.adef) {
		if(this.inputs[i])
		    values[i]=this.inputs[i].getValue();
	    }
	}
	return values;
    },
    setValues: function(values) {
	if(values && this.model && this.inputs) {
	    for(var i in this.model.adef) {
		if(this.inputs[i])
		    this.inputs[i].setValue(values[i]);
	    }
	}
    },
    clearValues: function() { this.resetValues(); },
    resetValues: function() {
	if(this.model && this.inputs) {
	    for(var i in this.model.adef) {
		if(this.inputs[i])
		    this.inputs[i].setValue(null);
	    }
	}
    },

    // list view delegate methods
    setModel: function(model) {
	this.model=model;
	this.inputs=null;
	this.listView.reloadData();
	return this;
    },
    numberOfSectionsInListView: function(listView) { 
	if(!this.model) return 0;
	return 1;
	// return this.model.sections.length; 
    },
    numberOfRowsInSection: function(listView,section) { 
	return this.model.names.length; },
/*
    titleForListViewSection: function(s) { 
	return this.model.sectionIndexTitlesForListView[s];
    },
*/
    cellForRowAtIndexPath: function(indexPath) {
	var me = this;
	var attName = me.model.names[indexPath.row];
	var adef = this.model.adef[attName];

	if(!me.inputs) me.inputs = {};
	var c = new wb.WidgetListViewCell({parent:this,adef:adef,delegate:this});
//	c.setValue(me.values[attName]);
	c.setValue(null);

	me.inputs[attName] = c;

	return c;
    },

    viewWillAppear: function() {
	this.busy = true;
	console.log("Detail Open!");
	this.clearValues();
    },

    viewWillDisappear: function() {
	console.log("Detail Close!");
    },

});

////////////////////////////////////////////////////////////////
// APPLICATION
////////////////////////////////////////////////////////////////


var QueryApplication = wb.Application.extend({
    init: function(options) {
	var me = this;
	me.label = "Atom";
	var nc = new wb.NavigationController({parent:this});
	me.css({background: "white"});
	me.master = new wb.QueryViewController({delegate:this}).maximize();
	me.detail = new wb.FormViewController({delegate:this}).maximize();

	var iri    = new URI(wb.urlParams.iri || 'data:/oordbms/list_queries');
	me.loadIRI(iri);

	nc.pushViewControllerAnimated(me.master,false);
	me.navigationController = nc;

	me.screen = wb.getSharedScreen();
	me.setParent(me.screen);
    },
    loadIRI: function(iri) {
	var me = this;
	console.log("OPEN",iri.toString());
	window.iri=iri;
	if(iri.hash()) {
	    window.location.hash=iri.hash();
	    me.navigationController.showViewControllerAnimated(me.detail,true);
	} else {
	    if(iri.search()) {
		me.detail.loadIRI(iri);
		me.navigationController.showViewControllerAnimated(me.detail,true);
	    } else {
		if(defined(wb.urlParams.action)) me.master.autostart=true;
		me.master.loadIRI(iri);
	    }
	}
    },
    setTitleText: function(text) { 
	document.title=text+this.label?(" - "+this.label):""; 
    },
});

function init() {
    app = new QueryApplication();
}

$(window).load(init);
