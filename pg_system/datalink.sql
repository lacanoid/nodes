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
-- Name: datalink; Type: SCHEMA; Schema: -; Owner: datalink
--

CREATE SCHEMA datalink;


ALTER SCHEMA datalink OWNER TO datalink;

--
-- Name: SCHEMA datalink; Type: COMMENT; Schema: -; Owner: datalink
--

COMMENT ON SCHEMA datalink IS 'SQL/MED datalink type support';


SET search_path = datalink, pg_catalog;

--
-- Name: datalink; Type: DOMAIN; Schema: datalink; Owner: postgres
--

CREATE DOMAIN datalink AS bigint;


ALTER DOMAIN datalink OWNER TO postgres;

--
-- Name: datalink1; Type: TYPE; Schema: datalink; Owner: datalink
--

CREATE TYPE datalink1 AS (
	id bigint,
	token uuid
);


ALTER TYPE datalink1 OWNER TO datalink;

--
-- Name: dl_id; Type: DOMAIN; Schema: datalink; Owner: postgres
--

CREATE DOMAIN dl_id AS bigint;


ALTER DOMAIN dl_id OWNER TO postgres;

--
-- Name: dl_integrity; Type: TYPE; Schema: datalink; Owner: datalink
--

CREATE TYPE dl_integrity AS ENUM (
    'NONE',
    'SELECTIVE',
    'ALL'
);


ALTER TYPE dl_integrity OWNER TO datalink;

--
-- Name: dl_link_control; Type: TYPE; Schema: datalink; Owner: datalink
--

CREATE TYPE dl_link_control AS ENUM (
    'NO',
    'FILE'
);


ALTER TYPE dl_link_control OWNER TO datalink;

--
-- Name: dl_on_unlink; Type: TYPE; Schema: datalink; Owner: datalink
--

CREATE TYPE dl_on_unlink AS ENUM (
    'NONE',
    'RESTORE',
    'DELETE'
);


ALTER TYPE dl_on_unlink OWNER TO datalink;

--
-- Name: dl_read_access; Type: TYPE; Schema: datalink; Owner: datalink
--

CREATE TYPE dl_read_access AS ENUM (
    'FS',
    'DB'
);


ALTER TYPE dl_read_access OWNER TO datalink;

--
-- Name: dl_recovery; Type: TYPE; Schema: datalink; Owner: datalink
--

CREATE TYPE dl_recovery AS ENUM (
    'NO',
    'YES'
);


ALTER TYPE dl_recovery OWNER TO datalink;

--
-- Name: dl_write_access; Type: TYPE; Schema: datalink; Owner: datalink
--

CREATE TYPE dl_write_access AS ENUM (
    'FS',
    'BLOCKED',
    'ADMIN NOT REQUIRING TOKEN FOR UPDATE',
    'ADMIN REQUIRING TOKEN FOR UPDATE'
);


ALTER TYPE dl_write_access OWNER TO datalink;

--
-- Name: dl_link_control_options; Type: TYPE; Schema: datalink; Owner: datalink
--

CREATE TYPE dl_link_control_options AS (
	link_control dl_link_control,
	integrity dl_integrity,
	read_access dl_read_access,
	write_access dl_write_access,
	recovery dl_recovery,
	on_unlink dl_on_unlink
);


ALTER TYPE dl_link_control_options OWNER TO datalink;

--
-- Name: dl_options; Type: DOMAIN; Schema: datalink; Owner: postgres
--

CREATE DOMAIN dl_options AS integer;


ALTER DOMAIN dl_options OWNER TO postgres;

--
-- Name: DOMAIN dl_options; Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON DOMAIN dl_options IS 'datalink file control options';


--
-- Name: dl_token; Type: DOMAIN; Schema: datalink; Owner: postgres
--

CREATE DOMAIN dl_token AS character varying;


ALTER DOMAIN dl_token OWNER TO postgres;

--
-- Name: file_flags; Type: DOMAIN; Schema: datalink; Owner: postgres
--

CREATE DOMAIN file_flags AS character varying;


ALTER DOMAIN file_flags OWNER TO postgres;

--
-- Name: file_handle; Type: DOMAIN; Schema: datalink; Owner: postgres
--

CREATE DOMAIN file_handle AS character varying;


ALTER DOMAIN file_handle OWNER TO postgres;

--
-- Name: file_name; Type: DOMAIN; Schema: datalink; Owner: postgres
--

CREATE DOMAIN file_name AS character varying;


ALTER DOMAIN file_name OWNER TO postgres;

--
-- Name: file_path; Type: DOMAIN; Schema: datalink; Owner: postgres
--

CREATE DOMAIN file_path AS character varying;


ALTER DOMAIN file_path OWNER TO postgres;

--
-- Name: file_regexp; Type: DOMAIN; Schema: datalink; Owner: postgres
--

CREATE DOMAIN file_regexp AS character varying;


ALTER DOMAIN file_regexp OWNER TO postgres;

--
-- Name: uri; Type: DOMAIN; Schema: datalink; Owner: postgres
--

CREATE DOMAIN uri AS character varying;


ALTER DOMAIN uri OWNER TO postgres;

--
-- Name: url; Type: DOMAIN; Schema: datalink; Owner: postgres
--

CREATE DOMAIN url AS character varying;


ALTER DOMAIN url OWNER TO postgres;

--
-- Name: urn; Type: DOMAIN; Schema: datalink; Owner: postgres
--

CREATE DOMAIN urn AS character varying;


ALTER DOMAIN urn OWNER TO postgres;

