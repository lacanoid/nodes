// JavaScript workbench ui toolkit
// v 20140918
// by ziga@ljudmila.org

/* perl functions */
function defined(v) { return (v !== undefined) && (v !== null); }
function ucfirst(string) { return string && (string.charAt(0).toUpperCase() + string.slice(1)); }

/* sql functions */
function coalesce() { for(var i in arguments) if(defined(arguments[i])) return arguments[i]; return undefined; }
/* custom functions */
//function nuls(s) { return s!=='' ? s : undefined; }
function nuls(s) { if(s==null) return null; return !(s.match(/^\s*$/)) ? s : undefined; }

/* BASIC functions */
function print(a) { console &&  console.log.apply(console,arguments); }
function chr(i) {  return String.fromCharCode(i); }
function debug(a) { console && console.debug.apply(console,arguments); }

function $$(id) { return document.getElementById(id); }
function int(x) { return Math.floor(x); }
function keys(a) {  var b=[];  for(var i in a) b.push(i); return b; }
function map(fun,obj) { var r=[]; for(var i in obj) { r.push(fun(obj[i])); } return r; }

/* c standard library emulation functions */
function time() { var d = new Date(); return d.getTime(); }
function rand(n) { Math.random()*coalesce(n,1.0); }

/* uri utilitys */
function encodeURIParams(params) {
    if(typeof(params)=='object') {
	return '?'+
	    (map(function(key)
		 {return(encodeURIComponent(key)+'='+encodeURIComponent(params[key]))},
		 keys(params).sort()).
	     join('&'));
    }
    return '';
}
function decodeURIParams(string) {
    var match,
        pl     = /\+/g,  // Regex for replacing addition symbol with a space
        search = /([^&=]+)=?([^&]*)/g,
        decode = function (s) { return decodeURIComponent(s.replace(pl, " ")); };

    var params = {};
    while (match = search.exec(string))
       params[decode(match[1])] = decode(match[2]);

    return params;
}
function encodeIRI(iri) {
    return encodeURIComponent(iri).replace(/%2F/g,'/','g').replace(/%3A/g,':','g');
}
/* misc useful stuff */
function to_json(object) { return JSON.stringify(object); }
function from_json(json) { try { return JSON.parse(json); } catch(e) { return null;} }
JSON.toHTML = function(json) {
  switch(typeof(json)) {
    case 'undefined':
          return '<i>undefined</i>';
          break;
    case 'function':
          return '<i>function</i>';
          break;
    case 'string':
    case 'number':
          return '<div class="input" contentEditable="true">'+json+'</div>';
          break;
    case 'object':
          var r='<details open>';
          var w0,w1;
          w0 = '{'; w1 = '}';
          if(Array.isArray(json)) { w0='['; w1=']'; }
          r += '<summary>'+w0+'</summary>';
          r += '<table>';
          for(var i in json) {
            r += '<tr>';
            r += '<th>'+i+'</th>';
            r += '<td>'+JSON.toHTML(json[i])+'</td>';
            r += '</tr>';
          }
          r += '</table>';
          r += '<div>'+w1+'</div>'
          r += '</details>';
          return r;
          break;
  }
  return '';
};

//////////////////////////////////////////////////////
// zocky's magical extend function

function  extend (base,extra,properties,statics) {
    if(!(base && extra)) return;
    var fn = function(options) {
	if (base!==Object) base.apply(this,[options]);
	extra.init && extra.init.apply(this,[options]);
    }
    fn.prototype = new base({});
    fn.prototype.constructor = base;
    fn.prototype.base = base.prototype;
    fn.prototype.__proto__ = base.prototype ;
    fn.extend = function(extra,statics) { return extend(fn,extra,statics); }
    if(statics && statics.name) fn.name = statics.name;
    for (var i in extra) fn.prototype[i]=extra[i];
    for (var i in statics) fn[i]=statics[i];
    if(Object && Object.defineProperties) {
	Object.defineProperties(fn.prototype,properties||{});
    } else {
	for (var i in properties) {
	    if(defined(properties[i].get))
		fn.prototype.__defineGetter__(i,properties[i].get);
	    if(defined(properties[i].set))
		fn.prototype.__defineSetter__(i,properties[i].set);
	}
    }
    return fn;
}

//////////////////////////////////////////////////////

window.nu = {
    args: function(me) {
	if(!me) me = {};
	var args = arguments.callee.caller.arguments;
	if(!args) return me;
	if(args) for(var i in args) {
	    for(var j in args[0]) me[j]=args[i][j];
	}
	return me;
    },
    echo: function() { console &&  console.log.apply(console,arguments); },
};

window.wb = {
    config: {
	navigationAnimationDuration: 400
    },
    getSharedScreen: function() {
	if(!this._sharedScreen)
	    this._sharedScreen = new wb.Screen();
	return this._sharedScreen;
    },
    ajax: function(args) {
	$.ajax(args);
    }
};

nu.Object = extend(Object, 
{
/*
  init: function(options) {
      var me = nu.args(this);
      if(!defined(me.id)) {
	  if(me.persistent)
	      this.id= 'noo' + this.uniqueId()
	  else
	      this.id = 'nu' + nu.Object.objId++;
      }
  },
*/
  init: function(options) {
      if(!defined(options)) options={};
      this.id = options.id;
      this.delegate = options.delegate;
      if(!defined(this.id)) {
	  if(options.persistent)
	      this.id= 'noo' + this.uniqueId()
	  else
	      this.id = 'nu' + nu.Object.objId++;
      }
  },
  delegateCall: function(procName) {
      var args = [].slice.call(arguments,1);
      this.delegate && this.delegate[procName] 
	  && typeof this.delegate[procName].apply(this.delegate,args);
  },
  extId: function(ext) { return this.id+'-'+ext; },
  uniqueId: function() {
    return
      (new Date().valueOf()-1325376000000).toString(36)+'-'+
      Number(String(Math.random()).slice(2,12)).toString(36);
  },
    print: function() { console.log(this); return this; },
  getInfo: function() {
      return coalesce(this._info,this);
  },
  updateInfo: function(data) {
      var info = this.getInfo();
      if(!info) { 
	  this.info=new nu.Object(); 
	  info=this.info;
      }
      for(var k in data) { info[k]=data[k]; }
      return this;
  },
}, 
{
  url: {
      get: function() { return coalesce(this._url,'#'+this.id); },
      set: function(url) { this._url=url; }
  },
  super: {
      get: function() { return this.__proto__; }
  }
}, 
{
  objId: 1
});

