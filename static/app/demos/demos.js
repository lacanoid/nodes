var app = {};
var formDef;

app.logout = function() {
    $.ajax({url:"/api/logout", 
	    success: function(res,status) {
		app.goHome();
	    },
	   });
}
app.goHome = function() { window.location="/"; }


var demos = {};

function init() {
    demos.Form = wb.ListViewController.extend({
    init: function(options) {
	var self = this;

	var formDef = new wb.FormDef({});
	
	this.setClass('Form');
	this.listView.style = "grouped";
	
	this.navigationItem.rightItem = new wb.Button({
	    label:"Finish", 
	    callback: function() {
		app.nc.pushViewControllerAnimated(app.End,true);
	    }
	});
	this.title = "My Form";
	if(options && options.formDef) this.setFormDef(options.formDef);
	var v = new wb.View();
	this.listView.listFooterView = v;
	var t = new wb.Toolbar({parent:v});
	new wb.Button({
	    parent: t,
	    label:"Finish", 
	    callback: function() {
		var data = self.getValues();
		self.con.setValue('<pre>'+JSON.stringify(data)+'</pre>');
	    }
	});
	this.con = new wb.RichTextWidget({parent:v,value:'Hello'});
	
	new wb.Button({
	    label:"Save",
	    callback: function() {
		app.nc.pushViewControllerAnimated(app.End,true);
	    }
	});
    },
    // form delegate methods
    getValues: function() {
	var val = {};
	if(this.formDef && this.widgets) {
	    for(var i in this.formDef.attributeDef) {
		if(this.widgets[i])
		    val[i]=this.widgets[i].getValue();
	    }
	}
	return val;
    },
    setValues: function(val) {
	
    },
    // table delegate methods
    setFormDef: function(formDef) {
	this.formDef=formDef;
	this.widgets=null;
	this.listView.reloadData();
	return this;
    },
    numberOfSectionsInListView: function(listView) { 
	if(!this.formDef) return 0;
	return this.formDef.sections.length; },
    numberOfRowsInSection: function(listView,section) { 
	return this.formDef.sections[section].length; },
    titleForListViewSection: function(s) { 
	return this.formDef.sectionIndexTitlesForListView[s];
    },
    cellForRowAtIndexPath: function(indexPath) {
	var c = new wb.ListViewCell({parent:this}).
	    initWithStyle('widget');
	var cv = c.contentView;
	var attName = this.formDef.sections[indexPath.section][indexPath.row];
	var label = new wb.Label({parent:c.textLabel,text:attName});
	if(!defined(this.widgets)) this.widgets={};
	if(this.widgets[attName]) {
	    new wb.Label({HTMLclass:'error', parent:cv, text:"Duplicate name!"});
	    return c;
	}
	var adef = this.formDef.attributeDef[attName];
	
	var widgetClass=ucfirst(coalesce(adef.widgetClass,'text'))+"Widget";
	if(!wb[widgetClass]) widgetClass="TextWidget";

	var w = new wb[widgetClass]({parent:cv,value:widgetClass});  

	this.widgets[attName] = w;

	return c;
    },
});

demos.Navigation = wb.ViewController.extend({
    init: function(options) {
	this.title = "Navigation controller!";
	this.navigationItem.rightItem = new wb.Button({
	    parent:this, 
	    label:"Done!", 
	    callback: function() {
		app.nc.pushViewControllerAnimated(app.End,true);
	    }
	});

	this.b3 = new wb.Button({
	    parent:this, 
	    label:"Push again!", 
	    callback: function() {
		app.nc.pushViewControllerAnimated(app.Form,true);
	    }
	});
    }
});


demos.End = wb.ViewController.extend({
    init: function(options) {
	this.title = "The end!";
	this.l1 = new wb.Label({
	    parent: this,
	    text:"That's all folks!", 
	});
	this.l1.css({
	    marginTop: 20, fontSize: 60, fontFamily: 'fantasy',
	    textAlign: 'center' 
	});
	this.l1.centerInParent();
    }
});

demos.List = wb.ListViewController.extend({
    init: function(options) {
	var self=this;
	this.listView.style = "grouped";
	options = options || {};
	this.title = coalesce(options.title,"List view");
	this.navigationItem.rightItem = new wb.Button({
	    parent:this, 
	    label:"Reload", 
	    callback: function() {
		self.refresh();
	    }
	});
	this.listView.listFooterView = 
	    new wb.Label({text:"That's all"}).
	    css({fontSize: 32, textAlign: 'center', padding: 10});
	this.refresh();
    },

    refresh: function() {
	var self = this;
	var bg = self.navigationItem.rightItem.$.css('background');
	self.navigationItem.rightItem.$.css('background','red');
	$.ajax({url:'response.json',
		success:function(data) {
		    var listData = new wb.ResultSet({
			data: data,
			sectionTitleAttribute: 'namespace'
		    });
		    self.navigationItem.rightItem.$.css('background',bg);
		    self.listData = listData;
		    self.listView.reloadData();
		    setTimeout(function(){self.refresh()},10000);
		},
		error:function(data) {
		    console.log(data);
		},
		dataType: "json"
	       });
    },

    cellForRowAtIndexPath: function(indexPath) {
	var c = new wb.ListViewCell().initWithStyle('subtitle');
	var item = this.listData.objectForIndexPath(indexPath);
	c.textLabel.text = item.namespace;
	c.detailTextLabel.text = item.comment;
	return c;
    },
});

demos.Web = wb.ViewController.extend({
    init: function(options) {
	var self = this;
	this.title = "Wikipedia";

	this.webView = new wb.WebView({
	    parent: this,
	    url: 'ps.html'    
	}).maximize();
	//    this.webView.loadURL('http://en.wikipedia.org');

	this.b1 = new wb.Button({
	    label:"Pasta!",
	    callback: function() {
		self.title="Pasta Time!";
		self.navigationItem.rightItem = self.b2;
		self.webView.
		    loadURL('http://alteredqualia.com/three/examples/webgl_pasta.html');
	    }
	});
	
	this.b2 = new wb.Button({
	    label:"Wikipedia",
	    callback: function() {
		self.title="Wikipedia";
		self.navigationItem.rightItem = self.b1;
		self.webView.
		    loadURL('http://en.wikipedia.org');
	    }
	});

	this.navigationItem.rightItem = this.b1;
    }
});

demos.Root = wb.ViewController.extend({
    init: function(options) {
	this.setClass('Demos');
	this.title = "Demos";
	this.navigationItem.rightItem = new wb.Button({
	    label:"About", 
	    callback: function() {
		alert("WB Toolkit 0.1");
	    }
	});
	new wb.Label({id:'helloWorld',parent:this}).
	    maximize();

	var box = new wb.Toolbar({parent:this});
/*
	this.b1 = new wb.Button({
	    parent:box, 
	    label:"Logout", 
	    callback: function() {
		app.logout();
	    }
	});
*/
	this.b2 = new wb.Button({
	    parent:box, 
	    label:"Navigation", 
	    callback: function() {
		app.nc.pushViewControllerAnimated(app.Navigation,true);
	    }
	});
	this.b3 = new wb.Button({
	    parent:box, 
	    label:"List",
	    callback: function() {
		app.nc.pushViewControllerAnimated(app.List,true);
	    }
	});
	this.b4 = new wb.Button({
	    parent:box, 
	    label:"Form", 
	    callback: function() {
		app.nc.pushViewControllerAnimated(app.Form,true);
	    }
	});
	this.b4 = new wb.Button({
	    parent:box, 
	    label:"Web", 
	    callback: function() {
		app.nc.pushViewControllerAnimated(app.Web,true);
	    }
	});
	this.navigationItem.leftItem=box;
    }
});
}
function isFunction(functionToCheck) {
 var getType = {};
 return functionToCheck && getType.toString.call(functionToCheck) === '[object Function]';
}




$(window).load(function() {
    init();

    for(var i in demos) { app[i]=new demos[i](); }

    var formDef = new wb.FormDef();

    formDef.attributeDef = {
	id: { widgetClass: 'numeric'},  
	created: { widgetClass: 'date'},
	name: { widgetClass: 'text'},  
	isEnabled: { widgetClass: 'boolean'},
	isAdministrator: { widgetClass: 'boolean'},
	isBot: { widgetClass: 'boolean'},
	description: { widgetClass: 'richText'},
    };
    formDef.sections = [
	['id','created'],
	['name','description'],
	['isEnabled','isAdministrator','isBot']
    ];
    formDef.sectionIndexTitlesForListView = [
	"Metadata", "Basic Information", "Special Options"
    ];

    app.Form.setFormDef(formDef);

    var screen1 = new wb.Screen();
    app.nc = new wb.NavigationController({parent: screen1});

    app.nc.pushViewControllerAnimated(app.Root,false);

    var r = JSON.toHTML({con:console,win:window.location});
    $('#helloWorld').html(r);
});
