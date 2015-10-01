var LoginApplication = wb.Application.extend({
    init: function(options) {
    },

    api: function(name,args,success,error) {
	if(!name) return;
	var p={};
	p.url = "/api/"+name;
	if(args) p.data=args;
	if(success) p.success=success;
	if(error) p.error=error;
	p.dataType = "json";
	/*
	p.complete = function(x,s) {
	    console.log("COMPLETE",x,s);
	}
	*/
	$.ajax(p);
    },

    crash: function(title,msg) {
	console.log('CRASH');
	var screen = wb.getSharedScreen();

	var me = this;
	this.setParent(screen);

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
    },
});
					     
var app = new LoginApplication();
					     
app.$box=$('#loginBox');

app.showPage = function(page) {
    $('.wb-ui-form').hide();
    $('#wb-'+page).show();
}

app.block = function(doit) {
    if(doit) {
	$('input').attr('disabled','disabled');
    } else {
	$('input').removeAttr('disabled');
    }
}

app.animate = function(effect) {
    var e = this.$box;
    e.addClass('animated '+effect);
    e.one('webkitAnimationEnd mozAnimationEnd oAnimationEnd animationEnd', function() {
	e.removeClass('animated '+effect);
    });
};

app.say = function(html) { $('#wb-login-info').html(html); }
app.login = function() {
    var u = $('#username').val();
    var p = $('#password').val();
    app.block(true);
    app.say("Logging in...");
    app.api("login",
              {'username':u,'password':p},
	    function(data,status) {
		  app.block(false);
		  if(data && data.success) {
		      app.animate('fadeOutUp');
		      app.goHome();
		  } else {
		      app.say("Login failed!");
		      app.animate('wobble');
		      $('#username').focus();
		  }
	      },
	      function(data,status) {
		  app.block(false);
		  app.say("Server died?");
		  app.animate('hinge');
	      }
	    );
}
app.clear = function() {
    $('#username').val('');
    $('#password').val('');
    $('#username').focus();
}
app.goHome = function() { window.location="/app/shell/#"; }

app.enterUsername = function() {
    $('#password').focus();
}

$(window).load(function() {
    $('#wb-ui-system-coverscreen').hide();

    app.showPage('login-form');
    app.$box.show('fast');
    $('#buttonLogin').click(app.login);
    $('#buttonClear').click(app.clear);

    wb.ajax({url:'/api/hostinfo',
	     success: function(d) {
		 var host = d.hostname;
		 if(d.domainname && d.domainname!='(none)') {
//		     host += '.'+d.domainname;
		 } else {
//		     host += '.local';
		 }
		 document.title = host+' - Login';
		 $('#hostname').text(host);
		 $('#uptime').text(d.uptime);
	     }
	    });

    $('input').keydown( function(e) {
        var key = e.charCode ? e.charCode : e.keyCode ? e.keyCode : 0;
//	app.say('key='+key);
	if(key == 38) { // up
            e.preventDefault();
            var inputs = $(this).closest('form').find(':input:visible');
            inputs.eq( inputs.index(this)- 1 ).focus();
	}
        if(key == 13 || key == 40) { // enter or down
            e.preventDefault();
            var inputs = $(this).closest('form').find(':input:visible');
	    if(inputs.length==inputs.index(this)+1) {
		app.login();
	    } else {
		inputs.eq( inputs.index(this)+ 1 ).focus();
	    }
        }
    });
    $('#username').focus();
});