wb.View = extend(nu.Object, {
    init: function(options) {
	if(!defined(options)) options={};
	this.id = options.id;
	if(!defined(this.id)) {
	    //      this.id = 'wb' + this.uniqueId();
	    this.id = 'wb' + wb.View.viewCounter++;
	}
	this.element = document.getElementById(this.id);
	if(!this.element) {
	    this.element = document.createElement(coalesce(options.HTMLtag,"div"));
	    this.element.setAttribute('id',this.id);
//	    this.$ = jQuery(this.element);
	    this.$.data("wbView",this);
	}
	if(options.delegate) this.delegate=options.delegate;
	if(options.HTMLclass) this.$.addClass(options.HTMLclass);
	else this.setClass('View');
	if(options.css) this.css(options.css);
	if(options.html) this.html(options.html);
	if(options.parent) {
	    this.setParent(options.parent);
	}
    },
    setParent: function(parent) {
	if(!parent) { this.removeFromSuperView(); return; }
	if(parent instanceof HTMLElement)
	    // element
	    parent.appendChild(this.element);
	else
	    // wbView
	    if(parent.element instanceof HTMLElement) {
		parent.element.appendChild(this.element);
		this.parent = parent;
	    } else {
		if(parent.jquery && parent.jquery && parent.get(0)) {
		    // jQuery
		    parent.get(0).appendChild(this.element);
		}
	    }
	return this;
    },
    removeFromSuperview: function() { 
	$(this.element).remove();
    },
    setClass: function(klass) {
	this.className=klass;
	$(this.element).addClass('wb'+klass);
	return this;
    },
    addSubview: function(subview) {
	if(!subview) return this;
	if(subview instanceof HTMLElement)
	    this.element.appendChild(subview);
	else
	    this.element.appendChild(subview.element);
	return this;
    },
    clear: function() { this.html(''); return this; },
    destroy: function() { 
	this.removeFromSuperview(); 
	this.$.data('wbView',null);
//	this.$=null; 
	this.element=null; 
    },
    show: function(op) { this.$.show(op); },
    hide: function(op) { this.$.hide(op); },
    find: function(selector) {
	return this.$.find(selector).get(0);
    },
    css: function(defs) {
	this.$.css(defs);
	return this;
    },
    html: function(html) {
	if(this.contentView) {
	    this.contentView.$.html(html);
	} else {
	    this.$.html(html);
	}
	return this;
    },
    append: function(html) {
	this.$.append(html);
	return this;
    },
    maximize: function(css) {
	this.css({ position: 'absolute', left: 0, right: 0, top: 0, bottom: 0 });
	this.element.style.width=null;
	this.element.style.height=null;
	//    print('css ',this.element.getAttribute('style'));
	return this;
    },
    absolutize: function() {
	this.css({position:"absolute"});
	var f = this.frame;
	this.css(f);
	this.element.style.right=null;
	this.element.style.bottom=null;
	return this;
    },
    centerInParent: function() {
	var w = this.$.width();
	var h = this.$.height();
	this.css({
	   marginLeft: -w/2, marginTop: -h/2,
	   left: "50%", top: "50%",
	   position: "absolute"
	});
    },

    setState: function(stateName,enabled) {
	if(enabled) this.$.addClass('wbState'+stateName);
	else this.$.removeClass('wbState'+stateName);
    },
    getState: function(stateName) { return this.$.hasClass('wbState'+stateName); },
    
    setTransform: function(transform) {
	this.css({
	    '-webkit-transform': transform,
	    '-moz-transform': transform,
	    '-o-transform': transform,
	    'transform': transform,
	});
	return this;
    },

    centerInParent0: function() {
	var me=this;
	var f = me.frame;
	// print('Frame0',this.element.clientWidth);
	// FIXME
	this.css({
	    position:'absolute', 
	    top: '20%', left: '20%',
	    right: '20%', bottom: '20%'
	});
	/*
	  setTimeout(function(){
      var f = me.frame;
      print('Frame1',$('#'+me.id).width());
      me.css({marginLeft: -f.width/2,marginTop: -f.height/2});
      },2000);
	*/
	return this;
    },
    drawRect: function() {
	console.log('drawrect');
    },

    setStyleName: function(styleName) {
	if(this._styleName) { this.$.removeClass('wbStyle'+this._styleName); }
	this.$.addClass('wbStyle'+styleName);
	this._styleName=styleName;
	return this;
    },
}, 		 
{
    $: {
	get: function() { return jQuery(this.element); }
    },
    styleName: {
	get: function() { return this._styleName; },
	set: this.setStyleName
    },
    frame: {
	get: function() {
	    return {
		top: this.$.position().top, left: this.$.position().left,
		width: this.$.width(), height: this.$.height()
	    };
	}
    },
    hidden: {
	set: function(value) { 
	    if(value) this.hide(); else this.show(); 
	}
    },
    selected: {
	set: function(value) { this.setState('Selected',value); },
	get: function() { return this.getState('Selected'); }
    },
    animated: {
	set: function(value) { this.setState('Animated',value); },
	get: function() { return this.getState('Animated'); }
    },
    contentView: {
	set: function(value) { 
	    this._contentView && this._contentView.removeFromSuperview();
	    this._contentView = value;
	    value.setParent(this);
	},
	get: function() { return this._contentView; }
    },
    tooltipText: {
	set: function(b) { this.element.setAttribute('title',b); }
    }
}, 
{
  viewCounter: 0
});

wb.ImageView = wb.View.extend({
    init: function(options) {
	me = nu.args(this);
	this.setClass('ImageView');
	this.html('<img/>');
	this.$img = this.$.find('img');
	this.$img.bind('error', function(e) {
	    if(!me.inError) {
		me.inError=true;
		me.src="icon:mime/application/__DEFAULT__";
	    }
	}); 
	this.$img.bind('load', function(e) {
	    me.inError=false;
	});
   },
},
{
    src: {
	set: function(url) { 
	    if(url) {
		if(url.substr(0,5)=='icon:') url='/icon/'+url.substr(5)+'.png';
		this.$img.attr('src',url);
	    }
	}
    },
    size: {
	set: function(s) {
	    this.$img.attr('width',s.width);
	    this.$img.attr('height',s.height);
	},
	get: function(s) { return {width:this.$img.width(),height:this.$img.height()} }
    }
});

/*
wb.IconView = wb.ImageView.extend({
    init: function(options) {
	var me=this;
	this.setClass('IconView');
    }
});
*/

wb.ObjectView = wb.View.extend({
    init: function(options) {
	var me=this;
	this.setClass('ObjectView');
	this.iconView = new wb.ImageView({parent:this});
	this.label = new wb.Label({parent:this,delegate:this});

	this.label.css({wordBreak:"break-word"});

//	this.label.editable = true;
	

	$(this.label.label).
	    bind('focus', function() {
		me._oldName=me.label.text;
		me.label.selectAll();
	    }).
	    bind('blur', function(e) {
		var newName = me.label.text;
		if(newName!=me._oldName) me.shouldRenameObject();
	    }).
	    bind('keydown', function(e) {
		if(e.keyCode==13) 
		    me.label.blur();
		if(e.keyCode==27)  {
		    me.cancelRenameObject();
		    me.label.blur();
		}
	    });

	if(options) {
	    this.delegate=options.delegate;
	    this.setObject(options.object);
	}
	this.$.dblclick( function(e) { me.actionOpen(e); });
	this.element.addEventListener("touchend", function(e) {
	    if(me.selected) {
		me.actionOpen(e);
	    }
	}, false);

	this.$.bind('dragstart',function(e){
	    if(!this.draggable) { e.preventDefault(); }
	});
    },

    cancelRenameObject: function() {
	if(this._oldName) this.label.text = this._oldName;
    },

    shouldRenameObject: function() {
	var newName = this.label.text;
	if(!newName.match(/\S/)) {
	    this.cancelRenameObject();
	} else {
	    if(this.delegate && this.delegate.shouldRenameObjectInObjectView)
		this.delegate.shouldRenameObjectInObjectView
		    (this.object,this,this._oldName,newName);
	    else {
		// rename the object itself if no delegate
		if(this.object) this.object.name = newName;
	    }
	}
    },

    actionOpen: function(e) {
	this.delegate && this.delegate.didOpenObjectInView && 
	    this.delegate.didOpenObjectInView(this.object,this);
    },

    updateUI: function() {
	var info;
	if(this.object) {
	    info=this.object.getInfo();

	    if(info) {
		if(info.icon)
		    this.iconView.src=info.image;
		else if(info.image) 
		    this.iconView.src=info.image;
		else if(info.dc && info.dc.image)
		    this.iconView.src=info.dc.image;
	    }
	    else
		this.iconView.src="icon:mime/application/__DEFAULT__";

	    this.label.text = coalesce(info && info.name);
	    this.label.show();
	    this.iconView.show();
	} else {
	    this.label.text = null;
	    this.label.hide();
	    this.iconView.hide();
	}
    },
    getObject: function() { return this.object; },
    setObject: function(v) { this.object=v; this.updateUI(); }
},
{
    selected: {
	set: function(b) {
	    this.setState('Selected',b); 
	    this.label.editable = b;
	},
	get: function() { 
	    return this.getState('Selected'); 
	}
    },
}
);

