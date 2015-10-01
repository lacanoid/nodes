/* script for edit */

var app;

// Toolbar configuration generated automatically by the editor based on config.toolbarGroups.
CKEDITOR.config.toolbar = [
    { name: 'styles', items: [ 'Format', 'Styles' ] },
    { name: 'align', items: [ 'JustifyLeft', 'JustifyCenter', 'JustifyRight', 'JustifyBlock'] },
    { name: 'basicstyles', groups: [ 'basicstyles', 'super', 'cleanup' ], 
      items: [ 'Bold', 'Italic', 'Underline', 'Strike', '-', 'Subscript', 'Superscript' ] },
    { name: 'fancystyles', groups: ['font', 'color'], items: [ 'Font', 'FontSize', '-',  'TextColor', 'BGColor' ] },
    { name: 'source', items: [ 'Source' ] },
    '/',
    { name: 'undo', items: [ 'Undo', 'Redo' ] },
    { name: 'editing', items: [ 'Find', 'Replace', '-', 'SelectAll', '-',  'RemoveFormat' ] },
    { name: 'clipboard', items: [ 'Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord'] },
    { name: 'paragraph', groups: [ 'list', 'indent', 'blocks' ], items: [ 'NumberedList', 'BulletedList', '-', 'Outdent', 'Indent', '-', 'Blockquote', 'CreateDiv' ] },
    { name: 'links', items: [ 'Link', 'Unlink' ] },
    { name: 'insert', items: [ 'Image', 'Table', 'HorizontalRule' ] },
    { name: 'view', items: [ 'ShowBlocks' ] },
    { name: 'maximize', items: ['Maximize'] },
];

wb.ajax = function(args) {
    $.ajax(args);
};

wb.EditorModel = extend(Object,{
    init: function(options) {
	var me = nu.args(this);
    },
    loadPageData: function(title, rev_id, callback) {
	if(!title) return;
	var me = this;
	me._title = title;
	wb.ajax({url:'/api/wiki/getPageData', 
		 data:{title:title,rev_id:rev_id},
		 success:function(data) {
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
    save: function(callback) {
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
},
{
    title: { 
	get: function() { return this._title; } 
    },
    body: {
	get: function() { return this.data.page_body; },
	set: function(v) { return this.data.page_body=v; },
    },
    isShownAt: {
	get: function() { return "/"+encodeURI(this.title); }
    },
});




wb.DocumentEditor = wb.View.extend({
    init: function(options) {
	var args = nu.args(this);
	var me = this;

	this.setClass('DocumentEditor');

	this._mode = 'text';
	this.texted = new wb.View({parent: this, HTMLtag:"pre"}).maximize();
	this.element.onresize=function(e) { me.viewDidResize(e); };

	var ace1;
	    ace1 = ace.edit(this.texted.element);
//	    ace1.setTheme("ace/theme/cobalt");
	    ace1.setShowPrintMargin(false);
	    ace1.session.setMode("ace/mode/text");
	    ace1.session.setFoldStyle('markbegin');
	    ace1.session.setTabSize(2);
	this.ace = ace1;

	this.keyDown = function() {
	    return true;
	};
	this.setDirty = function() {
	    me.dirty = true;
	    console.log("DIRTY");
	    me.validateUI();
	};

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
	    var s = (v=="rich");
	    this.riched.hidden=!s; 
	    this.texted.hidden=s; 
	    this._mode = v;
	}
    },
    body: {
	get: function() {
	    var q;
	    if(this._mode=='rich') {
		q = CKEDITOR.instances[this.riched.id].getData();
	    } else {
		q = this.ace.getSession().getValue();
	    }
	    return q;
	},
	set: function(val) {
	    if(this._mode=='rich') {
		this.riched.html(val);
		q = CKEDITOR.instances[this.riched.id].setData(val);
	    }else {
		this.ace && this.ace.getSession().setValue(val);
	    }
	},
    }
});

wb.EditorViewController = wb.ViewController.extend({
    init: function(options) {
	var me = this;

	this.view = new wb.DocumentEditor({parent:this, delegate:this}).maximize();
	this.model = new wb.EditorModel({delegate:this});

	this.navigationItem.rightItem = new wb.Button({
	    label:"Done", 
	    callback: function() { 
		me.model.body = me.view.body;
		me.model.save( function(data) {
		    if(data.success)
			me.delegateCall('didSaveEditor',me); 
		});
	    }
	});

    },
    loadPage: function(title, rev_id) {
	var me = this;
	this.model.loadPageData(title, rev_id, function(model) {
	    console.log("LOADED DATA",title,rev_id,model);
	    me.view.mode = "rich";
	    me.view.body = model.body;
	});
    }
},{
    title: { get: function() { return this.model.title; }}
});

var EditorApplication = wb.Application.extend({
    init: function(options) {
	var me = this;
	// this.splitViewController = new wb.SplitViewController({parent:this});
	var nc = new wb.NavigationController({parent:this});
	this.editor = new wb.EditorViewController({parent:this,delegate:this}).maximize();
	nc.pushViewControllerAnimated(this.editor,false);
	this.navigationController = nc;

	var title  = wb.urlParams.title;
	var rev_id = wb.urlParams.rev_id;
//	console.log('ARGS',title,rev_id);
	if(title) { this.editor.loadPage(title,rev_id); }

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
    willSaveEditor: function(e) {
    },
    didSaveEditor: function(e) {
	var url = e.model.isShownAt;
	this.openURL(url);
    },
});

function init() {
    app = new EditorApplication();
}

$(window).load(init);
