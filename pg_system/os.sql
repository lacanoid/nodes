--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: os; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA os;


ALTER SCHEMA os OWNER TO postgres;

--
-- Name: SCHEMA os; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA os IS 'Operating system utilities';


SET search_path = os, pg_catalog;

--
-- Name: file_name; Type: DOMAIN; Schema: os; Owner: postgres
--

CREATE DOMAIN file_name AS character varying;


ALTER DOMAIN file_name OWNER TO postgres;

--
-- Name: file_path; Type: DOMAIN; Schema: os; Owner: postgres
--

CREATE DOMAIN file_path AS character varying;


ALTER DOMAIN file_path OWNER TO postgres;

--
-- Name: basename(file_path); Type: FUNCTION; Schema: os; Owner: postgres
--

CREATE FUNCTION basename(file_path) RETURNS file_path
    LANGUAGE plperl IMMUTABLE
    AS $_$
  my $str=shift; $str=~s|^(.*/)([^/]*)$|$2|; return $str;
$_$;


ALTER FUNCTION os.basename(file_path) OWNER TO postgres;

--
-- Name: FUNCTION basename(file_path); Type: COMMENT; Schema: os; Owner: postgres
--

COMMENT ON FUNCTION basename(file_path) IS 'Return file base name';


--
-- Name: basename(file_path, text); Type: FUNCTION; Schema: os; Owner: postgres
--

CREATE FUNCTION basename(file_path, text) RETURNS file_path
    LANGUAGE plperl IMMUTABLE
    AS $_$my $str=shift; my $ext=shift;
$str=~s|^(.*/)([^/]*)$|$2|; 
$str=~s|$ext$||;
return $str;
$_$;


ALTER FUNCTION os.basename(file_path, text) OWNER TO postgres;

--
-- Name: FUNCTION basename(file_path, text); Type: COMMENT; Schema: os; Owner: postgres
--

COMMENT ON FUNCTION basename(file_path, text) IS 'Return file base name with extension removed';


--
-- Name: dirname(file_path); Type: FUNCTION; Schema: os; Owner: postgres
--

CREATE FUNCTION dirname(file_path) RETURNS file_path
    LANGUAGE plperl IMMUTABLE
    AS $_$
my $str=shift; $str=~s|^(.*/)[^/]*$|$1|; 
return $str; 
$_$;


ALTER FUNCTION os.dirname(file_path) OWNER TO postgres;

--
-- Name: FUNCTION dirname(file_path); Type: COMMENT; Schema: os; Owner: postgres
--

COMMENT ON FUNCTION dirname(file_path) IS 'Return file directory name';


--
-- Name: disk_free(); Type: FUNCTION; Schema: os; Owner: postgres
--

CREATE FUNCTION disk_free(OUT dev integer, OUT filesystem text, OUT fstype text, OUT mountpoint text, OUT size numeric, OUT used numeric, OUT avail numeric, OUT "%use" double precision, OUT options text[]) RETURNS SETOF record
    LANGUAGE plperlu COST 1000 ROWS 10
    AS $_$
# Get UNIX file system information
# this uses UNIX df(1) and mount(1) commands

my %d=();

