/* script for preview */

var app;

wb.BookmarkModel = nu.Object.extend({
    init: function(options) {
	var me = nu.args(this);
	me.info={};
    },
    getInfo: function(iri, callback) {
	var me=this;
	wb.ajax({ url: '/api/filer/getinfo/', data: { iri: iri },
	    success:function(data) { 
		me.info = data; me.iri  = iri;
		callback && callback(me, data); 
	    },
	    dataType: "json"
	});
    },
},
{
    isShownBy: { // file
	get: function() { if(this.iri)  return "/api/filer/get?iri="+encodeIRI(this.iri); }
    },
    isShownAt: { // preview app
	get: function() { if(this.iri)  return "/app/preview/?iri="+encodeIRI(this.iri); }
    },
    isGotAt: { // file
	get: function() { if(this.iri)  return "/api/filer/get/"+encodeIRI(this.iri); }
    },
    isDownloadedAt: { // download link
	get: function() { if(this.iri)  return "/api/filer/download?iri="+encodeIRI(this.iri); }
    },
    isEditedAt: { // editor link
	get: function() { if(this.iri)  return "/app/edit/?iri="+encodeIRI(this.iri); }
    },
});


wb.PreviewController = wb.ViewController.extend({
    init: function(options) {
	var me = this;

	this.limit = 100000000; // editor file size limit 100 Mb
	this.webView  = new wb.WebView({parent:this,delegate:this}).maximize();
	this.model = new wb.BookmarkModel({delegate:this});

	this.navigationItem.rightItem = new wb.Button({
	    label:"Edit",
	    callback: function() { me.delegateCall('actionEdit',me.model); }
	});

	this.navigationItem.leftItem = new wb.Button({
	    label:"Download",
	    callback: function() { me.delegateCall('actionDownload',me.model); }
	});
    },
    loadIRI: function(iri) {
	if(!iri) return;
	var me = this;
	me.setTitleText("Loading...");
	me.model.getInfo(iri, function(model, info) {
	    me.iri = iri;
	    me.setTitleText();
	    var m = info.mime.match(/^([^\/]+)\/([^\/]+)$/);
	    var type =    m[1]; var subType = m[2];
	    if(!type) return;
	    
	    var icon = '/'+info.icon.replace(':','/')+'.png';
	    console.log("INFO",info);
	    me.delegate.setIcon(icon);
	    if(me.shouldPreviewInEditor(model)) {
		me.delegateCall('openURL',model.isEditedAt);
	    } else {
		var url;
		if(info.mime=="application/x-nodex-bookmark") {
		    url = ( info.data && info.data.URL );
		    if(info.data && info.data.URL) {
			url =  info.data.URL;
			window.location = url;
		    }
		} else {
		    if(info.isObject && info.data) {
			me.webView.write(JSON.toHTML(info.data));
			return;
		    } 

		    url = model.isGotAt;
		}
		// set iframe source
		if(url) {
		    me.setTitleText("Loading...");
		    me.webView.loadURL(url);
		} else { console.log("BAD URL"); }
	    }
	});
    },
    shouldPreviewInEditor: function(model) {
	var mime = model.info && model.info.mime;
	if(mime=="application/pdf") return false;
	if(mime=="application/x-nodex-bookmark") return false;
	if(mime=="application/x-plist") return false;
	if(mime=="application/json") return false;
	if(mime=="application/octet-stream") return true;
	if(mime.match('^application/')) return true;
	return false;
    },
    webViewDidFinishLoad: function(v) {
	this.setTitleText();
    },
    setTitleText: function(string) { 
	var label = this.model.info.name;
	this.navigationItem.title=string || label || this.iri;
	document.title=label+
	    ((this.delegate && this.delegate.label)?
	     (" - "+this.delegate.label):""); 
    }
},{
//    title: { get: function() { return this.model.title; }}
});

var PreviewApplication = wb.Application.extend({
    init: function(options) {
	var me = this;
	me.label = "Preview";
	// this.splitViewController = new wb.SplitViewController({parent:this});
	var nc = new wb.NavigationController({parent:this});
	this.css({background: "white"});
	this.editor = new wb.PreviewController({parent:this,delegate:this}).maximize();
	nc.pushViewControllerAnimated(this.editor,false);
	this.navigationController = nc;

	var iri    = wb.urlParams.iri;
	if(iri) { this.editor.loadIRI(iri); }

	this._info = {					     
	    name:"Preview",
	    title:"Nodex Preview",
	    version:"0.1 alpha",
	    image:"icon:applications/utilities-preview",
	    description:"file preview",
	};

	this.screen = wb.getSharedScreen();
	this.setParent(this.screen);

	var me = this;
    },
    actionEdit: function(model) { 
	if(model && model.isEditedAt)
	    window.open(model.isEditedAt+"&returnTo=app/preview",model.iri).focus();
    },
    actionDownload: function(model) { 
	if(model && model.isDownloadedAt)
	    this.openURL(model.isDownloadedAt);
    },
});

function init() {
    app = new PreviewApplication();
}

$(window).load(init);
