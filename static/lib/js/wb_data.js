// JavaScript workbench
// v 20110408
// by ziga@ljudmila.org

/*
function $$(id) { return typeof(id)=='string'?document.getElementById(id):id; }
function defined(v) { return (typeof v != "undefined") && (v !== null); }
function coalesce(a,b) { return defined(a)?a:b; }
function nuls(s) { if(s!=='') { return s; } else { return undefined; } }
function empty(hash) { for(var i in hash) { return false; } return true; }
*/

// function print(a,b,c) { if(typeof console != 'undefined') console.log(a,b,c); }
if(typeof console != 'undefined') print = console.log;

wb.xmlns = { 
    ns: {
	rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
	ical: "http://www.w3.org/2002/12/cal/icaltzd#",
	dc: "http://purl.org/dc/elements/1.1/",
	dcterms: "http://purl.org/dc/terms/",
	cc: "http://web.resource.org/cc/",
	skos: "http://www.w3.org/2004/02/skos/core#" ,
	vCard: "http://www.w3.org/2001/vcard-rdf/3.0#",
	foaf: "http://xmlns.com/foaf/0.1/",
	geo: "http://www.w3.org/2003/01/geo/wgs84_pos#",
	xhtml: "http://www.w3.org/1999/xhtml#",
	style: "http://w3c.org/css#",
	m3c: "http://www.m3c.si/xmlns/m3c/2006-06#",
	lj: "http://www.ljudmila.org/terms#"
    },
    ins: {},
    expandURI: function(uri) {
	var i=uri.indexOf(':');
	if(i>=0) {
	    var ns = uri.substr(0,i);
	    if(ns=='http') return uri;
	    if(defined(wb.xmlns.ns[ns])) {
		return wb.xmlns.ns[ns] + uri.substr(i+1);
	    }
	}
	return uri;
    },
    contractURI: function(uri) {
	if(defined(this.ins[uri])) {
	    if(this.ins[uri]) return this.ins[uri];
	    else return uri;
	}
	for(var ns in this.ns) {
	    if(uri.indexOf(this.ns[ns])==0) {
		var uri2 = ns+':'+uri.substr(this.ns[ns].length);	
		this.ins[uri] = uri2;
		return uri2;
	    }
	}
	return uri;
    },
};

wb.nid = 1000;
wb.resources = {};

wb.new_id = function() { return 'wb_'+(wb.nid++); };

wb.object = {};

wb.object = function(args) { return this.init(args); };

wb.subclass = function(me,superclass,args) {
    $.extend(me,new superclass(args));
    if(defined(wb.data.observers[me.url])) {
	wb.data.observers[me.url]=me;
    }
};

wb.object.prototype = {};
wb.object.prototype.constructor = wb.object;

/* object needs 
   - 

*/

var objproto = {
    // ivars
    id: null,
    url: null,
    meta: null, /* meta object pointer */
    persistent: null,
    observant: null,

    el: null, /* DOM element, for views etc */
    
    // functions
    description: function() { return this.url; },
    init: function(args) {
	args = coalesce(args,{});
//	print('NEW',args);
	var mee=this;
	
	$.extend(this,args);
	if(this.url) {
	    var i=this.url.indexOf('#');
	    if(i>=0 && this.url.substr(i+1).length>0 && !defined(this.id)) {
		this.id=this.url.substr(i+1);
	    }
	    if(!this.id) { this.id = wb.new_id(); }
	    this.persistent=true;
	} else {
	    if(!this.id) { this.id = wb.new_id(); }
	    this.url = window.location.pathname+'#'+this.id;
	}
	this.persistent = coalesce(this.persistent,false);
	this.observant = coalesce(this.observant,this.persistent);
	this.el = coalesce(this.el,null);
	if(this.persistent) { 
	    wb.data.observers[this.url]=this; 
	    wb.data.defaultMOC.addLoad(this.url);
	    // print ("ISIIT",mee===wb.data.observers[this.url]);
	    return wb.data.observers[this.url];
	}
	// print ("ISIT",this==mee);
    },
    // properties
    get: function(properties) { return this.getProperty(properties); },
    set: function(properties,values,local) { this.setProperty(properties,values,local); },
    getProperty: function(properties) {
	if(typeof(properties)=='string') { 
	    return this[properties];
	} else {
	    var r=[];
	    for(var i in properties) { r.push(this[properties[i]]); }
	    return r;
	}
    },
    setProperty: function(properties,values,local) {
	// print('SET',this.url,properties,values);
	if(typeof(properties)=='string') { properties=[properties]; values=[values]; }
	for(var i in properties) { this[properties[i]]=values[i]; }
	if(!local && this.url && this.persistent) { 
	    wb.data.defaultMOC.setProperties(this.url,properties,values,false); 
	}
    },
    appendToProperty: function(properties,values) {
	if(typeof(properties)=='string') { properties=[properties]; values=[values]; }
	for(var i in properties) { this[properties[i]]=values[i]; }
	if(this.url && this.persistent) { wb.data.defaultMOC.setProperties(this.url,properties,values,true); }
    },
    // storage
    save: function() {
	wb.data.defaultMOC.commit();
    },
    load: function() {
	wb.data.defaultMOC.addLoad(this.url);
	wb.data.defaultMOC.commit();
    }
    /*
      saveAll: function() {
      wb.data.defaultMOC.commit();
      },
    */
};

