/* script for textedit */

var app;

wb.DocumentModel = nu.Object.extend({
    init: function(options) {
	var me = nu.args(this);
	me.info = {wb:{}};
    },
    // load wiki page
    loadWikiPageData: function(title, rev_id, callback) {
	if(!title) return;
	var me = this;
	wb.ajax({url:'/api/wiki/getPageData', 
		 data:{title:title,rev_id:rev_id},
		 success:function(data) {
		     me._title = title;
		     me._iri = null;
		     me.data = data.data || data;
		     callback && callback(me,me.data);
		 },
		 error:function(r) {
		     me.data = {};
		     callback && callback(me,r);
		 },
		 dataType: "json"
		});
    },
    saveWikiPageData: function(callback) {
	if(!this.title) return;
	var me = this;
	wb.ajax({
	    type: 'POST',
	    url:'/api/wiki/setPageData', 
	    data:{title:this.title,body:this.body},
	    success:function(data) {
		if(data && data.success) {
		    callback && callback(data);
		} else {
		    app.alert(data);
		    callback && callback(data);
		}
	    },
	    error:function(r) {
		me.data = {};
		me.alert(r)
		callback && callback(me.data);
	    },
	    dataType: "json"
	});
    },
    // save any type of page
    save: function(callback) {
	console.log('SAVING MODEL',this);
	if(this._iri) { this.saveIRIData(callback); }
	else if(this.title) { this.saveWikiPageData(callback); }
    },
    // inspect 
    getIRIInfo: function(iri, callback) {
	var me=this;
	wb.ajax({
	    url: '/api/filer/getinfo/', 
	    data: { iri: iri },
	    success:function(data) {
		callback && callback(me, data);
	    },
	});
    },
    loadIRIData: function(iri, callback) {
	var me=this;
	wb.ajax({
	    url:"/api/filer/get/",
	    data: {iri: iri},
	    success: function(data) {
		me._iri = iri;
		me._title = null;
		me.data={page_body:data};
		if(localStorage[iri]) {
		    me.focus = from_json(localStorage[iri])
		}
		callback && callback(me, me.data);
	    },
	    error: function(err) {
		me.data=null;
		callback && callback(me);
	    },
	    dataType: "text"
	});
	
    },
    saveIRIData: function(callback) {
	var me=this;
	if(!me._iri) return;
	if(me.focus) {
	    localStorage[me._iri]=to_json(me.focus);
	}
	wb.ajax({
	    url:"/api/filer/put/",
	    type:"GET",
	    data: {iri: me._iri, content: me.body },
	    success: function(data) {
		    callback && callback(me,data);
	    },
	    error: function(err) {
		console.log(err);
		app.alert("Error while saving document",{err:err});
		callback && callback(me,null,err);
	    }
	});
    },
    aceModeForMimetype: function(mime) {
	if(!mime) return;
	if(mime=="application/octet-stream") return 'text';
	if(mime=="text/css") return 'css';
	if(mime=="application/x-nodex-bookmark") return 'xml';
	if(mime.match('^application/x-nodex-')) return 'text';
	if(mime.match('^text/x?html')) return 'html';
	if(mime.match('^text/')) return 'text';
	if(mime.match('^text/')) return 'text';
	if(mime.match('^(audio|video)/')) return null;
	if(mime.match('(json|javascript)')) return 'javascript';
	if(mime.match('(x-plist|xml|rdf|svg)')) return 'xml';
	if(mime.match('sql')) return 'text';

	return null;
    },
},
{
    iri: {
	get: function() { return this._iri; },
	set: function(v) { return this._iri=v; },
    },
    title: { 
	get: function() { return this._title; } 
    },
    body: {
	get: function() { return this.data.page_body; },
	set: function(v) { return this.data.page_body=v; },
    },
    aceMode: {
	get: function() { return this.info?this.aceModeForMimetype(this.info.mime):null; },
    },
    isShownAt: {
	get: function() { 
	    if(this._iri)  return this._iri;
	    if(this.title) return "/"+encodeURI(this.title); 
	}
    },
});




