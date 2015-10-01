// version 0.9.8

var locale = {
  translation: {},
  search_path: [],
  domains: {},
  current_lang: 'C',
  current_domain: undefined,

  gettext: function(Msgid1,MsgidN,N) {
    var c = this.translation[this.current_lang];
    if(c) { // language found
      for (var i in this.search_path) { // all domains
	if(c[this.search_path[i]]) {  // if domain is defined
	  var t=c[this.search_path[i]][Msgid1];
	  if(t) { 
	    if(typeof(N)=='undefined') { // singular
	      return t;
	    }
	    // plural
	    if(typeof(t)=='object') { 
	      if(c[this.search_path[i]]._plural) {
		return t[c[this.search_path[i]]._plural(N)];
	      }
	      return t[N==1?0:1];
	    }
	    return t; 
	  }
	}
      } 
      // console.warn(['Not found',this.current_lang,this.current_domain,Msgid1,MsgidN,N]);
    } else {
      console.warn(['No translation',this.current_lang,Msgid1,MsgidN,N]);
    }
    if(typeof(N)=='undefined') { return Msgid1; }
    else { return N==1?Msgid1:MsgidN; }
  },

  add_catalog: function(lang, domain, definition) {
    if(!this.translation[lang]) { this.translation[lang]={}; }
    this.translation[lang][domain]=definition;

    if(!this.domains[domain]) {
      this.search_path.unshift(domain);
      this.domains[domain]=true;
    }

    this.current_lang=lang;
    this.current_domain=domain;
  },

  lang: function(name) {
    this.current_lang=name;
  },

  domain: function(name) {
    this.current_domain=name;
  },

};

function gettext(Msgid1,MsgidN,N) { return locale.gettext(Msgid1,MsgidN,N); }
function _(Msgid1,MsgidN,N) { return locale.gettext(Msgid1,MsgidN,N); }

String.prototype.gettext = function() {
      return locale.gettext(this);
};

locale.add_catalog('en', 'core', {}); // this is the default. no need for strings

locale.add_catalog('de', 'core', {
    'yes': 'Ja',
    'no':  'Nein',
    'loading...': 'Laden...',
    'cut': 'Ausschneiden', 
    'copy': 'Kopieren', 
    'paste': 'Einfugen',
    'more': 'Mehr'
});

locale.add_catalog('sl','core',{
  _plural: function(N) { 
		     switch(N%100) {
		     case 1: return 0;
		     case 2: return 1;
		     case 3: return 2;
		     case 4: return 2;
		     default: return 3;
		     }
		   },
		       
    'result': ['rezultat','rezultata','rezultati','rezultatov'],
    'record': ['zapis','zapisa','zapisi','zapisov'],
    'yes': 'da',
    'no':  'ne',
    'loading...': 'nalagam...',
    'undo': 'razveljavi',
    'cut': 'izreži', 
    'more': 'več',
    'copy': 'kopiraj', 
    'paste': 'prilepi',
});
