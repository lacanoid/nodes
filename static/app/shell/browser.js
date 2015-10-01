var Browser = wb.CollectionViewController.extend({
    init: function(options) {
	var me = this;

	this.title = "Browser";
	this.stack=[];

	this.collectionView.css({background: "#ddd"});
	this.collectionView.animated = true;

	/*
	  this.navigationItem.backItem = new wb.Button({
	  label:chr(11013)+" Browser",
	  callback: function() {
	  me.parentController.popViewControllerAnimated(true);
	  }
	  });
	*/

	this.zoomerView = new wb.CoverView({parent:this}).
	    css({width:96,height:96,position:"absolute",left:0,top:0});
	//	    this.zoomerView.hidden = false;

	var boxRight = new wb.Toolbar({parent:this});

	this.bAbout = new wb.Button({ parent:boxRight, label:'About', 
				      callback: function() { app.actionAbout() }
				    });
	this.b1 = new wb.Button({ parent:boxRight, label:"Logout", 
				  callback: function() { app.actionLogout(); }
				});

	this.navigationItem.rightItem = boxRight;

	var boxLeft = new wb.Toolbar({parent:this});
	/*
	  this.bBack = new wb.Button({
	  parent:boxLeft, // label:"&#9632;", 
	  label:'<i class="fa fa-arrow-left" title="Previous folder"/>',
	  callback: function() { me.goBack(); }
	  });
	*/
	this.b3 = new wb.Button({
	    parent:boxLeft, label:'<i class="fa fa-list-alt" title="Command Line Interface"> Console</i>', 
	    callback: function() { 
		app.openConsoleAnimated(me.q,true);
	    }
	});
	this.b3 = new wb.Button({
	    parent:boxLeft, label:'<i class="fa fa-search" title="Search for files"> Find</i>', 
	    callback: function() { 
		app.searcher.iri = me.q;
		app.presentViewControllerAnimated(app.searcher,true); 
	    }
	});
	/*
	  this.b3 = new wb.Button({
	  parent:boxLeft, label:"Dev", 
	  callback: function() { 
	  app.Dev.loadURL(me.q+"/index.html");
	  app.presentViewControllerAnimated(app.Dev,true); 
	  }
	  });
	*/
	this.bNew = new wb.Button({
	    //		parent:boxLeft, // label:"&#10133", 
	    parent:boxLeft, // label:"New Folder", 
	    label:'<i class="fa fa-plus" title="Create new folder"> New Folder</i>',
	    callback: function() { me.actionNewFolder(); }
	});
	/*
	  this.b4 = new wb.Button({
	  parent:boxLeft, label:"Web", 
	  callback: function() { app.presentViewControllerAnimated(app.Web,true); }
	  });
	*/
	this.navigationItem.leftItem = boxLeft;

	this.collectionView.element.addEventListener('drop', function(ev) { 
	    ev.stopPropagation();
	    ev.preventDefault();

	    var droppedText = ev.dataTransfer.getData('text/plain');
	    if(droppedText && droppedText.match(/^https?:/) && droppedText.length < 2048) {
		var url = droppedText;
		var hostname = new URI(url).hostname();
		var filename = hostname+".webloc";
		
	
		var a = {
		    url: '/api/filer/putinfo/',
		    data: {
			iri: me.q+'/'+filename,
			json: to_json({
			    URL: url
			}),
		    },
		    success:function(data) {
			console.log("R",data);
			me.reload();},
		    error:function(err) {
			me.showError("Can't create bookmark",{err:err});},
		    dataType: "json"
		};

		console.log("CREATE BOOKMARK",a);
		wb.ajax(a);
	    }

	    var files = ev.dataTransfer.files;
	    if(!(files.length && files.length)) return;

	    me.setBusyUploading(true,files.length);

	    var formData = new FormData();

	    // upload
	    formData.append('iri',me.q);
	    for(var i=0;i<files.length;i++) {
		console.log("DROP",files.item(i));
		formData.append('file',files[i]);
	    }

	    // upload
	    var xhr = new XMLHttpRequest();
	    xhr.open('POST', '/api/filer/upload/');
	    xhr.onload = function () {
		me.setBusyUploading(false);
		if (xhr.status === 200) {
		    console.log('all done: ' + xhr.status);
		} else {
		    console.log('UPLOAD ERROR',xhr);
		    me.showError("Upload error",{err:xhr});
		}
		me.reload();
	    };

	    setTimeout(
		function() {
		    xhr.send(formData);
		},10);

	    return false;
	});
    },

    viewWillAppear: function() {
	var me=this;
	console.log("ViewWillAppear");
	setTimeout(function(){me.reload();},100);
	app.setHash('#');
    },

    viewDidAppear: function() {
	console.log("ViewDidAppear");
    },

    setBusyUploading: function(b,n) {
	var cv = this.getCoverView();
	this.setBusy(b);
	var ai = new wb.ActivityIndicator({title:"Uploading"+(n?(" "+n):"...")});
	ai.hidden = true;
	setTimeout(function(){ai.$.fadeIn()}, 400);
	cv.contentView = ai;
	cv.hidden=!b;
    },

    didSelectCell: function(view) {
	var me = this;
	if(view) {
	    var p = view.$.position();
	    var f = { left:  p.left, top: p.top,
		      width: view.$.width(), height: view.$.height() };

	    me.zoomerView.animated = false;
	    me.zoomerView.hidden = true;
	    me.zoomerView.css(f);
	}
    },

    didOpenObjectInView: function(object,view) {
	var me = this;
	console.log('OPEN',object);
	var info=object.getInfo();

	if(0) {
	    //	  me.zoomerView.animated = true;
	    me.zoomerView.hidden = false;
	    me.zoomerView.css({border:"2px solid blue",background:"rgba(255,255,255,0.4)"});
	    me.collectionView.deselectAll();
	    setTimeout(function() {
		me.zoomerView.$.transit(
		    { left: 0, top: 0, width: "100%", height: "100%"},
		    100, "linear",
		    function() {
			me.delegateCall("openObject",info);
		    });
	    },1);
	} else {
	    me.delegateCall("openObject",info);
	}
    },

    goBack: function(animated) {
	var me = this;
	var t = this.stack.pop();
	if(t) {
	    if(!animated) {
		me.go(t, {noHistory:true});
	    } else {
		/*
		  me.coverView.hidden=false;
		  html2canvas(this.collectionView.element, {
		  onrendered: function(canvas) {
		  me.coverView.clear();
		  new wb.View({parent:me.coverView}).$.append(canvas);
		  
		  me.coverView.css({opacity:1});
		  me.coverView.$.animate({opacity:0},200,function() {
		  me.coverView.hidden=true;
		  });
		  me.go(t, {noHistory:true});
		  }
		  });
		*/
	    }
	} else this.reload();
    },

    showError: function(title,info) {
	this.alert(title,info);
	return;

	this.setBusy(false);
	if(!info) return;
	console.log(info);
	var title = info.statusText+" "+info.status;

	var w = new wb.Window().setStyleName("Dialog").css({padding: 20});

	w.append('<h1>'+title+'</h1>');
	
	if(info.responseText)  {
	    var wh = new wb.View({parent:w,HTMLtag:"section"}).css({textAlign:"left"}).
		html('<pre>'+info.responseText+'</pre>');
	    wh.$.find('pre').css({whiteSpace:'pre'});
	}

	this.presentModal(w);
    },

    shouldRenameObjectInObjectView: function(object,objectView,oldName,newName) {
	var me = this;
	if(me.q) {
	    var a = {
		iri: me.q+'/'+oldName,
		new_iri:me.q+'/'+newName };
	    app.log("RENAME",a);
	    me.setBusy(true);
	    $.ajax({url:'/api/filer/rename/', data:a,
		    success:function(data) {
			me.setBusy(false);
			me.reload();},
		    error:function(err) {
			objectView.cancelRenameObject();
			me.showError("Can't rename object",{err:err});},
		    dataType: "json"
		   });
	}
    },

    actionNewFolder: function() {
	var me = this;
	var newName = "New Folder";
	if(me.q) {
	    me.setBusy(true);
	    $.ajax({url:'/api/filer/mkdir/', data:{iri:me.q+'/'+newName},
		    success:function(data) {
			app.log("MKDIR",newName);
			me.setBusy(false);
			me.reload();
		    },
		    error:function(err) {
			me.showError("Can't create directory",{err:err});
		    },
		    dataType: "json"
		   });
	}
    },

    /*
      resize: function() {
      console.log("Shell resize");
      },
    */

    reload: function() {
	var me = this;
	if(me.q) {
	    me.setBusy(true);
	    me.navigationItem.title="Loading...";
	    $.ajax({url:'/api/explore/', data:{iri:me.q, hidden:''},
		    success:function(data) {
			me.setBusy(false);
			try {
			    data = JSON.parse(data);
			}
			catch(e) {
			    app.crash("Session lost!",
				      "Your session seems to have dissapeared. <br/>"+
				      "You will probably need to log in again.");
			}
			//			console.log('LS',data);
			var collectionData = new wb.ResultSet({
			    data: data,
			    sectionTitleAttribute: 'schemas'
			});
			me.collectionData = collectionData;
			me.collectionView.reloadData();
			me.q=data.iri;
			var puri = new URI(new URI(".").absoluteTo(data.iri).toString().replace(/\/$/,''));
			var url = '/app/shell/?iri='+encodeIRI(puri.toString());
			me.navigationItem.title='<a class="white" href="'+url+'">'+puri.filename()+'</a> &#10132; '+data.label;
			document.title = data.label + ' @ ' + data.hostname + ' - Filer';
		    },
		    error:function(err) {
			me.showError("Can't list directory",{err:err});
		    },
		   });
	}
    },

    go: function(q, options) {
	var me = this;
	if(!options) options={};
	if(this.q && !options.noHistory) this.stack.push(this.q);
	this.q=q;
	// this.reload();
    },
});