wb.EditorView = wb.View.extend({
    init: function(options) {
	var args = nu.args(this);
	var me = this;

	this.setClass('EditorView');

	this._mode = 'none';
	this.element.onresize=function(e) { me.viewDidResize(e); };

//	if(timer) clearTimeout(timer);
//	timer = setTimeout('save()',500);
    },
    validateUI: function() {
//	console.log(this.enabledStuff());
    },
    enabled: function(command) {
	return this.riched.element.queryCommandValue(command)=='true';
    },
    enabledStuff: function() {
	var stuff='';
	if(this.enabled('bold')) stuff+='B';
	if(this.enabled('italic')) stuff+='I';
	if(this.enabled('underline')) stuff+='U';
	if(this.enabled('strikeThrough')) stuff+='S';
	if(this.enabled('superscript')) stuff+='^';
	if(this.enabled('subscript')) stuff+='_';
	
	if(this.enabled('justifyFull')) { stuff+='F'; }
	if(this.enabled('justifyLeft')) { stuff+='L'; }
	if(this.enabled('justifyCenter')) { stuff+='C'; }
	if(this.enabled('justifyRight')) { stuff+='R'; }
	
	return stuff;
    },
    blockFormatLabel: function() {
    },
    highlightColor: function() {
    },
    viewDidResize: function(e) {
	var h = this.$.height();
	var htop = this.$.find('.cke_top').height();
	var hbot = this.$.find('.cke_bottom').height();
	h = h - htop - hbot - 21;
	this.$.find('.cke_contents').height(h+'px');
	console.log('RESIZE',h);
    },
},{
    texted: {
	get: function() {
	    if(!this._texted) {
		var me = this;
		var texted = new wb.View({parent: this, HTMLtag:"pre"}).maximize();
		this._texted = texted;
		
		var ace1;
		ace1 = ace.edit(texted.element);
		//	      ace1.setTheme("ace/theme/cobalt");
		ace1.setShowPrintMargin(false);
 		ace1.session.setMode("ace/mode/text");
		ace1.session.setFoldStyle('markbegin');
		ace1.session.setTabSize(2);
		ace1.commands.addCommand({
		    name: 'compile',
		    bindKey: { win: 'Ctrl-S', mac: 'Command-S', sender: me },
		    exec: function(env, args, request) {
			me.delegateCall('saveModel');
		    }
		});

		this.ace = ace1;
		
		this.keyDown = function() {
		    return true;
		};
		this.setDirty = function() {
		    me.dirty = true;
		    console.log("DIRTY");
		    me.validateUI();
		};
	    }
	    return this._texted;
	}
    },
    riched: {
	get: function() {
	    if(!this._riched) {
		var me = this;
		/*
		var riched = new wb.ScrollView({parent: this, HTMLtag:"article"}).maximize();

		riched.$.bind('keydown', this.keyDown);
		riched.$.bind('keyup', this.setDirty);
		riched.$.bind('cut', this.setDirty);
		riched.$.bind('paste', this.setDirty);
		riched.$.bind('change', this.setDirty);
		riched.$.attr({contentEditable:"true"});
		*/
		var riched = new wb.View({parent: this, HTMLtag:"textarea"}).maximize();
		
		CKEDITOR.config.keystrokes = [
		    [ CKEDITOR.CTRL + 83 /*S*/, 'save' ],
		];
		CKEDITOR.on('instanceReady', function() { 
		    /*
		      CKEDITOR.instances[riched.id].on('key', function(e) {
		      console.log('KEY',e);
		      });
		    */
		    CKEDITOR.instances[riched.id].focus();
		    me.viewDidResize(); 
		});
		CKEDITOR.replace(riched.id,{ fullPage:true });
//		riched.$.ckeditor();

		this._riched = riched;
	    }
	    return this._riched;
	}
    },
    mode: {
	get: function() { return this._mode; },
	set: function(v) {
	    switch(v) {
	    case 'rich':
		this.riched.hidden=false;
		if(this._texted) this._texted.hidden=true;
		break;
	    case 'text':
		this.texted.hidden=false;
		if(this._riched) this._riched.hidden=true;
		break;
	    }
	    this._mode = v;
	}
    },
    body: {
	get: function() {
	    var q;
	    switch(this._mode) {
	    case 'rich':
		return CKEDITOR.instances[this.riched.id].getData();
	    case 'text':
		return this.ace.getSession().getValue();
	    }
	},
	set: function(val) {
	    switch(this._mode) {
	    case 'rich':
		// this.riched.html(val);
		CKEDITOR.instances[this.riched.id].setData(val);
		break;
	    case 'text':
		this.ace && this.ace.getSession().setValue(val);
		break;
	    }
	},
    },
    aceMode: {
	set: function(v) {
	    switch(this._mode) {
	    case 'text':
		this.ace && this.ace.getSession().setMode('ace/mode/'+v);
		break;
	    }
	}
    },
    selectedRange: {
	get: function() {
	    switch(this._mode) {
	    case 'text':
		return this.ace && app.editor.view.ace.selection.getRange();
		break;
	    }
	},
	set: function(v) {
	    switch(this._mode) {
	    case 'text':
		return this.ace && v && this.ace.selection.setSelectionRange(v);
		break;
	    }
	}
    },
});

