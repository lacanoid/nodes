var app;

wb.PSTreeController = wb.ViewController.extend({
    init: function(options) {
	var me = this;

	this.i = 0;
	this.duration = 750;

	this.view  = new wb.View({parent:this,delegate:this}).css({background:"white"}).maximize();
	this.title = "Process Tree";

	d3.json("/api/os/ps", function(error, flare) {
	    if(!me.svg) { me.create(); }

	    me.root = flare;
	    me.root.x0 = me.height / 2;
	    me.root.y0 = 0;
	    
	    function collapse(d) {
		if (d.children) {
		    d._children = d.children;
		    d._children.forEach(collapse);
		    d.children = null;
		}
	    }
	    
	    me.root.children.forEach(collapse);
	    me.update(me.root);
	});

//	d3.select(self.frameElement).style("height", "800px");
    },
    resize: function() {
	var w = this.view.$.width();
	var h = this.view.$.height();

	this.margin = {top: 20, right: 80, bottom: 20, left: 80};

	this.width = w - this.margin.right - this.margin.left;
	this.height = h - this.margin.top - this.margin.bottom;

	if(this.svg) {
	    console.log('RESIZE',w,h,this.svg);
	    $('svg').attr('width',w-2).attr('height',h-2);
	}
    },
    create: function() {
	this.resize();

	this.tree = d3.layout.tree().size([this.height, this.width]);
	this.diagonal = d3.svg.diagonal().projection(function(d) { return [d.y, d.x]; });
	this.svg = d3.select(this.view.element).append("svg")
	    .attr("width", this.width + this.margin.right + this.margin.left -2)
	    .attr("height", this.height + this.margin.top + this.margin.bottom -2)
	    .append("g")
	    .attr("transform", "translate(" + this.margin.left + "," + this.margin.top + ")");

    },
    update: function(source) {
	var me = this;

	// Compute the new tree layout.
	var nodes = this.tree.nodes(this.root).reverse(),
	            links = this.tree.links(nodes);

	// Normalize for fixed-depth.
	nodes.forEach(function(d) { d.y = d.depth * 180; });

	// Update the nodes…
	var node = this.svg.selectAll("g.node")
	    .data(nodes, function(d) { return d.id || (d.id = ++me.i); });

	// Enter any new nodes at the parent's previous position.
	var nodeEnter = node.enter().append("g")
	    .attr("class", "node")
	    .attr("transform", function(d) { return "translate(" + source.y0 + "," + source.x0 + ")"; })
	    .on("click", function(d) { me.click(d) });

	nodeEnter.append("circle")
	    .attr("r", 1e-6)
	    .style("fill", function(d) { return d._children ? "lightsteelblue" : "#fff"; });

	nodeEnter.append("text")
	    .attr("x", function(d) { return d.children || d._children ? -10 : 10; })
	    .attr("dy", ".35em")
	    .attr("text-anchor", function(d) { return d.children || d._children ? "end" : "start"; })
	    .text(function(d) { return d.name; })
	    .style("fill-opacity", 1e-6);

	// Transition nodes to their new position.
	var nodeUpdate = node.transition()
	    .duration(me.duration)
	    .attr("transform", function(d) { return "translate(" + d.y + "," + d.x + ")"; });
	
	nodeUpdate.select("circle")
	    .attr("r", 4.5)
	    .style("fill", function(d) { return d._children ? "lightsteelblue" : "#fff"; });
	
	nodeUpdate.select("text")
	    .style("fill-opacity", 1);
	
	// Transition exiting nodes to the parent's new position.
	var nodeExit = node.exit().transition()
	    .duration(me.duration)
	    .attr("transform", function(d) { return "translate(" + source.y + "," + source.x + ")"; })
	    .remove();

	nodeExit.select("circle")
	    .attr("r", 1e-6);
	
	nodeExit.select("text")
	    .style("fill-opacity", 1e-6);
	
	// Update the links…
	var link = this.svg.selectAll("path.link")
	    .data(links, function(d) { return d.target.id; });
	
	// Enter any new links at the parent's previous position.
	link.enter().insert("path", "g")
	    .attr("class", "link")
	    .attr("d", function(d) {
		var o = {x: source.x0, y: source.y0};
		return me.diagonal({source: o, target: o});
	    });
	
	// Transition links to their new position.
	link.transition()
	    .duration(me.duration)
	    .attr("d", me.diagonal);
	
	// Transition exiting nodes to the parent's new position.
	link.exit().transition()
	    .duration(me.duration)
	    .attr("d", function(d) {
		var o = {x: source.x, y: source.y};
		return me.diagonal({source: o, target: o});
      })
	    .remove();
	
	// Stash the old positions for transition.
	nodes.forEach(function(d) {
	    d.x0 = d.x;
	    d.y0 = d.y;
	});
    },
    
    // Toggle children on click.
    click: function(d) {
	if (d.children) {
	    d._children = d.children;
	    d.children = null;
	} else {
	    d.children = d._children;
	    d._children = null;
	}
	this.update(d);
    }

},{
});

var PSViewApplication = wb.Application.extend({
    init: function(options) {
	var me = this;

	var nc = new wb.NavigationController({parent:this});
	this.editor = new wb.PSTreeController({parent:this,delegate:this}).maximize();
	nc.pushViewControllerAnimated(this.editor,false);
	this.navigationController = nc;

	this._info = {					     
	    name:"PSTree",
	    title:"Process Tree",
	    version:"0.1 alpha",
	    description:"process tree",
	};

	this.screen = wb.getSharedScreen();
	this.setParent(this.screen);

	var me = this;
    },
});

function init() {
    app = new PSViewApplication();
}

$(window).load(init);
