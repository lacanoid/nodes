var Searcher = wb.ListViewController.extend({
    init: function(options) {
	var me = this;
	var q = sessionStorage.nodexQuery||'';

	this.listView.style = "grouped";
	this.css({background:'#ddd'});
	this.title = "Search";
	this.w = new wb.TextWidget({value:q,type:"search",delegate:this})
	    .css({margin:"9px auto",width:"320px"});
	this.navigationItem.titleView = this.w;
	this.w.focus();
	this.w.input.setAttribute('name','q');

	
	var v = new wb.View();

	this.status = new wb.Label({parent:v});
	this.ai = new wb.ActivityIndicator({parent:v,title:"Searching..."});
	this.ai.hidden = true;
	this.listView.listFooterView = v;
    },

    action: function() {
	var me = this;
	var q = this.w.getValue();
	if(!q) return;
	if(!this.iri) return;
	if(q.length<2) return;

	console.log("FIND",q);
	this.q = q;

	this.listData = new wb.ResultSet({});
//	this.listData.selectSectionByTitle(null);
	this.myRelPath = [];

	if(this.query) this.query.abort();
	this.status.text = "";
	this.ai.hidden = false;
	this.more = false;
	this.query = new wb.Query({url:"/api/filer/find/",
				   data:{iri:this.iri,pid:"find0",q:q},
				   delegate:this});

	this.listView.reloadData();
    },

    didReceiveData: function(query,data) {
	var i,j,k;
	var me = this;
	var l=0;
	for(i in data) { 
	    var d = JSON.parse(data[i]);
	    if(d.stdout) l+=d.stdout.length;
	    for(k in d.stdout) {
		var info = d.stdout[k];
		if(!info.relpath) continue;
		var relpath = info.relpath.split("/");
//		relpath.pop();
		info.indent=relpath.length-1;
		for(j=0;j<relpath.length && this.myRelPath[j]==relpath[j];j++);
		for(j++;j<relpath.length;j++) {
		    var relpath1 = relpath.slice(0,j).join('/');
		    if(j>0) {
			var o = new nu.Object();
			this.listData.addObject({
			    relpath:relpath1,
			    name:relpath[j-1],
			    mime:"inode/directory",
			    icon:"icon:mime/inode/directory",
			    url:this.iri+'/'+relpath1,
			    indent:j-1
			});
//			console.log("mkdir",relpath1);
		    }
		}
		this.myRelPath=relpath;
		this.listData.addObject(info);
		this.needsRefresh = true;
	    }
	    this.more = d.more;
	}
	console.log("DATA",data.length);
    },

    queryFinished: function(query) {
	var me = this;
	console.log('DONE');
	setTimeout(function(){
	    me.listView.reloadData()
	    me.ai.hidden = true;
	    if(me.listData.numberOfSections()==0) {
		me.status.text="No results";
	    } else {
		if(me.more) {
		    me.status.text='More results not shown.';
		} else {
		    me.status.text='';
		}
	    }
	},1);
	sessionStorage.nodexQuery=this.q;
    },

    widgetValueDidChange: function(w) {
//	this.action();
    },

    viewWillAppear: function() {
//	console.log("ViewWillAppear");
	var me = this;
	var q = this.w.getValue();
	if(!q) return;
	if(!this.iri) return;
	if(q.length<2) return;

	this.listView.clear();
	this.status.text = "";
	this.ai.hidden = false;
    },

    viewDidAppear: function() {
	var me = this;
//	console.log("ViewDidAppear");
	this.w.input.focus();
	setTimeout(function(){me.action()},100);
    },

    cellForRowAtIndexPath: function(indexPath) {
	var c = new wb.ListViewCell().initWithStyle('image');
	var item = this.listData.objectForIndexPath(indexPath);
//	console.log(item);
	
	c.textLabel.text = item.name;
	c.textLabel.tooltipText = item.relpath;
	c.imageView.src = item.icon;
	c.imageView.size = {width:38,height:38};
	c.imageView.css({float:"left",margin:"2px 4px"});
	c.textLabel.css({marginLeft: "40px"});
	c.css({clear:"left"});
	c.contentView.css({marginLeft: 20*item.indent});
//	c.detailTextLabel.text = item.comment;
	return c;
    },

    didSelectCell: function(cell) {
	var item = this.listData.objectForIndexPath(cell.indexPath);
	console.log("CELL",cell.indexPath,item);
	this.delegateCall("openObject",item,{newWindow:true});
    },

});
