wb.cal = {};

wb.cal.model = function(args) {
    $.extend(this,{
	weekday: ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'],
	wdy: ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'],
	mon: ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'],
	month: ['January','February','March','April','May','June','July',
		'August','September','October','November','December'],
	weekdayLabel: function(d) {
            return this.weekday[d];
	},
	wdyLabel: function(d) {
            return this.wdy[d];
	},
	monLabel: function(m) {
            return this.mon[m];
	},
	monthLabel: function(m) {
            return this.month[m];
	},
	getWeekStartDate: function(day) {
            var month = day.getMonth();
            var year = day.getFullYear();
            var d = new Date(year,month,1);
            var r = new Date(d.valueOf()-((d.getDay()+6)%7)*24*60*60*1000);	
            print(r); return r;
	},
	intervalMinute: 60*1000,
	intervalHour: 60*60*1000,
	intervalDay: 24*60*60*1000,
	intervalWeek: 7*24*60*60*1000,
    });

    return this;
};

wb.cal.app = function(args) {
    var app = this;
    this.model = new wb.cal.model();

    $.extend(this,{
        profileSet: function(name,value) {
            window.localStorage[name]=value;
        },
        profileGet: function(name,defaultValue) {
            return coalesce(window.localStorage[name],defaultValue);
        },
	setTab: function(tabName) {
	    var viewName = tabName;
	    var fcViewName;

	    if(viewName == 'day') {
		viewName = 'fullcal'; 
		fcViewName = 'basicDay';
	    }
	    else if(viewName == 'week') {
		viewName = 'fullcal'; 
		fcViewName = 'basicWeek';
	    }
	    else if(viewName == 'month') { 
		viewName = 'fullcal'; 
		fcViewName = 'month';
	    }
	    $('#wb-cal-tabs .wb-ui-segment').removeClass('selected');
	    $('#wb-cal-tab-'+tabName).addClass('selected');
	    $('#main > div').hide();
	    $('#main-'+viewName).show();

            $('body').attr('data-tab',tabName);

            $('#wb-cal-navigator .wb-cal-navigator').hide();
            if(tabName=='list') $('#wb-cal-navigator-day').show()
            else $('#wb-cal-navigator-'+tabName).show();

	    if(defined(fcViewName)) this.fc.changeView(fcViewName);

            this.resize();
            this.profileSet('openTab',tabName);
	    this.dateNavigator.setMode(tabName=='list'?'day':tabName);
	    this.dateNavigator.resize();
	    $('#q').focus();
	},
        resize: function() {
            var w,wc;
            var h,hc;

            w = $(window).width();
            if(w<768) { 
		$('#alert').html('Window size too small!<br/>Please resize it bigger!'); 
		$('#wb-ui-system-coverscreen').show(); 
		return;
	    }
            else { $('#wb-ui-system-coverscreen').hide(); }

	    this.resizeMonth();
	    this.resizeWeek();
	},
	resizeMonth: function() {
            var w,wc;
            var h,hc;

	    // resize month page
            w = $('#main-month-page').width() - 60;
            wc = int(w/7);
            $('#wb-cal-timeline-month tr:first td').width(wc);

	    // resize week page
            h = $('#main-month-page').height() - 80;
            hc = int(h/this.monthWeeks);
            $('#wb-cal-timeline-month tr').each( function(i,e) {
		$('td:first',e).height(hc);
	    });
	},
	resizeWeek: function() {
            var w,wc;

            w = $('#main-week-page').width() - 120;
            wc = int(w/7);
            $('#wb-cal-timeline-week tr:first td').width(wc);
            $('#wb-cal-timeline-week-top tr:first td').width(wc);

        },
        goToDate: function(di) {
	    var d0;
	    if(typeof(di)=='string') d0 = Date.parse(di);
	    else d0 = new Date(di);

            $('#main-day-daily-day').text(d0.getDate());
	    $('#main-day-daily-fullday').html(
		this.model.weekdayLabel(d0.getDay())+', '+
		    this.model.monLabel(d0.getMonth())+' '+d0.getDate()+'<br/>'+d0.getFullYear());

	    /*
	    $('#main-week-label').text(this.model.monthLabel(d0.getMonth())+' '+d0.getFullYear());

	    if(!defined(this.d) ||
               this.d.getMonth()!=d0.getMonth() || 
               this.d.getFullYear()!=d0.getFullYear()) {
		this.rebuildMonth(d0);
		$('#main-month-label').text(this.model.monthLabel(d0.getMonth())+' '+d0.getFullYear());
            }
	    */

	    this.fc.gotoDate(d0);

	    this.d = d0;
//            print(d0);
        },
	fc: {
	    gotoDate: function(d) { app.fc.cmd('gotoDate',d); },
	    changeView: function(v) { app.fc.cmd('changeView',v); },
	    cmd: function(c,a) {
		$(app.fullCal).fullCalendar(c,a); 
	    }
	},
	didSelectDate: function(di, controller) {
	    app.goToDate(di);
	},
        goToDateAuto: function(e) {
	    if(e.currentTarget) {
                var v = $(e.currentTarget).text();
	        app.goToDate(v);
	    }
        },
        rebuildMonth: function(day) {
	    var self = this;
            self.monthWeeks = 6; // 
            var d = this.model.getWeekStartDate(day);
	    var today = new Date();
            $('#main-day-monthly').html('<table id="main-day-monthly-tab"></table>');
	    
	    $('#wb-cal-timeline-month tr').each( function(i,e) { // each week
		if(d.getMonth()>day.getMonth() ||
                   d.getFullYear()>day.getFullYear()) {
                    self.monthWeeks = i;
                    return;
                }
		var row = '';
		$('td',e).each( function(i1,e1) { // each day
		    var weekDay = '';
                    if(i==0)  { weekDay = self.model.wdyLabel(d.getDay())+' '; }
                    var todayP = 
                        d.getDate()==today.getDate() && 
                        d.getMonth()==today.getMonth() &&
                        d.getFullYear()==today.getFullYear();
                    if(todayP) {
                        $(e1).html('<div class="cal-md today"><div class="icons">Today</div>'+
				   weekDay+d.getDate()+'. '+self.model.monLabel(d.getMonth())+'.'+
				   '</div>');
                    } else {
                        $(e1).html('<div class="cal-md">'+weekDay+d.getDate()+'</div>');
                    }
		    if(d.getMonth()==today.getMonth()) {
			if(todayP) {
			    row += '<td class="today">'+d.getDate()+'</td>';
			} else {
			    row += '<td>'+d.getDate()+'</td>';
			}
		    }
                    else row += '<td></td>';
		    
		    d = new Date(d.valueOf() + self.model.intervalDay);
		});
		$('#main-day-monthly-tab').append('<tr>'+row+'</tr>');
	    });
	    $('#wb-cal-timeline-month tr').each( function(i,e) { // each week
		if(i<self.monthWeeks) $(e).show();
		else $(e).hide();
	    });
	    $('#main-day-monthly-tab td').click(this.goToDateAuto);


        },
	updateHourLine: function() {
	    var d = new Date();
	    var y = d.getHours()+d.getMinutes()/60.0;
	    var h0 = $('#wb-cal-timeline-week th:first').height()+1;
//	    print('hour-line',y);
	    $('#main-week-hour-line').css('top',y*h0);
	    setTimeout("app.updateHourLine()",60000);
	},
	searchChangedAction: function(e) {
	    if(e.type=="change" || e.keyCode==13) {
		// enter!
		var d = Date.parse($('#q').val());
		// it's a valid date!
		if(d) { app.goToDate(d); }
	    }
	},
	create: function() {
	    this.dateNavigator = new DateNavigatorController({id:"DNC",parent:"wb-cal-navigator",delegate:this});

		var date = new Date();
		var d = date.getDate();
		var m = date.getMonth();
		var y = date.getFullYear();
		
   

	    this.fullCal = $('#main-fullcal-bottom').fullCalendar({
		header: {
		    left: 'title',
		    center: false,
		    right: false
		},
		selectable: true,
		selectHelper: true,
		select: function(start, end, allDay) {
		    var title = prompt('Event Title:');
		    if (title) {
			calendar.fullCalendar('renderEvent',
					      {
						  title: title,
						  start: start,
						  end: end,
						  allDay: allDay
					      },
					      true // make the event "stick"
					     );
		    }
		    calendar.fullCalendar('unselect');
		},
		editable: true,
		events: [
		    {
			title: 'All Day Event',
			start: new Date(y, m, 1)
		    },
		    {
			title: 'Long Event',
			start: new Date(y, m, d-5),
			end: new Date(y, m, d-2)
		    },
		    {
			id: 999,
			title: 'Repeating Event',
			start: new Date(y, m, d-3, 16, 0),
			allDay: false
		    },
		    {
			id: 999,
			title: 'Repeating Event',
			start: new Date(y, m, d+4, 16, 0),
			allDay: false
		    },
		    {
			title: 'Meeting',
			start: new Date(y, m, d, 10, 30),
			allDay: false
		    },
		    {
			title: 'Lunch',
			start: new Date(y, m, d, 12, 0),
			end: new Date(y, m, d, 14, 0),
			allDay: false
		    },
		    {
			title: 'Birthday Party',
			start: new Date(y, m, d+1, 19, 0),
			end: new Date(y, m, d+1, 22, 30),
			allDay: false
		    },
		    {
			title: 'Click for Google',
			start: new Date(y, m, 28),
			end: new Date(y, m, 29),
			url: 'http://google.com/'
		    }
		]
	    }); // fullCalendar
	},
	modalShowAnimated: function(id,animated) {
	    var m = $('#'+id);
	    if(m.length>0) {
		if(animated) {
		    $('#wb-ui-modal-coverscreen').fadeIn();
		    m.fadeIn();
		} else {
		    $('#wb-ui-modal-coverscreen').show();
		    m.show();
		}
	    }
	},
	modalHideAnimated: function(id,animated) {
	    if(animated) {
		$('#wb-ui-modal-coverscreen').fadeOut();
		$('#'+id).fadeOut();
	    } else {
		$('#wb-ui-modal-coverscreen').hide();
		$('#'+id).hide();
	    }
	},
	showCreateEventForm: function() {
	    app.modalShowAnimated('wb-cal-event-form',true);
	},
    });
    
    this.create();
    this.goToDate('Today');
    this.updateHourLine();
    this.resize();
    this.setTab(this.profileGet('openTab','day'));

    $('#wb-cal-today-button').click(this.goToDateAuto);
    $('#q').keydown(this.searchChangedAction);
    $('#q').change(this.searchChangedAction);
    $(window).resize(function() { app.resize(); });

    return this;
};