# reported by df(1)
my $df=`df -B1 -a -P`;my @df=split(/[\n\r]+/,$df); shift @df;
for my $l (@df) { 
	my @a=split(/\s+/,$l); my $i=$a[0];
	$d{$i}={
		'filesystem'=>$i,'size'=>$a[1],'used'=>$a[2],
		'avail'=>$a[3],'%use'=>$a[4],'mountpoint'=>$a[5]
	};
	if( $d{$i}{'%use'}eq'-') { $d{$i}{'%use'}=undef; } 
	else { $d{$i}{'%use'}=~s/%//; }
	my @stat=stat($d{$i}{'mountpoint'});
	$d{$i}{'dev'}=$stat[0];
}

# reported by mount(1)
my $mt=`mount`; my @mt=split(/[\n\r]+/,$mt);
for my $l (@mt) {
	my @a=split(/\s+/,$l);
	$d{$a[0]}{'fstype'}=$a[4];
	$d{$a[0]}{'options'}=$a[5];
	$d{$a[0]}{'options'}=~y/\(\)/\{\}/;
}

for my $i (keys(%d)) { return_next($d{$i}); }

return undef;
$_$;


ALTER FUNCTION os.disk_free(OUT dev integer, OUT filesystem text, OUT fstype text, OUT mountpoint text, OUT size numeric, OUT used numeric, OUT avail numeric, OUT "%use" double precision, OUT options text[]) OWNER TO postgres;

--
-- Name: FUNCTION disk_free(OUT dev integer, OUT filesystem text, OUT fstype text, OUT mountpoint text, OUT size numeric, OUT used numeric, OUT avail numeric, OUT "%use" double precision, OUT options text[]); Type: COMMENT; Schema: os; Owner: postgres
--

COMMENT ON FUNCTION disk_free(OUT dev integer, OUT filesystem text, OUT fstype text, OUT mountpoint text, OUT size numeric, OUT used numeric, OUT avail numeric, OUT "%use" double precision, OUT options text[]) IS 'Get UNIX file system information
';


--
-- Name: file_get(file_path); Type: FUNCTION; Schema: os; Owner: postgres
--

CREATE FUNCTION file_get(file_path) RETURNS text
    LANGUAGE plperlu STRICT COST 1000
    AS $_$
my $filename=shift;
if(-f $filename) {
  if(open(Fi,$filename)) {
    $d=join("",<Fi>);
    close(Fi);
    return $d;
  }
}
#elog(WARNING,"File not found: <$file>");

return undef;
$_$;


ALTER FUNCTION os.file_get(file_path) OWNER TO postgres;

--
-- Name: file_put(file_path, text); Type: FUNCTION; Schema: os; Owner: postgres
--

CREATE FUNCTION file_put(file_path, text) RETURNS bigint
    LANGUAGE plperlu STRICT
    AS $_$
my $file=shift; 
my $data=shift; 
my $ok=0; 
 
if(!defined($file)) { 
  elog ERROR, "File not specified"; 
  return undef; 
} 
 
unless($file=~m|^/|) { 
  elog ERROR, "Relative path not allowed in function file_put()"; 
  return undef; 
} 
 
if(-f $file) {
  elog ERROR, "File exists!";
  return undef;
}

if(open(Fo,">".$file)) { 
  $ok = print Fo $data; 
  close(Fo); 
  chmod 0644, $file; 
  return $ok?length($data):undef; 
} else { 
  elog WARNING, "Can't create $file"; 
} 
return undef; 
$_$;


ALTER FUNCTION os.file_put(file_path, text) OWNER TO postgres;

--
-- Name: FUNCTION file_put(file_path, text); Type: COMMENT; Schema: os; Owner: postgres
--

COMMENT ON FUNCTION file_put(file_path, text) IS 'Create a file';


--
-- Name: file_size(file_path); Type: FUNCTION; Schema: os; Owner: postgres
--

CREATE FUNCTION file_size(file_path) RETURNS bigint
    LANGUAGE sql STRICT
    AS $_$select (os.file_stat($1)).size::bigint$_$;


ALTER FUNCTION os.file_size(file_path) OWNER TO postgres;

--
-- Name: FUNCTION file_size(file_path); Type: COMMENT; Schema: os; Owner: postgres
--

COMMENT ON FUNCTION file_size(file_path) IS 'Determine size of a file';


--
-- Name: file_stat(file_path); Type: FUNCTION; Schema: os; Owner: postgres
--

CREATE FUNCTION file_stat(file_path, OUT dev bigint, OUT inode bigint, OUT mode integer, OUT nlink integer, OUT uid integer, OUT gid integer, OUT rdev integer, OUT size numeric, OUT atime timestamp without time zone, OUT mtime timestamp without time zone, OUT ctime timestamp without time zone, OUT blksize integer, OUT blocks bigint) RETURNS record
    LANGUAGE plperlu STRICT
    AS $_$
use Date::Format; 

my ($filename) = @_; 
unless(-e $filename) { return undef; }
my (@s) = stat($filename); 

return {
 'dev'=>$s[0],'inode'=>$s[1],'mode'=>$s[2],'nlink'=>$s[3],
 'uid'=>$s[4],'gid'=>$s[5],
 'rdev'=>$s[6],'size'=>$s[7],
 'atime'=>time2str("%C",$s[8]),'mtime'=>time2str("%C",$s[9]),'ctime'=>time2str("%C",$s[10]),
 'blksize'=>$s[11],'blocks'=>$s[12]
};
$_$;


ALTER FUNCTION os.file_stat(file_path, OUT dev bigint, OUT inode bigint, OUT mode integer, OUT nlink integer, OUT uid integer, OUT gid integer, OUT rdev integer, OUT size numeric, OUT atime timestamp without time zone, OUT mtime timestamp without time zone, OUT ctime timestamp without time zone, OUT blksize integer, OUT blocks bigint) OWNER TO postgres;

--
-- Name: FUNCTION file_stat(file_path, OUT dev bigint, OUT inode bigint, OUT mode integer, OUT nlink integer, OUT uid integer, OUT gid integer, OUT rdev integer, OUT size numeric, OUT atime timestamp without time zone, OUT mtime timestamp without time zone, OUT ctime timestamp without time zone, OUT blksize integer, OUT blocks bigint); Type: COMMENT; Schema: os; Owner: postgres
--

COMMENT ON FUNCTION file_stat(file_path, OUT dev bigint, OUT inode bigint, OUT mode integer, OUT nlink integer, OUT uid integer, OUT gid integer, OUT rdev integer, OUT size numeric, OUT atime timestamp without time zone, OUT mtime timestamp without time zone, OUT ctime timestamp without time zone, OUT blksize integer, OUT blocks bigint) IS 'Return info record from stat(2)';


--
-- Name: file_stat(file_path, integer); Type: FUNCTION; Schema: os; Owner: postgres
--

CREATE FUNCTION file_stat(file_path, integer) RETURNS text
    LANGUAGE plperlu STRICT
    AS $_$
my ($filename,$item) = @_; 
unless(-f $filename) { return undef; }
my (@stat) = stat($filename); 

return $stat[$item]; 

my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
    $atime,$mtime,$ctime,$blksize,$blocks) = stat($filename);