$.extend(wb.object.prototype, objproto);

wb.log = function(x) { if(typeof console != 'undefined') console.log(x); }
wb.fail = function(err) { wb.log(err); }

wb.ui = new wb.object();


wb.ui.view = function(args) {
    args = coalesce(args,{});
    args['class']=coalesce(args['class'],'wb-ui-view');
    this.init(args);
    var parent;
    //	$.extend(this, new wb.object(args));
    // print(args.parent);
    if(defined(args.parent)) { parent = $$(args.parent); }
    else { parent = document.body };
    if(!parent) wb.fail("Can't find parent element #"+args.parent);
    this.parentElement = parent;
    if(!this.el) this.el=document.getElementById(this.id);
    if(!this.el) {
	$(parent).append('<div id="'+this.id+'" class="'+coalesce(args["class"],'wb-ui-view')+'">'+
			 coalesce(args.text,'')+'</div>');
	this.el=document.getElementById(this.id);
    }
    if(!this.el) wb.fail("Failed to create element #"+this.id);
    return this;
};
wb.ui.view.prototype.__proto__=wb.object.prototype;
wb.ui.view.prototype=$.extend({},wb.object.prototype);
wb.ui.view.prototype.setProperty = function(properties,values,local) {
    if(typeof(properties)=='string') { properties=[properties]; values=[values]; }
    for(var i in properties) { 
	var p=properties[i];
	var v=values[i];
	wb.log('view:'+p+'='+v);
	if(p.indexOf('style:')==0) { this.el.style[p.substr(6)]=v; } 
	else { this[p]=values[v]; }
    }
    if(!local && this.url && this.persistent) { wb.data.defaultMOC.setProperties(this.url,properties,values,false); }
};
wb.ui.view.prototype.css = function(property,value) {
    property='style:'+property;
    this.setProperty(property,value);
};
wb.ui.view.prototype.setFrame = function(frame) {
    this.css('position','absolute');
    if(defined(frame.top))    this.css('top',frame.top);
    if(defined(frame.left))   this.css('left',frame.left);
    if(defined(frame.right))  this.css('right',frame.right);
    if(defined(frame.bottom)) this.css('bottom',frame.bottom);
};
wb.ui.view.prototype.constructor = wb.ui.view;
wb.ui.view.prototype.tag = function(tag) {
};

wb.ui.viewController = function(args) {
    args = coalesce(args,{});
    //	this.prototype = new wb.object(args);
    wb.subclass(this, wb.object, args);
    this.view = null;
    this.loadView = function() {
	if(!this.view) { this.view = new wb.ui.view({
	    id:this.id+'-view', parent:args.parent, 'class':args['class']
	}); }
    };
    return this;
};

wb.ui.navigationController = function(args) {
    args = coalesce(args,{});
    args['class']=coalesce(args['class'],'wb-ui-navigationController');
    wb.subclass(this, wb.ui.viewController, args);
    this.loadView();
    var self = this;
    this.id = this.view.id;
    this.toolbarTop = new wb.ui.toolbar({
	parent:self.id,'class':'wb-ui-toolbar toolbar-top'
    });
    this.toolbarTop.setFrame({left:0,right:0,top:0});
    this.scrollView = new wb.ui.scrollView({
	parent:self.id,'class':'wb-ui-scrollview'
    });
    this.scrollView.setFrame({left:0,right:0,top:'33px',bottom:'33px'});
    this.toolbarBottom = new wb.ui.toolbar({
	parent:self.id,'class':'wb-ui-toolbar toolbar-bottom'
    });
    this.toolbarTop.setFrame({left:0,right:0,bottom:0});
    this.pushViewControllerAnimated = function(viewController,animated) {
    };
    this.popViewControllerAnimated = function(animated) {
    };
    return this;
};


wb.ui.button = function(args) {
    args = coalesce(args,{});
    args['class']=coalesce(args['class'],'wb-ui-button');
    wb.subclass(this, wb.ui.view, args);
    $(this.el).text(coalesce(args.text,'Button'));
    this.el.style.background='#ddd';
    this.el.style.textAlign='center';
    this.el.style.border='1px solid gray';
};

