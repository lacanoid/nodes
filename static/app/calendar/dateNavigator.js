function DateNavigatorView(args) {
    var self = this;
    this.args = args;
//    print(args);
    this.id = args.id;
    this.parent = args.parent;
    this.delegate = args.delegate;
    this.w1 = 60;
    this.t0 = 400;
    $.extend(this, {
	tag: function(tagName) { return $('#'+this.id+(defined(tagName)?('-'+tagName):'')); },
	tags: function(tagNames) { return $(tagNames.map(function(i){return '#'+this.id+'-'+tagName}).join(', ')); },
	scrollRight: function(ev) {
	    if(defined(self.delegate) && typeof(self.delegate.willScrollLeft)=='function') {
		self.delegate.willScrollLeft(self);
	    }
	    var tag = self.tag('w1-3').data('tag');
	    if(defined(tag) && defined(self.delegate) && typeof(self.delegate.willSelectDate)=='function')
		self.delegate.willSelectDate(tag,self);
	    self.tag('sel').hide();
	    self.tag('w1-0').hide(); self.tag('w2-0').hide();
	    self.tag('w1-4').show(); self.tag('w2-2').show();
	    self.tag('w1-1').animate({'left': -self.w1}, self.t0);
	    self.tag('w1-2').animate({'left': self.p0}, self.t0);
	    self.tag('w1-3').animate({'left': self.p1}, self.t0);
	    self.tag('w2-1').animate({'left': self.p1 - self.w2, 'opacity': 0}, self.t0);
	    self.tag('w1-4').animate({'left': self.p3}, self.t0);
	    self.tag('w2-2').animate({'left': self.p2}, self.t0, function() {
		self.delegate.didSelectDate(tag,self);
//		self.init();
	    });
	},
	scrollLeft: function(ev) {
	    if(defined(self.delegate) && typeof(self.delegate.willScrollRight)=='function') {
		self.delegate.willScrollRight(self);
	    }
	    var tag = self.tag('w1-1').data('tag');
	    if(defined(tag) && defined(self.delegate) && typeof(self.delegate.willSelectDate)=='function')
		self.delegate.willSelectDate(tag,self);
	    self.tag('sel').hide();
	    self.tag('w1-4').hide(); self.tag('w2-2').hide();
	    self.tag('w1-0').show(); self.tag('w2-0').show();
	    self.tag('w1-0').animate({'left': self.p0}, self.t0);
	    self.tag('w1-1').animate({'left': self.p1}, self.t0);
	    self.tag('w2-0').animate({'left': self.p2, 'opacity': 1}, self.t0);
	    self.tag('w1-2').animate({'left': self.p3}, self.t0);
	    self.tag('w1-3').animate({'left': self.p5}, self.t0);
	    self.tag('w2-1').animate({'left': self.p4}, self.t0, function() {
		self.delegate.didSelectDate(tag,self);
//		self.init();
	    });
	},
	goLeft: function(ev) {
	    var d = self.tag().find('.selected').prev().data('tag');
//	    print('goLeft',d);
	    if(!defined(d)) self.scrollLeft(ev);
	    else self.goWithButtonToTag(d);
	},
	goRight: function(ev) {	
	    var d = self.tag().find('.selected').next().data('tag');
//	    print('goRight',d);
	    if(!defined(d)) self.scrollRight(ev);
	    else self.goWithButtonToTag(d);
	},
	goWithButtonToTag: function(tag) {
	    if(defined(self.delegate) && typeof(self.delegate.willSelectDate)=='function')
		self.delegate.willSelectDate(tag,self);
	    if(self.continuous) {
		self.setSelectedAnimated(tag, false);
		self.scrollSelectedToCenter( function() {
		    self.delegate.didSelectDate(tag,self);
		});
	    } else {
		self.setSelectedAnimated(tag, true, function() {
		    self.delegate.didSelectDate(tag,self);
		});
	    }
	},
	clickHandler: function(e) {
	    if(defined(self.delegate) && typeof(self.delegate.didSelectDate)=='function') {
		var d = $(e.target).data('tag');
		self.delegate.willSelectDate(d,self);
		if(self.continuous) {
		    // scroll selection to center
		    self.setSelectedAnimated(d, false);
		    self.scrollSelectedToCenter( function() {
			self.delegate.didSelectDate(d,self);
		    });
		} else {
		    self.setSelectedAnimated(d, true, function() {
			self.delegate.didSelectDate(d,self);
		    });
		}
	    }
	},
	scrollSelectedToCenter: function(callback) {
	    var q = self.tag().find('.selected');
	    var w = self.tag('bar').width();
	    var p = q.position();
	    if(defined(p)) {
		var left1 = (w-q.width()+2)/2-p.left-5;
		self.tag('w2-1').animate({'left': left1}, self.t0, callback);
	    }
	},
	setSelected: function(tag) {
//	    print('setSelected','#'+this.id+'-w2-1 [data-tag="'+tag+'"]');
	    self.tag().find('.selected').removeClass('selected');
	    self.tag('w2-1').find('[data-tag="'+tag+'"]').addClass('selected'); 
	},
	setSelectedAnimated: function(tag, animated, callback) {
//	    print('setSelectedAnimated',tag);
	    if(defined(tag)) { self.setSelected(tag); }
	    var q = self.tag().find('.selected');
	    if(!defined(tag)) { tag = q.data('tag'); }
	    if(defined(tag) && q.length>0) {
		var r0 = { top: q.position().top, width:q.width()+6, height:q.height()-2 };
		var r1 = { left: q.position().left-1  };
		if(animated) {
		    self.tag('sel').
			css(r0).
			animate(r1, self.t0, callback);
		} else {
		    self.tag('sel').
			css(r0).css(r1);
		    if(defined(callback)) callback();
		}
		self.tag('sel').show();
	    }
	},
	layout: function() {
	    var w = this.tag('bar').width();
	    var h = this.tag('bar').height();

	    if(this.continuous) {
		this.tag('w1-0').hide();
		this.tag('w1-1').hide();
		this.tag('w1-2').hide();
		this.tag('w1-3').hide();
		this.tag('w1-4').hide();
		this.tag('w2-0').hide();
		this.tag('w2-2').hide();
		var w1 = 62;
		this.tag('w2-1 table td').each(function(i,e) { $(e).css('min-width',w1); });
		var w2 = this.tag('w2-1 table').width();
		this.tag('w2-1').css('position','absolute').css('left',(w-w2)/2);
	    } else {
		// sections
		var w2 = w - 3*this.w1;
		this.w2 = w2;
		this.p0 = 0;
		this.p1 = this.w1;
		this.p2 = this.w1*2;
		this.p3 = this.w1*2+w2;
		this.p4 = w;
		this.p5 = w+w2;
		$('#'+this.id+'-bar > div').css('position','absolute').width(this.w1).height(h);
		this.tag('w1-0').css('left',-this.w1);
		this.tag('w1-1').css('left',this.p0).css('opacity',1).show();
		this.tag('w1-2').css('left',this.p1);
		this.tag('w2-1').css('left',this.p2).css('opacity',1).width(w2).show();
		this.tag('w2-0').css('left',this.p1-w2).width(w2).css('opacity',0);
		this.tag('w1-3').css('left',this.p3);
		this.tag('w2-2').css('left',this.p4).width(w2);
		this.tag('w1-4').css('left',this.p5);
	    }	
	    self.setSelectedAnimated(undefined,false);
	},
	create: function() {
	    var cl = ['w1-0','w1-1','w1-2','w2-1','w1-3','w2-0','w2-2','w1-4'];

	    $('#'+this.parent).append(
		'<div id="'+this.id+'" class="wb-date-navigator">' +
		'<div id="'+this.id+'-bar" class="wb-date-navigator-bar sunken rounded">' +
		    cl.map(function(i){ return '<div id="'+self.id+'-'+i+'" class="wb-DNV-'+i.substr(0,2)+'"></div>';}).
		    join('') +
		'</div>'+
		'<div id="'+this.id+'-button-left" class="wb-DNV-button wb-DNV-button-left">◀</div>'+
		'<div id="'+this.id+'-button-right" class="wb-DNV-button wb-DNV-button-right">▶</div>'+
		'</div>'
	    );

	    this.tag('button-left').click(self.goLeft);
	    this.tag('button-right').click(self.goRight);
	    this.tag('w1-1').click(self.scrollLeft);
	    this.tag('w1-2').css({cursor: 'default'});
	    this.tag('w1-3').click(self.scrollRight);
	    this.tag('w2-1').click(self.clickHandler);
	},
	init: function() {
	    if(defined(self.delegate) && typeof(self.delegate.getDateNavigatorViewSections)=='function') {
		var data = self.delegate.getDateNavigatorViewSections(self);
		if(defined(data.w1)) { this.w1=data.w1; }
		if(defined(data.sectionLabels)) {
		    this.tag('w1-0').text(data.sectionLabels[0]);
		    this.tag('w1-1').text(data.sectionLabels[1]);
		    if(defined(data.tags)) { 
			this.tag('w1-1').data('tag',data.tags[0]); 
			this.tag('w1-3').data('tag',data.tags[1]);
		    }
		    this.tag('w1-2').text(data.sectionLabels[2]);
		    this.tag('w1-3').text(data.sectionLabels[3]);
		    this.tag('w1-4').text(data.sectionLabels[4]);
		    this.continuous = false;
		} else {
		    this.continuous = true;
		}
	    }

	    var data = this.delegate.getDateNavigatorViewData(self);
	    var a=[];
	    if(defined(data.titles)) {
		for(var i=0;i<data.labels.length;i++) {
		    a.push('<td data-tag="'+data.tags[i]+'" title="'+data.titles[i]+'">'+data.labels[i]+'</td>');
		}
	    } else {
		for(var i=0;i<data.labels.length;i++) {
		    a.push('<td data-tag="'+data.tags[i]+'">'+data.labels[i]+'</td>');
		}
	    }

	    var c='<table cellspacing="0" cellpadding="0" border="0"><tr>' +
		a.join('') + 
		'</tr></table>';
	    var s='<div id="'+self.id+'-sel'+'" class="wb-DNV-box"></div>';

	    this.tag('w2-1').html(c+s);
	    if(!this.continuous) {
		this.tag('w2-0').html(c);
		this.tag('w2-2').html(c);
	    }

	    this.layout();
	},
    });

    this.create();
    this.init();
    return this;
};

