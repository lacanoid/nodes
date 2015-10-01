// currently not used


    var formDef = new wb.FormDef({});
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
    
    demos.Form = wb.ListViewController.extend({
	init: function(options) {
	    var me = this;
	    this.setClass('Form');
	    this.listView.style = "grouped";
	    
	    this.navigationItem.rightItem = new wb.Button({
		label:"Finish", 
		callback: function() {
		    app.presentViewControllerAnimated(app.End,true);
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
		    var data = me.getValues();
		    me.con.setValue('<pre>'+JSON.stringify(data)+'</pre>');
		}
	    });
	    this.con = new wb.RichTextWidget({parent:v,value:'Hello'});
	    
	    new wb.Button({
		label:"Save",
		callback: function() {
		    app.presentViewControllerAnimated(app.End,true);
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
	    print('setFormDef',this);
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

//	    print('cellForRow this=',indexPath.row,attName,w,this);

	    return c;
	},
    });

    var Schemas = wb.ListViewController.extend({
	init: function(options) {
	    var me=this;
	    this.listView.style = "grouped";
	    options = options || {};
	    this.title = coalesce(options.title,"Schemas");
	    this.navigationItem.rightItem = new wb.Button({
		parent:this, 
		label:"Reload", 
		callback: function() {
		    me.reload();
		}
	    });
	    this.listView.listHeaderView = 
		new wb.Label({text:"Database ????"}).
		css({fontSize: 32, textAlign: 'center', padding: 10});
	    this.refresh();
	},

	reload: function() {
	    var me = this;
	    var bg = me.navigationItem.rightItem.$.css('background');
	    me.navigationItem.rightItem.$.css('background','red');
	    $.ajax({url:'/api/pg/proc/oordbms/get_namespaces',
		    success:function(data) {
			var listData = new wb.ResultSet({
			    data: data,
			    sectionTitleAttribute: 'schemas'
			});
			console.log(me);
			me.navigationItem.rightItem.$.css('background',bg);
			me.listData = listData;
			me.listView.reloadData();
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