wb.EditorViewController = wb.ViewController.extend({
    init: function(options) {
	var me = this;

	this.view  = new wb.EditorView({parent:this, delegate:this}).maximize();
	this.model = new wb.DocumentModel({delegate:this});

	this.navigationItem.rightItem = new wb.Button({
	    label: wb.urlParams.returnTo?"Done":"Save",
	    callback: function() { me.saveModel(); }
	});

    },
    canHandleFile: function(model,info) {
	var aceMode = model.aceModeForMimetype(info.mime);
	return aceMode?true:false;
    },
    save: function() { this.saveModel(); },
    saveModel: function() {
	var me = this;
	me.model.body = me.view.body;
	me.model.focus = me.view.selectedRange;
	me.setTitleText("Saving...");
	me.delegateCall('willSaveModel',me.model);
	me.model.save( function(m,r,e) {
	    console.log('SAVED',r);
	    if(!e) {
		me.setTitleText("Saved...");
		me.delegateCall('didSaveModel',me.model,r);
		me.setTitleText();
	    } else {
		me.setTitleText("Save error!");
	    }
	});
    },
    loadWikiPage: function(title, rev_id) {
	var me = this;
	this.model.loadWikiPageData(title, rev_id, function(model) {
	    console.log("LOADED DATA",title,rev_id,model);
	    me.view.mode = "rich";
	    me.view.body = model.body;
	});
    },
    loadIRI: function(iri) {
	var me = this;
	this.setTitleText("Loading...");
	this.model.getIRIInfo(iri, function(model,info) {
	    console.log("INFO",iri,info);
	    if(me.canHandleFile(model,info)) {
		me.setTitleText("Loading "+info.name+"...");
		me.model.loadIRIData(iri, function(model,data) {
		    me.model.info = info;
		    me.filename = info.name;
		    me.view.mode = "text";
		    me.view.aceMode = model.aceMode;
		    me.view.body = model.body;
		    if(me.model.focus)
			me.view.selectedRange = me.model.focus;
		    me.setTitleText();
		});
	    } else {
		me.setTitleText("Error");
		me.alert("Can't open file "+info.name,
			 {message:"File type <b>"+info.mime+"</b> is not supported"});
	    }
	});
    },
    setTitleText: function(string) { 
	this.navigationItem.title=string?string:this.filename;

	document.title=this.filename+
		((this.delegate && this.delegate.label)?
		 (" - "+this.delegate.label):""); 
    }
},{
    title: { get: function() { return this.model.title; }}
});

var EditorApplication = wb.Application.extend({
    init: function(options) {
	var me = this;
	me.label = "TextEdit";
	// this.splitViewController = new wb.SplitViewController({parent:this});
	var nc = new wb.NavigationController({parent:this});
	this.editor = new wb.EditorViewController({parent:this,delegate:this}).maximize();
	nc.pushViewControllerAnimated(this.editor,false);
	this.navigationController = nc;

	var title  = wb.urlParams.title;
	var iri    = wb.urlParams.iri;
	var rev_id = wb.urlParams.rev_id;

	if(iri) { this.editor.loadIRI(iri); }
	else if(title) { this.editor.loadWikiPage(title,rev_id); }

	this._info = {					     
	    name:"Editor",
	    title:"Nodex Editor",
	    version:"0.1 alpha",
	    image:"icon:applications/utilities-editor",
	    description:"a web file editor",
	};

	this.screen = wb.getSharedScreen();
	this.setParent(this.screen);

	var me = this;
    },
    willSaveModel: function(model) { 
	this.setBusy(true);
    },
    didSaveModel: function(model,result) {
	this.setBusy(false);
	var returnTo = wb.urlParams.returnTo;
	if(returnTo) {
	    var url = '/'+returnTo+'?iri='+encodeIRI(model.iri);
	    this.openURL(url);
	}
    },
    save: function() { this.editor.save(); }
});

function init() {
    app = new EditorApplication();
}

$(window).load(init);