function DateNavigatorController(args) {
    var self = this;
    $.extend(this, args);
    this.id = coalesce(this.id,'DNC');
    var p = coalesce(this.parent,'main');

    $.extend(this, {
	loadView: function() {
	    self.navDay   = new DateNavigatorView({delegate: self, id: this.id+'d', parent: p});
	    self.navWeek  = new DateNavigatorView({delegate: self, id: this.id+'w', parent: p});
	    self.navMonth = new DateNavigatorView({delegate: self, id: this.id+'m', parent: p});
	    $('#'+this.id+'d').addClass('day');
	    $('#'+this.id+'w').addClass('week');
	    $('#'+this.id+'m').addClass('month');
	},
	getDateNavigatorViewSections: function(dateNavigatorView) {
	    if(dateNavigatorView.id==this.id+'m') {
		var y = self.dateMonthly.getFullYear();
		return {
		    w1: 50,
		    sectionLabels: [ y-2, y-1, y, y+1, y+2 ],
		    tags: [ sprintf('%04d-12-01',y-1), sprintf('%04d-01-01',y+1) ]
		} 
	    }
	    else if(dateNavigatorView.id==this.id+'w') {
		return {
		}
	    }
	    else if(dateNavigatorView.id==this.id+'d') {
		var m =  new Date(self.dateDaily);
		var m2 = new Date(self.dateDaily);
		var mm = m2.getMonth();
		var yy = m2.getFullYear();
		m2.setDate(1); m2.addDays(-1);
		m.addMonths(-2);
		var labels = [];
		for(var i=0;i<5;i++) { labels.push(m.getMonthName().substr(0,3)); m.addMonths(1); };
		return {
		    w1: 48,
		    sectionLabels: labels, 
		    tags: [ m2.toISOString().substr(0,10), 
//			    m2.toISOString().substr(0,10), 
			    sprintf('%04d-%02d-01',yy,((mm+1)%12)+1) 
			  ],
		}
	    }
	},
	getDateNavigatorViewData: function(dateNavigatorView) {
	    if(dateNavigatorView.id==this.id+'m') {
		var a = [];
		var y = self.dateMonthly.getFullYear();
		for(var i=1;i<=12;i++) { a.push( sprintf('%04d-%02d-01',y,i) ); }
		return {
		    tags: a,
		    labels: ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
		};
	    } 
	    else if(dateNavigatorView.id==this.id+'w') {
		var n = 25;
		var a = []; var b = [];
		var d = new Date(self.dateWeekly);
		
		if(self.dateWeekly.getDay()!=1) {
		    d.moveToDayOfWeek(1,-1); // go to monday
		}
		d.addWeeks(-Math.floor(n/2));
		for(var i=0;i<n;i++) {
		    a.push( sprintf('%04d-%02d-%02d',d.getFullYear(),d.getMonth()+1,d.getDate())); 
		    var d1 = new Date(d); d1.addDays(6);
		    b.push( d.getMonthName().substr(0,3)+' '+d.getDate()+'-'+d1.getDate() );
		    d.addWeeks(1);
		}
		return {
		    tags: a,
		    labels: b
		};
	    }
	    else if(dateNavigatorView.id==this.id+'d') {
		var a = []; var b = []; var c = [];
		var y = self.dateDaily.getFullYear();
		var m = self.dateDaily.getMonth()+1;
		var days = Date.getDaysInMonth(y,m-1);
		var d,d1;
		for(var i=1;i<=days;i++) { 
		    d = sprintf('%04d-%02d-%02d',y,m,i);
		    a.push( d ); 
		    b.push( i );
		    d1 = new Date(d);
		    c.push(d1.toDateString());
		}
		return {
		    tags: a,
		    labels: b,
		    titles: c,
		}
	    }
	},
	willScrollLeft: function(dateNavigatorView) {
	    if(dateNavigatorView.id==this.id+'m') {
		self.dateMonthly=new Date(self.dateMonthly.getFullYear()+1,0,1);
	    }
	    else if(dateNavigatorView.id==this.id+'d') {
		self.dateDaily.addMonths(1);
	    }
	},
	willScrollRight: function(dateNavigatorView) {
	    if(dateNavigatorView.id==this.id+'m') {
		self.dateMonthly=new Date(self.dateMonthly.getFullYear()-1,11,1);
	    }
	    else if(dateNavigatorView.id==this.id+'d') {
		self.dateDaily.addMonths(-1);
	    }
	},
	setDate: function(d) {
//	    print('setDate',d);
	    this.dateDaily = new Date(d);
	    this.dateWeekly = new Date(d);
	    if(this.dateWeekly.getDay()!=1) {
		this.dateWeekly.moveToDayOfWeek(1,-1);
	    }
	    this.dateMonthly = new Date(d);
	    this.dateMonthly.setDate(1);
	},
	willSelectDate: function(d,dateNavigatorView) {
	    $('#theLabel').text("("+d+")");
//	    print("willSelectDate",d);
	    if(defined(self.delegate) && typeof(self.delegate.willSelectDate)=='function')
		self.delegate.willSelectDate(d,self)
	    self.setDate(d);
	},
	didSelectDate: function(d,dateNavigatorView) {
	    $('#theLabel').text(d);
//	    print("didSelectDate",d);
	    self.setDate(d);
	    if(defined(self.delegate) && typeof(self.delegate.didSelectDate)=='function')
		self.delegate.didSelectDate(d,self)
	    self.updateViews();
	},
	updateViews: function() {
//	    print('updateViews',self);
	    self.navMonth.init();
	    self.navMonth.setSelectedAnimated(this.dateMonthly.toISOString().substr(0,10), false);
	    self.navWeek.init();
	    self.navWeek.setSelectedAnimated(this.dateWeekly.toISOString().substr(0,10), false);
	    self.navDay.init();
	    self.navDay.setSelectedAnimated(this.dateDaily.toISOString().substr(0,10), false);
	},
	resize: function() {
	    self.navDay.layout();
	    self.navWeek.layout();
	    self.navMonth.layout();
	},
	setMode: function(mode) {
	    self.mode = mode;
	    $('#'+self.parent+' > div').hide();
	    $('#'+self.parent+' .'+mode).show();
	}
    });

    this.setDate(new Date());
    this.loadView();
    this.setDate(new Date());
    this.updateViews();
    $(window).resize(this.resize);
    return this;
}

// DateNavigatorView.prototype.__proto__=wb.ui.view.prototype;
// DateNavigatorViewController.prototype.__proto__=wb.ui.viewController.prototype;
