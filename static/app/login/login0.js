wb.ui.widget = function(args) {
    $.extend(this,args);
    var self = this;
    
    $.extend(this, {
	val: function() {
	},
	set: function(v) {
	},
	labelString: function() {
	    return self.label;
	},
	input: function() {
	    var t = 'text';
	    return '<input type="'+t+'"></input>';
	}
    });

    return this;
}; // wb.ui.widget

wb.ui.form = function(args) {
    $.extend(this,args);
    var self = this;
    
    $.extend(this, {
	show: function() {
	},
	hide: function() {
	},
	create: function() {
	    $('#'+self.parent).append('<div id="'+self.id+'" class="wb-ui-form"></div>');
	    if(defined(self.label)) {
		$('#'+self.id).append('<h2>'+self.label+'</h2>');
	    }
	    $('#'+self.id).append('<table class="wb-ui-form-table"></table>');
	    self.formMain = $('#'+self.id+' .wb-ui-form-table');
	    if(defined(self.fields)) {
		for(var i in self.fields) {
		    var w=new wb.ui.widget(self.fields[i]);
		    self.addWidget(w);
		}
	    }
	    if(defined(self.buttons)) {
		var p = $('#'+self.id);
		p.append('<div "'+self.id+'-bb" class="wb-ui-buttonbar"></div>');
		p = $('#'+self.id+'-bb');
		for(var i in self.buttons) {
		    var b = self.buttons[i];
		    p.append('<div class="wb-ui-button">'+b.label+'</div>');
		}
	    }
	    if(defined(self.buttons2)) {
		var p = $('#'+self.id);
		p.append('<div id="'+self.id+'-bb2" class="wb-ui-buttonbar"></div>');
		p = $('#'+self.id+'-bb2');
		for(var i in self.buttons2) {
		    var b = self.buttons2[i];
		    p.append('<div class="wb-ui-button">'+b.label+'</div>');
		}
	    }
	},
	addWidget: function(w) {
	    var l = w.labelString();
	    var i = w.input();
	    self.formMain.append('<tr><th>'+l+'</th><td>'+i+'</td></tr>');
	},
    });

    self.create();
    return this;
}; // wb.ui.form