$_$;


ALTER FUNCTION os.file_stat(file_path, integer) OWNER TO postgres;

--
-- Name: FUNCTION file_stat(file_path, integer); Type: COMMENT; Schema: os; Owner: postgres
--

COMMENT ON FUNCTION file_stat(file_path, integer) IS 'Return info item from stat(2) [DEPRECATED]';


--
-- Name: process_kill(integer); Type: FUNCTION; Schema: os; Owner: postgres
--

CREATE FUNCTION process_kill(integer) RETURNS text
    LANGUAGE sql
    AS $_$select os.system('kill '||$1)$_$;


ALTER FUNCTION os.process_kill(integer) OWNER TO postgres;

--
-- Name: FUNCTION process_kill(integer); Type: COMMENT; Schema: os; Owner: postgres
--

COMMENT ON FUNCTION process_kill(integer) IS 'Kill a process, Process must be owned by user postgresql.';


--
-- Name: process_status(); Type: FUNCTION; Schema: os; Owner: postgres
--

CREATE FUNCTION process_status(OUT username name, OUT pid integer, OUT "%cpu" double precision, OUT "%mem" double precision, OUT vsz bigint, OUT rss bigint, OUT tty name, OUT stat name, OUT start timestamp with time zone, OUT "time" interval, OUT command character varying) RETURNS SETOF record
    LANGUAGE plperlu COST 1000 ROWS 100
    AS $_$my $data=`ps aux`;
my @lines=split("\n",$data);
my $header=shift @lines;
my @labels=split(/\s+/,$header);

my ($ss,$mi,$hh24,$mday,$mm,$yyyy,$wday,$yday,$isdst) = localtime(time);
$yyyy+=1900; $mm+=1;

$labels[0]='username';

