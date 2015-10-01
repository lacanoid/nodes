var os={};
os.system=function(file,args) {
  dump('$ '+file);
  if(args ) for(var i in args) { dump("  "+args[i]); }
  else args={};
  dump("\n");

  netscape.security.PrivilegeManager.enablePrivilege("UniversalXPConnect");
  var bin = Components.classes["@mozilla.org/file/local;1"]
                              .createInstance(Components.interfaces.nsILocalFile);
  bin.initWithPath(file);

  // create an nsIProcess
  var process = Components.classes["@mozilla.org/process/util;1"]
                        .          createInstance(Components.interfaces.nsIProcess);
  process.init(bin);

// If first param is true, calling thread will be blocked until
// called process terminates.
// Second and third params are used to pass command-line arguments
// to the process.
  process.run(true, args, args.length);
};

os.time = function() { var time=new Date(); return time.getTime(); };

os.file = function(base, filename) {
		var file;
		if(base) {
			file = DirIO.get(base);
			file.append(filename);
		} else {
			file = FileIO.open(filename);
		}
		this.path=file.path;
		this.file=file;
		this.put = function(data) {
			dump('FILE_PUT:'+this.path+"\n");
			FileIO.create(this.file);
			FileIO.write(this.file, data, 'w', 'UTF-8');
		};
		this.get = function() {
			dump('FILE_GET:'+this.path+"\n");
			return FileIO.read(this.file, 'UTF-8');
		};
		this.unlink = function() {
			dump('FILE_UNLINK:'+this.path+"\n");
			return FileIO.unlink(this.path);
		}
		return this;
};