wb.Widget = wb.View.extend(
{
    init: function(options) {
	this.setClass('Widget');
	if(options)
	    this.setValue(options.value);
    },
    getValue: function() { return this._value; },
    setValue: function(v) { this._value=v; }
},{
    value: {
	set: function(v) { this.setValue(v); },
	get: function() { return this.getValue(); }
    }
});

wb.SwitchWidget = wb.Widget.extend({
    init: function(options) {
	var me = nu.args(this);
	var w = '<input type="checkbox"/>';
	if(me.label) 
	    this.html('<label>'+w+me.label+'</label>');
	else
	    this.html(w);
    },
    getValue: function() { 
	var val = $("input:checked").val();
	return val; 
    },
    setValue: function(v) { 
    }

});

wb.Label = wb.View.extend({
    init: function(options) {
	this.setClass('Label');
	this.label = this.html('<label/>').find('label');
	this.text=options.text;
    },
    getValue: function() { return this.text; },
    setValue: function(v) { this.text=v; },
    setEditable: function(b) {
	var me = this;
	window.setTimeout(function(){
	    $(me.label).attr('contentEditable',
			     (b && b.toString()) || "false")}, 
	    1);
    },
    selectAll: function() { 
	var me = this;
	var w  = window;
	window.setTimeout(function() {
	    var sel, range;
	    if (w.getSelection && document.createRange) {
		range = document.createRange();
		range.selectNodeContents(me.label);
		sel = w.getSelection();
		sel.removeAllRanges();
		sel.addRange(range);
	    } else if (document.body.createTextRange) {
		range = document.body.createTextRange();
		range.moveToElementText(me.label);
		range.select();
	    }
	}, 1);
    },
    focus: function() { $(this.label).focus(); },
    blur:  function() { $(this.label).blur(); }
},
{
    text: {
	set: function(text) {
	    if(defined(text)) { this.label.innerHTML=text; }
	    else { this.label.innerHTML=''; }
	},
	get: function() { return this.label.innerHTML; }
    },
    editable: { 
	set: function(b) { this.setEditable(b); } 
    }
});

wb.TextWidget = wb.Widget.extend( {
  init: function(options) {
      var me = nu.args(this);
      this.setClass('TextWidget');

      me.updateUI();

      if(options) this.setValue(options.value);
      if(options.type)
	  $(this.input).attr({type:options.type});

      // this.nullStrings = false;
  },
  focus: function() { this.input.focus(); },
  valueDidChange: function() { },
  activate: function() { },
  updateUI: function() { 
      var me = this;
      if(!me.input) {
	  if(me._multiLine) {
	      me.input = document.createElement('textarea');
	  } else {
	      me.input = document.createElement('input');
	  }
	  $(me.input).css({width:"100%"});
	  $(me.input).change(function(e) { 
	      me.delegateCall('widgetValueDidChange', me, e); 
	  });
	  $(me.input).keydown(function(event) { me.keyDown(event) });
	  $(me.input).keypress(function(event) { me.keyPress(event) });
	  $(me.input).bind("paste", function(e) { 
	      me.delegateCall('widgetValueDidChange', me, e); 
	  });
	  me.addSubview(me.input);
      }
      if(me._multiLine) {
	  var v=$(me.input).val();
	  var rows=(v && (v.match(/\n/g)||[]).length)||1;
	  me.input.setAttribute('rows',rows+2);
      }
  },
  keyDown: function(event) {
      var me = this;
      switch(event.which) {
	  case 8: // backspace
	  case 46: // delete
	  me.delegateCall('keyPress', me, event); 
	  break;
	  case 27: // escape
	  me.delegateCall('actionCancel', me, event); 
      }
      if(this._multiLine) return;
      switch(event.which) {
	  case 38: // up
	    $.focusPrev(); break;
	  case 40: // down
	    $.focusNext(); break;
      }
  },
  keyPress: function(event) { 
      var me = this;
      this.updateUI();
      if (event.which == 13 && !me._multiLine) {
	  event.preventDefault();
	  if(me.delegate && me.delegate.action) {
	      me.delegateCall('action',me,event);
	  }
      }
      me.delegateCall('keyPress', me, event); 
  },
  getValue: function() { 
      return $(this.input).val(); 
  },
  setValue: function(value) {
      this._value = value;
      if(defined(value) && value.toString().indexOf("\n")>=0) this.multiLine=true;
      else this.multiLine=false;

      if(typeof(value)=="object" && defined(value)) {
	  $(this.input).val(JSON.stringify(value));
      } else $(this.input).val(value);
      if(this.nullStrings) { this.placeHolderText='NULL' } 
      else { this.placeHolderText='' }

      this.updateUI();
      return this;
  },
  validate: function() {
  },
},{
    placeHolderText: {
	set: function(v) { this.input && this.input.setAttribute('placeholder',v); }
    },
    multiLine: {
	get: function() { return this._multiLine; },
	set: function(v) { 
	    if(this._multiLine!=v) {
		this._multiLine = v;
		$(this.input).remove();
		this.input = null;
		this.updateUI();
	    }
	}
    },
}
);

wb.RichTextWidget = wb.TextWidget.extend( {
  init: function(options) {
    this.clear();
    this.setClass('RichTextWidget');
    this.input = new wb.View({parent:this});
    this.input.element.setAttribute('contentEditable','true');
    this.input.css({'marginLeft':2});
    if(options)
      this.setValue(options.value);
  },
  getValue: function() {
    return this.input.element.innerHTML;    
  },
  setValue: function(value) {
    if(this.input && this.input.element)
      this.input.element.innerHTML=value;
  },
});

wb.NumericWidget = wb.TextWidget.extend( {
  init: function(options) {
    this.setClass('NumericWidget');
  },
  validate: function() {
    return null;
  },
});

wb.BooleanWidget = wb.Widget.extend({
  init: function(options) {
    $(this.element).html(
      '<input type="radio" value="yes"> Yes</input>' + '&nbsp;&nbsp;' +
      '<input type="radio" value="no"> No</input>'
    );
    this.setClass('Boolean');
  },
  getValue: function() {
    return this.value;
  },
  setValue: function(value) {
//    this.base.setValue.call(this,1,2);
    if(value) {
      this.value = true;
      this.html('TRUE');
    } else {
      this.value = false;
      this.html('FALSE');
    }
  }
});

wb.Screen = wb.View.extend({
  init: function(options) {
    this.setClass('Screen');
    this.setParent(document.body);
  },
},
{},
{name:'screen'}
);

wb.Window = wb.View.extend({
  init: function(options) {
    this.setClass('Window');
  },
});

wb.Button = wb.View.extend({
    init: function(options) {
	this.setClass('Button');
	this.label = options.label;
	if(defined(options.callback))
	    $(this.element).click(options.callback);
	this.$.addClass('btn');
	this.$.mousedown(function(e){e.preventDefault();});
    },
},{
    label: {
	set: function(value) {
	    if(defined(value)) this.element.innerHTML=value;
	}
    }
}
);

wb.Toolbar = wb.View.extend({
  init: function(options) {
    this.setClass('Toolbar');
  }
});

