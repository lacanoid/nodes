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
