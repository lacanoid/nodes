// JavaScript IRI type
// v 20140918
// by ziga@ljudmila.org


function  extend (base,extra,properties,statics) {
    if(!(base && extra)) return;
    var fn = function(options) {
	if (base!==Object) base.apply(this,[options]);
	extra.init && extra.init.apply(this,[options]);
    }
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

var IRI = function(options) {}
IRI.prototype = new URL();
IRI.prototype.constructor = URL;
IRI.prototype.base = URL.prototype;
IRI.prototype.__proto__ = IRI.prototype;