--
-- Name: basename(text); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION basename(text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_$
  my $str=shift; $str=~s|^(.*/)([^/]*)$|$2|; return $str;
$_$;


ALTER FUNCTION datalink.basename(text) OWNER TO postgres;

--
-- Name: FUNCTION basename(text); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION basename(text) IS 'Return file path basename';


--
-- Name: basename(text, text); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION basename(text, text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_$my $str=shift; my $ext=shift;
$str=~s|^(.*/)([^/]*)$|$2|; 
$str=~s|$ext$||;
return $str;
$_$;


ALTER FUNCTION datalink.basename(text, text) OWNER TO postgres;

--
-- Name: FUNCTION basename(text, text); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION basename(text, text) IS 'Return file path basename without extension';


--
-- Name: curl_get(text); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION curl_get(url text, OUT ok boolean, OUT response_code integer, OUT response_body text, OUT retcode integer, OUT error text) RETURNS record
    LANGUAGE plperlu
    AS $_$
my ($url)=@_;

use strict;
use warnings;
use WWW::Curl::Easy;

my $curl = WWW::Curl::Easy->new;
my %r;
  
$curl->setopt(CURLOPT_USERAGENT, "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.1) Gecko/20061204 Firefox/2.0.0.1");
$curl->setopt(CURLOPT_URL, $url);
$curl->setopt(CURLOPT_HEADER,0);
$curl->setopt(CURLOPT_FOLLOWLOCATION, 1);

# A filehandle, reference to a scalar or reference to a typeglob can be used here.
my $response_body;
$curl->setopt(CURLOPT_WRITEDATA,\$response_body);

# Starts the actual request
my $retcode = $curl->perform;

# Looking at the results...
$r{ok} = ($retcode==0)?'yes':'no';
$r{retcode} = $retcode;
$r{response_code} = $curl->getinfo(CURLINFO_HTTP_CODE);
$r{response_body} = $response_body;
$r{error} = $curl->strerror($retcode);

return \%r;
$_$;


ALTER FUNCTION datalink.curl_get(url text, OUT ok boolean, OUT response_code integer, OUT response_body text, OUT retcode integer, OUT error text) OWNER TO postgres;

--
-- Name: dirname(text); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dirname(text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_$
  my $str=shift; $str=~s|^(.*/)[^/]*$|$1|; return $str;
$_$;


ALTER FUNCTION datalink.dirname(text) OWNER TO postgres;

--
-- Name: FUNCTION dirname(text); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dirname(text) IS 'Return file path directory name';


--
-- Name: dl_chattr(datalink, dl_options); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_chattr(datalink, dl_options) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$begin
 update dl_url 
 set attr = $2
 where id=$1;
 return true;
end;
$_$;


ALTER FUNCTION datalink.dl_chattr(datalink, dl_options) OWNER TO postgres;

--
-- Name: FUNCTION dl_chattr(datalink, dl_options); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dl_chattr(datalink, dl_options) IS 'Set attributes for datalink';


--
-- Name: dl_chattr(name, name, name, dl_options); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_chattr(name, name, name, dl_options) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$declare
 my_id regclass;
begin
 select into my_id regclass
 from dl_columns
 where schema_name=$1
   and table_name=$2
   and column_name=$3; 

 if not found then
  raise exception 'DL0101: Not a datalink column';
 end if; 

 update dl_optionsdef 
 set attr = $4
 where schema_name=$1
   and table_name=$2
   and column_name=$3;

 if not found then
  insert into dl_optionsdef (schema_name,table_name,column_name,attr)
  values ($1,$2,$3,$4);
 end if;

 return true;
end;
$_$;


ALTER FUNCTION datalink.dl_chattr(name, name, name, dl_options) OWNER TO postgres;

--
-- Name: FUNCTION dl_chattr(name, name, name, dl_options); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dl_chattr(name, name, name, dl_options) IS 'Set attributes for datalink column';


--
-- Name: dl_get(datalink); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_get(datalink) RETURNS text
    LANGUAGE plperlu
    AS $_$use LWP::Simple; 
use Data::Dumper;

my $dl=shift;
my $p=spi_prepare('SELECT * FROM dl_url WHERE id=$1','numeric');
my $rv=spi_exec_prepared($p,$dl);
spi_freeplan($p);
my %dl=%{$rv->{rows}[0]};

if(defined($dl{fpath})) {
 if(-f $dl{fpath}) { 
  if(open(DL_GET,$dl{fpath})) { 
    my $d=join("",<DL_GET>); 
    close(DL_GET); 
    return $d; 
  } 
 }
}

if(defined($dl{url})) {
 my $page=get($dl{url}); 
 return $page; 
}

return undef;
$_$;


ALTER FUNCTION datalink.dl_get(datalink) OWNER TO postgres;

--
-- Name: dl_id(); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_id() RETURNS dl_id
    LANGUAGE sql
    AS $$select nextval('datalink.dl_id_seq')::datalink.dl_id$$;


ALTER FUNCTION datalink.dl_id() OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: dl_inode; Type: TABLE; Schema: datalink; Owner: datalink; Tablespace: 
--

CREATE TABLE dl_inode (
    dl_id dl_id DEFAULT dl_id() NOT NULL,
    space_id dl_id,
    dev numeric,
    ino numeric,
    basename text NOT NULL,
    ext text,
    mimetype text,
    size numeric NOT NULL,
    state text DEFAULT 'new'::text NOT NULL,
    owner text,
    path text,
    ctime timestamp with time zone,
    mtime timestamp with time zone,
    atime timestamp with time zone,
    flags text,
    blksize integer,
    rdev integer,
    blocks bigint,
    uid integer,
    mode integer,
    nlink integer,
    gid integer,
    md5sum text
);


ALTER TABLE dl_inode OWNER TO datalink;

--
-- Name: dl_inode(file_path); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_inode(file_path) RETURNS dl_inode
    LANGUAGE plperlu
    AS $_$
use Date::Format;
use Fcntl ':mode';
use Data::Dumper;

my ($file_path,$create)=@_;

my $base_info=spi_prepare(q{
  SELECT coalesce(base.archive_path,base.base_path) as base_path,
         substr($1,length(coalesce(base.prefix,base.base_path))+2) as file_path,
         coalesce(base.archive_path,base.base_path) || '/' ||
         substr($1,length(coalesce(base.prefix,base.base_path))+2) as local_path,
         base.* 
    FROM datalink.dl_space($1) AS base
   }, 'file_path');

my %base = %{spi_exec_prepared($base_info,$file_path)->{rows}->[0]};
elog(NOTICE,'base:'.Dumper(\%base));
if(!$base{base_id}) {
    elog(ERROR,'File base not found. HINT: Perhaps you need to add entries to dl_space?');
    return undef;
}

my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)
    = stat($base{local_path});
my $mimetype=`file --brief --mime $base{local_path}`; chop($mimetype);

my $file_info=spi_prepare(q{
  SELECT *,
         (mtime is distinct from $2) or
         (size is distinct from $3)
         as updated
    FROM datalink.dl_inode
   WHERE path=$1
   }, 'text','timestamptz','bigint');
my %file = %{spi_exec_prepared($file_info,$file_path,time2str('%C',$mtime),$size)
           ->{rows}->[0]};
elog(NOTICE,'file:'.Dumper(\%file));

if(!$ino) {
    return undef;
}

my $state='new';
if($file{updated}eq't') { $state='updated'; }
if($file{updated}eq'f') { $state='old'; }

my %inode = (
            state=>$state,
            dl_id=>$file{dl_id},
	    'basename'=>$base{local_path},
	    'path'=>$base{local_path},
            base_id=>$base{base_id},
            size=> $size,
            dev=> $dev,
            ino=> $ino,
#            mimetype=> S_ISDIR($mode)?'inode/directory':$mimetype,
            mimetype=> $mimetype,
	    'mode'=> $mode,
            nlink=> $nlink,
            uid=> $uid,
            gid=> $gid,
            rdev=> $rdev,
            atime=>time2str('%C',$atime),
            mtime=>time2str('%C',$mtime),
            ctime=>time2str('%C',$ctime),
            blksize=>$blksize,
            blocks=>$blocks  
        );

if(S_ISDIR($mode)) {
 $inode{'basename'}=~s|^.*/(.+?)/$|$1|;
} else {
 $inode{'basename'}=~s|^.*/||;
}

if($inode{'basename'}=~s|\.([^\.\/]+)$||) {
 $inode{ext}=$1;
}

return {%inode};

$_$;


ALTER FUNCTION datalink.dl_inode(file_path) OWNER TO postgres;

--
-- Name: dl_linker_backup(datalink, text); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_linker_backup(datalink, my_options text) RETURNS boolean
    LANGUAGE plperlu
    AS $_$my ($datalink,$lockp)=@_;

if($lockp) {
  elog(NOTICE,"lock($datalink)");
} else {
  elog(NOTICE,"unlock($datalink)");
}

return $lockp;
$_$;


ALTER FUNCTION datalink.dl_linker_backup(datalink, my_options text) OWNER TO postgres;

--
-- Name: FUNCTION dl_linker_backup(datalink, my_options text); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dl_linker_backup(datalink, my_options text) IS 'Datalinker - backup file';


--
-- Name: dl_linker_checkpoint(); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_linker_checkpoint() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
begin

 return true;
end
$$;


ALTER FUNCTION datalink.dl_linker_checkpoint() OWNER TO postgres;

--
-- Name: FUNCTION dl_linker_checkpoint(); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dl_linker_checkpoint() IS 'Datalinker - wait for datalinker to complete its work';


--
-- Name: dl_linker_delete(datalink); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_linker_delete(datalink) RETURNS boolean
    LANGUAGE plperlu
    AS $_$my ($datalink,$lockp)=@_;

if($lockp) {
  elog(NOTICE,"lock($datalink)");
} else {
  elog(NOTICE,"unlock($datalink)");
}

return $lockp;
$_$;


ALTER FUNCTION datalink.dl_linker_delete(datalink) OWNER TO postgres;

--
-- Name: FUNCTION dl_linker_delete(datalink); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dl_linker_delete(datalink) IS 'Datalinker - delete file';


--
-- Name: dl_linker_get(datalink); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_linker_get(datalink) RETURNS text
    LANGUAGE plperlu
    AS $$$$;


ALTER FUNCTION datalink.dl_linker_get(datalink) OWNER TO postgres;

--
-- Name: dl_linker_put(datalink, text); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_linker_put(datalink, text) RETURNS boolean
    LANGUAGE plperlu
    AS $$$$;


ALTER FUNCTION datalink.dl_linker_put(datalink, text) OWNER TO postgres;

--
-- Name: dl_linker_replace(datalink); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_linker_replace(datalink) RETURNS boolean
    LANGUAGE plperlu
    AS $_$my ($datalink,$lockp)=@_;

if($lockp) {
  elog(NOTICE,"lock($datalink)");
} else {
  elog(NOTICE,"unlock($datalink)");
}

return $lockp;
$_$;


ALTER FUNCTION datalink.dl_linker_replace(datalink) OWNER TO postgres;

--
-- Name: FUNCTION dl_linker_replace(datalink); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dl_linker_replace(datalink) IS 'Datalinker - replace file with a link to another file';


--
-- Name: dl_linker_sqlr(datalink, dl_read_access); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_linker_sqlr(datalink, dl_read_access) RETURNS boolean
    LANGUAGE plperlu
    AS $_$my ($datalink,$lockp)=@_;


if($lockp && !$locked) {
  elog(NOTICE,"lock($datalink)");
  # strip all read permissions and make readable to postgres
  # remember previous mode and owner
  # update dl_url set sqlr=true, mode = mode, uid = uid, gid = gid where id=$datalink;
  # chmod a-r $1 ; chown postgres.postgres $1
}

if(!$lockp && $locked) 
{
  elog(NOTICE,"unlock($datalink)");
  # update dl_url set sqlr=false where id=$datalink;
  # chmod mode $1; chown uid.gid $1
}

return $lockp;
$_$;


ALTER FUNCTION datalink.dl_linker_sqlr(datalink, dl_read_access) OWNER TO postgres;

--
-- Name: FUNCTION dl_linker_sqlr(datalink, dl_read_access); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dl_linker_sqlr(datalink, dl_read_access) IS 'Datalinker - set FS/DB read permissions';


--
-- Name: dl_linker_sqlw(datalink, dl_write_access); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_linker_sqlw(datalink, dl_write_access) RETURNS boolean
    LANGUAGE plperlu
    AS $_$my ($datalink,$lockp)=@_;

if($lockp) {
  elog(NOTICE,"lock($datalink)");
} else {
  elog(NOTICE,"unlock($datalink)");
}

return $lockp;
$_$;


ALTER FUNCTION datalink.dl_linker_sqlw(datalink, dl_write_access) OWNER TO postgres;

--
-- Name: FUNCTION dl_linker_sqlw(datalink, dl_write_access); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dl_linker_sqlw(datalink, dl_write_access) IS 'Datalinker - set FS/DB write permissions';


--
-- Name: dl_options(dl_link_control, dl_integrity, dl_read_access, dl_write_access, dl_recovery, dl_on_unlink); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_options(dl_link_control, dl_integrity, dl_read_access, dl_write_access, dl_recovery, dl_on_unlink) RETURNS dl_options
    LANGUAGE plperl
    AS $_$
 my @o=@_;
 my $o=0;

 if($o[5]eq'RESTORE') { $o += 1; }
 elsif($o[5]eq'DELETE') { $o += 2; }
 $o=$o*16;

 if($o[4]eq'YES') { $o += 1; }
 $o=$o*16;

 if($o[3]eq'BLOCKED') { $o += 3; }
 elsif($o[3]eq'ADMIN NOT REQUIRING TOKEN FOR UPDATE') { $o += 1; }
 elsif($o[3]eq'ADMIN REQUIRING TOKEN FOR UPDATE') { $o += 2; }

 $o=$o*16;
 if($o[2]eq'DB') { $o += 1; }

 $o=$o*16;
 if($o[1]eq'SELECTIVE') { $o += 1; }
 elsif($o[1]eq'ALL') { $o += 2; }

 $o=$o*16;
 if($o[0]eq'FILE') { $o += 1; }

 return $o;
$_$;


ALTER FUNCTION datalink.dl_options(dl_link_control, dl_integrity, dl_read_access, dl_write_access, dl_recovery, dl_on_unlink) OWNER TO postgres;

--
-- Name: dl_options_add(dl_options, dl_options); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_options_add(dl_options, dl_options) RETURNS dl_options
    LANGUAGE plperl
    AS $_$my ($a1,$a2)=@_;
my @a1=split("",$a1);
my @a2=split("",$a2);
my @pri=(
 {n=>0,f=>1},
 {n=>0,s=>1,a=>2},
 {f=>0,d=>1},
 {f=>0,b=>1,a=>2,t=>3},
 {n=>0,y=>1},
 {n=>0,r=>1,d=>2}
);
my @a3;
for my $i (0..5) {
  if($pri[$i]{$a1[$i]}>$pri[$i]{$a2[$i]}) { push @a3,$a1[$i]; }
  else { push @a3,$a2[$i]; }
}
#elog(ERROR,"Hello!");
return join("",@a3);

$_$;


ALTER FUNCTION datalink.dl_options_add(dl_options, dl_options) OWNER TO postgres;

--
-- Name: dl_options_default(); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_options_default() RETURNS dl_options
    LANGUAGE sql IMMUTABLE
    AS $$select 0::datalink.dl_options$$;


ALTER FUNCTION datalink.dl_options_default() OWNER TO postgres;

--
-- Name: dl_options_sql(dl_options); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_options_sql(dl_options) RETURNS text
    LANGUAGE plperl
    AS $_X$my $h=sprintf('%06x',$_[0]);
my @a=reverse(split('',$h));

elog(error,$h);

if(!$a[0]) { return 'NO LINK CONTROL'; }
else {
return join("  ",
 ["NO","FILE"]->[$a[0]]." LINK CONTROL",
  "INTEGRITY ".["NONE","SELECTIVE","ALL"]->[$a[1]],
  "READ PERMISSION ".["FS","DB"]->[$a[2]],
  "WRITE PERMISSION ".["FS",
                       "ADMIN NOT REQUIRING TOKEN FOR UPDATE",
                       "ADMIN REQUIRING TOKEN FOR UPDATE",
                       "BLOCKED"]->[$a[3]],
  "RECOVERY ".["NO","YES"]->[$a[4]],
  "ON UNLINK ".["NONE","RESTORE","DELETE"]->[$a[5]]
 );
}


$_X$;


ALTER FUNCTION datalink.dl_options_sql(dl_options) OWNER TO postgres;

--
-- Name: FUNCTION dl_options_sql(dl_options); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dl_options_sql(dl_options) IS 'Return datalink attributes as SQL compliant specification';


--
-- Name: dl_options_valid(text); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_options_valid(text) RETURNS boolean
    LANGUAGE plperl
    AS $_X$my $a={
 nnffnn=>"no control",
 fsffnn=>"file must exist when assigning",
 faffnn=>"file must exist and can be renamed or deleted",
 fafbnr=>"protect file from renaming and deletion",
 fafbyr=>"point-in-time recovery for file",
 fadbnr=>"read access thru db only (via datalinker)",
 fadbyr=>"read access thru db only (via datalinker)",
 fadbnd=>"delete when no more references to it exist",
 fadbyd=>"delete when no more references to it exist with rollback",
};
my $b={
 '00ff00'=>"no control",
 'fsff00'=>"file must exist when assigning",
 'faff00'=>"file must exist and can be renamed or deleted",
 'fafb01'=>"protect file from renaming and deletion",
 'fafb11'=>"point-in-time recovery for file",
 'fadb01'=>"read access thru db only (via datalinker)",
 'fadb11'=>"read access thru db only (via datalinker)",
 'fadb0d'=>"delete when no more references to it exist",
 'fadb1d'=>"delete when no more references to it exist with rollback",
};

if(defined($a->{$_[0]})) { return 1; }
if($_[0]=~m|^fad[ta][yn][rd]$|) { return 1; }
return 0;
$_X$;


ALTER FUNCTION datalink.dl_options_valid(text) OWNER TO postgres;

--
-- Name: FUNCTION dl_options_valid(text); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dl_options_valid(text) IS 'Validator for datalink attributes domain. It allows only values allowed by SQL/MED.';


--
-- Name: dl_prefix_id(url); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_prefix_id(url) RETURNS dl_id
    LANGUAGE sql
    AS $_$select b.id
from datalink.dl_prefix b
where $1 like b.prefix||'%'
order by length(prefix)
limit 1$_$;


ALTER FUNCTION datalink.dl_prefix_id(url) OWNER TO postgres;

--
-- Name: dl_purge(); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_purge() RETURNS integer
    LANGUAGE plpgsql
    AS $$declare
 n int;
begin
 delete from datalink.dl_url where ref <= 0;
 GET DIAGNOSTICS n = ROW_COUNT; 
 return n;
end
$$;


ALTER FUNCTION datalink.dl_purge() OWNER TO postgres;

--
-- Name: FUNCTION dl_purge(); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dl_purge() IS 'Purge unreferenced datalinks';


--
-- Name: dl_put(datalink, text); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_put(datalink, text) RETURNS integer
    LANGUAGE plperlu
    AS $$elog(error,"Not implemented!");

$$;


ALTER FUNCTION datalink.dl_put(datalink, text) OWNER TO postgres;

--
-- Name: dl_reconcile(); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_reconcile() RETURNS integer
    LANGUAGE plpgsql
    AS $$declare
 n int;
 r record;
begin
 n:=0;
 raise notice 'Updating foreign keys and triggers...';

 for r in
 select * 
   from datalink.dl_sql_advice
  where sql_identifier is null
 loop
  execute r.sql_advice;
  n:=n+1;
 end loop;

 return n;
end
$$;


ALTER FUNCTION datalink.dl_reconcile() OWNER TO postgres;

--
-- Name: dl_ref(datalink, dl_options); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_ref(datalink, dl_options) RETURNS integer
    LANGUAGE plpgsql
    AS $_$begin 
 update datalink.dl_url
 set 
  ref=coalesce(ref,0)+1
 where id=$1;

 return 1;
end$_$;


ALTER FUNCTION datalink.dl_ref(datalink, dl_options) OWNER TO postgres;

--
-- Name: FUNCTION dl_ref(datalink, dl_options); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dl_ref(datalink, dl_options) IS 'Trigger - reference a datalink';


--
-- Name: dl_setattr(datalink, name, text); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_setattr(datalink, name, text) RETURNS integer
    LANGUAGE plpgsql
    AS $$begin end$$;


ALTER FUNCTION datalink.dl_setattr(datalink, name, text) OWNER TO postgres;

--
-- Name: dl_space; Type: TABLE; Schema: datalink; Owner: datalink; Tablespace: 
--

CREATE TABLE dl_space (
    base_path file_path NOT NULL,
    space_id dl_id DEFAULT dl_id() NOT NULL,
    prefix file_path,
    archive_path file_path
);


ALTER TABLE dl_space OWNER TO datalink;

--
-- Name: dl_space(file_path); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_space(file_path) RETURNS dl_space
    LANGUAGE sql
    AS $_$
select * from datalink.dl_space where $1 like coalesce(prefix,base_path)||'%' 
$_$;


ALTER FUNCTION datalink.dl_space(file_path) OWNER TO postgres;

--
-- Name: dl_token(); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_token() RETURNS dl_token
    LANGUAGE sql
    AS $$
select (substr(to_char(now(),'YYYYMMDDHH24MISS'),2)||substr(to_char(dl_id(),'099999'),2))::dl_token
$$;


ALTER FUNCTION datalink.dl_token() OWNER TO postgres;

--
-- Name: dl_trigger(); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_trigger() RETURNS trigger
    LANGUAGE plperlu
    AS $_X$;
=pod

This is a trigger function used for updating reference counts on datalinks.
It should be enabled on all tables which have datalink columns.

=cut

 my $p=spi_prepare('SELECT column_name,control_options FROM datalink.dl_columns WHERE regclass = $1','oid');
 my $rv=spi_exec_prepared($p,$_TD->{relid});
 spi_freeplan($p);

 my %d;    # datalink changes

 for my $i (@{$rv->{rows}}) {
  my $c = $i->{column_name};
  next if !$c;
  if($_TD->{event} eq 'INSERT' || $_TD->{event} eq 'UPDATE') {
   if(defined($_TD->{new}{$c})) { 
    elog(NOTICE,"dl_ref($_TD->{new}{$c},$i->{control_options})");
    spi_exec_query("SELECT datalink.dl_ref($_TD->{new}{$c},$i->{control_options})");
    $d{$_TD->{new}{$c}}++;
   }
  }
  if($_TD->{event} eq 'DELETE' || $_TD->{event} eq 'UPDATE') {
   if(defined($_TD->{old}{$c})) { 
    elog(NOTICE,"dl_unref($_TD->{old}{$c})");
    spi_exec_query("SELECT datalink.dl_unref($_TD->{old}{$c})");
    $d{$_TD->{old}{$c}}--; 
   }
  }
 }
 
if($_TD->{event} eq 'DELETE') { return "SKIP"; }
return "MODIFY";
$_X$;


ALTER FUNCTION datalink.dl_trigger() OWNER TO postgres;

--
-- Name: dl_unref(datalink); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_unref(datalink) RETURNS integer
    LANGUAGE plpgsql
    AS $_$begin 
 update datalink.dl_url
 set 
  ref=ref-1
 where id=$1;

 return 1;
end$_$;


ALTER FUNCTION datalink.dl_unref(datalink) OWNER TO postgres;

--
-- Name: FUNCTION dl_unref(datalink); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dl_unref(datalink) IS 'Trigger - unreference a datalink';


--
-- Name: dl_update_triggers(); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_update_triggers() RETURNS text
    LANGUAGE plpgsql
    AS $$declare
 my_sql text;
 r record;
 n integer;
begin
 my_sql:=''; n:=0;
 for r in
  select 
      datalink.sql_identifier(c.schema_name,c.table_name) as sql_identifier,
      t.trigger_name 
    from dl_columns c left join datalink.triggers t on t.regclass=c.regclass 
   where trigger_name='DL_RI_trigger' or trigger_name is null loop
  if r.trigger_name is null then
    my_sql:=my_sql||
           'CREATE TRIGGER "DL_RI_trigger"'||
           ' AFTER INSERT OR DELETE OR UPDATE ON '||r.sql_identifier||
           ' FOR EACH ROW EXECUTE PROCEDURE datalink.dl_trigger();';
    n:=n+1;
  end if;
 end loop;
 if n>0 then execute my_sql; end if;
 return my_sql;
end
$$;


ALTER FUNCTION datalink.dl_update_triggers() OWNER TO postgres;

--
-- Name: dl_url_init(); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_url_init() RETURNS trigger
    LANGUAGE plperlu
    AS $_X$use URI;

my $p;

if($_TD->{event} eq 'DELETE') { return; }

$_TD->{new}{url}=~s|^\s*||;
$_TD->{new}{url}=~s|\s*$||;
my $u=URI->new($_TD->{new}{url});
$_TD->{new}{url}=$u->canonical;
$_TD->{new}{scheme}=uc($u->scheme);
$_TD->{new}{authority}=$u->authority;

if($_TD->{new}{scheme} eq 'FILE') {
 if($_TD->{new}{authority} eq '') {
   $_TD->{new}{authority}='localhost';
 }
}

$_TD->{new}{sqlr}=($_TD->{new}{attr}=~m|^f.d|)?1:0;
$_TD->{new}{sqlw}=($_TD->{new}{attr}=~m|^f..[ta]|)?1:0;

if($_TD->{new}{attr} =~ m|^f|) {
  unless($_TD->{new}{fpath}=~m|^/|) {
   elog(ERROR,"DL0003:$_TD->{new}{id}:no local path for file link control; perhaps you need to add a base in dl_prefix");
  }
  unless(-f $_TD->{new}{fpath}) {
   elog(ERROR,"DL0002:$_TD->{new}{id}:referenced file does not exist:$_TD->{new}{path}");
  }
}

if($_TD->{new}{fpath}=~m|^/|) {
  if($_TD->{new}{attr} =~ m|^fa.[tab]| ) {
   $p=spi_prepare('SELECT dl_linker_lock($1,true)','numeric');
  } else {
   $p=spi_prepare('SELECT dl_linker_lock($1,false)','numeric');
  }
  spi_exec_prepared($p,$_TD->{new}{fpath});
  spi_freeplan($p);
}

return "MODIFY";
$_X$;


ALTER FUNCTION datalink.dl_url_init() OWNER TO postgres;

--
-- Name: dl_url_touch(); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_url_touch() RETURNS trigger
    LANGUAGE plpgsql
    AS $$begin 
 if TG_OP = 'DELETE' then
  return old;
 end if;

 new.base_id := dl_prefix_id(new.url);

 return new;
end

$$;


ALTER FUNCTION datalink.dl_url_touch() OWNER TO postgres;

--
-- Name: dl_url_valid(text); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dl_url_valid(text) RETURNS boolean
    LANGUAGE plperl
    AS $_X$if($_[0]=~m!^(https?|file):!) { return 1; }
return 0;
$_X$;


ALTER FUNCTION datalink.dl_url_valid(text) OWNER TO postgres;

--
-- Name: dlcomment(datalink); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dlcomment(datalink) RETURNS text
    LANGUAGE sql STRICT
    AS $_$select comment from datalink.dl_url where id=$1$_$;


ALTER FUNCTION datalink.dlcomment(datalink) OWNER TO postgres;

--
-- Name: FUNCTION dlcomment(datalink); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dlcomment(datalink) IS 'SQL/MED - returns the comment value, if it exists, from a DATALINK value';


--
-- Name: dllinktype(datalink); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dllinktype(datalink) RETURNS text
    LANGUAGE sql
    AS $_$select linktype::text from datalink.dl_url where id=$1$_$;


ALTER FUNCTION datalink.dllinktype(datalink) OWNER TO postgres;

--
-- Name: FUNCTION dllinktype(datalink); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dllinktype(datalink) IS 'SQL/MED - returns the linktype value from a DATALINK value';


--
-- Name: dlnewcopy(url, integer); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dlnewcopy(url, has_token integer) RETURNS datalink
    LANGUAGE plpgsql
    AS $_$declare
 id datalink.dl_id;
begin
 insert into dl_url (url)
 values ($1);
 id:=dlpreviouscopy($1,$2);
 return id::datalink.datalink;
end;
$_$;


ALTER FUNCTION datalink.dlnewcopy(url, has_token integer) OWNER TO postgres;

--
-- Name: FUNCTION dlnewcopy(url, has_token integer); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dlnewcopy(url, has_token integer) IS 'SQL/MED - returns a DATALINK value which has an attribute indicating that the referenced file has changed.';


--
-- Name: dlpreviouscopy(url, integer); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dlpreviouscopy(url, has_token integer) RETURNS datalink
    LANGUAGE sql
    AS $_$select id::datalink.datalink from datalink.dl_url where url=datalink.url_canonical($1)

$_$;


ALTER FUNCTION datalink.dlpreviouscopy(url, has_token integer) OWNER TO postgres;

--
-- Name: FUNCTION dlpreviouscopy(url, has_token integer); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dlpreviouscopy(url, has_token integer) IS 'SQL/MED - returns a DATALINK value which has an attribute indicating that the previous version of the file should be restored.';


--
-- Name: dlreplacecontent(url, url, text); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dlreplacecontent(target url, source url, comment text) RETURNS datalink
    LANGUAGE sql
    AS $$select 1::datalink.datalink;

$$;


ALTER FUNCTION datalink.dlreplacecontent(target url, source url, comment text) OWNER TO postgres;

--
-- Name: FUNCTION dlreplacecontent(target url, source url, comment text); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dlreplacecontent(target url, source url, comment text) IS 'SQL/MED - returns a DATALINK value. Returned value results in replacing the content of a file by another file and then creating a link to it.';


--
-- Name: dlurlcomplete(datalink); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dlurlcomplete(datalink) RETURNS uri
    LANGUAGE sql STRICT SECURITY DEFINER
    AS $_$
select url::datalink.uri 
  from datalink.dl_url where id=$1
$_$;


ALTER FUNCTION datalink.dlurlcomplete(datalink) OWNER TO postgres;

--
-- Name: FUNCTION dlurlcomplete(datalink); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dlurlcomplete(datalink) IS 'SQL/MED - returns the data location attribute from a DATALINK value with a link type of URL';


--
-- Name: dlurlcompleteonly(datalink); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dlurlcompleteonly(datalink) RETURNS uri
    LANGUAGE sql STRICT
    AS $_$select datalink.dlurlcomplete($1)$_$;


ALTER FUNCTION datalink.dlurlcompleteonly(datalink) OWNER TO postgres;

--
-- Name: dlurlcompletewrite(datalink); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dlurlcompletewrite(datalink) RETURNS uri
    LANGUAGE sql STRICT
    AS $_$select datalink.dlurlcomplete($1)$_$;


ALTER FUNCTION datalink.dlurlcompletewrite(datalink) OWNER TO postgres;

--
-- Name: dlurlpath(datalink); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dlurlpath(datalink) RETURNS file_path
    LANGUAGE sql
    AS $_$select fpath::datalink.file_path from datalink.dl_url where id=$1$_$;


ALTER FUNCTION datalink.dlurlpath(datalink) OWNER TO postgres;

--
-- Name: FUNCTION dlurlpath(datalink); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dlurlpath(datalink) IS 'SQL/MED - returns the path and file name necessary to access a file within a given server from a DATALINK value with a linktype of URL';


--
-- Name: dlurlpath(uri); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dlurlpath(uri) RETURNS file_path
    LANGUAGE sql STRICT
    AS $_$
select (base||substr(u.url,length(prefix)+1))::datalink.file_path
from datalink.dl_url u join datalink.dl_prefix b on (u.url like b.prefix||'%')
where u.url=$1$_$;


ALTER FUNCTION datalink.dlurlpath(uri) OWNER TO postgres;

--
-- Name: dlurlpathonly(datalink); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dlurlpathonly(datalink) RETURNS url
    LANGUAGE sql
    AS $_$select url::datalink.url from datalink.dl_url where id=$1$_$;


ALTER FUNCTION datalink.dlurlpathonly(datalink) OWNER TO postgres;

--
-- Name: FUNCTION dlurlpathonly(datalink); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dlurlpathonly(datalink) IS 'SQL/MED - returns the path and file name necessary to access a file within a given server from a DATALINK value with a linktype of URL';


--
-- Name: dlurlpathwrite(datalink); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dlurlpathwrite(datalink) RETURNS url
    LANGUAGE sql
    AS $_$select url::datalink.url from datalink.dl_url where id=$1
$_$;


ALTER FUNCTION datalink.dlurlpathwrite(datalink) OWNER TO postgres;

--
-- Name: FUNCTION dlurlpathwrite(datalink); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dlurlpathwrite(datalink) IS 'SQL/MED - returns the path and file name necessary to access a file within a given server from a DATALINK value with a linktype of URL';


--
-- Name: dlurlscheme(datalink); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dlurlscheme(datalink) RETURNS text
    LANGUAGE sql
    AS $_$select upper(datalink.url_part('scheme',url)) as scheme
from datalink.dl_url where id=$1$_$;


ALTER FUNCTION datalink.dlurlscheme(datalink) OWNER TO postgres;

--
-- Name: FUNCTION dlurlscheme(datalink); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dlurlscheme(datalink) IS 'SQL/MED - returns the scheme from a DATALINK value with a linktype of URL';


--
-- Name: dlurlserver(datalink); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dlurlserver(datalink) RETURNS text
    LANGUAGE sql
    AS $_$select datalink.url_part('host',url) from datalink.dl_url where id=$1$_$;


ALTER FUNCTION datalink.dlurlserver(datalink) OWNER TO postgres;

--
-- Name: FUNCTION dlurlserver(datalink); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dlurlserver(datalink) IS 'SQL/MED - returns the file server from a DATALINK value with a linktype of URL';


--
-- Name: dlvalue(url); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dlvalue(url) RETURNS datalink
    LANGUAGE plpgsql
    AS $_$begin
 return datalink.dlvalue($1,'URL',NULL);
end
$_$;


ALTER FUNCTION datalink.dlvalue(url) OWNER TO postgres;

--
-- Name: FUNCTION dlvalue(url); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dlvalue(url) IS 'SQL/MED - return DATALINK value of type URL';


--
-- Name: dlvalue(text); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dlvalue(text) RETURNS datalink
    LANGUAGE plpgsql
    AS $_$begin
 return datalink.dlvalue($1,'URL',NULL);
end
$_$;


ALTER FUNCTION datalink.dlvalue(text) OWNER TO postgres;

--
-- Name: dlvalue(text, name); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dlvalue(text, name) RETURNS datalink
    LANGUAGE plpgsql
    AS $_$begin
 return datalink.dlvalue($1,$2,NULL);
end
$_$;


ALTER FUNCTION datalink.dlvalue(text, name) OWNER TO postgres;

--
-- Name: FUNCTION dlvalue(text, name); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dlvalue(text, name) IS 'SQL/MED - return DATALINK value of any type';


--
-- Name: dlvalue(text, name, text); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION dlvalue(text, name, text) RETURNS datalink
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$declare
 my_address alias for $1;
 my_linktype alias for $2;
 my_comment alias for $3;

 my_id datalink.dl_id;
 my_url datalink.uri;
 my_fpath datalink.file_path;
begin
 if my_linktype not in ('URL','FS') then
  raise exception 'DL0102:linktype must be URL or FS';
 end if;

 if my_linktype = 'URL' then
  my_url := datalink.url_canonical(my_address);
  my_fpath := datalink.dlurlpath(my_address);
  select into my_id
   id from datalink.dl_url where url=my_url;
 end if;

 if my_linktype = 'FS' then
  my_fpath := my_address;
  select into my_id
   id from datalink.dl_url where fpath=my_fpath;
 end if;

 if not found then
   my_id := datalink.dl_id();
   insert into datalink.dl_url (id,url,cons,linktype,comment)
   values (my_id,my_url,'v',my_linktype,my_comment);
 end if;

 return my_id;
end
$_$;


ALTER FUNCTION datalink.dlvalue(text, name, text) OWNER TO postgres;

--
-- Name: FUNCTION dlvalue(text, name, text); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION dlvalue(text, name, text) IS 'SQL/MED - return DATALINK value of any type with comment';


--
-- Name: file_abort(file_handle); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION file_abort(file_handle) RETURNS name
    LANGUAGE plperlu
    AS $_X$
my $fh=shift;

if(!defined($_SHARED{$fh})) {
	elog(ERROR,'Illegal file handle. HINT: Use file_begin() first!');
} 
close $fh;
delete $_SHARED{$fh};
$_X$;


ALTER FUNCTION datalink.file_abort(file_handle) OWNER TO postgres;

--
-- Name: FUNCTION file_abort(file_handle); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION file_abort(file_handle) IS 'FILEIO - abort writing to a file';


--
-- Name: file_begin(file_path); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION file_begin(file_path) RETURNS file_handle
    LANGUAGE plperlu
    AS $_X$
my $file=shift;
my %q=(
 base_info=>spi_prepare('
  SELECT 
      datalink.dl_id(),
      coalesce(base.archive_path,base.base_path) as base_path,
      trim(coalesce(base.prefix,base.base_path) from $1) as file_path,
      base.* 
    FROM datalink.dl_space($1) AS base', 'datalink.file_path'),
);
my $base = spi_exec_prepared($q{base_info},$file)->{rows}->[0];
if(!$base->{space_id}) {
    elog(ERROR,'File space not found. HINT: Perhaps you need to add entries to dl_space?');
    return undef;
}
my %file;
$file{fh}=$base->{dl_id};
$file{space_id}=$base->{space_id};
$file{full_path}=$base->{base_path}.'/'.$base->{file_path}.','.$base->{dl_id};
$file{file_path}=$base->{file_path};
elog(NOTICE,'full_path:'.$file{full_path});
if(open($file{fh},">",$file{full_path})) {
  $_SHARED{$file{fh}}=\%file;
  chmod 0644, $file{full_path};
  return $file{fh};
} else {
 elog(ERROR,'Cannot open file for writing:'.$file{full_path});
 return undef;
}
$_X$;


ALTER FUNCTION datalink.file_begin(file_path) OWNER TO postgres;

--
-- Name: FUNCTION file_begin(file_path); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION file_begin(file_path) IS 'FILEIO - create new file for writing';


--
-- Name: file_end(file_handle); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION file_end(file_handle) RETURNS numeric
    LANGUAGE plperlu
    AS $_X$
my $fh=shift;

if(!defined($_SHARED{$fh})) {
 elog(ERROR,'Illegal file handle. HINT: Use file_begin() first!');
} 
close $fh;
delete $_SHARED{$fh};
return 1;

$_X$;


ALTER FUNCTION datalink.file_end(file_handle) OWNER TO postgres;

--
-- Name: FUNCTION file_end(file_handle); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION file_end(file_handle) IS 'FILEIO - finnish writing to a file';


--
-- Name: file_find(file_path); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION file_find(file_path) RETURNS dl_inode
    LANGUAGE plpgsql
    AS $_$
declare
 my_node datalink.dl_inode;
 my_dl_id bigint;
begin
 my_node:=datalink.dl_inode($1);

 if my_node.path is not null then
  if my_node.dl_id is null then
   my_node.dl_id:=datalink.dl_id();
   insert into datalink.dl_inode values (my_node.*)
   returning *
        into my_node;
  else
   if my_node.state='updated' then
    update datalink.dl_inode
       set mtime=my_node.mtime,
           size=my_node.size
     where dl_id=my_node.dl_id;
   end if;
  end if;
 end if;
 
 return my_node;
end
$_$;


ALTER FUNCTION datalink.file_find(file_path) OWNER TO postgres;

--
-- Name: file_get(file_path); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION file_get(file_path) RETURNS text
    LANGUAGE plperlu
    AS $_$my $file=shift;
if(-f $file) {
  if(open(Fi,$file)) {
    $d=join("",<Fi>);
    close(Fi);
    return $d;
  }
}
elog(ERROR,"File not found: <$file>");

return undef;
$_$;


ALTER FUNCTION datalink.file_get(file_path) OWNER TO postgres;

--
-- Name: file_list(file_path); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION file_list(file_path) RETURNS SETOF dl_inode
    LANGUAGE plperlu
    AS $_$use Date::Format;
use Fcntl ':mode';

my $file=shift;
my %q=(
 base_info=>spi_prepare('
  SELECT 
      coalesce(base.archive_path,base.base_path) as base_path,
      trim(coalesce(base.prefix,base.base_path) from $1) as file_path,
      base.* 
    FROM datalink.dl_space($1) AS base', 'file_path'),
);
my $base = spi_exec_prepared($q{base_info},$file)->{rows}->[0];
if(!$base->{space_id}) {
    elog(ERROR,'File base not found. HINT: Perhaps you need to add entries to dl_space?');
    return undef;
}
my %file;
$file{fh}='DL_RD_FH';
$file{space_id}=$base->{space_id};
$file{full_path}=$base->{base_path}.'/'.$base->{file_path};
if(opendir($file{fh},$file{full_path})) {
  while(my $i=readdir($file{fh})) {
  my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)
    = stat($file{full_path}."/".$i);
    my %inode = (
	    'basename'=>$i,
	    'path'=>$file{full_path}."/".$i,
            space_id=>$base{space_id},
            size=> $size,
            dev=> $dev,
            ino=> $ino,
            owner=> [getpwuid($uid)]->[0],
            mimetype=> S_ISDIR($mode)?'inode/directory':undef,
	    'mode'=> $mode,
            nlink=> $nlink,
            uid=> $uid,
            gid=> $gid,
            rdev=> $rdev,
            atime=>time2str('%C',$atime),
            mtime=>time2str('%C',$mtime),
            ctime=>time2str('%C',$ctime),
            blksize=>$blksize,
            blocks=>$blocks  
        );
	return_next(\%inode);
  }
  closedir($file{fh});
  return undef;
} else {
 elog(ERROR,'Cannot open file for listing:'.$file{full_path});
 return undef;
}
$_$;


ALTER FUNCTION datalink.file_list(file_path) OWNER TO postgres;

--
-- Name: file_put(file_path, text); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION file_put(file_path, text) RETURNS numeric
    LANGUAGE plpgsql
    AS $_$declare
 my_fh datalink.file_handle;
 n numeric;
begin
 my_fh := datalink.file_begin($1);
 n := datalink.file_write(my_fh,$2);
 perform datalink.file_end(my_fh);

 return my_fh;
end
$_$;


ALTER FUNCTION datalink.file_put(file_path, text) OWNER TO postgres;

--
-- Name: file_write(file_handle, text); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION file_write(file_handle, text) RETURNS numeric
    LANGUAGE plperlu
    AS $_X$
my $fh=shift;
if(!defined($_SHARED{$fh})) {
	elog(ERROR,'Illegal file handle. HINT: Use file_begin() first!');
} else {
	print {$fh} $_[0];
}
return length($_[0]);
$_X$;


ALTER FUNCTION datalink.file_write(file_handle, text) OWNER TO postgres;

--
-- Name: FUNCTION file_write(file_handle, text); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION file_write(file_handle, text) IS 'FILEIO - append text to a file';


--
-- Name: ri_datalink(); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION ri_datalink() RETURNS trigger
    LANGUAGE plperlu
    AS $_X$use URI;

elog(ERROR,'not implemented');

if($_TD->{event} eq 'DELETE') { return; }

$_TD->{new}{url}=~s|^\s*||;
$_TD->{new}{url}=~s|\s*$||;
my $u=URI->new($_TD->{new}{url});
$_TD->{new}{url}=$u->canonical;
$_TD->{new}{scheme}=uc($u->scheme);
$_TD->{new}{authority}=$u->authority;
$_TD->{new}{path}=$u->path;

if($_TD->{new}{scheme} eq 'FILE') {
 if($_TD->{new}{authority} eq '') {
   $_TD->{new}{authority}='localhost';
 }
}

if($_TD->{new}{link_control} eq 'FILE') {
 if($_TD->{new}{scheme} ne 'FILE') {
  elog(ERROR,"DL0001:FILE LINK CONTROL suported only for file:// scheme:$_TD->{new}{url}");
 } else {
  unless(-f $_TD->{new}{path}) {
   elog(ERROR,"DL0002:referenced file does not exist:$_TD->{new}{path}");
  }

  my $p;
  if($_TD->{new}{integrity} eq 'ALL') {
   $p=spi_prepare('SELECT datalink.file_lock($1,true)','uri');
  } else {
   $p=spi_prepare('SELECT datalink.file_lock($1,false)','uri');
  }
  spi_exec_prepared($p,$_TD->{new}{path});
  spi_freeplan($p);
 }
}
 
return "MODIFY";
$_X$;


ALTER FUNCTION datalink.ri_datalink() OWNER TO postgres;

--
-- Name: sql_identifier(name, name); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION sql_identifier(name, name) RETURNS text
    LANGUAGE sql STABLE
    AS $_$SELECT regclass(quote_ident($1)||'.'||quote_ident($2))::text$_$;


ALTER FUNCTION datalink.sql_identifier(name, name) OWNER TO postgres;

--
-- Name: url_canonical(url); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION url_canonical(url) RETURNS url
    LANGUAGE plperlu
    AS $_X$use URI; 
my $u=URI->new($_[0]); 
if($u->query() eq '') { $u->query(undef); }
if($u->fragment() eq '') { $u->fragment(undef); }
return $u->canonical;
$_X$;


ALTER FUNCTION datalink.url_canonical(url) OWNER TO postgres;

--
-- Name: FUNCTION url_canonical(url); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION url_canonical(url) IS 'return canonical form of URL';


--
-- Name: url_get(url); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION url_get(url) RETURNS text
    LANGUAGE plperlu
    AS $_$use LWP::Simple; 
my ($url)=@_;

if(defined($url)) {
 my $page=get($url); 
 return $page; 
}

return undef;
$_$;


ALTER FUNCTION datalink.url_get(url) OWNER TO postgres;

--
-- Name: url_part(text, url); Type: FUNCTION; Schema: datalink; Owner: postgres
--

CREATE FUNCTION url_part(text, url) RETURNS url
    LANGUAGE plperlu
    AS $_X$use URI; 
my $part=shift; lc($part);
my $u=URI->new($_[0]); 
if($part eq 'scheme') { return $u->scheme(); }
if($part eq 'path') { return $u->path(); }
if($part eq 'authority') { return $u->authority(); }
if($part eq 'path_query') { return $u->path_query(); }
if($part eq 'query_form') { return $u->query_form(); }
if($part eq 'query_keywords') { return $u->query_keywords(); }
if($part eq 'userinfo') { return $u->userinfo(); }
if($part eq 'host') { return $u->host(); }
if($part eq 'domain') { my $d = $u->host(); $d=~s|^www\.||; return $d; }
if($part eq 'port') { return $u->port(); }
if($part eq 'host_port') { return $u->host_port(); }
if($part eq 'query') { return $u->query(); }
if($part eq 'fragment') { return $u->fragment(); }
if($part eq 'canonical') { return $u->canonical(); }
elog(ERROR,"Unknown part '$path'.");
$_X$;


ALTER FUNCTION datalink.url_part(text, url) OWNER TO postgres;

--
-- Name: FUNCTION url_part(text, url); Type: COMMENT; Schema: datalink; Owner: postgres
--

COMMENT ON FUNCTION url_part(text, url) IS 'extract part of URL';


--
-- Name: dl_optionsdef; Type: TABLE; Schema: datalink; Owner: datalink; Tablespace: 
--

CREATE TABLE dl_optionsdef (
    schema_name name NOT NULL,
    table_name name NOT NULL,
    column_name name NOT NULL,
    control_options dl_options DEFAULT 0 NOT NULL
);


ALTER TABLE dl_optionsdef OWNER TO datalink;

--
-- Name: TABLE dl_optionsdef; Type: COMMENT; Schema: datalink; Owner: datalink
--

COMMENT ON TABLE dl_optionsdef IS 'Current link control options; this should really go to pg_attribute.atttypmod';


--
-- Name: dl_columns; Type: VIEW; Schema: datalink; Owner: postgres
--

CREATE VIEW dl_columns AS
 SELECT s.nspname AS schema_name,
    c.relname AS table_name,
    a.attname AS column_name,
    COALESCE((ad.control_options)::integer, 0) AS control_options,
    a.attnotnull AS not_null,
    col_description(c.oid, (a.attnum)::integer) AS comment,
    a.attislocal AS islocal,
    a.attnum AS ord,
    ((sql_identifier(s.nspname, c.relname) || '.'::text) || quote_ident((a.attname)::text)) AS sql_identifier,
    c.oid AS regclass,
    ((((((quote_ident((a.attname)::text) || ' '::text) || format_type(t.oid, NULL::integer)) ||
        CASE
            WHEN ((a.atttypmod - 4) > 65536) THEN (((('('::text || ((a.atttypmod - 4) / 65536)) || ','::text) || ((a.atttypmod - 4) % 65536)) || ')'::text)
            WHEN ((a.atttypmod - 4) > 0) THEN (('('::text || (a.atttypmod - 4)) || ')'::text)
            ELSE ''::text
        END) || ' '::text) || dl_options_sql((COALESCE((ad.control_options)::integer, 0))::dl_options)) ||
        CASE
            WHEN a.attnotnull THEN ' NOT NULL'::text
            ELSE ''::text
        END) AS definition
   FROM ((((((pg_class c
     JOIN pg_namespace s ON ((s.oid = c.relnamespace)))
     JOIN pg_attribute a ON ((c.oid = a.attrelid)))
     LEFT JOIN pg_attrdef def ON (((c.oid = def.adrelid) AND (a.attnum = def.adnum))))
     LEFT JOIN pg_type t ON ((t.oid = a.atttypid)))
     JOIN pg_namespace tn ON ((tn.oid = t.typnamespace)))
     LEFT JOIN dl_optionsdef ad ON ((((ad.schema_name = s.nspname) AND (ad.table_name = c.relname)) AND (ad.column_name = a.attname))))
  WHERE ((((((c.relkind = 'r'::"char") AND (a.attnum > 0)) AND (t.typname = 'datalink'::name)) AND (NOT a.attisdropped)) AND has_table_privilege(c.oid, 'select'::text)) AND has_schema_privilege(s.oid, 'usage'::text))
  ORDER BY s.nspname, c.relname, a.attnum;


ALTER TABLE dl_columns OWNER TO postgres;

--
-- Name: dl_columns_stats; Type: VIEW; Schema: datalink; Owner: datalink
--

CREATE VIEW dl_columns_stats AS
 SELECT s.nspname AS schema_name,
    c.relname AS table_name,
    a.attname AS column_name,
    COALESCE((ad.control_options)::integer, 0) AS control_options,
    a.attnotnull AS not_null,
    col_description(c.oid, (a.attnum)::integer) AS comment,
    a.attislocal AS islocal,
    a.attnum AS ord,
    ((sql_identifier(s.nspname, c.relname) || '.'::text) || quote_ident((a.attname)::text)) AS sql_identifier,
    st.stanullfrac AS "NullF",
        CASE
            WHEN (st.stadistinct < (0)::double precision) THEN (- st.stadistinct)
            ELSE NULL::real
        END AS "DistF",
    (
        CASE
            WHEN (st.stadistinct >= (0)::double precision) THEN st.stadistinct
            ELSE NULL::real
        END)::integer AS "DistN",
    c.oid AS regclass,
    ((((((quote_ident((a.attname)::text) || ' '::text) || format_type(t.oid, NULL::integer)) ||
        CASE
            WHEN ((a.atttypmod - 4) > 65536) THEN (((('('::text || ((a.atttypmod - 4) / 65536)) || ','::text) || ((a.atttypmod - 4) % 65536)) || ')'::text)
            WHEN ((a.atttypmod - 4) > 0) THEN (('('::text || (a.atttypmod - 4)) || ')'::text)
            ELSE ''::text
        END) || ' '::text) || dl_options_sql((COALESCE((ad.control_options)::integer, 0))::dl_options)) ||
        CASE
            WHEN a.attnotnull THEN ' NOT NULL'::text
            ELSE ''::text
        END) AS definition
   FROM (((((((pg_class c
     JOIN pg_namespace s ON ((s.oid = c.relnamespace)))
     JOIN pg_attribute a ON ((c.oid = a.attrelid)))
     LEFT JOIN pg_attrdef def ON (((c.oid = def.adrelid) AND (a.attnum = def.adnum))))
     LEFT JOIN pg_type t ON ((t.oid = a.atttypid)))
     JOIN pg_namespace tn ON ((tn.oid = t.typnamespace)))
     LEFT JOIN pg_statistic st ON (((st.starelid = c.oid) AND (st.staattnum = a.attnum))))
     LEFT JOIN dl_optionsdef ad ON ((((ad.schema_name = s.nspname) AND (ad.table_name = c.relname)) AND (ad.column_name = a.attname))))
  WHERE ((((((c.relkind = 'r'::"char") AND (a.attnum > 0)) AND (t.typname = 'datalink'::name)) AND (NOT a.attisdropped)) AND has_table_privilege(c.oid, 'select'::text)) AND has_schema_privilege(s.oid, 'usage'::text))
  ORDER BY s.nspname, c.relname, a.attnum;


ALTER TABLE dl_columns_stats OWNER TO datalink;

--
-- Name: dl_id_seq; Type: SEQUENCE; Schema: datalink; Owner: datalink
--

CREATE SEQUENCE dl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dl_id_seq OWNER TO datalink;

--
-- Name: dl_prefix; Type: TABLE; Schema: datalink; Owner: datalink; Tablespace: 
--

CREATE TABLE dl_prefix (
    id dl_id DEFAULT dl_id() NOT NULL,
    name name,
    prefix character varying NOT NULL,
    base character varying NOT NULL
);


ALTER TABLE dl_prefix OWNER TO datalink;

--
-- Name: TABLE dl_prefix; Type: COMMENT; Schema: datalink; Owner: datalink
--

COMMENT ON TABLE dl_prefix IS 'Valid prefixes/directories for datalinks';


--
-- Name: COLUMN dl_prefix.name; Type: COMMENT; Schema: datalink; Owner: datalink
--

COMMENT ON COLUMN dl_prefix.name IS 'optional name';


--
-- Name: dl_sql_advice; Type: VIEW; Schema: datalink; Owner: datalink
--

CREATE VIEW dl_sql_advice AS
 SELECT 'TRIGGER'::text AS advice_type,
    quote_ident((t.tgname)::text) AS sql_identifier,
    (('CREATE CONSTRAINT TRIGGER "DL_RI_trigger"    
  AFTER INSERT OR UPDATE OR DELETE   
  ON '::text || dl_c.sql_identifier) || '   
  FOR EACH ROW    
  EXECUTE PROCEDURE datalink.dl_trigger()   
 '::text) AS sql_advice
   FROM (( SELECT DISTINCT dl_columns.schema_name,
            dl_columns.table_name,
            ((quote_ident((dl_columns.schema_name)::text) || '.'::text) || quote_ident((dl_columns.table_name)::text)) AS sql_identifier,
            dl_columns.regclass
           FROM dl_columns_stats dl_columns
          ORDER BY dl_columns.schema_name, dl_columns.table_name, ((quote_ident((dl_columns.schema_name)::text) || '.'::text) || quote_ident((dl_columns.table_name)::text)), dl_columns.regclass) dl_c
     LEFT JOIN pg_trigger t ON (((t.tgrelid = dl_c.regclass) AND (t.tgname = 'DL_RI_trigger'::name))))
UNION
 SELECT 'CONSTRAINT'::text AS advice_type,
    quote_ident((c.conname)::text) AS sql_identifier,
    (((((('ALTER TABLE '::text || quote_ident((dl_columns.schema_name)::text)) || '.'::text) || quote_ident((dl_columns.table_name)::text)) || '   
  ADD CONSTRAINT "DL_RI_constraint"    
  FOREIGN KEY ('::text) || quote_ident((dl_columns.column_name)::text)) || ')   
  REFERENCES datalink.dl_url(id)'::text) AS sql_advice
   FROM (dl_columns_stats dl_columns
     LEFT JOIN pg_constraint c ON (((c.conrelid = dl_columns.regclass) AND (c.conname = 'DL_RI_constraint'::name))));


ALTER TABLE dl_sql_advice OWNER TO datalink;

--
-- Name: dl_url; Type: TABLE; Schema: datalink; Owner: datalink; Tablespace: 
--

CREATE TABLE dl_url (
    id dl_id DEFAULT dl_id() NOT NULL,
    url text NOT NULL,
    scheme name NOT NULL,
    authority text,
    ref integer DEFAULT 0,
    attr dl_options DEFAULT dl_options_default() NOT NULL,
    base_id dl_id,
    sqlr boolean DEFAULT false,
    sqlw boolean DEFAULT false,
    cons character(1) NOT NULL,
    token dl_token,
    comment text,
    linktype name,
    attrs integer[],
    dl_id dl_id,
    dlrelid oid,
    CONSTRAINT dl_url_cons_check CHECK ((cons = ANY (ARRAY['v'::bpchar, 'n'::bpchar, 'p'::bpchar]))),
    CONSTRAINT dl_url_url_check CHECK (dl_url_valid(url))
);


ALTER TABLE dl_url OWNER TO datalink;

--
-- Name: COLUMN dl_url.id; Type: COMMENT; Schema: datalink; Owner: datalink
--

COMMENT ON COLUMN dl_url.id IS 'unique numeric id, datalink actual value';


--
-- Name: COLUMN dl_url.url; Type: COMMENT; Schema: datalink; Owner: datalink
--

COMMENT ON COLUMN dl_url.url IS 'datalink URL';


--
-- Name: COLUMN dl_url.scheme; Type: COMMENT; Schema: datalink; Owner: datalink
--

COMMENT ON COLUMN dl_url.scheme IS '/ URL access scheme, HTTP or FILE';


--
-- Name: COLUMN dl_url.authority; Type: COMMENT; Schema: datalink; Owner: datalink
--

COMMENT ON COLUMN dl_url.authority IS '/ URL access authority (username and host)';


--
-- Name: COLUMN dl_url.ref; Type: COMMENT; Schema: datalink; Owner: datalink
--

COMMENT ON COLUMN dl_url.ref IS '/ reference count';


--
-- Name: COLUMN dl_url.attr; Type: COMMENT; Schema: datalink; Owner: datalink
--

COMMENT ON COLUMN dl_url.attr IS 'file control options';


--
-- Name: COLUMN dl_url.sqlr; Type: COMMENT; Schema: datalink; Owner: datalink
--

COMMENT ON COLUMN dl_url.sqlr IS 'SQL mediated read access';


--
-- Name: COLUMN dl_url.sqlw; Type: COMMENT; Schema: datalink; Owner: datalink
--

COMMENT ON COLUMN dl_url.sqlw IS 'SQL mediated write access';


--
-- Name: COLUMN dl_url.cons; Type: COMMENT; Schema: datalink; Owner: datalink
--

COMMENT ON COLUMN dl_url.cons IS 'construction indication: v = DLVALUE(), n = DLNEWCOPY(), p = DLPREVIOUSCOPY()';


--
-- Name: COLUMN dl_url.attrs; Type: COMMENT; Schema: datalink; Owner: datalink
--

COMMENT ON COLUMN dl_url.attrs IS '/ previos values of attr';


--
-- Name: file_link; Type: TABLE; Schema: datalink; Owner: datalink; Tablespace: 
--

CREATE TABLE file_link (
    dl_id dl_id NOT NULL,
    file_path file_path NOT NULL
);


ALTER TABLE file_link OWNER TO datalink;

--
-- Name: file_media; Type: TABLE; Schema: datalink; Owner: datalink; Tablespace: 
--

CREATE TABLE file_media (
    dl_id dl_id DEFAULT dl_id() NOT NULL,
    length numeric,
    demuxer text,
    video_width integer,
    video_height integer,
    video_fps real,
    video_bitrate real,
    video_format text,
    video_codec text,
    video_aspect real,
    audio_format text,
    audio_codec text,
    audio_bitrate real,
    audio_rate real,
    is_interlaced boolean,
    audio_channels integer
);


ALTER TABLE file_media OWNER TO datalink;

--
-- Name: file_xlog; Type: TABLE; Schema: datalink; Owner: datalink; Tablespace: 
--

CREATE TABLE file_xlog (
    dl_id dl_id DEFAULT dl_id() NOT NULL,
    base_id dl_id NOT NULL,
    file_path file_path NOT NULL,
    state integer DEFAULT 0 NOT NULL,
    ctime timestamp with time zone DEFAULT now()
);


ALTER TABLE file_xlog OWNER TO datalink;

--
-- Name: sample_datalinks; Type: TABLE; Schema: datalink; Owner: datalink; Tablespace: 
--

CREATE TABLE sample_datalinks (
    url text NOT NULL,
    link datalink
);


ALTER TABLE sample_datalinks OWNER TO datalink;

--
-- Name: dl_inode_base_id_key; Type: CONSTRAINT; Schema: datalink; Owner: datalink; Tablespace: 
--

ALTER TABLE ONLY dl_inode
    ADD CONSTRAINT dl_inode_base_id_key UNIQUE (space_id, basename);


--
-- Name: dl_inode_pkey; Type: CONSTRAINT; Schema: datalink; Owner: datalink; Tablespace: 
--

ALTER TABLE ONLY dl_inode
    ADD CONSTRAINT dl_inode_pkey PRIMARY KEY (dl_id);


--
-- Name: dl_optionsdef_pkey; Type: CONSTRAINT; Schema: datalink; Owner: datalink; Tablespace: 
--

ALTER TABLE ONLY dl_optionsdef
    ADD CONSTRAINT dl_optionsdef_pkey PRIMARY KEY (schema_name, table_name, column_name);


--
-- Name: dl_prefix_base_key; Type: CONSTRAINT; Schema: datalink; Owner: datalink; Tablespace: 
--

ALTER TABLE ONLY dl_prefix
    ADD CONSTRAINT dl_prefix_base_key UNIQUE (base);


--
-- Name: dl_prefix_name_key; Type: CONSTRAINT; Schema: datalink; Owner: datalink; Tablespace: 
--

ALTER TABLE ONLY dl_prefix
    ADD CONSTRAINT dl_prefix_name_key UNIQUE (name);


--
-- Name: dl_prefix_pkey; Type: CONSTRAINT; Schema: datalink; Owner: datalink; Tablespace: 
--

ALTER TABLE ONLY dl_prefix
    ADD CONSTRAINT dl_prefix_pkey PRIMARY KEY (id);


--
-- Name: dl_prefix_prefix_key; Type: CONSTRAINT; Schema: datalink; Owner: datalink; Tablespace: 
--

ALTER TABLE ONLY dl_prefix
    ADD CONSTRAINT dl_prefix_prefix_key UNIQUE (prefix);


--
-- Name: dl_space_home_key; Type: CONSTRAINT; Schema: datalink; Owner: datalink; Tablespace: 
--

ALTER TABLE ONLY dl_space
    ADD CONSTRAINT dl_space_home_key UNIQUE (base_path);


--
-- Name: dl_space_pkey; Type: CONSTRAINT; Schema: datalink; Owner: datalink; Tablespace: 
--

ALTER TABLE ONLY dl_space
    ADD CONSTRAINT dl_space_pkey PRIMARY KEY (space_id);


--
-- Name: dl_space_url_key; Type: CONSTRAINT; Schema: datalink; Owner: datalink; Tablespace: 
--

ALTER TABLE ONLY dl_space
    ADD CONSTRAINT dl_space_url_key UNIQUE (prefix);


--
-- Name: dl_url_dl_id_key; Type: CONSTRAINT; Schema: datalink; Owner: datalink; Tablespace: 
--

ALTER TABLE ONLY dl_url
    ADD CONSTRAINT dl_url_dl_id_key UNIQUE (dl_id);


--
-- Name: dl_url_pkey; Type: CONSTRAINT; Schema: datalink; Owner: datalink; Tablespace: 
--

ALTER TABLE ONLY dl_url
    ADD CONSTRAINT dl_url_pkey PRIMARY KEY (id);


--
-- Name: dl_url_url_key; Type: CONSTRAINT; Schema: datalink; Owner: datalink; Tablespace: 
--

ALTER TABLE ONLY dl_url
    ADD CONSTRAINT dl_url_url_key UNIQUE (url);


--
-- Name: file_link_file_path_key; Type: CONSTRAINT; Schema: datalink; Owner: datalink; Tablespace: 
--

ALTER TABLE ONLY file_link
    ADD CONSTRAINT file_link_file_path_key UNIQUE (file_path);


--
-- Name: file_link_pkey; Type: CONSTRAINT; Schema: datalink; Owner: datalink; Tablespace: 
--

ALTER TABLE ONLY file_link
    ADD CONSTRAINT file_link_pkey PRIMARY KEY (dl_id);


--
-- Name: file_media_pkey; Type: CONSTRAINT; Schema: datalink; Owner: datalink; Tablespace: 
--

ALTER TABLE ONLY file_media
    ADD CONSTRAINT file_media_pkey PRIMARY KEY (dl_id);


--
-- Name: file_xlog_pkey; Type: CONSTRAINT; Schema: datalink; Owner: datalink; Tablespace: 
--

ALTER TABLE ONLY file_xlog
    ADD CONSTRAINT file_xlog_pkey PRIMARY KEY (dl_id);


--
-- Name: sample_datalinks_pkey; Type: CONSTRAINT; Schema: datalink; Owner: datalink; Tablespace: 
--

ALTER TABLE ONLY sample_datalinks
    ADD CONSTRAINT sample_datalinks_pkey PRIMARY KEY (url);


--
-- Name: DL_RI_trigger; Type: TRIGGER; Schema: datalink; Owner: datalink
--

CREATE CONSTRAINT TRIGGER "DL_RI_trigger" AFTER INSERT OR DELETE OR UPDATE ON sample_datalinks NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE dl_trigger();


--
-- Name: DL_url_init; Type: TRIGGER; Schema: datalink; Owner: datalink
--

CREATE TRIGGER "DL_url_init" BEFORE INSERT OR UPDATE ON dl_url FOR EACH ROW EXECUTE PROCEDURE dl_url_init();


--
-- Name: DL_RI_constraint; Type: FK CONSTRAINT; Schema: datalink; Owner: datalink
--

ALTER TABLE ONLY sample_datalinks
    ADD CONSTRAINT "DL_RI_constraint" FOREIGN KEY (link) REFERENCES dl_url(id);


--
-- Name: ISA dl_inode; Type: FK CONSTRAINT; Schema: datalink; Owner: datalink
--

ALTER TABLE ONLY file_media
    ADD CONSTRAINT "ISA dl_inode" FOREIGN KEY (dl_id) REFERENCES dl_inode(dl_id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: base_id; Type: FK CONSTRAINT; Schema: datalink; Owner: datalink
--

ALTER TABLE ONLY dl_url
    ADD CONSTRAINT base_id FOREIGN KEY (base_id) REFERENCES dl_prefix(id);


--
-- Name: dl_inode_base_id_fkey; Type: FK CONSTRAINT; Schema: datalink; Owner: datalink
--

ALTER TABLE ONLY dl_inode
    ADD CONSTRAINT dl_inode_base_id_fkey FOREIGN KEY (space_id) REFERENCES dl_space(space_id);


--
-- Name: dl_url_dl_id_fkey; Type: FK CONSTRAINT; Schema: datalink; Owner: datalink
--

ALTER TABLE ONLY dl_url
    ADD CONSTRAINT dl_url_dl_id_fkey FOREIGN KEY (dl_id) REFERENCES dl_inode(dl_id);


--
-- Name: file_xlog_base_id_fkey; Type: FK CONSTRAINT; Schema: datalink; Owner: datalink
--

ALTER TABLE ONLY file_xlog
    ADD CONSTRAINT file_xlog_base_id_fkey FOREIGN KEY (base_id) REFERENCES dl_space(space_id);


--
-- Name: datalink; Type: ACL; Schema: -; Owner: datalink
--

REVOKE ALL ON SCHEMA datalink FROM PUBLIC;
REVOKE ALL ON SCHEMA datalink FROM datalink;
GRANT ALL ON SCHEMA datalink TO datalink;
GRANT USAGE ON SCHEMA datalink TO PUBLIC;


--
-- Name: dl_get(datalink); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION dl_get(datalink) FROM PUBLIC;
REVOKE ALL ON FUNCTION dl_get(datalink) FROM postgres;
GRANT ALL ON FUNCTION dl_get(datalink) TO postgres;
GRANT ALL ON FUNCTION dl_get(datalink) TO PUBLIC;


--
-- Name: dl_inode; Type: ACL; Schema: datalink; Owner: datalink
--

REVOKE ALL ON TABLE dl_inode FROM PUBLIC;
REVOKE ALL ON TABLE dl_inode FROM datalink;
GRANT ALL ON TABLE dl_inode TO datalink;


--
-- Name: dl_inode(file_path); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION dl_inode(file_path) FROM PUBLIC;
REVOKE ALL ON FUNCTION dl_inode(file_path) FROM postgres;
GRANT ALL ON FUNCTION dl_inode(file_path) TO postgres;
GRANT ALL ON FUNCTION dl_inode(file_path) TO PUBLIC;


--
-- Name: dl_linker_backup(datalink, text); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION dl_linker_backup(datalink, my_options text) FROM PUBLIC;
REVOKE ALL ON FUNCTION dl_linker_backup(datalink, my_options text) FROM postgres;
GRANT ALL ON FUNCTION dl_linker_backup(datalink, my_options text) TO postgres;
GRANT ALL ON FUNCTION dl_linker_backup(datalink, my_options text) TO PUBLIC;


--
-- Name: dl_linker_delete(datalink); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION dl_linker_delete(datalink) FROM PUBLIC;
REVOKE ALL ON FUNCTION dl_linker_delete(datalink) FROM postgres;
GRANT ALL ON FUNCTION dl_linker_delete(datalink) TO postgres;
GRANT ALL ON FUNCTION dl_linker_delete(datalink) TO PUBLIC;


--
-- Name: dl_linker_get(datalink); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION dl_linker_get(datalink) FROM PUBLIC;
REVOKE ALL ON FUNCTION dl_linker_get(datalink) FROM postgres;
GRANT ALL ON FUNCTION dl_linker_get(datalink) TO postgres;
GRANT ALL ON FUNCTION dl_linker_get(datalink) TO PUBLIC;


--
-- Name: dl_linker_put(datalink, text); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION dl_linker_put(datalink, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION dl_linker_put(datalink, text) FROM postgres;
GRANT ALL ON FUNCTION dl_linker_put(datalink, text) TO postgres;
GRANT ALL ON FUNCTION dl_linker_put(datalink, text) TO PUBLIC;


--
-- Name: dl_linker_replace(datalink); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION dl_linker_replace(datalink) FROM PUBLIC;
REVOKE ALL ON FUNCTION dl_linker_replace(datalink) FROM postgres;
GRANT ALL ON FUNCTION dl_linker_replace(datalink) TO postgres;
GRANT ALL ON FUNCTION dl_linker_replace(datalink) TO PUBLIC;


--
-- Name: dl_linker_sqlr(datalink, dl_read_access); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION dl_linker_sqlr(datalink, dl_read_access) FROM PUBLIC;
REVOKE ALL ON FUNCTION dl_linker_sqlr(datalink, dl_read_access) FROM postgres;
GRANT ALL ON FUNCTION dl_linker_sqlr(datalink, dl_read_access) TO postgres;
GRANT ALL ON FUNCTION dl_linker_sqlr(datalink, dl_read_access) TO PUBLIC;


--
-- Name: dl_linker_sqlw(datalink, dl_write_access); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION dl_linker_sqlw(datalink, dl_write_access) FROM PUBLIC;
REVOKE ALL ON FUNCTION dl_linker_sqlw(datalink, dl_write_access) FROM postgres;
GRANT ALL ON FUNCTION dl_linker_sqlw(datalink, dl_write_access) TO postgres;
GRANT ALL ON FUNCTION dl_linker_sqlw(datalink, dl_write_access) TO PUBLIC;


--
-- Name: dl_put(datalink, text); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION dl_put(datalink, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION dl_put(datalink, text) FROM postgres;
GRANT ALL ON FUNCTION dl_put(datalink, text) TO postgres;
GRANT ALL ON FUNCTION dl_put(datalink, text) TO PUBLIC;


--
-- Name: dl_trigger(); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION dl_trigger() FROM PUBLIC;
REVOKE ALL ON FUNCTION dl_trigger() FROM postgres;
GRANT ALL ON FUNCTION dl_trigger() TO postgres;
GRANT ALL ON FUNCTION dl_trigger() TO PUBLIC;


--
-- Name: dl_url_init(); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION dl_url_init() FROM PUBLIC;
REVOKE ALL ON FUNCTION dl_url_init() FROM postgres;
GRANT ALL ON FUNCTION dl_url_init() TO postgres;
GRANT ALL ON FUNCTION dl_url_init() TO PUBLIC;


--
-- Name: file_abort(file_handle); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION file_abort(file_handle) FROM PUBLIC;
REVOKE ALL ON FUNCTION file_abort(file_handle) FROM postgres;
GRANT ALL ON FUNCTION file_abort(file_handle) TO postgres;
GRANT ALL ON FUNCTION file_abort(file_handle) TO PUBLIC;


--
-- Name: file_begin(file_path); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION file_begin(file_path) FROM PUBLIC;
REVOKE ALL ON FUNCTION file_begin(file_path) FROM postgres;
GRANT ALL ON FUNCTION file_begin(file_path) TO postgres;
GRANT ALL ON FUNCTION file_begin(file_path) TO PUBLIC;


--
-- Name: file_end(file_handle); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION file_end(file_handle) FROM PUBLIC;
REVOKE ALL ON FUNCTION file_end(file_handle) FROM postgres;
GRANT ALL ON FUNCTION file_end(file_handle) TO postgres;
GRANT ALL ON FUNCTION file_end(file_handle) TO PUBLIC;


--
-- Name: file_list(file_path); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION file_list(file_path) FROM PUBLIC;
REVOKE ALL ON FUNCTION file_list(file_path) FROM postgres;
GRANT ALL ON FUNCTION file_list(file_path) TO postgres;
GRANT ALL ON FUNCTION file_list(file_path) TO PUBLIC;


--
-- Name: file_write(file_handle, text); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION file_write(file_handle, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION file_write(file_handle, text) FROM postgres;
GRANT ALL ON FUNCTION file_write(file_handle, text) TO postgres;
GRANT ALL ON FUNCTION file_write(file_handle, text) TO PUBLIC;


--
-- Name: ri_datalink(); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION ri_datalink() FROM PUBLIC;
REVOKE ALL ON FUNCTION ri_datalink() FROM postgres;
GRANT ALL ON FUNCTION ri_datalink() TO postgres;
GRANT ALL ON FUNCTION ri_datalink() TO PUBLIC;


--
-- Name: url_canonical(url); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION url_canonical(url) FROM PUBLIC;
REVOKE ALL ON FUNCTION url_canonical(url) FROM postgres;
GRANT ALL ON FUNCTION url_canonical(url) TO postgres;
GRANT ALL ON FUNCTION url_canonical(url) TO PUBLIC;


--
-- Name: url_part(text, url); Type: ACL; Schema: datalink; Owner: postgres
--

REVOKE ALL ON FUNCTION url_part(text, url) FROM PUBLIC;
REVOKE ALL ON FUNCTION url_part(text, url) FROM postgres;
GRANT ALL ON FUNCTION url_part(text, url) TO postgres;
GRANT ALL ON FUNCTION url_part(text, url) TO PUBLIC;


--
-- Name: dl_url; Type: ACL; Schema: datalink; Owner: datalink
--

REVOKE ALL ON TABLE dl_url FROM PUBLIC;
REVOKE ALL ON TABLE dl_url FROM datalink;
GRANT ALL ON TABLE dl_url TO datalink;


--
-- Name: file_media; Type: ACL; Schema: datalink; Owner: datalink
--

REVOKE ALL ON TABLE file_media FROM PUBLIC;
REVOKE ALL ON TABLE file_media FROM datalink;
GRANT ALL ON TABLE file_media TO datalink;


--
-- Name: sample_datalinks; Type: ACL; Schema: datalink; Owner: datalink
--

REVOKE ALL ON TABLE sample_datalinks FROM PUBLIC;
REVOKE ALL ON TABLE sample_datalinks FROM datalink;
GRANT ALL ON TABLE sample_datalinks TO datalink;
GRANT SELECT ON TABLE sample_datalinks TO PUBLIC;


--
-- PostgreSQL database dump complete
--

