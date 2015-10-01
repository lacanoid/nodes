
var app = {};
app.edit = function() {
    var title = decodeURI(window.location.pathname).replace(/^\/|\/$/g,'');
    var a = {title:title};
    if(wb.urlParams.rev_id) a.rev_id=wb.urlParams.rev_id;
    if(title) {
	var url = '/app/edit/'+encodeURIParams(a);
//	console.log(url);
	document.location = url;
    }
};

app.go_home = function() {
    document.location = '/';
};

function init() {
    
}

$(window).load(init);