wb.NavigationBar = wb.View.extend({
  init: function(options) {
      this.setClass('NavigationBar');
      this.box1 = new wb.View({parent:this});
      this.box1.$.addClass('title');
      this.box1.maximize();
      this.box2 = new wb.View({parent:this});
      this.box2.$.addClass('title');
      this.items=[];
      this.updateUI();
//      this.$.addClass('navbar');
  },
  updateUI: function() {
    var i = this.topItem;
    var bi = this.backItem();
    this.box1.maximize();
    if(defined(i)) {
	this.mySetupTitles(i,null);
      this.box1.css({opacity: 1});
      this.box2.hidden=true;
      this.box2.text='';
      if(defined(i.leftItem)) {
        i.leftItem.setParent(this);
        i.leftItem.hidden=false;
        i.leftItem.css({position:'absolute',left:0,opacity:1});
      } else {
        if(defined(bi)) {
          bi.setParent(this);
          bi.hidden=false;
          bi.css({position:'absolute',left:0,opacity:1});
        }
      }
      if(defined(i.rightItem)) {
        i.rightItem.setParent(this);
        i.rightItem.hidden=false;
        i.rightItem.css({position:'absolute',right:0,opacity:1});
      }
    }
  },
  pushNavigationItemAnimated: function(navigationItem,animated) {
    var pi = this.topItem;
    var pbi = this.backItem();
    this.items.push(navigationItem);
    navigationItem.navigationBar = this;
    if(animated) {
      var me = this;
      this.box1.absolutize();
      var w = this.box1.frame.width;
	this.mySetupTitles(null,navigationItem);

	// this.box2.text=navigationItem.title;
      this.box2.maximize().absolutize();
      this.box2.css({left: w});
      this.box2.hidden=false;
      this.box1.$.
      css({left: 0, opacity: 1}).
      transit(
        {left: -w/2, opacity: 0}, wb.config.navigationAnimationDuration,
        function() { me.updateUI(); }
      );
      this.box2.$.
      css({left: w/2, opacity: 0}).
      transit(
        {left: 0, opacity: 1 }, wb.config.navigationAnimationDuration
      );
      if(defined(pi)) {
        if(pi.leftItem) {
          pi.leftItem.$.css({opacity:1}).
          transit(
            {opacity:0}, wb.config.navigationAnimationDuration,
            function() { pi.leftItem.hidden=true; }
          )
        } else {
          if(pbi) {
            pbi.$.css({opacity:1}).
            transit(
              {opacity:0}, wb.config.navigationAnimationDuration,
              function() { pbi.hidden=true; }
            )
          }
        }
        if(pi.rightItem) {
          pi.rightItem.$.css({opacity:1}).
          transit(
            {opacity:0}, wb.config.navigationAnimationDuration,
            function() { pi.rightItem.hidden=true; }
          )
          
        }
      }
      if(navigationItem.leftItem) {
        navigationItem.leftItem.setParent(this);
        navigationItem.leftItem.hidden=false;
        navigationItem.leftItem.$.
        css({position:'absolute', left:(w-navigationItem.leftItem.$.width())/2, opacity:0}).
        transit(
          {left: 0, opacity: 1}, wb.config.navigationAnimationDuration
        );
      } else {
        var bi = this.backItem();
        if(defined(bi)) {
          bi.setParent(this);
          bi.hidden=false;
          bi.$.
          css({position:'absolute', left:(w-bi.$.width())/2, opacity:0}).
            transit(
            {left: 0, opacity: 1}, wb.config.navigationAnimationDuration
          );
        }
      }
      if(navigationItem.rightItem) {
        navigationItem.rightItem.setParent(this);
        navigationItem.rightItem.hidden=false;
        navigationItem.rightItem.$.
        css({position:'absolute', right:0, opacity:0}).
        transit(
          {opacity: 1}, wb.config.navigationAnimationDuration
        );
      }
    } else {
      if(defined(pi)) {
        if(pi.leftItem) { pi.leftItem.hidden=true; }
        else { if(pbi) pbi.hidden=true; }
        if(pi.rightItem) { pi.rightItem.hidden=true; }
      }
      this.updateUI();
    }
  },
    mySetupTitles: function(i1,i2) {
	if(i1) {
	    if(i1.titleView) { this.box1.clear(); i1.titleView.setParent(this.box1); } 
	    else { this.box1.html('<label>'+i1.title+'</label>'); }
	}
	if(i2) {
	    if(i2.titleView) { this.box2.clear(); i2.titleView.setParent(this.box2); } 
	    else { this.box2.html('<label>'+i2.title+'</label>'); }
	}
    },
    popNavigationItemAnimated: function(animated) {
	if(this.items.length>0) {
	    var bi=this.backItem();
	    var i=this.items.pop();
	    i.navigationBar = null;
	    var pbi=this.backItem();
	    var navigationItem = this.topItem;
	    print('animated',animated);
	    if(animated) {
		var me = this;
		this.box1.maximize().absolutize();
		this.box1.css({left: -w});
		
		this.mySetupTitles(navigationItem,i);

		var w = this.box1.frame.width;

		this.box2.maximize().absolutize();
		this.box2.hidden=false;
		this.box1.$.
		    css({left: -w/2, opacity: 0}).
		    transit(
			{left: 0, opacity: 1}, wb.config.navigationAnimationDuration,
			function() { me.updateUI(); }
		    );
		this.box2.$.
		    css({left: 0, opacity: 1}).
		    transit(
			{left: w/2, opacity: 0}, wb.config.navigationAnimationDuration
		    );
		if(defined(navigationItem)) {
		    if(navigationItem.leftItem) {
			navigationItem.leftItem.hidden=false;
			navigationItem.leftItem.$.css({opacity: 0}).
			    transit({opacity:1}, wb.config.navigationAnimationDuration);
		    } else {
			if(pbi) {
			    pbi.hidden=false;
			    pbi.$.css({opacity: 0}).
				transit({opacity:1}, wb.config.navigationAnimationDuration);
			}
		    }
		    if(navigationItem.rightItem) {
			navigationItem.rightItem.hidden=false;
			navigationItem.rightItem.$.css({opacity: 0}).
			    transit({opacity:1}, wb.config.navigationAnimationDuration);
		    }
		} 
		if(i.leftItem) { 
		    i.leftItem.$.
			css({left: 0, opacity:1}).
			transit(
			    {left: (w-i.leftItem.$.width())/2, opacity: 0}, wb.config.navigationAnimationDuration,
			    function() { i.leftItem.hidden=true; }
			);
		} else {
		    bi.$.
			css({left: 0, opacity:1}).
			transit(
			    {left: (w-bi.$.width())/2, opacity: 0}, wb.config.navigationAnimationDuration,
			    function() { bi.hidden=true; }
			);
		}
		if(i.rightItem) { 
		    i.rightItem.$.
			css({opacity:1}).
			transit(
			    {opacity: 0}, wb.config.navigationAnimationDuration,
			    function() { i.rightItem.hidden=true; }
			);
		}
	    } else {
		if(i.leftItem)  { i.leftItem.hidden=true; }
		if(i.rightItem) { i.rightItem.hidden=true; }
		this.updateUI();
	    }
	}
    },
  backItem: function() {
    if(this.items.length>1) {
      return this.items[this.items.length-2].backItem;
    }
  }
},{
  topItem:{
    get: function() {
      if(defined(this.items) && this.items.length>0) 
        return this.items[this.items.length-1];
      return null;
    }
  }
});

wb.NavigationItem = extend (Object, {
  init: function(options) {
      return;
  },
    setTitleAnimated: function(title, animated) {
      this._title=title; 
      if(this.navigationBar) this.navigationBar.updateUI();
  },
    setLeftItemAnimated: function(item, animated) {
      this._leftItem=item; 
      if(this.navigationBar) this.navigationBar.updateUI();
  },
    setRightItemAnimated: function(item, animated) {
      this._rightItem=item; 
      if(this.navigationBar) this.navigationBar.updateUI();
  },
},{
    title: {
      set: function(title) { this.setTitleAnimated(title,false); },
      get: function() { return this._title; },
  },
    leftItem: {
      set: function(item) { this.setLeftItemAnimated(item,false); },
      get: function() { return this._leftItem; },
  },
    rightItem: {
      set: function(item) { this.setRightItemAnimated(item,false); },
      get: function() { return this._rightItem; },
  }
}
			   );

