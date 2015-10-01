/* script for preview */

var app;


function init() {
  var r0 = 256;
  var pi = Math.atan(1)*4;
  var ii,phi,phi1;

  $('#c').append('<img id="bg" src="/app/clock/bg.jpg"/>');

  $('#c').append('<div id="c1" class="cc"></div>');
  $('#c').append('<div id="c3" class="cc"></div>');

  $('#c').append('<div id="hh" class="cc" style=""></div>');
  $('#c').append('<div id="hm" class="cc" style=""></div>');
  $('#c').append('<div id="hs" class="cc" style=""></div>');

  $('#hh').append('<div class="cc"></div>');
  $('#hm').append('<div class="cc"></div>');
  $('#hs').append('<div class="cc"></div>');

  var ha = ['hs','hm','hh'];
  
  for(var i=-4;i<3;i++) {
    for(var j in ha) {
      var id2='ha-'+i+ha[j];
      $('#'+ha[j]).append('<div id="'+id2+'" style="" class="cc"><div class="'+ha[j]+'"></div>');
      $('#'+id2).css({transform:'scale('+Math.pow(2,i)+')'});
    }
  }

  $('#c').append('<div id="c2" class="cc"></div>');

  for(var i=-6;i<=1;i++) {
    for(var j=0;j<12;j++) {
      for(var k=0;k<5;k++) {
        ii = ((i*12)+j)*5+k; 
        phi1 = ii/60; 
        phi = phi1*2*pi;
        phi2 = phi1*360;
        var s = Math.pow(2,phi1);
        var r = r0 * s;
        var n = j?j:12;
        var id = "n"+ii;

        var x = r * Math.sin(phi);
        var y = -r * Math.cos(phi);

        var a = 1.3;
        var ab = a*1.05;
        var b = 1.5;
        var c = k===0?1.6:1;
        var d = 1.05;

        $('#c1').append('<div id="t'+id+'" class="cc"><div class="tik"/></div>');
        $('#t'+id).css({top:y*a,left:x*a,transform:"rotate("+phi2+"deg) scale("+(c*s)+")"});

        $('#c2').append('<div id="b'+id+'" class="cc"><div class="b"/></div>');
        $('#b'+id).css({top:y*ab,left:x*ab,transform:"rotate("+(phi2-6.5)+"deg) scale("+s+")"});

        if(k===0) {
          $("#c3").append('<div id="'+id+'" class="n">'+n+'</div>');
          $('#'+id).css({top:y*d,left:x*d,transform:"scale("+(b*s)+")"});
        }
      }
    }
  }

  setInterval(function(){setClock();},50);
}

function setClock() {
  var date = new Date();
  var h = parseInt(date.getHours());
  h = h > 12 ? h-12: h;
  var m = parseInt(date.getMinutes());
  var s = parseInt(date.getSeconds())+parseInt(date.getMilliseconds())/1000;

  var second = 6*s;
  var minute =(m+s/60)*6;
  var hour = (h+m/60+s/3600)*30;
 
  var hourHand = document.getElementById("hour");
  var minuteHand = document.getElementById("minute");
  var secondHand = document.getElementById("second");
  var sh = Math.pow(2,hour/360);
  var sm = Math.pow(2,minute/360);
  var ss = Math.pow(2,second/360);


//  hourHand.setAttribute("transform","rotate("+ hour.toString() +")");
//  minuteHand.setAttribute("transform","rotate("+ minute.toString() +")");
  $('#hh').css({"transform":"rotate("+hour.toString()+"deg) scale("+sh+')'});
  $('#hm').css({"transform":"rotate("+minute.toString()+"deg) scale("+sm+')'});
  $('#hs').css({"transform":"rotate("+second.toString()+"deg) scale("+ss+')'});
}

$(window).load(init);