for my $line (@lines) {
 my @line=split(/\s+/,$line,$#labels+1);
 my %line;

 for(my $li=0;$li<(@line);$li++) { $line{lc($labels[$li])}=$line[$li]; }

 # fix the start time to be SQL compliant
    if($line{'start'}=~m|^(2\d\d\d)$|) { $line{'start'}=sprintf('%04d-01-01',$1); }
 elsif($line{'start'}=~m|^([A-Za-z]{3}\d\d)$|) { $line{'start'}.=", $yyyy"; }
 elsif($line{'start'}=~m|^(\d\d:\d\d)$|) { $line{'start'}="today, ".$line{'start'}; }

 return_next(\%line);
}

return undef;
$_$;


ALTER FUNCTION os.process_status(OUT username name, OUT pid integer, OUT "%cpu" double precision, OUT "%mem" double precision, OUT vsz bigint, OUT rss bigint, OUT tty name, OUT stat name, OUT start timestamp with time zone, OUT "time" interval, OUT command character varying) OWNER TO postgres;

--
-- Name: FUNCTION process_status(OUT username name, OUT pid integer, OUT "%cpu" double precision, OUT "%mem" double precision, OUT vsz bigint, OUT rss bigint, OUT tty name, OUT stat name, OUT start timestamp with time zone, OUT "time" interval, OUT command character varying); Type: COMMENT; Schema: os; Owner: postgres
--

COMMENT ON FUNCTION process_status(OUT username name, OUT pid integer, OUT "%cpu" double precision, OUT "%mem" double precision, OUT vsz bigint, OUT rss bigint, OUT tty name, OUT stat name, OUT start timestamp with time zone, OUT "time" interval, OUT command character varying) IS 'SQL interface to UNIX ps(1) command';


--
-- Name: system(text); Type: FUNCTION; Schema: os; Owner: postgres
--

CREATE FUNCTION system(text) RETURNS text
    LANGUAGE plperlu
    AS $_X$return `$_[0]`$_X$;


ALTER FUNCTION os.system(text) OWNER TO postgres;

--
-- Name: FUNCTION system(text); Type: COMMENT; Schema: os; Owner: postgres
--

COMMENT ON FUNCTION system(text) IS 'Execute shell commands';


--
-- Name: disk_free; Type: VIEW; Schema: os; Owner: postgres
--

CREATE VIEW disk_free AS
 SELECT disk_free.dev,
    disk_free.filesystem,
    disk_free.fstype,
    disk_free.mountpoint,
    disk_free.size,
    disk_free.used,
    disk_free.avail,
    disk_free."%use",
    disk_free.options
   FROM disk_free() disk_free(dev, filesystem, fstype, mountpoint, size, used, avail, "%use", options);


ALTER TABLE disk_free OWNER TO postgres;

--
-- Name: process_status; Type: VIEW; Schema: os; Owner: postgres
--

CREATE VIEW process_status AS
 SELECT process_status.username,
    process_status.pid,
    process_status."%cpu",
    process_status."%mem",
    process_status.vsz,
    process_status.rss,
    process_status.tty,
    process_status.stat,
    process_status.start,
    process_status."time",
    process_status.command
   FROM process_status() process_status(username, pid, "%cpu", "%mem", vsz, rss, tty, stat, start, "time", command);


ALTER TABLE process_status OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: version; Type: TABLE; Schema: os; Owner: postgres; Tablespace: 
--

CREATE TABLE version (
    version timestamp with time zone
);


ALTER TABLE version OWNER TO postgres;

--
-- Name: version_singleton; Type: INDEX; Schema: os; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX version_singleton ON version USING btree ((1));


--
-- Name: os; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA os FROM PUBLIC;
REVOKE ALL ON SCHEMA os FROM postgres;
GRANT ALL ON SCHEMA os TO postgres;
GRANT USAGE ON SCHEMA os TO system;


--
-- Name: disk_free(); Type: ACL; Schema: os; Owner: postgres
--

REVOKE ALL ON FUNCTION disk_free(OUT dev integer, OUT filesystem text, OUT fstype text, OUT mountpoint text, OUT size numeric, OUT used numeric, OUT avail numeric, OUT "%use" double precision, OUT options text[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION disk_free(OUT dev integer, OUT filesystem text, OUT fstype text, OUT mountpoint text, OUT size numeric, OUT used numeric, OUT avail numeric, OUT "%use" double precision, OUT options text[]) FROM postgres;
GRANT ALL ON FUNCTION disk_free(OUT dev integer, OUT filesystem text, OUT fstype text, OUT mountpoint text, OUT size numeric, OUT used numeric, OUT avail numeric, OUT "%use" double precision, OUT options text[]) TO postgres;
GRANT ALL ON FUNCTION disk_free(OUT dev integer, OUT filesystem text, OUT fstype text, OUT mountpoint text, OUT size numeric, OUT used numeric, OUT avail numeric, OUT "%use" double precision, OUT options text[]) TO PUBLIC;
GRANT ALL ON FUNCTION disk_free(OUT dev integer, OUT filesystem text, OUT fstype text, OUT mountpoint text, OUT size numeric, OUT used numeric, OUT avail numeric, OUT "%use" double precision, OUT options text[]) TO atom;


--
-- Name: file_put(file_path, text); Type: ACL; Schema: os; Owner: postgres
--

REVOKE ALL ON FUNCTION file_put(file_path, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION file_put(file_path, text) FROM postgres;
GRANT ALL ON FUNCTION file_put(file_path, text) TO postgres;
GRANT ALL ON FUNCTION file_put(file_path, text) TO PUBLIC;


--
-- Name: process_kill(integer); Type: ACL; Schema: os; Owner: postgres
--

REVOKE ALL ON FUNCTION process_kill(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION process_kill(integer) FROM postgres;
GRANT ALL ON FUNCTION process_kill(integer) TO postgres;
GRANT ALL ON FUNCTION process_kill(integer) TO system;


--
-- Name: system(text); Type: ACL; Schema: os; Owner: postgres
--

REVOKE ALL ON FUNCTION system(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION system(text) FROM postgres;
GRANT ALL ON FUNCTION system(text) TO system;


--
-- PostgreSQL database dump complete
--

