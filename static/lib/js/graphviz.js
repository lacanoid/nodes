if(typeof org=='undefined') {
	org={};
}

org.graphviz={
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

org.graphviz.attr=[
	// Object
	  {"type":"separator"},
    {"name":"id","used_by":"GNE","type":"lblString","default":"\"\"","minimum":"","notes":"svg, postscript, map only"},
    {"name":"label","used_by":"ENGC","type":"lblString","default":"\"\\N\" (nodes)\"\" (otherwise)","minimum":"","notes":""},
    {"name":"tooltip","used_by":"NEC","type":"escString","default":"\"\"","minimum":"","notes":"svg, cmap only"},
    {"name":"target","used_by":"ENGC","type":"escStringstring","default":"<none>","minimum":"","notes":"svg, map only"},
    {"name":"comment","used_by":"ENG","type":"string","default":"\"\"","minimum":"","notes":""},
    {"name":"layer","used_by":"EN","type":"layerRange","default":"\"\"","minimum":"","notes":""},
    {"name":"layers","used_by":"G","type":"layerList","default":"\"\"","minimum":"","notes":""},

	// Appearance
	  {"type":"separator"},
    {"name":"aspect","used_by":"G","type":"aspectType","default":"","minimum":"","notes":"dot only"},
    {"name":"fontnames","used_by":"G","type":"string","default":"\"\"","minimum":"","notes":"svg only"},
    {"name":"fontpath","used_by":"G","type":"string","default":"system-dependent","minimum":"","notes":""},
    {"name":"dpi","used_by":"G","type":"double","default":"96.00.0","minimum":"","notes":"svg, bitmap output only"},

	  {"type":"separator"},
    {"name":"color","used_by":"ENC","type":"colorcolorList","default":"black","minimum":"","notes":""},
    {"name":"fillcolor","used_by":"NC","type":"color","default":"lightgrey(nodes)black(clusters)","minimum":"","notes":""},
    {"name":"bgcolor","used_by":"GC","type":"color","default":"<none>","minimum":"","notes":""},
    {"name":"colorscheme","used_by":"ENCG","type":"string","default":"\"\"","minimum":"","notes":""},

	  {"type":"separator"},
    {"name":"shape","used_by":"N","type":"shape","default":"ellipse","minimum":"","notes":""},
    {"name":"shapefile","used_by":"N","type":"string","default":"\"\"","minimum":"","notes":""},

	  {"type":"separator"},
    {"name":"arrowhead","used_by":"E","type":"arrowType","default":"normal","minimum":"","notes":""},
    {"name":"arrowtail","used_by":"E","type":"arrowType","default":"normal","minimum":"","notes":""},
    {"name":"arrowsize","used_by":"E","type":"double","default":"1.0","minimum":"0.0","notes":""},

	  {"type":"separator"},
    {"name":"fontname","used_by":"ENGC","type":"string","default":"\"Times-Roman\"","minimum":"","notes":""},
    {"name":"fontsize","used_by":"ENGC","type":"double","default":"14.0","minimum":"1.0","notes":""},
    {"name":"fontcolor","used_by":"ENGC","type":"color","default":"black","minimum":"","notes":""},

	  {"type":"separator"},
    {"name":"headURL","used_by":"E","type":"escString","default":"\"\"","minimum":"","notes":"svg, map only"},
    {"name":"headclip","used_by":"E","type":"bool","default":"true","minimum":"","notes":""},
    {"name":"headhref","used_by":"E","type":"escString","default":"\"\"","minimum":"","notes":"svg, map only"},
    {"name":"headlabel","used_by":"E","type":"lblString","default":"\"\"","minimum":"","notes":""},
    {"name":"headport","used_by":"E","type":"portPos","default":"center","minimum":"","notes":""},
    {"name":"headtarget","used_by":"E","type":"escString","default":"<none>","minimum":"","notes":"svg, map only"},
    {"name":"headtooltip","used_by":"E","type":"escString","default":"\"\"","minimum":"","notes":"svg, cmap only"},

	  {"type":"separator"},
    {"name":"tailURL","used_by":"E","type":"escString","default":"\"\"","minimum":"","notes":"svg, map only"},
    {"name":"tailclip","used_by":"E","type":"bool","default":"true","minimum":"","notes":""},
    {"name":"tailhref","used_by":"E","type":"escString","default":"\"\"","minimum":"","notes":"svg, map only"},
    {"name":"taillabel","used_by":"E","type":"lblString","default":"\"\"","minimum":"","notes":""},
    {"name":"tailport","used_by":"E","type":"portPos","default":"center","minimum":"","notes":""},
    {"name":"tailtarget","used_by":"E","type":"escString","default":"<none>","minimum":"","notes":"svg, map only"},
    {"name":"tailtooltip","used_by":"E","type":"escString","default":"\"\"","minimum":"","notes":"svg, cmap only"},

	// Position
	  {"type":"separator"},
		{"name":"pin","used_by":"N","type":"bool","default":"false","minimum":"","notes":"fdp, neato only"},
    {"name":"pos","used_by":"EN","type":"pointsplineType","default":"","minimum":"","notes":""},

	  {"type":"separator"},
    {"name":"width","used_by":"N","type":"double","default":"0.75","minimum":"0.01","notes":""},
    {"name":"height","used_by":"N","type":"double","default":"0.5","minimum":"0.02","notes":""},

	  {"type":"separator"},
    {"name":"bb","used_by":"G","type":"rect","default":"","minimum":"","notes":"write only"},
    {"name":"center","used_by":"G","type":"bool","default":"false","minimum":"","notes":""},
    {"name":"concentrate","used_by":"G","type":"bool","default":"false","minimum":"","notes":""},
    {"name":"compound","used_by":"G","type":"bool","default":"false","minimum":"","notes":"dot only"},
    {"name":"clusterrank","used_by":"G","type":"clusterMode","default":"local","minimum":"","notes":"dot only"},
    {"name":"maxiter","used_by":"G","type":"int","default":"100 * # nodes(mode == KK)200(mode == major)600(fdp)","minimum":"","notes":"fdp, neato only"},
    {"name":"mclimit","used_by":"G","type":"double","default":"1.0","minimum":"","notes":"dot only"},
    {"name":"mindist","used_by":"G","type":"double","default":"1.0","minimum":"0.0","notes":"circo only"},

	  {"type":"separator"},
    {"name":"diredgeconstraints","used_by":"G","type":"stringbool","default":"false","minimum":"","notes":"neato only"},

	  {"type":"separator"},
    {"name":"truecolor","used_by":"G","type":"bool","default":"","minimum":"","notes":"bitmap output only"},
    {"name":"viewport","used_by":"G","type":"viewPort","default":"\"\"","minimum":"","notes":""},
    {"name":"voro_margin","used_by":"G","type":"double","default":"0.05","minimum":"0.0","notes":"not dot"},

	  {"type":"separator"},
    {"name":"Damping","used_by":"G","type":"double","default":"0.99","minimum":"0.0","notes":"neato only"},
    {"name":"defaultdist","used_by":"G","type":"double","default":"1+(avg. len)*sqrt(|V|)","minimum":"epsilon","notes":"neato only"},
    {"name":"dim","used_by":"G","type":"int","default":"2","minimum":"2","notes":"sfdp, fdp, neato only"},
    {"name":"dimen","used_by":"G","type":"int","default":"2","minimum":"2","notes":"sfdp, fdp, neato only"},

	  {"type":"separator"},
    {"name":"weight","used_by":"E","type":"double","default":"1.0","minimum":"0(dot)1(neato,fdp,sfdp)","notes":""},
    {"name":"len","used_by":"E","type":"double","default":"1.0(neato)0.3(fdp)","minimum":"","notes":"fdp, neato only"},

	  {"type":"separator"},
    {"name":"K","used_by":"GC","type":"double","default":"0.3","minimum":"0","notes":"sfdp, fdp only"},

	// Advanced
	  {"type":"separator"},
    {"name":"charset","used_by":"G","type":"string","default":"\"UTF-8\"","minimum":"","notes":""},

	  {"type":"separator"},
    {"name":"URL","used_by":"ENGC","type":"escString","default":"<none>","minimum":"","notes":"svg, postscript, map only"},

	  {"type":"separator"},
    {"name":"constraint","used_by":"E","type":"bool","default":"true","minimum":"","notes":"dot only"},
    {"name":"decorate","used_by":"E","type":"bool","default":"false","minimum":"","notes":""},
    {"name":"dir","used_by":"E","type":"dirType","default":"forward(directed)none(undirected)","minimum":"","notes":""},

	  {"type":"separator"},
    {"name":"distortion","used_by":"N","type":"double","default":"0.0","minimum":"-100.0","notes":""},
    {"name":"edgeURL","used_by":"E","type":"escString","default":"\"\"","minimum":"","notes":"svg, map only"},
    {"name":"edgehref","used_by":"E","type":"escString","default":"\"\"","minimum":"","notes":"svg, map only"},
    {"name":"edgetarget","used_by":"E","type":"escString","default":"<none>","minimum":"","notes":"svg, map only"},
    {"name":"edgetooltip","used_by":"E","type":"escString","default":"\"\"","minimum":"","notes":"svg, cmap only"},
    {"name":"epsilon","used_by":"G","type":"double","default":".0001 * # nodes(mode == KK).0001(mode == major)","minimum":"","notes":"neato only"},
    {"name":"esep","used_by":"G","type":"doublepointf","default":"+3","minimum":"","notes":"not dot"},
    {"name":"fixedsize","used_by":"N","type":"bool","default":"false","minimum":"","notes":""},
    {"name":"group","used_by":"N","type":"string","default":"\"\"","minimum":"","notes":"dot only"},

	  {"type":"separator"},


    {"name":"href","used_by":"E","type":"escString","default":"\"\"","minimum":"","notes":"svg, postscript, map only"},
    {"name":"image","used_by":"N","type":"string","default":"\"\"","minimum":"","notes":""},
    {"name":"imagescale","used_by":"N","type":"boolstring","default":"false","minimum":"","notes":""},

	  {"type":"separator"},
    {"name":"labelangle","used_by":"E","type":"double","default":"-25.0","minimum":"-180.0","notes":""},
    {"name":"labeldistance","used_by":"E","type":"double","default":"1.0","minimum":"0.0","notes":""},
    {"name":"labelfloat","used_by":"E","type":"bool","default":"false","minimum":"","notes":""},
    {"name":"labelfontcolor","used_by":"E","type":"color","default":"black","minimum":"","notes":""},
    {"name":"labelfontname","used_by":"E","type":"string","default":"\"Times-Roman\"","minimum":"","notes":""},
    {"name":"labelfontsize","used_by":"E","type":"double","default":"14.0","minimum":"1.0","notes":""},
    {"name":"labelhref","used_by":"E","type":"escString","default":"\"\"","minimum":"","notes":"svg, map only"},
    {"name":"labeljust","used_by":"GC","type":"string","default":"\"c\"","minimum":"","notes":""},
    {"name":"labelloc","used_by":"GC","type":"string","default":"\"t\"(clusters)\"b\"(root graphs)","minimum":"","notes":""},
    {"name":"labelloc","used_by":"N","type":"string","default":"\"c\"(clusters)","minimum":"","notes":""},
    {"name":"labeltarget","used_by":"E","type":"escString","default":"<none>","minimum":"","notes":"svg, map only"},
    {"name":"labeltooltip","used_by":"E","type":"escString","default":"\"\"","minimum":"","notes":"svg, cmap only"},
    {"name":"labelURL","used_by":"E","type":"escString","default":"\"\"","minimum":"","notes":"svg, map only"},

	  {"type":"separator"},
    {"name":"landscape","used_by":"G","type":"bool","default":"false","minimum":"","notes":""},
    {"name":"layersep","used_by":"G","type":"string","default":"\" :\\t\"","minimum":"","notes":""},
    {"name":"layout","used_by":"G","type":"string","default":"\"\"","minimum":"","notes":""},
    {"name":"levels","used_by":"G","type":"int","default":"MAXINT","minimum":"0.0","notes":"sfdp only"},
    {"name":"levelsgap","used_by":"G","type":"double","default":"0.0","minimum":"","notes":"neato only"},
    {"name":"lhead","used_by":"E","type":"string","default":"\"\"","minimum":"","notes":"dot only"},
    {"name":"lp","used_by":"EGC","type":"point","default":"","minimum":"","notes":"write only"},
    {"name":"ltail","used_by":"E","type":"string","default":"\"\"","minimum":"","notes":"dot only"},
    {"name":"margin","used_by":"NG","type":"doublepointf","default":"<device-dependent>","minimum":"","notes":""},
    {"name":"minlen","used_by":"E","type":"int","default":"1","minimum":"0","notes":"dot only"},
    {"name":"mode","used_by":"G","type":"string","default":"\"major\"","minimum":"","notes":"neato only"},
    {"name":"model","used_by":"G","type":"string","default":"\"shortpath\"","minimum":"","notes":"neato only"},
    {"name":"mosek","used_by":"G","type":"bool","default":"false","minimum":"","notes":"neato only"},
    {"name":"nodesep","used_by":"G","type":"double","default":"0.25","minimum":"0.02","notes":"dot only"},
    {"name":"nojustify","used_by":"GCNE","type":"bool","default":"false","minimum":"","notes":""},
    {"name":"normalize","used_by":"G","type":"bool","default":"false","minimum":"","notes":"not dot"},
    {"name":"nslimitnslimit1","used_by":"G","type":"double","default":"","minimum":"","notes":"dot only"},
    {"name":"ordering","used_by":"G","type":"string","default":"\"\"","minimum":"","notes":"dot only"},
    {"name":"orientation","used_by":"N","type":"double","default":"0.0","minimum":"360.0","notes":""},
    {"name":"orientation","used_by":"G","type":"string","default":"\"\"","minimum":"","notes":""},
    {"name":"outputorder","used_by":"G","type":"outputMode","default":"breadthfirst","minimum":"","notes":""},
    {"name":"overlap","used_by":"G","type":"stringbool","default":"true","minimum":"","notes":"not dot"},
    {"name":"overlap_scaling","used_by":"G","type":"double","default":"-4","minimum":"-1.0e10","notes":"prism only"},
    {"name":"pack","used_by":"G","type":"boolint","default":"false","minimum":"","notes":"not dot"},
    {"name":"packmode","used_by":"G","type":"packMode","default":"node","minimum":"","notes":"not dot"},
    {"name":"pad","used_by":"G","type":"doublepointf","default":"0.0555 (4 points)","minimum":"","notes":""},
    {"name":"page","used_by":"G","type":"pointf","default":"","minimum":"","notes":""},
    {"name":"pagedir","used_by":"G","type":"pagedir","default":"BL","minimum":"","notes":""},
    {"name":"pencolor","used_by":"C","type":"color","default":"black","minimum":"","notes":""},
    {"name":"penwidth","used_by":"CNE","type":"double","default":"1.0","minimum":"0.0","notes":""},
    {"name":"peripheries","used_by":"NC","type":"int","default":"shape default(nodes)1(clusters)","minimum":"0","notes":""},
    {"name":"quadtree","used_by":"G","type":"quadTypebool","default":"\"normal\"","minimum":"","notes":"sfdp only"},
    {"name":"quantum","used_by":"G","type":"double","default":"0.0","minimum":"0.0","notes":""},
    {"name":"rank","used_by":"S","type":"rankType","default":"","minimum":"","notes":"dot only"},
    {"name":"rankdir","used_by":"G","type":"rankdir","default":"TB","minimum":"","notes":"dot only"},
    {"name":"ranksep","used_by":"G","type":"double","default":"0.5(dot)1.0(twopi)","minimum":"0.02","notes":"twopi, dot only"},
    {"name":"ratio","used_by":"G","type":"doublestring","default":"","minimum":"","notes":""},
    {"name":"rects","used_by":"N","type":"rect","default":"","minimum":"","notes":"write only"},
    {"name":"regular","used_by":"N","type":"bool","default":"false","minimum":"","notes":""},
    {"name":"remincross","used_by":"G","type":"bool","default":"false","minimum":"","notes":"dot only"},
    {"name":"repulsiveforce","used_by":"G","type":"double","default":"1.0","minimum":"0.0","notes":"sfdp only"},
    {"name":"resolution","used_by":"G","type":"double","default":"96.00.0","minimum":"","notes":"svg, bitmap output only"},
    {"name":"root","used_by":"GN","type":"stringbool","default":"\"\"(graphs)false(nodes)","minimum":"","notes":"circo, twopi only"},
    {"name":"rotate","used_by":"G","type":"int","default":"0","minimum":"","notes":""},
    {"name":"samehead","used_by":"E","type":"string","default":"\"\"","minimum":"","notes":"dot only"},
    {"name":"sametail","used_by":"E","type":"string","default":"\"\"","minimum":"","notes":"dot only"},
    {"name":"samplepoints","used_by":"N","type":"int","default":"8(output)20(overlap and image maps)","minimum":"","notes":""},
    {"name":"searchsize","used_by":"G","type":"int","default":"30","minimum":"","notes":"dot only"},
    {"name":"sep","used_by":"G","type":"doublepointf","default":"+4","minimum":"","notes":"not dot"},
    {"name":"showboxes","used_by":"ENG","type":"int","default":"0","minimum":"0","notes":"dot only"},
    {"name":"sides","used_by":"N","type":"int","default":"4","minimum":"0","notes":""},
    {"name":"size","used_by":"G","type":"pointf","default":"","minimum":"","notes":""},
    {"name":"skew","used_by":"N","type":"double","default":"0.0","minimum":"-100.0","notes":""},
    {"name":"smoothing","used_by":"G","type":"smoothType","default":"\"none\"","minimum":"","notes":"sfdp only"},
    {"name":"sortv","used_by":"GCN","type":"int","default":"0","minimum":"0","notes":""},
    {"name":"splines","used_by":"G","type":"boolstring","default":"","minimum":"","notes":""},
    {"name":"start","used_by":"G","type":"startType","default":"\"\"","minimum":"","notes":"fdp, neato only"},
    {"name":"style","used_by":"ENC","type":"style","default":"","minimum":"","notes":""},
    {"name":"stylesheet","used_by":"G","type":"string","default":"\"\"","minimum":"","notes":"svg only"},

	  {"type":"separator"},
    {"name":"vertices","used_by":"N","type":"pointfList","default":"","minimum":"","notes":"write only"},
    {"name":"z","used_by":"N","type":"double","default":"0.0","minimum":"-MAXFLOAT-1000","notes":""},
];

org.graphviz.attrs={};
for(var i in org.graphviz.attr) {
  org.graphviz.attrs[org.graphviz.attr[i].name]=i;
};

org.graphviz.esc=function(id) {
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

org.graphviz.parser = {
	r: { // common regexes used by lexer and such
		space: /\s/,
		ident: /[a-zA-Z0-9_\200-\377]/,
		punct1: /[\{\}\[\]\-\>=]/,
		punct2: /[,;:]/,
		graph_type: /^(graph|digraph)$/,
		attr_type: /^(node|edge|graph)$/
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
		if(!this.src[this.pos]) { return null; }
		var sym={type:null,name:''};
		while(this.pos<this.len && this.src[this.pos].match(this.r.space)) {
			if(this.src[this.pos]=="\n") { this.row++; this.col=-1; }
			this.pos++; this.col++;
		}
		if(this.src[this.pos]=='"') {
			sym.pos=this.pos; sym.row=this.row; sym.len=0;
			sym.type='string';
			this.pos++; this.col++; sym.len++;
			while(this.pos<this.len && this.src[this.pos]!='"') {
				if(this.src[this.pos]=="\n") { this.row++; this.col=-1; }
				if(this.src[this.pos]=='\\') { 
					this.pos++; this.col++; 
					sym.name+=this.src[this.pos]; // FIXME: unescape '\n'-ish things in strings
					sym.len++;
				} else {
					sym.name+=this.src[this.pos]; sym.len++;
				}
				this.pos++; this.col++;
			}
			if(this.src[this.pos]=='"') { this.pos++; this.col++; sym.len++; }
		}
		else if(this.src[this.pos].match(this.r.ident)) {
			sym.pos=this.pos; sym.row=this.row; sym.len=0;
			sym.type='ident';
			while(this.pos<this.len && this.src[this.pos].match(this.r.ident)) {
				sym.name+=this.src[this.pos]; sym.len++;
				this.pos++; this.col++;
			}
		}
		else if(this.src[this.pos].match(this.r.punct1)) {
			sym.pos=this.pos; sym.row=this.row; sym.len=0;
			sym.type='punct1';
			while(this.pos<this.len && this.src[this.pos].match(this.r.punct1)) {
				sym.name+=this.src[this.pos]; sym.len++;
				this.pos++; this.col++;
			}
		}
		else if(this.src[this.pos].match(this.r.punct2)) {
			sym.pos=this.pos; sym.row=this.row; sym.len=0;
			sym.type='punct2';
			while(this.pos<this.len && this.src[this.pos].match(this.r.punct2)) {
				sym.name+=this.src[this.pos]; sym.len++;
				this.pos++; this.col++;
			}
		}
		else if(this.src[this.pos]=='#') {
			sym.pos=this.pos; sym.row=this.row; sym.len=0;
			sym.type='comment';
			while(this.pos<this.len && this.src[this.pos]!="\n") {
				sym.name+=this.src[this.pos]; sym.len++;
				this.pos++; this.col++;
			}
			if(this.src[this.pos]=="\n") { this.row++; this.col=0; this.pos++; }
			return sym.name.length>0?sym:null;
		}
		if(this.src[this.pos]) {
			while(this.pos<this.len && this.src[this.pos].match(this.r.space)) {
				if(this.src[this.pos]=="\n") { this.row++; this.col=-1; }
				this.pos++; this.col++;
			}
		}
		return sym.name.length>0?sym:null;
	}
};