wb.ViewController = wb.View.extend({
    init: function(options) {
	this.setClass('ViewController');
	this.navigationItem = new wb.NavigationItem();
	this.traitCollection = {};
    },
    
    setBusy: function(busy, animated) {
	if(busy) { 
	    var cv = this.getCoverView();
	    var ai = cv.getActivityIndicator();
	    var t0 = this.$.hasClass('wbStateBusy')?0:1500;
	    if(t0) {
		ai.hidden = true;
		cv.hidden = true; // FIXME: not hidden, but transparent
		this.$.addClass('wbStateBusy'); 
	    }
	    cv.dismissOnClick = false;
	    if(cv.timer) clearTimeout(cv.timer);
	    cv.timer=setTimeout(function(){ 
		cv.$.fadeIn() 
		cv.timer=setTimeout(function(){ ai.$.fadeIn() }, 1500);
	    }, t0);
	}
	else { 
	    var cv = this.getCoverView();
	    if(cv.timer) clearTimeout(cv.timer);
	    cv.$.fadeOut(100, function() { cv.hidden = true; });
	    this.$.removeClass('wbStateBusy'); 
	}
    },
    
    getCoverView: function() {
	if(!this._coverView)
	    this._coverView = new wb.CoverView({parent:this, delegate:this});
	return this._coverView;
    },
    
    presentModal: function(view,options) {
	var cv = this.getCoverView();
	this._modalView = view;
	cv.contentView = view;
	cv.$.fadeIn();
    },
    
    dismissModal: function(view,options) {
	this._modalView = null;
	this.getCoverView().$.fadeOut();
    },

    raiseViewController: function(viewController) {
	var i = this.viewControllers.indexOf(viewController);
	if(i>=0) {
	    var vc = this.viewControllers[i];
	    this.$.append(vc.$);
	    return viewController;
	}
	return null;
    },

    alert: function(title,details) {
	if(title && typeof(title)=="object") { details = title; title = details.message; }
	if(!details) details={};
	var err = details.err;

	console.log('ALERT',title,details);
	
	var w = new wb.Window().setStyleName("Dialog").css({padding: 20});

	if(err) {
	    var h1; 
	    h1 = err.severity || err.status;
	    w.append('<h1>'+h1+'</h1>');
	}

	if(!title) title="Alert!";
	w.append('<h2>'+title+'</h2>');
	
	if(details.message) {
	    var wh = new wb.View({parent:w,HTMLtag:"section"}).html(details.message);
	}
	if(err) {
	    if(err.responseText) {
		var wh = new wb.View({parent:w,HTMLtag:"section"}).html('<pre>'+err.responseText+'</pre>');
	    }
	    if(err.detail) {
		var wh = new wb.View({parent:w,HTMLtag:"section"}).$.text(err.detail);
	    }
	    if(err.hint) {
		var wh = new wb.View({parent:w,HTMLtag:"section"}).$.text(err.hint);
	    }
	}
	if(details.code) {
	    var wh = new wb.View({parent:w,HTMLtag:"section"}).css({textAlign:"left"}).
		html('<pre>'+details+'</pre>');
	}

	var wh = new wb.View({parent:w,HTMLtag:"section"}).css({textAlign:"center",marginTop:"2em"});
	new wb.Button({
	    parent: wh,
	    label:'Understood', 
	    callback: function() {
	    }
	});
	
	this.presentModal(w);
    },
    resize: function() {
	var me = this;
	var w = me.$.width();
	var h = me.$.width();
	if(w<=480)      me.hSizeClass='Compact';
	else if(w> 960) me.hSizeClass='Wide';
	else            me.hSizeClass='Normal';
    },
},{
    hSizeClass: {
	set: function(className) {
	    if(this._hSizeClass) { this.$.removeClass('wbHSizeClass'+this._hSizeClass); }
	    this.$.addClass('wbHSizeClass'+className);
	    this._hSizeClass=className;
	    return this;
	},
	get: function() { return this._hSizeClass }
    },
    title: {
	get: function() {
	    if(this.navigationItem) return this.navigationItem.title;
	    return null;
	},
	set: function(value) {
	    if(this.navigationItem) this.navigationItem.title=value;  
	}
    },
    parentController: { 
	get: function()  { return this._parentController; },
	set: function(v) { this._parentController=v; }
    },
    busy: { 
	set: function(v) { this.setBusy(v); }
    },
});

wb.NavigationController = wb.ViewController.extend({
  init: function(options) {
      options = nu.args();
      this.setClass('NavigationController');
      this.navigationBar = new wb.NavigationBar({parent:this});
      if(!defined(this.viewControllers)) {
	  this.viewControllers = [];
      }
      if(defined(options.rootViewController)) {
	  this.pushViewControllerAnimated(options.rootViewController,false);
      }
      this.updateUI();
  },
  updateUI: function() {
//    print('TVC',this.topViewController);
    if(this.topViewController) {
      this.topViewController.maximize().css({top: '44px'});
    }
  },
  pushViewControllerAnimated: function(viewController, animated) {
      var previousVC = this.topViewController;
      var ni = viewController.navigationItem || {};
      var me = this;
      
      this.viewControllers.push(viewController);
      
      if(!ni.backItem) {
	  ni.backItem = 
	      new wb.Button({
//		  label:chr(11013)+" "+coalesce(ni.title,this.title),
		  label:'<i class="fa fa-chevron-left"> '+coalesce(ni.title,me.title)+'</i>',
		  callback: function() {
		      me.popViewControllerAnimated(true);
		  }
	      });
      };
      
      viewController.maximize().css({top: '44px'});
      viewController.setParent(this);
      viewController.parentController=this;

      viewController.viewWillAppear && viewController.viewWillAppear();
      viewController.hidden=false;

      if(animated) {
	  var me = this;
	  viewController.absolutize();
	  var w = viewController.frame.width;
	  var af = viewController.$.transit || viewController.$.animate;
	  viewController.$.css({left: w}).
	      transit(
		  {left: 0}, wb.config.navigationAnimationDuration,
		  function() { 
		      viewController.viewDidAppear && viewController.viewDidAppear();
		      me.updateUI(); 
		  }
	      );
	  if(previousVC) {
              previousVC.$.css({left:0}).
		  transit(
		      {left: -w}, wb.config.navigationAnimationDuration,
		      function() { previousVC.hidden=true; }
		  );
	  }
      } else {
	  viewController.viewDidAppear && viewController.viewDidAppear();
	  this.updateUI();
      }
      this.navigationBar.pushNavigationItemAnimated(ni, animated);
  },
  popViewControllerAnimated: function(animated) {
      if(this.viewControllers.length>0) {
	  var previousVC = this.viewControllers.pop()
	  var viewController = this.topViewController;
	  viewController.maximize().css({top: '44px'});
	  viewController.hidden=false;
	  viewController.parentController=null;
	  viewController.viewWillAppear && viewController.viewWillAppear();
	  if(animated) {
              var me = this;
              previousVC.absolutize();
              viewController.absolutize();
              var w = viewController.frame.width;
              viewController.$.css({left: -w}).
		  transit(
		      {left: 0}, wb.config.navigationAnimationDuration,
		      function() { 
			  viewController.viewDidAppear && viewController.viewDidAppear();
			  me.updateUI(); 
		      }
		  );
              previousVC.$.css({left:0}).
		  transit(
		      {left: w}, wb.config.navigationAnimationDuration,
		      function() { previousVC.hidden=true; }
		  );
	  } else {
              previousVC.hidden=true;
	      viewController.viewDidAppear && viewController.viewDidAppear();
              this.updateUI();
	  }
      }
      this.navigationBar.popNavigationItemAnimated(animated);
  },
    showViewControllerAnimated: function(viewController, animated) {
	if(!this.raiseViewController(viewController))
	    this.pushViewControllerAnimated(viewController, animated);
    },
},{
  topViewController: { 
    get: function() {
      if(defined(this.viewControllers) && this.viewControllers.length>0) 
        return this.viewControllers[this.viewControllers.length-1];
      return null;
    },
    set: function() {
	// NOT YET
    },
  }
});

