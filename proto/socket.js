var socketAPI = {
    find: function(socket,data) {
	console.log("FIND",data);
	if(!data.q) return;
	if(!data.p) return;
	if(data.q.length<2) return;
	var p = ".";
	var cmd = 'find';
	var args = [p,'-name','*'+data.q+'*'];
	console.log(cmd,args);
	if(socket.proc) {
	    socket.proc.kill();
	}
	socket.proc = child_process.spawn(cmd, args, {env:{TERM:'dumb'},cwd:p});
	socket.proc.stdout.setEncoding('utf8');

	var c = new LineCutter();
	socket.proc.stdout.on('data',function(data) { 
	    c.input(line, function(d) {
		socket.emit('output',d);
	    });
	},'utf8');
	socket.proc.on('close',function(code) {
	    socket.proc = null;
	    socket.emit('end');
	});
    }
};

function socketHandler(socket) {
    socket.emit('hello', {});
    console.log('IO.CONNECT', socket.id);
    socket.on('echo', function(data) {
	socket.emit('echo',data);
	console.log('IO.ECHO',data);
    });
    socket.on('run', function(data) {
	if(!data) return;
	if(socketAPI[data.action]) {
	    socketAPI[data.action](socket,data);
	}
    });
};

