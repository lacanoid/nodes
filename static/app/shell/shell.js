var app;

var ShellApplication = wb.Application.extend({
    init: function(options) {
	this.navigationController = new wb.NavigationController({parent:this});

	this._info = {					     
	    name:"Filer",
	    title:"Nodex Filer",
	    version:"0.1 alpha",
	    image:"icon:applications/shell",
	    description:"a web file manager",
	};

	if(_build_date) { this._info.version += "<br><small>built on "+_build_date+"</small>"; }
	this.screen = wb.getSharedScreen();
	this.setParent(this.screen);


	this.browser = new Browser({parent:this,delegate:this});
	this.console = new Console({delegate:this});
	this.searcher = new Searcher({delegate:this});

	var me = this;
    },

    viewURL: function(url, options) { url && this.openURL("/api/filer/get?iri="+encodeIRI(url),options); },

    setHash: function(h) { window.location.hash=h; },

    openConsoleAnimated: function(iri,animated) {
	this.console.setURL(iri);
	this.presentViewControllerAnimated(this.console,animated); 
    },

    openObject: function(object,options) { 
	if(!object) return;
	var newWindow;
	var iri = object.url;
	var url;

	if(object.mime=='inode/directory' && object.url) {
	    url = window.location.origin+window.location.pathname+'?iri='+encodeIRI(iri);
	    newWindow = false;
	} else {
	    url = window.location.origin+'/app/preview/?iri='+encodeIRI(iri);
	    newWindow = true;
	}
	if(options && options.newWindow) newWindow = true;

	if(newWindow) {
	    // new window
	    if(object.mime=='application/octet-stream') {
		// generic file
		this.inspectObject(object);
	    } else {
		// some specific file type
		window.open(url,iri).focus();
	    }
	} else {
	    // same window
	    window.location = url;
	}
    },

    downloadURL: function(url,options) { url && this.openURL("/api/filer/download?iri="+encodeIRI(url),options); },
    downloadObject: function(object) { object && this.downloadURL(object.url); },

    inspectObject: function(object) {
	if(object) {
	    var me = this;
	    var info = object.getInfo();

	    var w = new wb.Window().setStyleName("Dialog").css({padding: 20});
	    w.css({textAlign:"center"});
	    
	    var wh = new wb.View({parent:w,HTMLtag:"section"});

	    var wi = new wb.ImageView({parent:wh}).setStyleName("Icon");
	    wi.src = info.image;
	    
	    wh.append("<h1>"+info.name+"</h1>");
	    if(info) {
		if(info.description) 
		    wh.append("<p>"+info.description+"</p>");
		if(info.version)
		    wh.append("<p><small>version "+info.version+"</small></p>");
		if(info.fs && info.fs.size) {
		    var fSize = (function(number) {
			return Math.max(0, number).toFixed(0).replace(/(?=(?:\d{3})+$)(?!^)/g, ',');
		    })(info.fs.size);
		    wh.append("<p><small>size: "+fSize+" bytes</small></p>");
		}

		if(info.url) {
		    var wa = new wb.View({parent:w,HTMLtag:"section"});
		    
		    new wb.Button({
			parent: wa,
			label:'<i class="fa fa-edit"/> Edit', 
			callback: function() {
			    console.log('EDIT', info);
			    var url = '/app/edit/?iri='+encodeIRI(info.url);
			    var win = window.open(url,info.url); win.focus();
			    /*
			      wa.clear();
			      var wv = new wb.WebView({
			      parent: wa,
			      url: "/api/filer/get?iri="+encodeURIComponent(info.url)
			      });
			    */
			}
		    });
		    
		    new wb.Button({
			parent: wa,
			label:'<i class="fa fa-cloud-download"/> Download', 
			callback: function() {
			    me.downloadURL(info.url);
			}
		    });
		}
	    }
	    this.presentModal(w);
	}
    },

    actionLogout: function() {
	wb.ajax({url:"/api/logout", 
		success: function(res,status) {
		    
		    app.actionGoHome();
		}
	       });
    },
    
    actionAbout: function() {
	print('ABOUT',this);

	this.inspectObject(this);
	return;

	// custom about box
	var w = new wb.Window().setStyleName("Dialog").css({padding: 20});
	w.css({minWidth:"320px",maxWidth:"480px",textAlign:"center",margin:"auto"});

	var wi = new wb.ImageView({parent:w}).setStyleName("Icon");
	wi.src = app.info.image;

	w.append("<h1>"+this.info.title+"</h1>");
	w.append("<h2>"+this.info.description+"</h2>");
	w.append("<h3>version "+this.info.version+"</h3>");
	this.presentModal(w);
    },

    presentViewControllerAnimated: function(viewController,animated) {
	this.navigationController.pushViewControllerAnimated(viewController,animated);
    },
});

var Dev = wb.ViewController.extend({
    init: function(options) {
	var me = this;
	this.title = "Dev";
	
	this.webView = new wb.WebView({
	    parent: this,
	    url: '/app/udev'    
	}).maximize();
	
	this.b2 = new wb.Button({
	    label:"About",
	    callback: function() {
		me.actionAbout();
	    }
	});
	
	this.navigationItem.rightItem = this.b2;
    },
    loadURL: function(url) {
	if(!url) return;
	this.webView.loadURL('/app/udev?iri='+encodeIRI(url));
	},
});



/////////////////////////////////////////////////////////////////


function init() {
    if(app) return;
    console.log("SHELL INIT");
    app = new ShellApplication();

    var splash = (window.location.hash=='#hello') || wb.urlParams.splash;

    var openConsole = (window.location.hash=='#console');

    if(splash) {
	app.setState("Minified",true);
	app.setState("Animated",true);
    }

    app.presentViewControllerAnimated(app.browser,false);
    var iri = wb.urlParams.iri || 'file:';

    if(openConsole) {
	app.openConsoleAnimated(iri,false);
    }

    app.browser.go(iri);

    if(splash) {
	setTimeout(function(){app.setState("Minified",false);},1);
    }

}

$(window).load(init);