wb.TabController = wb.ViewController.extend({
     init: function(options) {
	options = nu.args();
	this.setClass('TabController');
	this.navigationBar = new wb.Toolbar({parent:this});
	if(!defined(this.viewControllers)) {
	    this.viewControllers = [];
	}
	if(defined(options.rootViewController)) {
	    this.pushViewController(options.rootViewController);
	}
	this.updateUI();
    },
    updateUI: function() {
	//    print('TVC',this.topViewController);
	if(this.topViewController) {
	    this.topViewController.maximize();
	}
    },
    pushViewController: function(viewController, options) {
	var previousVC = this.topViewController;
	var me = this;

	if(this.navigationController) {
	    this.navigationBar = this.navigationController.navigationBar;
	}
	this.viewControllers.push(viewController);
	
	viewController.maximize();
	viewController.hidden=false;
	viewController.setParent(this);
	viewController.parentController=this;
    },
    popViewController: function(options) {
	if(this.viewControllers.length>0) {
	    var previousVC = this.viewControllers.pop()
	    var viewController = this.topViewController;
	    viewController.maximize();
	    viewController.hidden=false;
	    viewController.parentController=null;
	}
    },
},{
    topViewController: { 
	get: function() {
	    if(defined(this.viewControllers) && this.viewControllers.length>0) 
		return this.viewControllers[this.viewControllers.length-1];
	    return null;
	},
    navigationController: { 
	get: function()  { return this._parentController; },
    },
  }
});

wb.SplitViewController = wb.ViewController.extend({
    init: function(options) {
	options = nu.args();
	this.setClass('SplitViewController');
	this.navigationBar = new wb.Toolbar({parent:this});
	this.viewControllers = [];
	if(defined(options.viewControllers)) {
	    this.viewControllers = options.viewControllers;
	}
	var c = this.getCoverView();
	c.$.css({display:'none'});

	this._masterO = new wb.View({parent:this});
	this._masterI = new wb.View({parent:this._masterO});
	this._grippy = new wb.View({parent:this._masterO,HTMLclass:"wbSplitViewGrip"});
	this._detail  = new wb.View({parent:this});

	var me = this;

	this._grippy.$.mousedown(function( e, dd ){
		c.css({display:'block'});
	});

	this._grippy.$.mouseup(function( e, dd ){
	    c.css({display:'none'});
	    me.updateUI();
	});

	this._masterO.css({position:"absolute",bottom:0,left:0,top:0});
	this._grippy.css({position:"absolute",bottom:0,right:0,top:0,width:"8px",cursor:"col-resize"});
	this._detail.css({position:"absolute",bottom:0,right:0,top:0});

	this.updateUI();

	this.splitPoint = options.splitPoint || '320px';
    },
    updateUI: function() {
	if(this._viewControllers) {
	}
    },
},{
    viewControllers: {
	get: function()  { return this._viewControllers; },
	set: function(v) { this._viewControllers=v; this.updateUI(); }
    },
    splitPoint: {
	set: function(v) { this._masterO.css({width:v}); 
			   this._detail.css({left:v}); 
			 }
    }
});

wb.Application = wb.ViewController.extend({
    init: function(options) {
	var me = nu.args(this);
	this.setClass('Application');
	this.maximize();
    },

    openURL: function(url,options) { if(url) window.location=url; },

    log: function() { console &&  console.log.apply(console,arguments); },


    viewURL: function(url, options) { url && this.openURL("/api/filer/download?q="+encodeURIComponent(url), options); },
    openObject: function(object,options) { object && this.openURL(object.url,options); },

    downloadURL: function(ur, optionsl) { url && this.openURL("/api/filer/download?q="+encodeURIComponent(url), options); },
    downloadObject: function(object) { object && this.downloadURL(object.url); },
    
    actionGoHome: function() { 
	this.openURL("/"); 
    },
    setIcon: function(url) {
	if(url) {
	    $('link[rel=icon]').attr('href',url);
	    $('link[rel=apple-touch-icon-precomposed]').attr('href',url);
	}
    },

    crash: function(title,msg) {
	console.log('CRASH');
	var me = this;
	var w = new wb.Window().setStyleName("Dialog").css({padding: 20});
	title=title || "Crash!";
	w.append('<h1>'+title+'</h1>');
	w.append('<div>'+msg+'</div>');
	new wb.Button({
	    parent: w,
	    label:'<i class="fa fa-refresh"/> Restart', 
	    callback: function() {
		me.openURL("/");
	    }
	}).css({padding:"10px",fontSize:"120%",marginTop:"20px"});

	this.presentModal(w);
    }
});

wb.ActivityIndicator = wb.View.extend({
  init: function(options) {
      var me = nu.args();

      if(me.title) { this.title = me.title; }

      var spinner = new wb.View({parent:this}).
	  css({width: "80%", height: 20, 
	       background: "white url(/lib/images/busy.gif)",
	       border: "2px solid white",
	       display: "inline-block",
	       borderRadius: "6px"
	      });

      this.css({
	  width: 320, height: 150, 
	  textAlign: "center", margin:"auto"
      });

/*
      this.centerInParent();

      this.css({width: 320, height: 150, 
	   marginLeft: -150, marginTop: -75,
	   left: "50%", top: "50%",
	   position: "absolute",
	   display: "inline-block",
	   textAlign: "center"
	  });
*/

  },
},{
    busy: {
	set: function(state) { 
	    if(state) {}
	} 
    },
    title: {
	set: function(v) {
	    if(!this.labelView)
		this.labelView = new wb.View({parent:this}).css({textAlign: "center", padding: 8});
	    this.labelView.html(v);
	}
    }
});

wb.ScrollView = wb.View.extend({
    init: function(options) {
	this.setClass('ScrollView');
	this.css({overflow:'auto',display:'block'}).maximize();
	
	this._tableView = new wb.View({parent:this,HTMLtag:'table'}).
	    css({width:"100%"}).
	    //	  maximize().
	    html('<tr><td></td></tr>').
	    //	    css({zIndex:1,paddingTop:'44px',paddingBottom:'44px'}).
	    //	    css({border:"1px solid pink"}).
	    css({width:"100%",height:"100%"});
	this._tableView.$.find('td').css({textAlign: "center"});
	this.contentView = new wb.View();
	this.contentView.css({textAlign: "center"});
    },
},{
    contentView: {
	set: function(value) { 
	    var td=this._tableView.find('td');
	    this._contentView && this._contentView.removeFromSuperview();
	    this._contentView = value;
	    value.setParent(td);
	},
	get: function() { return this._contentView; }
    }
});

wb.CoverView = wb.ScrollView.extend({
    init: function(options) {
	options = nu.args();
	var me=this;
	me.setClass('CoverView'); 
	me.css({overflow:'hidden',display:'block'}).maximize();
	me.dismissOnClick = false;

	me.contentView.css({textAlign: "center"});
	me.hide();

	me.$.click(function(ev) {
	    if(me.dismissOnClick)
		me.delegateCall('dismissModal');
	});
    },
    getActivityIndicator: function() {
	var me=this;
    	if(!me._activityIndicator) {
	    me._activityIndicator = 
		new wb.ActivityIndicator({parent:me, title:"Working..."});
	}
	return me._activityIndicator;
    }
},{
});

wb.TableView = wb.ScrollView.extend({
  init: function(options) {
    this.setClass('TableView');
    if(options.delegate) this.delegate=options.delegate;
    this.$.html('<table border="1"></table>');
    this.$table=$('table:first',this.element);
    this.reloadData();
  },
  reloadData: function() {
    this.$table.html('');
    if(this.delegate) {
      var sections = this.delegate.numberOfSectionsInTableView(this);
      for(var s=0;s<sections;s++) {
        var n = this.delegate.numberOfRowsInSection(this,s);
	  console.log("SECTION",s,n);
        for(var i=0;i<n;i++) {
          this.$table.append('<tr><td>'+s+' '+i+'</td></tr>');          
        }
      }
    }
  }
});