wb.ui.toolbar = function(args) {
    args = coalesce(args,{});
    args['class']=coalesce(args['class'],'wb-ui-toolbar');
    wb.subclass(this, wb.ui.view, args);
    this.css('background','#ccc');
    this.css('height','33px');
    this.css('border','1px solid black');
    this.css('padding','4px');
};

wb.ui.scrollView = function(args) {
    args = coalesce(args,{});
    args['class']=coalesce(args['class'],'wb-ui-scrollview');
    wb.subclass(this, wb.ui.view, args);
    this.css('overflow','auto');
};


wb.ui.console = function(args) {
    args = coalesce(args,{});
    args['class']=coalesce(args['class'],'wb-ui-console');
    wb.subclass(this, wb.ui.viewController, args);
    this.loadView();
    var self = this;
    this.i=1;
    $(this.view.el)
	.append('<div id="'+self.id+'-output" class="wb-ui-console-output"></div>'+
	        '<div id="'+self.id+'-input" class="wb-ui-console-input">'+
                '<input class="text" type="text" style="width: 90%"></div>'+
                '<div id="'+self.id+'-history" class="wb-ui-console-history"></div>')
	.css('margin','8px');


    $.extend(this,{
	output: function(msg) { 
	    $('#'+self.id+'-output').append(msg); 
	    $(self.view.parentElement).scrollTop(10000000); // FIXME: scroll to proper place
	},
	focus: function() { $('#'+self.id+'-input input.text').focus(); },
	val: function() { return $('#'+self.id+'-input input.text').val(); },
    });

    $(this.view.el).keypress(function(e) { 
	if(e.keyCode==13) {
	    var expr0=self.val();
	    if(expr0.length<1) return;
	    self.output('<div id="'+self.id+'-in-'+self.i+'">In['+self.i+']='+expr0+'</div>');
	    if(self.interpreter) { 
		var expr1 = self.interpreter(expr0);
		self.output('<div id="'+self.id+'-out-'+self.i+'">Out['+self.i+']='+expr1+'</div>');
	    }
	    self.appendToProperty('log',expr0);
	    $('#'+self.id+'-input input.text').select();
	    self.i++;
	} else {
	    self.output()
	}
    });
    return this;
};


wb.data = new wb.object();
wb.data.observers = {};
wb.data.xid=101;
wb.data.MOC = function(args) {
    var self = this;
    this.url_base = '/wb/api/request';
    $.extend(this, new wb.object(args));
    $.extend(this, {
	cache: {},
	cache_out: {},
	// set object properties
	setProperties: function(url,properties,values,append) {
	    if(!self.cache[url]) { self.cache[url]={}; }
	    if(typeof(properties)=='string') {
		properties=[properties]; values=[values];
	    }
	    for(var i in properties) {
		var p=wb.xmlns.expandURI(properties[i]);
		var v=values[i];
		if(!self.cache[url][p]) { self.cache[url][p]=[]; }
		var vv;

		if(typeof(v)=='object') vv={value: v.url, type: 'uri'} 
		else vv={value: v, type:'literal', datatype:typeof(v)};

		if(append) self.cache[url][p].push(vv)
		else self.cache[url][p]=[vv];
	    }
	},
	// commit object to server
	commit: function(callback,data) {
	    var req = {};
	    if(!empty(self.cache)) {
		req.rdf = self.cache;
		// FIXME: do this when really saved!
		self.cache_out[req.xid]=self.cache; self.cache={}; 
	    }
	    req.xid = wb.data.xid++;
	    req.action = 'commit';
	    req.url = wb.page.url;
	    if(self.loadQueue) {
		req.load = self.loadQueue; self.loadQueue = null;
	    }
	    print('REQ',req);
	    // swap in new cache
	    $.ajax({type: 'POST',
		    url: self.url_base,
		    data: JSON.stringify(req),
		    contentType: 'application/json',
		    processData: false,
  		    dataType: 'json',
  		    success: function(res,xid) {
			print('RES',res);
			if(res.xid && res.rdf) { 
			    for(var uri in res.rdf) {
				if(wb.data.observers[uri]) { 
				    var s = res.rdf[uri];
				    var obj = wb.data.observers[uri];
				    print('UPDATE',uri,s);
				    for(var prop in s) {
					var vals = s[prop];
					prop = wb.xmlns.contractURI(prop);
					for(var i in vals) {
					    obj.setProperty(prop,vals[i].value,true);
					}
				    }
				}
			    }
			}
		    }
		   });
	},
	// add deferred loading
	addLoad: function(url) {
	    if(!self.loadQueue) self.loadQueue=[];
	    self.loadQueue.push(url);
	}
    });
};
wb.data.defaultMOC = new wb.data.MOC();

wb.sync = function() { wb.data.defaultMOC.commit(); }

wb.page = new wb.ui.view({id:'page', url:window.location.pathname, el:document.body});

