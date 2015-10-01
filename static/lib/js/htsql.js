/*
  htsql parser in javascript

  (c)2011 ziga@ljudmila.org
*/

if(typeof org=='undefined') {
	org={};
}

org.htsql={
	seq: 0,
	uniq: undefined,
	render: function(layout, data, options) {
		this.seq++;
		var now = new Date;
		this.uniq = now.getTime();
		var filename='geexie.'+this.uniq;
		var fin =new os.file('TmpD',filename+'.dot');
		var fout=new os.file('TmpD',filename+'.svg');
		fin.put(data);
		os.system('/usr/bin/'+layout,["-T","svg",fin.path,'-o',fout.path]);
		var result = fout.get();
		fin.unlink(); fout.unlink();
		return result;
	},
};

org.htsql.esc=function(id) {
	var stmt;
	if(!id) return;
	if(typeof(id)=='object') {
		// parse node object
		switch(id.type) {
		case 'node':
      var defn=[];
	    for(var i in id.attr) { defn.push(this.esc(i)+'='+this.esc(id.attr[i])); }
      stmt=this.esc(id.node_id.id)+' ['+defn.join(' ')+']';
			break;
		case 'edge':
      var id1=[];
	    for(var i in id.nodes) { id1.push(this.esc(id.nodes[i].node_id.id)); }
      var defn=[];
	    for(var i in id.attr) { defn.push(this.esc(i)+'='+this.esc(id.attr[i])); }
      stmt=id1.join('--')+' ['+defn.join(' ')+']';
			break;
		}
		return stmt;
	} else
	// scalar
	if(!id.match(/^[a-zA-Z0-9_\200-\377]+$/)) {
		id=id.replace(/\n/,"\\n");
		id=id.replace(/"/,"'");
		id='"'+id+'"';
	}
	return id;
};

org.htsql.parser = function(args) {
	this.args = args;

  	this.lexize = function() {
	    while(this.htsql) {
	      if(this.htsql=~s!^('([^']|'')*')!!) 
			{ push @tok,['QL',$1]; next; } # QL = quoted literal
	      if(this.htsql=~s!^(((\d*\.)?\d+[eE][+-]?\d+)|(\d*\.\d+)|(\d+\.?))!!) { push @tok,['NL',$1]; next; } # NL = numeric literal
      if(this.htsql=~s!^((==)|(=)|(<=)|(<)|(>=)|(>)|(~~)|(~)|(\!==)|(\!=)|(\!~~)|(\!~))!!) { push @tok,['SY',$1]; next; } # SY= symbol
      if(this.htsql=~s!^((\!)|(\$)|(&)|(\|)|(->)|(\.)|(,)|(\()|(\))|(\[)|(\])|(\{)|(\}))!!) { push @tok,['SY',$1]; next; }
      if(this.htsql=~s!^((:=)|(\?)|(:)|(;)|(@)|(\^)|(/)|(\*)|(\+)|(-))!!) { push @tok,['SY',$1]; next; }
      if(this.htsql=~s!^(\w+)!!) { push @tok,['UN',$1]; next; } # UN = unquoted identifier
      if(this.htsql=~s!^("([^"]|"")*")!!) { push @tok,['QN',$1]; next; } # QN = quoted identifier

      die "Syntax error near: $htsql\n";
      return undef;
    }
  }
	r: { // common regexes used by lexer and such
		QL: /^('([^']|'')*')/,
		NL: /^(((\d*\.)?\d+[eE][+-]?\d+)|(\d*\.\d+)|(\d+\.?))/,
		SY1: /^((==)|(=)|(<=)|(<)|(>=)|(>)|(~~)|(~)|(\!==)|(\!=)|(\!~~)|(\!~))/,
		SY2: /^((\!)|(\$)|(&)|(\|)|(->)|(\.)|(,)|(\()|(\))|(\[)|(\])|(\{)|(\}))/,
		SY3: /^((:=)|(\?)|(:)|(;)|(@)|(\^)|(/)|(\*)|(\+)|(-))/,
		UN: /^(\w+)/,
		QN: /^("([^"]|"")*")/
	},
	parse: function(string) {
		this.error=null;
		this.src=string;
		this.pos=0;
		this.row=1; this.col=0;
		this.len=string.length;
		this.lexed=[];
		this.stack=[];
		this.edges={};
		this.n={graph:1};
		var v;
		// lexical split into tokens
		while(v=this.lexer()) {
			this.lexed.push(v);
		}
		// delete comments
		for(var i=this.lexed.length-1;i>=0;i--) {
			if(this.lexed[i].type=='comment') {
				this.lexed.splice(i,1);
			}
		}

		if(this.pos<this.len) {
			// if more stuff at the end...
			$('#result').append('<p class="error">Syntax error, '+
				'line '+this.row+' char '+this.pos+' near <span>'+this.src.substr(this.pos,20)+'</span></p>');
		} else {
			// everything was parsed
			this.pos=0; this.len=this.lexed.length;
			var data=this.parse_graph();
			if(!data) { data={}; }
			if(this.error) {
				this.error.range=[this.error.lex.pos,this.error.lex.pos+this.error.lex.len];
				data.errstr='<p class="error">'+this.error.str+' on '+
				'line '+this.error.lex.row+' char '+this.error.lex.pos+' near "<span>'+this.error.lex.name+'</span>"</p>';
//				$('#src').get(0).setSelectionRange(this.error.lex.pos,this.error.lex.pos+this.error.lex.len);
			}
			if(data && !data.errstr) {
				data.object={};
				this.parse_finalize(data,data.stmt);
				data.lexed=this.lexed;
				return data;
			}
		}
	},
	parse_finalize: function(top,stmt) {
		for(var i in stmt) {
			switch(stmt[i].type) {
			case 'node':
				top.object[stmt[i].node_id.id]=stmt[i];
				break;
			case 'edge':
				var ids=[];
				for(var j in stmt[i].nodes) {
					var nid=stmt[i].nodes[j].node_id.id;
					ids.push(nid);
					if(!top.object[nid]) { top.object[nid]=stmt[i]; }
				}
				var id=ids.join('--');
				if(!this.edges[id]) { this.edges[id]=1; }
				else { this.edges[id]++; }
				id=id+"-"+this.edges[id];
				top.object[id]=stmt[i];
				break;
			case 'graph':
				top.object[stmt[i].id]=stmt[i];
				this.parse_finalize(top,stmt[i].stmt);
				break;
			}
		}
	},
	parse_graph: function() {
		this.begin();
		var cons={};
		cons.type='graph';
		if(this.lex_name().toLowerCase()=='strict') { cons.strict=true; this.next(); }
		if(this.lex_name().toLowerCase().match(this.r.graph_type)) { 
			cons.graph_type=this.lex_name().toLowerCase(); this.next();
		} else {
			this.abort('Expecting "graph" or "digraph" keyword');
			return null;
		}
		cons.id=this.parse_id(); if(!cons.id) { cons.id='graph'+this.n.graph; this.n.graph++; }
		if(this.lex_name()=='{') { 
			cons.id=this.lex_name(); this.next(); 
			cons.pos_begin=this.pos_begin();
			cons.stmt = this.parse_stmt_list();
//			console.log(cons);
			if(this.lex_name()=='}') { 
				cons.pos_end=this.pos_end();
				this.end();
				return cons;
			} else {
				this.abort('Expecting "}" in parse_graph()');
				return null;
			}
		} else {
			this.abort('Expecting "{" in parse_graph()');
			return null;
		}
		this.abort('parse_graph() error');
		return null;
	},
	parse_subgraph: function() {
		var cons={};
		this.begin();
		cons.type='graph';
		cons.graph_type='subgraph';
		if(this.lex_name().toLowerCase()=='subgraph') { 
			this.next(); 
			cons.id=this.parse_id(); if(!cons.id) { cons.id='graph'+this.n.graph; this.n.graph++; }
		}
		if(this.lex_name()=='{') {
			this.next();
			cons.stmt = this.parse_stmt_list();
			if(this.lex_name()=='}') {
				this.next();
				this.end(); return cons;
			} else {
				this.abort('Expecting "}" in parse_subgraph()');
			}
		} else { this.abort(); return null; }
		this.end(); return cons;
	},
	parse_stmt_list: function() {
		this.begin();
		var stmt=this.parse_stmt();
		if(stmt) {
			while(this.lex_name()==';') { this.next(); }
			var stmt_list=this.parse_stmt_list();
			stmt_list.unshift(stmt);
			this.end();
			return stmt_list;
		} else {
			this.end();
			return [];
		}
		this.abort('parse_stmt_list() error');
		return null;
	},
	parse_stmt: function() {
		this.begin();
		var stmt={};
		stmt = this.parse_set_stmt();
		if(stmt) { this.end(); return stmt; }
		stmt = this.parse_attr_stmt();
		if(stmt) { this.end(); return stmt; }
		stmt = this.parse_subgraph();
		if(stmt) { this.end(); return stmt; }
		stmt = this.parse_edge_stmt();
		if(stmt) { this.end(); return stmt; }
		stmt = this.parse_node_stmt();
		if(stmt) { this.end(); return stmt; }
		return null;
	},
	parse_set_stmt: function() {
		var cons={};
		cons.type='set';
		cons.pos=this.lex().pos;
		this.begin();
		if(this.lex_name(1)=='=') {
			if(cons.name=this.parse_id()) {
				this.next();
				if(cons.value=this.parse_id()) {
					this.end(); return cons;
				}
			}
		}
		this.abort(); return null;
	},
	parse_edge_stmt: function() {
		var cons={};
		var node={}
		cons.type='edge'; 
		cons.pos_begin=this.lex().pos;
		node.pos=this.lex().pos;
		this.begin();
		node.subgraph = this.parse_subgraph();
		if(!node.subgraph) { 
			node.node_id = this.parse_node_id(); 
			if(!node.node_id) { this.abort(); return null; }
		}
		var cons1=this.parse_edgeRHS();
		if(!cons1) { this.abort(); return null; }
		cons1.unshift(node);
		cons.nodes = cons1;
		cons.attr=this.parse_attr_list();
		cons.pos_end=this.pos_end();
		this.end(); return cons;
	},
	parse_edgeRHS: function() {
		if(this.lex_name()=='--' || this.lex_name()=='->') {
			this.begin(); this.next();
			var cons={};
			cons.pos=this.lex().pos;
			cons.subgraph = this.parse_subgraph();
			if(!cons.subgraph) { 
				cons.node_id = this.parse_node_id(); 
				if(!cons.node_id) { this.abort('Expecting a subgraph or node_id in parse_edgeRHS()'); return null; }
			}
			var cons1=this.parse_edgeRHS();
			if(!cons1) { cons1=[]; }
			cons1.unshift(cons);
			this.end(); return cons1;
		}
		return null;
	},
	parse_node_stmt: function() {
		var cons={};
		cons.type='node'; 
		cons.pos_begin=this.lex().pos;
		this.begin();
		cons.node_id=this.parse_node_id();
		if(!cons.node_id) { this.abort(); return null; }
		cons.attr=this.parse_attr_list();
		cons.pos_end=this.pos_end();
		this.end(); return cons;
	},
	parse_node_id: function() {
		var cons={};
		this.begin();
		cons.id=this.parse_id();
		if(!cons.id) { this.abort(); return null; }
		cons.port=this.parse_port();
		cons.pos_end=this.pos_end();
		this.end(); return cons;
	},
	parse_port: function() { // FIXME: todo
		return null;
	},
	parse_attr_stmt: function() {
		var cons={};
		cons.type='attr'; 
		cons.pos=this.lex().pos;
		this.begin();
		if(this.lex_name().toLowerCase().match(this.r.attr_type)) {
			cons.attr_type=this.lex_name();
			this.next();
			cons.attr=this.parse_attr_list();
			if(cons.attr) {
				cons.pos_end=this.pos_end();
				this.end(); return cons;
			}
			this.abort('Expecting an attribute list in parse_attr_stmt()'); return null;
		}
		this.abort(); return null;
	},
	parse_attr_list: function() {
		var cons={};
		this.begin();
		if(this.lex_name()=='[') { this.next(); }
		else { this.abort(); return {}; }
		var a_list=this.parse_a_list();
		if(a_list) { for(var i in a_list) { cons[a_list[i].id1]=a_list[i].id2; } }
		if(this.lex_name()==']') { this.next(); }
		else { this.abort(); return null; }
		if(this.lex_name()=='[') {
			var cons1=this.parse_attr_list();
			for(var i in cons1) { cons[i]=cons1[i]; }
		}
		this.end(); return cons;
	},
	parse_a_list: function(expected) {
		var cons={};
		cons.id1=this.parse_id();
		if(!cons.id1) { return []; }
		this.begin();
		if(this.lex_name()=='=') {
			this.next();
			cons.id2=this.parse_id();
			if(!cons.id2) {
				this.abort('Expecting identifier name in parse_a_list()'); return null;
			}
		}
		while(this.lex_name()==',') { this.next(); }
		var cons1=this.parse_a_list();
		cons1.unshift(cons);
		this.end(); return cons1;
	},
	parse_id: function() {
		if(this.lex_type().match(/^(ident|string)$/)) { 
			var id=this.lex_name(); this.next(); 
			return id;
		}
		return null;
	},

	// parser control

	pos_begin: function() { return this.lex().pos; },
	pos_end: function() { return this.lex(-1).pos+this.lex(-1).len; },
	next: function() { if(this.pos<this.len) this.pos++; },

	begin: function(i) {
		this.stack.push({pos:this.pos});
	},
	end: function() {
		this.stack.pop();
	},
	abort: function(error) {
		if(error) {
			this.error={str:error, lex:this.lex() };
		}
		var state=this.stack.pop();
		this.pos=state.pos;
	},

	// lexer
	lex_name: function(i) { return this.lex(i).name; },
	lex_type: function(i) { return this.lex(i).type; },
	lex: function(i) {
		if(!i) {i=0;}
		if(this.pos+i<this.len) {
			return this.lexed[this.pos+i];
		}
		return {name:null, type:null};
	},

	lexer: function(string) {
		if(!this.cur()) { return null; }
		var sym={type:null,name:''};
		while(this.pos<this.len && this.cur().match(this.r.space)) {
			if(this.cur()=="\n") { this.row++; this.col=-1; }
			this.pos++; this.col++;
		}
		if(this.cur()=='"') {
			sym.pos=this.pos; sym.row=this.row; sym.len=0;
			sym.type='string';
			this.pos++; this.col++; sym.len++;
			while(this.pos<this.len && this.cur()!='"') {
				if(this.cur()=="\n") { this.row++; this.col=-1; }
				if(this.cur()=='\\') { 
					this.pos++; this.col++; 
					sym.name+=this.cur(); // FIXME: unescape '\n'-ish things in strings
					sym.len++;
				} else {
					sym.name+=this.cur(); sym.len++;
				}
				this.pos++; this.col++;
			}
			if(this.cur()=='"') { this.pos++; this.col++; sym.len++; }
		}
		else if(this.cur().match(this.r.ident)) {
			sym.pos=this.pos; sym.row=this.row; sym.len=0;
			sym.type='ident';
			while(this.pos<this.len && this.cur().match(this.r.ident)) {
				sym.name+=this.cur(); sym.len++;
				this.pos++; this.col++;
			}
		}
		else if(this.cur().match(this.r.punct1)) {
			sym.pos=this.pos; sym.row=this.row; sym.len=0;
			sym.type='punct1';
			while(this.pos<this.len && this.cur().match(this.r.punct1)) {
				sym.name+=this.cur(); sym.len++;
				this.pos++; this.col++;
			}
		}
		else if(this.cur().match(this.r.punct2)) {
			sym.pos=this.pos; sym.row=this.row; sym.len=0;
			sym.type='punct2';
			while(this.pos<this.len && this.cur().match(this.r.punct2)) {
				sym.name+=this.cur(); sym.len++;
				this.pos++; this.col++;
			}
		}
		else if(this.cur()=='#') {
			sym.pos=this.pos; sym.row=this.row; sym.len=0;
			sym.type='comment';
			while(this.pos<this.len && this.cur()!="\n") {
				sym.name+=this.cur(); sym.len++;
				this.pos++; this.col++;
			}
			if(this.cur()=="\n") { this.row++; this.col=0; this.pos++; }
			return sym.name.length>0?sym:null;
		}
		if(this.cur()) {
			while(this.pos<this.len && this.cur().match(this.r.space)) {
				if(this.cur()=="\n") { this.row++; this.col=-1; }
				this.pos++; this.col++;
			}
		}
		return sym.name.length>0?sym:null;
	}
};