wb.TableViewController = wb.ViewController.extend({
  init: function(options) {
    this.setClass('TableViewController');
    this.updateUI();
  },
  updateUI: function() {
  },
  numberOfSectionsInTableView: function(tableView) { return 0; },
  numberOfRowsInSection: function(tableView) { return 0; },
},{
    navigationController: { 
	get: function()  { return this._parentController; },
    },
}
);

wb.IndexPath = extend(Object, {
  init: function(options) {
    if(defined(options)) { for(k in options) this[k]=options[k]; }
  }
});

wb.CollectionView = wb.ScrollView.extend({
  init: function(options) {
    this.setClass('CollectionView');
    this.headerView = new wb.View({parent:this});
    this.contentView = new wb.View({parent:this});
    this.footerView = new wb.View({parent:this});
    if(options) {
      this.collectionHeaderView = options.collectionHeaderView;
      this.collectionFooterView = options.collectionFooterView;
      this.collectionViewLayout = options.collectionViewLayout;
      if(options.delegate) {
        this.delegate=options.delegate;
        this.reloadData();
      }
    }
  },
  reloadData: function() {
    this.contentView.clear();
    if(this.delegate) {
      var indexPath=new wb.IndexPath();
      var sections = this.delegate.numberOfSectionsInCollectionView(this);
//      print('ReloadData '+sections);
      for(indexPath.section=0;indexPath.section<sections;indexPath.section++) {
        var n = this.delegate.numberOfItemsInSection(this,indexPath.section);
        var title = null;
        var sectionView = new wb.View({HTMLtag:'section',parent:this.contentView});
        var dataView = new wb.View({parent:sectionView,HTMLclass:"sectionData"});
        for(indexPath.row=0;indexPath.row<n;indexPath.row++)
          this.delegate.cellForItemAtIndexPath(indexPath).setParent(dataView);
      }
    }
  },
  setLayout: function(layout) {
      this.collectionViewLayout = layout;
      this.reloadData();
  },
  deselectAll: function() {
      this.$.find(".wbCollectionViewCell.wbStateSelected").
	  each(function(i,e) { $(e).data('wbView').selected=false; } );
  },
},
{
  collectionHeaderView: {
    set: function(view) { this.headerView.clear().addSubview(view); }
  },
  collectionFooterView: {
    set: function(view) { this.footerView.clear().addSubview(view); }
  },
}
);


wb.ListView = wb.ScrollView.extend({
    init: function(options) {
      this.setClass('ListView');
      this.headerView = new wb.View({id:this.extId('header'), parent:this.contentView});
      this.sectionsView   = new wb.View({id:this.extId('data'),   parent:this.contentView});
      this.footerView = new wb.View({id:this.extId('footer'), parent:this.contentView});
      if(options) {
	  this.listHeaderView = options.listHeaderView;
	  this.listFooterView = options.listFooterView;
	  if(options.delegate) {
              this.delegate=options.delegate;
              this.reloadData();
	  }
      }
  },
    reloadData: function() {
      this.sectionsView.clear();
      if(this.delegate) {
	  var indexPath=new wb.IndexPath();
	  var sections = this.delegate.numberOfSectionsInListView(this);
	  //      print('ReloadData '+sections);
	  for(indexPath.section=0;indexPath.section<sections;indexPath.section++) {
              var n = this.delegate.numberOfRowsInSection(this,indexPath.section);
              var title = null;
              if(this.delegate.titleForListViewSection)
		  title = this.delegate.titleForListViewSection(this,indexPath.section);
	      if(!n>0) continue;
              var sectionView = new wb.View({HTMLtag:'section',parent:this.sectionsView});
              if(defined(title))
		  new wb.Label({parent:sectionView,text:title,HTMLclass:"sectionLabel"});
              var dataView = new wb.View({parent:sectionView,HTMLclass:"sectionData"});
              for(indexPath.row=0;indexPath.row<n;indexPath.row++) {
		  var c = this.delegate.cellForRowAtIndexPath(indexPath);
		  if(c) {
		      c.indexPath = {row:indexPath.row,section:indexPath.section};
		      c.delegate = this;
		      c.setParent(dataView);
		  }
	      }
	  }
      }
    },
    html: function(h) { return this.sectionsView.html(h); }
},
{
  style: {
    set: function(style) {
      if(style=='grouped') this.$.addClass('listStyleGrouped');
      else this.$.removeClass('listStyleGrouped');
    }
  },
  listHeaderView: {
    set: function(view) { this.headerView.clear().addSubview(view); }
  },
  listFooterView: {
    set: function(view) { this.footerView.clear().addSubview(view); }
  },
}
);

wb.ListViewCell = wb.View.extend({
    init: function(options) {
	var me = nu.args(this);
	// var me=this;
	this.setClass('ListViewCell');
	this.contentView = new wb.View({HTMLclass:'contentView',parent:this});
	
	if(me.style) me.initWithStyle(me.style);
	if(me.title && me.textLabel) me.textLabel.text = me.title;
	
	this.$.mousedown(
	    function(e){
		me.selected = true;
		me.delegate && me.delegate.delegateCall('didSelectCell',me);
	    }
	);
    },
    initWithStyle: function(style) {
	this.clear();
	this.detailTextLabel = null; this.textLabel = null;
	switch(style) {
	case 'subtitle': 
	case 'leftDetail': 
	case 'rightDetail':
            this.textLabel = new wb.Label({
		parent:this.contentView, id:this.extId('text'),
		HTMLclass: "textLabel"
            });
            this.detailTextLabel = new wb.Label({
		parent:this.contentView, id:this.extId('detailText'),
		HTMLclass: "detailTextLabel"
            });
            break;
	case 'basic': 
	case 'widget': 
	case 'title':
	case 'button':
            this.textLabel = new wb.Label({
		parent:this.contentView, id:this.extId('text'),
		HTMLclass: "textLabel"
            });
	    break;
	case 'image':
	case 'object': 
            this.imageView = new wb.ImageView({
		parent:this.contentView, id:this.extId('image')
            });
            this.textLabel = new wb.Label({
		parent:this.contentView, id:this.extId('text'),
		HTMLclass: "textLabel"
            });
	break;
      case 'empty': case 'none':
      default:
    }
    this.$.addClass('wbListCellStyle'+ucfirst(style));
    return this;
  },
});

wb.WidgetListViewCell = wb.ListViewCell.extend({
    init: function(args) {
	var me = nu.args(this);
	var cv = me.contentView;
	var adef = me.adef || {};

	me.initWithStyle('widget');
	me.textLabel.text = adef.name;
	me.textLabel.tooltipText = adef.type;
	
	var widgetClass=ucfirst(coalesce(adef.widgetClass,'text'))+"Widget";
	if(!wb[widgetClass]) widgetClass="TextWidget";

	me.w = new wb[widgetClass]({parent:cv,value:widgetClass,delegate:me});  
    },
    keyPress: function(w,e) { this.changed = true; },
    widgetValueDidChange: function(w,e) { this.changed = true; },
    setValue: function(v) { this.changed=false; this.w.setValue(v); },
    getValue: function() { return this.w.getValue(); }
},{
    changed: {
	get: function() { 
	    return this._changed; 
	},
	set: function(v) { 
	    if(this._changed==v) return;
	    this._changed=v; 
	    if(this._changed) { this.$.addClass('changed'); }
	    else { this.$.removeClass('changed'); }
	    this.delegateCall('widgetValueDidChange',this);
	}
    }
}
);

wb.CollectionViewCell = wb.View.extend({
  init: function(options) {
    var me=this;
    this.setClass('CollectionViewCell');
    this.$.mousedown(
	function(e){
	    me.delegateCall('willSelectCell',me);
	    me.selected = true;
	    me.delegateCall('didSelectCell',me);
	}
    );
  },
},{
    selected: {
	set: function(value) { 
	    this.setState('Selected',value); 
	    if(this.contentView) this.contentView.selected = value;
	},
	get: function() { 
	    return this.getState('Selected'); 
	}
    },
});

wb.ListViewController = wb.ViewController.extend({
    init: function(options) {
	options=options||{};
	this.setClass('ListViewController');
	this.listView = new wb.ListView({parent: this});
	this.listView.delegate = this;
	this.updateUI();
    },
    updateUI: function() { this.listView.reloadData(); },
    numberOfSectionsInListView: function(listView) { 
	return this.listData?this.listData.numberOfSections():0;
    },
    numberOfRowsInSection: function(listView,section) {
	return this.listData?this.listData.numberOfRowsInSection(section):0;
    },
    titleForListViewSection: function(listView,section) { 
	return this.listData?this.listData.titleForSection(section):null;
    },
    cellForRowAtIndexPath: function(indexPath) {
	if(this.listData) {
	    var item = this.listData.objectForIndexPath(indexPath);
	    if(item) {
		var c = new wb.ListViewCell().initWithStyle(coalesce(item.cell_style,'subtitle'));
		c.delegate = this;
		c.textLabel.text = coalesce(item.text,'Row '+indexPath.row);
		c.detailTextLabel.text = item.detail_text;
		return c;
	    }
	}
	return null;
    },
});

wb.CollectionViewController = wb.ViewController.extend({
    init: function(options) {
	options=options||{};
	this.setClass('CollectionViewController');
	this.collectionView = new wb.CollectionView({parent: this});
	this.collectionView.delegate = this;
	this.updateUI();
    },
    updateUI: function() { this.collectionView.reloadData(); },
    numberOfSectionsInCollectionView: function(collectionView) { 
	return this.collectionData?this.collectionData.numberOfSections():0;
    },
    numberOfItemsInSection: function(collectionView,section) {
	return this.collectionData?this.collectionData.numberOfRowsInSection(section):0;
    },
    cellForItemAtIndexPath: function(indexPath) {
	if(this.collectionData) {
	    var item = this.collectionData.objectForIndexPath(indexPath);
	    if(item) {
		var c = new wb.CollectionViewCell();
		c.delegate = this;
		var cov = new wb.ObjectView({parent:c});
		c.contentView = cov;
		cov.delegate = this;
		cov.setObject(item);
		return c;
	    }
	}
	return null;
    },
    willSelectCell: function(cell) {
	this.collectionView.deselectAll();
    },
    didSelectCell: function(cell) {}
});

wb.WebView = wb.View.extend({
    init: function(options) {
	var me = this;
	this.setClass('WebView');
	this.iframe = new wb.View({parent:this,HTMLtag:"iframe"}).maximize();
	this.iframe.element.setAttribute('width','100%');
	this.iframe.element.setAttribute('height','100%');
	this.iframe.$.bind('load',function(e){me.webViewDidFinishLoad(me);});
	if(options && options.url)
	    this.loadURL(options.url);
    },
    loadURL: function(url) {
	this.iframe.element.setAttribute('src',url);
    },
    write: function(text) {
	// FIXME: change contents of iframe
	this.html(text);
    },
    webViewDidFinishLoad: function(v) {
	this.delegateCall('webViewDidFinishLoad',v);
    },
},{
});

wb.ClassDef = nu.Object.extend({
  init: function(options) {
    this.def = {};
    this.attr = [];
    if(defined(options.attr)) {
      for(var i in options.attr) this.addAttribute(i,{});
    }
    else if(defined(options.def)) {
      for(var i in options.def) this.addAttribute(i,options.def[i]);
    }
  },
  addAttribute: function(attributeName,attributeDef) {
    if(!defined(this.def[attributeName])) {
      this.attr.push(attributeName);
    }
    this.def[attributeName]=attributeDef;
    this.def[attributeName].name=attributeName;
  }
});

wb.Query = nu.Object.extend({
    init: function(args) {
	args = nu.args(this);
	var xhr = new XMLHttpRequest();
	var me = this;
	me.xhr = xhr;

	xhr.onreadystatechange = function() {
	    me.xhr_fragment(xhr,function(d) { me.delegateCall('didReceiveData',me,d); });
	};

	xhr.onloadend = function() {
	    me.xhr_fragment(xhr,function(d) {  me.delegateCall('didReceiveData',me,d); });
	    me.delegateCall('queryFinished',me);
	};

	if(me.url) { me.start(); }
    },
    start: function() {
	var url = this.url;
	if(this.data) url += encodeURIParams(this.data);
	this.xhr.open('GET',url,true);
	this.xhr.send();
    },
    abort: function() {
	this.xhr.abort();
    },
    xhr_fragment: function(xhr,cb) {
//	xhr.myData = xhr.myData || [];
	xhr.mySeq = (xhr.mySeq||0)+1;
	xhr.myFragment = (xhr.myFragment||'') + xhr.response.substr(xhr.myOffset);
	xhr.myOffset = xhr.response.length;
	var a = xhr.myFragment.split("\n");
	xhr.myFragment = a.pop();
	if(a.length>0) {
	    cb && cb(a);
//	    xhr.myData = xhr.myData.concat(a);
	}
    }
});

wb.ResultSet = nu.Object.extend({
    init: function(options) {
	this.sectionTitles = [];
	this.sectionByTitle = {};
	this.sectionData = [];
	this.currentSection = null;
	this.currentSectionTitle = null;
	if(options.data) { this.appendData(options.data); }
    },

    appendData: function(data) {
	var item;
	for(var i in data.rows) {
	    item = data.rows[i];
	    this.selectSectionByTitle(item.section_title);
	    this.addObject(item);
	}
    },
    selectSectionByTitle: function(sectionTitle) {
	if(defined(this.sectionByTitle[sectionTitle])) {
	    this.currentSection = this.sectionData[this.sectionByTitle[sectionTitle]];
	} else {
	    this.sectionData.push([]);
	    this.sectionTitles.push(sectionTitle);
	    this.sectionByTitle[sectionTitle] = this.sectionData.length-1;
	    this.selectSectionByTitle(sectionTitle);
	}
    },
    addObject: function(item) { 
	var item2;
	if(!item.prototype) item2 = new nu.Object().updateInfo(item);
	if(!this.currentSection) this.selectSectionByTitle(null);
	this.currentSection.push(item2); 
    },
    objectForIndexPath: function(indexPath) {
	return this.sectionData[indexPath.section][indexPath.row];
    },

    numberOfSections: function() { return this.sectionData.length; },
    numberOfRowsInSection: function(section) { return this.sectionData[section].length; },
    titleForSection: function(section) { return this.sectionTitles[section]; },
});

wb.ResultSkin = nu.Object.extend({}, {});

wb.FormDef = nu.Object.extend({});

/////////////////////////////////////////////////////////////////
// init

$(document).ready(function(){
    // prevent stupid system default dnd
    window.addEventListener("dragover",function(e){ e = e || event; e.preventDefault(); },false);
    window.addEventListener("drop",function(e){ e = e || event; e.preventDefault(); },false);
});

// decode URL parameters
(window.onpopstate = function () {
    wb.urlParams = decodeURIParams(window.location.search.substring(1));

    var hashQuery  = window.location.hash.substring(1);
    if(hashQuery.indexOf('=')>=0) {
	wb.hashParams = decodeURIParams(hashQuery);
	// hash constains query string
	while (match = search.exec(hashQuery))
	    wb.hashParams[decode(match[1])] = decode(match[2]);
    }
})();

// resize hook
$(window).resize(function() {
    $('.wbViewController').each(function(i,e) {
	var d = $(e).data('wbView');
	d && d.resize && d.resize();
    });
});

