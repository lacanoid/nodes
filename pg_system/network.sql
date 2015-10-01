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
-- Name: network; Type: SCHEMA; Schema: -; Owner: network
--

CREATE SCHEMA network;


ALTER SCHEMA network OWNER TO network;

--
-- Name: SCHEMA network; Type: COMMENT; Schema: -; Owner: network
--

COMMENT ON SCHEMA network IS 'Network configuration information';


SET search_path = network, pg_catalog;

--
-- Name: full_dns_domain; Type: DOMAIN; Schema: network; Owner: network
--

CREATE DOMAIN full_dns_domain AS text
	CONSTRAINT "Domain name check" CHECK ((VALUE ~~ '%.%.'::text));


ALTER DOMAIN full_dns_domain OWNER TO network;

--
-- Name: hostname; Type: DOMAIN; Schema: network; Owner: network
--

CREATE DOMAIN hostname AS name;


ALTER DOMAIN hostname OWNER TO network;

--
-- Name: id; Type: DOMAIN; Schema: network; Owner: network
--

CREATE DOMAIN id AS integer;


ALTER DOMAIN id OWNER TO network;

--
-- Name: sql_identifier; Type: DOMAIN; Schema: network; Owner: network
--

CREATE DOMAIN sql_identifier AS character varying;


ALTER DOMAIN sql_identifier OWNER TO network;

--
-- Name: DOMAIN sql_identifier; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON DOMAIN sql_identifier IS 'SQL object identifier';


--
-- Name: unix_name; Type: DOMAIN; Schema: network; Owner: network
--

CREATE DOMAIN unix_name AS text
	CONSTRAINT unix_name_check CHECK ((VALUE ~ '^[a-zA-Z0-9_\-]+$'::text));


ALTER DOMAIN unix_name OWNER TO network;

--
-- Name: bind_a_touch(); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION bind_a_touch() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
 if network.nul(NEW.mac::text) IS NULL THEN
  NEW.mac:=network.macaddr(NEW.ip);
 END IF;

 RETURN NEW;
END
$$;


ALTER FUNCTION network.bind_a_touch() OWNER TO network;

--
-- Name: FUNCTION bind_a_touch(); Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON FUNCTION bind_a_touch() IS 'Changing IP (A) records';


--
-- Name: bind_master_stereotype_touch(); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION bind_master_stereotype_touch() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO network
    AS $$
begin
 if tg_op = 'DELETE' then
   update network.bind_master set name=name where stereotype=old.stereotype;
   return old;
 end if;

 if tg_op = 'UPDATE' and new.stereotype is distinct from old.stereotype then
   update network.bind_master set name=name where stereotype=old.stereotype;
 end if;

 if tg_op = 'INSERT' or tg_op = 'UPDATE' then
   update network.bind_master set name=name where stereotype=new.stereotype;
 end if;

 return new;
end
$$;


ALTER FUNCTION network.bind_master_stereotype_touch() OWNER TO network;

--
-- Name: FUNCTION bind_master_stereotype_touch(); Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON FUNCTION bind_master_stereotype_touch() IS 'Changing domain templates';


--
-- Name: bind_master_touch(); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION bind_master_touch() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO network
    AS $$
declare
 basename text;
 tablename text;
 filename text;
 tablenames text[];
 q text;
begin
 basename := 'dns_';
 tablenames := '{network.bind_a,network.bind_mx,network.bind_master,network.bind_ns,network.bind_cname}';

 if tg_op in ('INSERT', 'UPDATE') then
   new.mtime := now();
   tablename := basename||new.name;
   if not new.hidden then
     execute
       'create table if not exists '||quote_ident(tablename)||' ( '||
       ' like '||quote_ident(basename)||' including defaults including indexes including comments '||
       ') inherits('||quote_ident(basename)||')';
     execute
       'alter table '||quote_ident(tablename)||' owner to network';
     execute
       'alter table '||quote_ident(tablename)||' drop constraint if exists cname';
     execute
       'alter table '||quote_ident(tablename)||' add constraint cname foreign key (cname) references '||quote_ident(tablename);
     execute
       'comment on table '||quote_ident(tablename)||' is '||quote_literal('AUTODOMAIN '||new.name);
     execute
       'drop trigger if exists touch on '||quote_ident(tablename);
     execute
       'create trigger touch before insert or update or delete on '||quote_ident(tablename)||
       ' for each row execute procedure network.dns_touch()';
        
     tablenames := array['network.'||quote_ident(tablename)] || tablenames;
     if not exists(select * from network.config where path = 'bind_'||new.name) then
       insert into network.config (query,tablename,path)
              values ('network.bind_zone_conf('||quote_literal(new.name)||')', tablenames, 'bind_'||new.name);
     end if; -- not exists
   end if; -- not hidden
      
   return new;
 end if; -- insert or update

 if tg_op = 'UPDATE' then
   if new.name is distinct from old.name then
   raise exception 'Renaming of master DNS domains id forbidden!';
   q :='alter table if exists '||quote_ident(basename||old.name)||' rename to '||quote_ident(basename||new.name);
   execute q;
   end if;
   return new;
 end if; -- update

 if tg_op = 'DELETE' then
   tablename := quote_ident(basename||old.name);
   if network.count_records(tablename) is distinct from 0 then
     raise exception 'Table % not empty, cowardly refusing to delete zone.',tablename;
   end if;
   delete from network.config where path = 'bind_'||old.name;
   q :='drop table if exists '||tablename;
   execute q;
   return old;
 end if; -- delete

end
$$;


ALTER FUNCTION network.bind_master_touch() OWNER TO network;

--
-- Name: FUNCTION bind_master_touch(); Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON FUNCTION bind_master_touch() IS 'Changing domains';


--
-- Name: bind_serial_new(); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION bind_serial_new() RETURNS numeric
    LANGUAGE sql
    AS $$select (to_char(now(),'YYYYMMDD')::numeric)*100 + nextval('network.cycle100')::numeric$$;


ALTER FUNCTION network.bind_serial_new() OWNER TO network;

--
-- Name: FUNCTION bind_serial_new(); Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON FUNCTION bind_serial_new() IS 'Return new serial number for BIND config file';


--
-- Name: bind_zone_conf(name); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION bind_zone_conf(name) RETURNS text
    LANGUAGE plpgsql
    AS $_$DECLARE 
 soa text; 
 r text; 
 def text; 
 w1 int; 
 zone alias for $1; 
BEGIN 
 def := ''; 
 
-- SELECT INTO w1 max(length(name))+1 FROM network.dns_; 
 w1 := 24;
 
 SELECT INTO soa 
   '$TTL ' || extract(epoch from s.minimum) || E'\t; ' || s.minimum || E'\n' || 
   rpad(zone,w1) || E'IN SOA\t' || s.nameserver || ' ' || s.email || E' (\n' ||  
   rpad('',w1) || E'\t' || network.bind_serial_new() || E' ; autogenerated serial\n' || 
   rpad('',w1) || E'\t' || extract(epoch from s.refresh) ||  
    E'\t; refresh (' || s.refresh || E')\n' || 
   rpad('',w1) || E'\t' || extract(epoch from s.retry) ||  
    E'\t; retry (' || s.retry || E')\n' || 
   rpad('',w1) || E'\t' || extract(epoch from s.expire) ||  
    E'\t; expire (' || s.expire || E')\n' || 
   rpad('',w1) || E'\t' || extract(epoch from s.minimum) ||  
    E'\t; minimum (' || s.minimum || E')\n' || 
   rpad('',w1) || E')\n' ||
   coalesce(rpad('',w1) || E'NS    \t' || s.ns1 || E'\n' ,'')||
   coalesce(rpad('',w1) || E'NS    \t' || s.ns2 || E'\n'  ,'')||
   coalesce(rpad('',w1) || E'MX    \t10\t' || s.mx  || E'\n'  ,'')||
   coalesce(rpad('',w1) || E'A     \t' || host(coalesce(m.ip,s.ip4)) || E'\n' ,'')||
   coalesce(rpad('',w1) || E'AAAA  \t' || host(s.ip6) || E'\n'  ,'')||
   coalesce(rpad('',w1) || E'CNAME \t' || s.cname || E'\n'  ,'')
  FROM network.bind_master m
  JOIN network.bind_master_stereotype s using (stereotype)
  WHERE name = zone; 
 
 SELECT INTO r string_agg(r0,'') FROM ( 
  SELECT  
   rpad('',w1) || E'NS    \t' || value || E'\n' AS r0 
  FROM network.bind_ns 
  WHERE master = zone 
  ORDER BY value 
 ) AS r1; 
 def := def || network.wrap(E'\n; Name Server (NS) records\n',network.nul(r)); 

 /*
 SELECT INTO r string_agg(r0,'') FROM ( 
  SELECT  
   rpad('',w1) || E'A     \t' || host(ip) || E'\n' AS r0 
  FROM network.bind_master 
  WHERE name = zone 
  AND ip IS NOT NULL 
 ) AS r1; 
 def := def || network.wrap(E'\n; Domain Address (A) record\n',network.nul(r)); 
*/
 
 SELECT INTO r string_agg(r0,'') FROM ( 
  SELECT  
   rpad('',w1) || E'MX    \t' || priority || E'\t' || value || E'\n' AS r0 
  FROM network.bind_mx 
  WHERE master = zone 
  ORDER BY priority 
 ) AS r1; 
 def := def || network.wrap(E'\n; Mail eXchanger (MX) records\n',network.nul(r)); 
 
 SELECT INTO r string_agg(r0,'') FROM ( 
  SELECT  
   rpad(name,w1) || E'A     \t' || host(ip) || E'\n' AS r0 
  FROM network.bind_a 
  WHERE master = zone 
  ORDER BY ip 
 ) AS r1; 
 def := def || network.wrap(E'\n; Address (A) records\n',network.nul(r)); 
 
 SELECT INTO r string_agg(r0,'') FROM ( 
  SELECT  
   rpad(name,w1) || E'CNAME \t' || value || E'\n' AS r0 
  FROM network.bind_cname 
  WHERE master = zone 
  ORDER BY value, name 
 ) AS r1; 
 def := def || network.wrap(E'\n; Canonical name (CNAME) records\n',network.nul(r)); 

 -- get records from specific domain table, if it exists
 if exists(select sysid from network.db_tables where schema='network' and name='dns_'||zone) then
 execute 
  'with q as ('||
  '   select rpad(name,'||w1||') || E''CNAME \t'' || coalesce(cname::text,fqdn::text) || E''\n'' AS r0 FROM network.'||quote_ident('dns_'||zone)||
  '    where cname is not null or fqdn is not null order by fqdn,cname,name '
  ')  select string_agg(r0,'''') from q'
    into r;
 def := def || network.wrap(E'\n; Canonical name (CNAME) records from table dns_'||zone||E'\n',network.nul(r)); 
 end if;
 
 RETURN  
  '; Autoconfigured by NETWORK on ' || to_char(now(),'YYYY-MM-DD HH24:MI:SS') || E'\n' || 
  E'$ORIGIN .\n' || soa || E'\n$ORIGIN ' || zone || E'.\n' || def; 
END; 
$_$;


ALTER FUNCTION network.bind_zone_conf(name) OWNER TO network;

--
-- Name: FUNCTION bind_zone_conf(name); Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON FUNCTION bind_zone_conf(name) IS 'Config file contents for individual zone';


--
-- Name: bind_zoneconf_conf(); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION bind_zoneconf_conf() RETURNS text
    LANGUAGE plpgsql
    AS $$DECLARE 
 r text; 
 def text; 
BEGIN 
 def := ''; 
  
 with q as (
  select m.name as zone,
         s.stereotype,
         s.dns_master
    from network.bind_master m
    join network.bind_master_stereotype s using (stereotype)
   order by stereotype, m.name
 )
 select into def string_agg(r1,'')
   from (
   select E'// domain stereotype "'||stereotype||E'"\n' ||
          string_agg(r0,'') ||
          E'\n' as r1
     from ( 
     select zone,
            stereotype,
            E'zone '||rpad('"'||zone||'"',20)||E'\t{'||
            case 
              when dns_master is null then
                E'  type master;'||
                E' file "/var/lib/postgresql/network/bind_'||zone||E'";'
              else
                E'  type slave;'||
                E'  file "/etc/bind/slave/'||zone||E'";'||
                E'  masters { '||host(dns_master)||E'; };'
            end ||
            E'  };\n' as r0
       from q
     ) as q1
   group by stereotype     
   order by stereotype
   ) as q2;
 
 RETURN  
  '// Autoconfigured by NETWORK on ' || to_char(now(),'YYYY-MM-DD HH24:MI:SS') || E'\n\n' || def;
END; 
$$;


ALTER FUNCTION network.bind_zoneconf_conf() OWNER TO network;

--
-- Name: FUNCTION bind_zoneconf_conf(); Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON FUNCTION bind_zoneconf_conf() IS 'Config file for including all zones';


--
-- Name: config_file_put(text, text); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION config_file_put(my_path text, my_content text) RETURNS text
    LANGUAGE plperlu
    AS $_$my $file=shift;
my $me="function network.config_file_put($file)";
my $prefix='/var/lib/postgresql/network/';
my $data=shift;
my $ok=0;

if(!defined($file)) { return "File not specified"; }
if($file=~m|\.\.|) { return "Multiple dots . not allowed in path"; }
if($file=~m|/|) { return "Slashes / not allowed in path"; }
# unless($file=~m|^/|) { return "Relative path not allowed in $me"; }
# unless($file=~m|^$prefix|) { return "Path must start with $prefix in $me"; }
$file = $prefix.$file;

unless(-d $prefix) { 
  mkdir $prefix; 
  elog NOTICE, "Creating NETWORK config directory $prefix";
}
if(open(Fo,">".$file)) {
  $ok = print Fo $data;
  close(Fo);
  chmod 0644, $file;
  if(!$ok) { return "Write failed"; }
  return undef;
} else {
  return "Can't open $file ";
}
return "Unknown error (end of function)";
$_$;


ALTER FUNCTION network.config_file_put(my_path text, my_content text) OWNER TO network;

--
-- Name: FUNCTION config_file_put(my_path text, my_content text); Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON FUNCTION config_file_put(my_path text, my_content text) IS 'Write a config file to filesystem, return error or NULL on success';


--
-- Name: config_file_update_by_id(integer); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION config_file_update_by_id(integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$DECLARE
 r RECORD;
 id1 ALIAS FOR $1;
BEGIN

 SELECT INTO r 
  network.config_file_put(path,network.eval(query)) as res,
  path
 FROM network.config
 WHERE id = id1;

 IF NOT FOUND THEN
  RAISE WARNING 'Config #% not found', id1;
  return false;
 END IF;

 IF r.res IS NOT NULL THEN
  RAISE EXCEPTION 'Could not write config file % - %', r.path, r.res;
  RETURN false;
 ELSE
  RAISE NOTICE 'Writing config file %', r.path; 
  RETURN true;
 END IF;
  
 RETURN false;
END;
$_$;


ALTER FUNCTION network.config_file_update_by_id(integer) OWNER TO network;

--
-- Name: FUNCTION config_file_update_by_id(integer); Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON FUNCTION config_file_update_by_id(integer) IS 'Recreate a configuration file';


--
-- Name: config_file_update_by_path(text); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION config_file_update_by_path(mypath text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$DECLARE
 r RECORD;
BEGIN

 SELECT INTO r 
  network.config_file_put(path,network.eval(query)) as res,
  path
 FROM network.config
 WHERE path = mypath;

 IF NOT FOUND THEN
  RAISE WARNING 'Config for % not found', mypath;
  return false;
 END IF;

 IF r.res IS NOT NULL THEN
  RAISE EXCEPTION 'Could not write config file % - %', r.path, r.res;
  RETURN false;
 ELSE
  RAISE NOTICE 'Writing config file %', r.path; 
  RETURN true;
 END IF;
  
 RETURN false;
END;
$$;


ALTER FUNCTION network.config_file_update_by_path(mypath text) OWNER TO network;

--
-- Name: FUNCTION config_file_update_by_path(mypath text); Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON FUNCTION config_file_update_by_path(mypath text) IS 'Recreate a configuration file';


--
-- Name: config_touch(); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION config_touch() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
 res bool;
 n int;
BEGIN
 IF TG_OP = 'UPDATE' THEN
  IF OLD.id <> NEW.id THEN
    RAISE EXCEPTION 'Cannot change network.config.id';
  END IF;
  IF OLD.path <> NEW.path THEN
    RAISE EXCEPTION 'Cannot change network.config.path';
  END IF;
 END IF;

--- Recreate triggers on tables in report ---

 IF TG_OP IN ('UPDATE','DELETE') THEN
  IF OLD.tablename IS NOT NULL THEN
    SELECT INTO n sum(network.execute(
     'DROP TRIGGER '||quote_ident(trigger_name)||' '||
     'ON '||event_object_sql_identifier||';'
     ))
    FROM network.db_triggers
    WHERE trigger_name LIKE 'NETWORK_config_'||OLD.id;
  END IF;
  EXECUTE 'SELECT 1';
 END IF;

 IF TG_OP IN ('INSERT','UPDATE') THEN 
  IF NEW.tablename IS NOT NULL THEN
    SELECT INTO n sum(network.execute(
      'CREATE TRIGGER '||
        quote_ident('NETWORK_config_'||r.id)||' '||
      'AFTER INSERT OR UPDATE OR DELETE ON '||sql_identifier||' '||
      'FOR EACH STATEMENT '||
      'EXECUTE PROCEDURE network.config_trigger('||quote_literal(r.path)||');'
     ))
    FROM network.db_tables t 
    JOIN network.config r ON (sysid in (select regclass(u) from unnest(NEW.tablename) u))
    WHERE r.id=NEW.id;    
  END IF;

  SELECT INTO res network.config_file_update_by_path(NEW.path);
 END IF;

 RETURN NEW;
END;
$$;


ALTER FUNCTION network.config_touch() OWNER TO network;

--
-- Name: FUNCTION config_touch(); Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON FUNCTION config_touch() IS 'Rebuild triggers on tables which generate configuration files';


--
-- Name: config_trigger(); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION config_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
 b bool;
BEGIN
 b := network.config_file_update_by_path(TG_ARGV[0]);
 RETURN NEW;
END;
$$;


ALTER FUNCTION network.config_trigger() OWNER TO network;

--
-- Name: FUNCTION config_trigger(); Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON FUNCTION config_trigger() IS 'Actually produce a configuration file';


--
-- Name: count_records(regclass); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION count_records(my_table regclass) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
declare
 my_count numeric;
begin
 select reltuples::numeric
   from pg_class
  where oid = my_table
   into my_count;
 if my_count < 1000 then
   execute 'select count(*) from only '||my_table into my_count;
 end if;
 return my_count::bigint;
end
$$;


ALTER FUNCTION network.count_records(my_table regclass) OWNER TO network;

--
-- Name: FUNCTION count_records(my_table regclass); Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON FUNCTION count_records(my_table regclass) IS 'Fast count number of tuples in a relation';


--
-- Name: dns_touch(); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION dns_touch() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO network
    AS $$
declare
begin
 if tg_op in ('INSERT', 'UPDATE') then
   new.mtime := now();
   if new.cname is not null and new.fqdn is not null then
     raise exception 'Please set either cname or fqdn';
   end if;
   if new.name is not distinct from new.cname then
     raise exception 'Please use distinct name and cname';
   end if;
 end if;

 if tg_op = 'INSERT' then
   return new;
 end if;

 if tg_op = 'UPDATE' then
   return new;
 end if;

 if tg_op = 'DELETE' then
   return old;
 end if;

end
$$;


ALTER FUNCTION network.dns_touch() OWNER TO network;

--
-- Name: FUNCTION dns_touch(); Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON FUNCTION dns_touch() IS 'Validate CNAME records in dns_* tables';


--
-- Name: domain_name(text); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION domain_name(text) RETURNS text
    LANGUAGE plperl STABLE
    AS $_$my $host=shift; 
if($host=~/\.$/) { 
 # it's a name 
 my @parts=split(/\./,$host); 
 if(@parts>2) { shift @parts; } 
 return join('.',@parts)."."; 
} else { 
 # it's IP 
 return undef; 
} 
$_$;


ALTER FUNCTION network.domain_name(text) OWNER TO network;

--
-- Name: eval(text); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION eval(sql_expression text) RETURNS text
    LANGUAGE plpgsql STRICT
    AS $_$DECLARE 
  body ALIAS FOR $1; 
  r RECORD; 
  result text; 
BEGIN 
 result = ''; 
 FOR r IN EXECUTE 'SELECT ('||body||')::text AS text' LOOP 
  result = result || r.text; 
 END LOOP; 
 RETURN result; 
END; 
$_$;


ALTER FUNCTION network.eval(sql_expression text) OWNER TO network;

--
-- Name: FUNCTION eval(sql_expression text); Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON FUNCTION eval(sql_expression text) IS 'Evaluate SQL expression';


--
-- Name: execute(text); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION execute(text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$DECLARE 
  body ALIAS FOR $1; 
  result INT; 
BEGIN 
--  RAISE NOTICE 'NETWORK DDL: %', body; 
  EXECUTE body; 
  GET DIAGNOSTICS result = ROW_COUNT; 
  RETURN result; 
END; 
$_$;


ALTER FUNCTION network.execute(text) OWNER TO network;

--
-- Name: FUNCTION execute(text); Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON FUNCTION execute(text) IS 'Execute SQL statement';


--
-- Name: local_service_reload(name); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION local_service_reload(name) RETURNS text
    LANGUAGE plperlu
    AS $_$my ($service,$args)=@_;
my $result;

if($service eq 'bind9') {
 $result=`sudo /etc/init.d/bind9 reload 2>&1`;
}

return $result;$_$;


ALTER FUNCTION network.local_service_reload(name) OWNER TO network;

--
-- Name: macaddr(inet); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION macaddr(inet) RETURNS macaddr
    LANGUAGE plperlu
    AS $_$my $ip=shift;
my $arp=`/usr/sbin/arp -n $ip`;
if($arp=~m|(..:..:..:..:..:..)|) {
 return $1;
} else {
 return undef;
}
$_$;


ALTER FUNCTION network.macaddr(inet) OWNER TO network;

--
-- Name: manufacturer(macaddr); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION manufacturer(macaddr) RETURNS text
    LANGUAGE plpgsql
    AS $_$DECLARE
 mac0 macaddr;
 maker text;
BEGIN
 mac0 := trunc($1);

 SELECT INTO maker 
  manufacturer 
 FROM network.mac_manufacturer
 WHERE mac = mac0;

 IF NOT FOUND THEN
  maker := network.manufacturer_from_web(mac0);
  IF network.nul(maker) IS NOT NULL THEN
   INSERT INTO network.mac_manufacturer (mac,manufacturer)
   VALUES (mac0,maker);
  END IF;
 END IF;

 RETURN maker;
END$_$;


ALTER FUNCTION network.manufacturer(macaddr) OWNER TO network;

--
-- Name: manufacturer_from_web(macaddr); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION manufacturer_from_web(macaddr) RETURNS text
    LANGUAGE plperlu IMMUTABLE
    AS $_$my $addr=shift; 
 
 $addr =~ s/.*?([\d\w]+:[\d\w]+:[\d\w]+):.*/$1/; 
 $addr =~ s/\b([\d\w])\b/0$1/g; 
 $addr =~ s/:/-/g; 
 return unless $addr =~ /..-..-../; 
 
 my $resp=`curl -sd 'x=$addr' http://standards.ieee.org/cgi-bin/ouisearch`; 
 ($resp =~ /Sorry!/) && return 'Unknown'; 
 
 $resp =~ s/.*.hex.\s+([\w\s\,\.\-\&';\(\)]+?)\n.*/$1/s; 
 
return $resp; 
$_$;


ALTER FUNCTION network.manufacturer_from_web(macaddr) OWNER TO network;

--
-- Name: new_id(); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION new_id() RETURNS id
    LANGUAGE sql
    AS $$select nextval('network.id_seq')::network.id;$$;


ALTER FUNCTION network.new_id() OWNER TO network;

--
-- Name: nul(text); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION nul(text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_X$return($_[0]?$_[0]:undef);$_X$;


ALTER FUNCTION network.nul(text) OWNER TO network;

SET default_tablespace = '';

SET default_with_oids = true;

--
-- Name: service; Type: TABLE; Schema: network; Owner: network; Tablespace: 
--

CREATE TABLE service (
    name unix_name NOT NULL
);


ALTER TABLE service OWNER TO network;

--
-- Name: reload(service); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION reload(service) RETURNS text
    LANGUAGE plpgsql
    AS $_$begin 
 return network.local_service_reload($1.name); 
end; 
$_$;


ALTER FUNCTION network.reload(service) OWNER TO network;

--
-- Name: reload(text); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION reload(service_name text) RETURNS text
    LANGUAGE sql
    AS $_$
select network.reload(s) from network.service s where name=$1;
$_$;


ALTER FUNCTION network.reload(service_name text) OWNER TO network;

--
-- Name: rnslookup(text); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION rnslookup(text) RETURNS text
    LANGUAGE plpgsql
    AS $_$declare 
 name text; 
 addr inet; 
begin 
 addr := inet($1); 
 select into name nslookup from network.ip_name where ip=addr; 
 if not found then  
   name := network.rnslookup_get($1);  
   if name is not null then 
     insert into network.ip_name (ip,nslookup) values (addr,name); 
     raise notice 'IP lookup: %',name;
   end if; 
 end if; 
 return name; 
end;$_$;


ALTER FUNCTION network.rnslookup(text) OWNER TO network;

--
-- Name: FUNCTION rnslookup(text); Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON FUNCTION rnslookup(text) IS 'Reverse lookup IP with DNS (cached)';


--
-- Name: rnslookup_get(text); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION rnslookup_get(text) RETURNS text
    LANGUAGE plperlu
    AS $_$my $ip=shift;
if($ip=~m|^\d+\.\d+\.\d+\.\d+$|) {
 my $r=`nslookup $ip`;
 if($r=~m|name\s*=\s*(\S+)|) {
  my $name=$1;
  return $name;
 } else {
  return $ip;
 }
}
return undef;$_$;


ALTER FUNCTION network.rnslookup_get(text) OWNER TO network;

--
-- Name: FUNCTION rnslookup_get(text); Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON FUNCTION rnslookup_get(text) IS 'Reverse lookup IP with DNS (non-cached)';


--
-- Name: sql_identifier(name, name); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION sql_identifier(namespace name, name name) RETURNS sql_identifier
    LANGUAGE sql STABLE STRICT
    AS $_$
select cast(quote_ident($1)||'.'||quote_ident($2) as network.sql_identifier)
$_$;


ALTER FUNCTION network.sql_identifier(namespace name, name name) OWNER TO network;

--
-- Name: FUNCTION sql_identifier(namespace name, name name); Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON FUNCTION sql_identifier(namespace name, name name) IS 'Return properly quoted SQL identifier';


--
-- Name: sql_tgargs(bytea); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION sql_tgargs(bytea) RETURNS text
    LANGUAGE plperl
    AS $_X$my @a; 
@a=split(/\\000/,$_[0]);
return join(',',map{$_=~s|'|''|g;"'$_'";}@a); 
 
$_X$;


ALTER FUNCTION network.sql_tgargs(bytea) OWNER TO network;

--
-- Name: wrap(text, text); Type: FUNCTION; Schema: network; Owner: network
--

CREATE FUNCTION wrap(text, text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_X$
 return defined($_[1])?"$_[0]$_[1]":"";
$_X$;


ALTER FUNCTION network.wrap(text, text) OWNER TO network;

--
-- Name: FUNCTION wrap(text, text); Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON FUNCTION wrap(text, text) IS '[p] Wrap $1 before $2';


SET default_with_oids = false;

--
-- Name: apache_vhost; Type: TABLE; Schema: network; Owner: network; Tablespace: 
--

CREATE TABLE apache_vhost (
    name character varying NOT NULL,
    configuration text
);


ALTER TABLE apache_vhost OWNER TO network;

--
-- Name: bind_a; Type: TABLE; Schema: network; Owner: network; Tablespace: 
--

CREATE TABLE bind_a (
    name hostname,
    id id DEFAULT new_id() NOT NULL,
    stereotype name,
    ctime timestamp with time zone DEFAULT now(),
    mtime timestamp with time zone DEFAULT now(),
    master hostname NOT NULL,
    ip inet NOT NULL,
    mac macaddr
);


ALTER TABLE bind_a OWNER TO network;

--
-- Name: TABLE bind_a; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON TABLE bind_a IS 'DNS A (IPV4 address) records';


--
-- Name: bind_a_conflict; Type: VIEW; Schema: network; Owner: network
--

CREATE VIEW bind_a_conflict AS
 SELECT bind_a.name,
    bind_a.ip
   FROM bind_a
  WHERE (bind_a.ip IN ( SELECT bind_a_1.ip
           FROM bind_a bind_a_1
          GROUP BY bind_a_1.ip
         HAVING (count(*) > 1)));


ALTER TABLE bind_a_conflict OWNER TO network;

--
-- Name: VIEW bind_a_conflict; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON VIEW bind_a_conflict IS 'Duplicated A DNS entries';


--
-- Name: bind_cname; Type: TABLE; Schema: network; Owner: network; Tablespace: 
--

CREATE TABLE bind_cname (
    name hostname,
    id id DEFAULT new_id() NOT NULL,
    stereotype name,
    ctime timestamp with time zone DEFAULT now(),
    mtime timestamp with time zone DEFAULT now(),
    value text NOT NULL,
    master hostname NOT NULL,
    cname_for id
);


ALTER TABLE bind_cname OWNER TO network;

--
-- Name: TABLE bind_cname; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON TABLE bind_cname IS 'DNS CNAME (canonical name) records';


--
-- Name: bind_master; Type: TABLE; Schema: network; Owner: network; Tablespace: 
--

CREATE TABLE bind_master (
    name hostname NOT NULL,
    stereotype text DEFAULT 'slave'::text NOT NULL,
    mtime timestamp with time zone DEFAULT now(),
    master inet,
    ip inet,
    hidden boolean DEFAULT false NOT NULL,
    description text
);


ALTER TABLE bind_master OWNER TO network;

--
-- Name: TABLE bind_master; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON TABLE bind_master IS 'DNS SAO (start of authority) records';


--
-- Name: bind_master_stereotype; Type: TABLE; Schema: network; Owner: network; Tablespace: 
--

CREATE TABLE bind_master_stereotype (
    stereotype text NOT NULL,
    mtime timestamp with time zone DEFAULT now(),
    dns_master inet DEFAULT '193.2.132.70'::inet,
    ip4 inet,
    ip6 inet,
    ns1 full_dns_domain NOT NULL,
    ns2 full_dns_domain NOT NULL,
    cname full_dns_domain,
    mx full_dns_domain,
    nameserver full_dns_domain NOT NULL,
    email full_dns_domain NOT NULL,
    refresh interval DEFAULT '03:00:00'::interval,
    retry interval DEFAULT '01:00:00'::interval,
    expire interval DEFAULT '7 days'::interval,
    minimum interval DEFAULT '1 day'::interval,
    description text
);


ALTER TABLE bind_master_stereotype OWNER TO network;

--
-- Name: TABLE bind_master_stereotype; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON TABLE bind_master_stereotype IS 'DNS templates for various kinds of domains';


--
-- Name: bind_mx; Type: TABLE; Schema: network; Owner: network; Tablespace: 
--

CREATE TABLE bind_mx (
    name hostname,
    id id DEFAULT new_id() NOT NULL,
    stereotype name,
    ctime timestamp with time zone DEFAULT now(),
    mtime timestamp with time zone DEFAULT now(),
    master hostname NOT NULL,
    value text NOT NULL,
    priority integer NOT NULL
);


ALTER TABLE bind_mx OWNER TO network;

--
-- Name: TABLE bind_mx; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON TABLE bind_mx IS 'DNS MX (mail exchanger) records';


--
-- Name: bind_ns; Type: TABLE; Schema: network; Owner: network; Tablespace: 
--

CREATE TABLE bind_ns (
    name hostname,
    id id DEFAULT new_id() NOT NULL,
    stereotype name,
    ctime timestamp with time zone DEFAULT now(),
    mtime timestamp with time zone DEFAULT now(),
    master hostname,
    value name NOT NULL
);


ALTER TABLE bind_ns OWNER TO network;

--
-- Name: TABLE bind_ns; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON TABLE bind_ns IS 'DNS NS (name server) records';


SET default_with_oids = true;

--
-- Name: config; Type: TABLE; Schema: network; Owner: network; Tablespace: 
--

CREATE TABLE config (
    query text NOT NULL,
    tablename text[],
    id integer DEFAULT new_id() NOT NULL,
    path text
);


ALTER TABLE config OWNER TO network;

--
-- Name: TABLE config; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON TABLE config IS 'Managed configuration files';


--
-- Name: COLUMN config.query; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON COLUMN config.query IS 'Query to run';


--
-- Name: COLUMN config.tablename; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON COLUMN config.tablename IS 'Tables to put AFTER STATEMENT triggers on to refresh the file';


--
-- Name: COLUMN config.path; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON COLUMN config.path IS 'Filename in /var/lib/postgresql/network/ tu put results into';


--
-- Name: cycle100; Type: SEQUENCE; Schema: network; Owner: network
--

CREATE SEQUENCE cycle100
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cycle100 OWNER TO network;

--
-- Name: cycle1000; Type: SEQUENCE; Schema: network; Owner: network
--

CREATE SEQUENCE cycle1000
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cycle1000 OWNER TO network;

--
-- Name: db_tables; Type: VIEW; Schema: network; Owner: network
--

CREATE VIEW db_tables AS
 SELECT c.oid AS sysid,
    n.nspname AS schema,
    c.relname AS name,
    ((c.oid)::regclass)::text AS sql_identifier,
        CASE c.relkind
            WHEN 'r'::"char" THEN 'table'::text
            WHEN 'v'::"char" THEN 'view'::text
            WHEN 'i'::"char" THEN 'index'::text
            WHEN 'S'::"char" THEN 'sequence'::text
            WHEN 's'::"char" THEN 'special'::text
            ELSE NULL::text
        END AS type,
    u.usename AS owner,
    obj_description(c.oid) AS comment,
    ((c.relname)::text || wrap(' - '::text, obj_description(c.oid))) AS label,
    c.relhasoids AS hasoids
   FROM ((pg_class c
     LEFT JOIN pg_user u ON ((c.relowner = u.usesysid)))
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE ((((c.relkind = ANY (ARRAY['r'::"char", 'v'::"char", ''::"char"])) AND has_table_privilege(c.oid, 'select'::text)) AND has_schema_privilege(n.oid, 'usage'::text)) AND (n.nspname !~~ 'pg_%'::text))
  ORDER BY c.oid, n.nspname;


ALTER TABLE db_tables OWNER TO network;

--
-- Name: VIEW db_tables; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON VIEW db_tables IS 'Database tables';


--
-- Name: db_triggers; Type: VIEW; Schema: network; Owner: network
--

CREATE VIEW db_triggers AS
 SELECT t.tgname AS trigger_name,
        CASE ((t.tgtype)::integer & 2)
            WHEN 2 THEN 'BEFORE'::text
            WHEN 0 THEN 'AFTER'::text
            ELSE NULL::text
        END AS action_order,
        CASE (((t.tgtype)::integer / 4) & 7)
            WHEN 1 THEN 'INSERT'::text
            WHEN 2 THEN 'DELETE'::text
            WHEN 3 THEN 'INSERT OR DELETE'::text
            WHEN 4 THEN 'UPDATE'::text
            WHEN 5 THEN 'INSERT OR UPDATE'::text
            WHEN 6 THEN 'UPDATE OR DELETE'::text
            WHEN 7 THEN 'INSERT OR UPDATE OR DELETE'::text
            ELSE NULL::text
        END AS event_manipulation,
    (sql_identifier(s.nspname, c.relname))::text AS event_object_sql_identifier,
    ((((sql_identifier(s1.nspname, p.proname))::text || '('::text) || sql_tgargs(t.tgargs)) || ')'::text) AS action_statement,
        CASE ((t.tgtype)::integer & 1)
            WHEN 1 THEN 'ROW'::text
            ELSE 'STATEMENT'::text
        END AS action_orientation,
    t.oid AS sysid,
    (c.oid)::regclass AS regclass,
    p.oid AS procid,
    (p.oid)::regprocedure AS regprocedure,
    s.nspname AS event_object_schema,
    c.relname AS event_object_table,
    ((quote_ident((t.tgname)::text) || ' ON '::text) || (sql_identifier(s.nspname, c.relname))::text) AS trigger_key
   FROM ((((pg_trigger t
     LEFT JOIN pg_class c ON ((c.oid = t.tgrelid)))
     LEFT JOIN pg_namespace s ON ((s.oid = c.relnamespace)))
     LEFT JOIN pg_proc p ON ((p.oid = t.tgfoid)))
     LEFT JOIN pg_namespace s1 ON ((s1.oid = p.pronamespace)))
  ORDER BY s.nspname, t.tgname, ((t.tgtype)::integer & 2) DESC;


ALTER TABLE db_triggers OWNER TO network;

--
-- Name: VIEW db_triggers; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON VIEW db_triggers IS 'Database triggers';


SET default_with_oids = false;

--
-- Name: dns_; Type: TABLE; Schema: network; Owner: network; Tablespace: 
--

CREATE TABLE dns_ (
    name hostname NOT NULL,
    cname hostname,
    fqdn full_dns_domain,
    mtime timestamp with time zone DEFAULT now(),
    description text
);


ALTER TABLE dns_ OWNER TO network;

--
-- Name: TABLE dns_; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON TABLE dns_ IS 'Template for individual domain tables';


--
-- Name: COLUMN dns_.name; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON COLUMN dns_.name IS 'Host name (*.name also ok)';


--
-- Name: COLUMN dns_.cname; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON COLUMN dns_.cname IS 'Canonical name in the same domain (alias)';


--
-- Name: COLUMN dns_.fqdn; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON COLUMN dns_.fqdn IS 'Fully qualified domain name with . at the end';


--
-- Name: COLUMN dns_.mtime; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON COLUMN dns_.mtime IS 'Record modification time';


--
-- Name: COLUMN dns_.description; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON COLUMN dns_.description IS 'Record comment';


--
-- Name: id_seq; Type: SEQUENCE; Schema: network; Owner: network
--

CREATE SEQUENCE id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE id_seq OWNER TO network;

SET default_with_oids = true;

--
-- Name: ip_name; Type: TABLE; Schema: network; Owner: network; Tablespace: 
--

CREATE TABLE ip_name (
    ip inet NOT NULL,
    nslookup text
);


ALTER TABLE ip_name OWNER TO network;

--
-- Name: TABLE ip_name; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON TABLE ip_name IS 'IP to name mapping cache';


--
-- Name: ipv4_ranges; Type: TABLE; Schema: network; Owner: network; Tablespace: 
--

CREATE TABLE ipv4_ranges (
    ip inet NOT NULL,
    label text
);


ALTER TABLE ipv4_ranges OWNER TO network;

--
-- Name: mac_manufacturer; Type: TABLE; Schema: network; Owner: network; Tablespace: 
--

CREATE TABLE mac_manufacturer (
    mac macaddr NOT NULL,
    manufacturer text
);


ALTER TABLE mac_manufacturer OWNER TO network;

--
-- Name: TABLE mac_manufacturer; Type: COMMENT; Schema: network; Owner: network
--

COMMENT ON TABLE mac_manufacturer IS 'MAC address manufactuter cache';


SET default_with_oids = false;

--
-- Name: mail_aliases; Type: TABLE; Schema: network; Owner: network; Tablespace: 
--

CREATE TABLE mail_aliases (
);


ALTER TABLE mail_aliases OWNER TO network;

--
-- Name: mailing_list; Type: TABLE; Schema: network; Owner: network; Tablespace: 
--

CREATE TABLE mailing_list (
    name text
);


ALTER TABLE mailing_list OWNER TO network;

--
-- Name: mysql_user; Type: TABLE; Schema: network; Owner: network; Tablespace: 
--

CREATE TABLE mysql_user (
    name name NOT NULL,
    id integer DEFAULT new_id() NOT NULL
);


ALTER TABLE mysql_user OWNER TO network;

--
-- Name: apache_vhost_pkey; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY apache_vhost
    ADD CONSTRAINT apache_vhost_pkey PRIMARY KEY (name);


--
-- Name: bind_a_name_key; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY bind_a
    ADD CONSTRAINT bind_a_name_key UNIQUE (name, master);


--
-- Name: bind_a_pkey; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY bind_a
    ADD CONSTRAINT bind_a_pkey PRIMARY KEY (id);


--
-- Name: bind_cname_name_key; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY bind_cname
    ADD CONSTRAINT bind_cname_name_key UNIQUE (name, master);


--
-- Name: bind_cname_pkey; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY bind_cname
    ADD CONSTRAINT bind_cname_pkey PRIMARY KEY (id);


--
-- Name: bind_master_name_key; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY bind_master
    ADD CONSTRAINT bind_master_name_key UNIQUE (name);


--
-- Name: bind_master_pkey; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY bind_master
    ADD CONSTRAINT bind_master_pkey PRIMARY KEY (name);


--
-- Name: bind_master_stereotype_pkey; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY bind_master_stereotype
    ADD CONSTRAINT bind_master_stereotype_pkey PRIMARY KEY (stereotype);


--
-- Name: bind_mx_name_key; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY bind_mx
    ADD CONSTRAINT bind_mx_name_key UNIQUE (name, master);


--
-- Name: bind_mx_pkey; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY bind_mx
    ADD CONSTRAINT bind_mx_pkey PRIMARY KEY (id);


--
-- Name: bind_ns_name_key; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY bind_ns
    ADD CONSTRAINT bind_ns_name_key UNIQUE (name, master);


--
-- Name: bind_ns_pkey; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY bind_ns
    ADD CONSTRAINT bind_ns_pkey PRIMARY KEY (id);


--
-- Name: config_path_key; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY config
    ADD CONSTRAINT config_path_key UNIQUE (path);


--
-- Name: config_pkey; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY config
    ADD CONSTRAINT config_pkey PRIMARY KEY (id);


--
-- Name: dns__pkey; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY dns_
    ADD CONSTRAINT dns__pkey PRIMARY KEY (name);


--
-- Name: ip_name_pkey; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY ip_name
    ADD CONSTRAINT ip_name_pkey PRIMARY KEY (ip);


--
-- Name: ipv4_ranges_pkey; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY ipv4_ranges
    ADD CONSTRAINT ipv4_ranges_pkey PRIMARY KEY (ip);


--
-- Name: mac_manufacturer_pkey; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY mac_manufacturer
    ADD CONSTRAINT mac_manufacturer_pkey PRIMARY KEY (mac);


--
-- Name: mysql_user_name_key; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY mysql_user
    ADD CONSTRAINT mysql_user_name_key UNIQUE (name);


--
-- Name: mysql_user_pkey; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY mysql_user
    ADD CONSTRAINT mysql_user_pkey PRIMARY KEY (id);


--
-- Name: service_pkey; Type: CONSTRAINT; Schema: network; Owner: network; Tablespace: 
--

ALTER TABLE ONLY service
    ADD CONSTRAINT service_pkey PRIMARY KEY (name);


--
-- Name: NETWORK_config_1009; Type: TRIGGER; Schema: network; Owner: network
--

CREATE TRIGGER "NETWORK_config_1009" AFTER INSERT OR DELETE OR UPDATE ON bind_master FOR EACH STATEMENT EXECUTE PROCEDURE config_trigger('config_zones');


--
-- Name: config_touch; Type: TRIGGER; Schema: network; Owner: network
--

CREATE TRIGGER config_touch AFTER INSERT OR DELETE OR UPDATE ON config FOR EACH ROW EXECUTE PROCEDURE config_touch();


--
-- Name: touch; Type: TRIGGER; Schema: network; Owner: network
--

CREATE TRIGGER touch BEFORE INSERT OR UPDATE ON bind_a FOR EACH ROW EXECUTE PROCEDURE bind_a_touch();


--
-- Name: touch; Type: TRIGGER; Schema: network; Owner: network
--

CREATE TRIGGER touch BEFORE INSERT OR DELETE OR UPDATE ON bind_master FOR EACH ROW EXECUTE PROCEDURE bind_master_touch();


--
-- Name: bind_master_stereotype_fkey; Type: FK CONSTRAINT; Schema: network; Owner: network
--

ALTER TABLE ONLY bind_master
    ADD CONSTRAINT bind_master_stereotype_fkey FOREIGN KEY (stereotype) REFERENCES bind_master_stereotype(stereotype);


--
-- Name: cname_for; Type: FK CONSTRAINT; Schema: network; Owner: network
--

ALTER TABLE ONLY bind_cname
    ADD CONSTRAINT cname_for FOREIGN KEY (cname_for) REFERENCES bind_a(id) DEFERRABLE;


--
-- Name: dns__cname_fkey; Type: FK CONSTRAINT; Schema: network; Owner: network
--

ALTER TABLE ONLY dns_
    ADD CONSTRAINT dns__cname_fkey FOREIGN KEY (cname) REFERENCES dns_(name) DEFERRABLE;


--
-- Name: master; Type: FK CONSTRAINT; Schema: network; Owner: network
--

ALTER TABLE ONLY bind_a
    ADD CONSTRAINT master FOREIGN KEY (master) REFERENCES bind_master(name) DEFERRABLE;


--
-- Name: master; Type: FK CONSTRAINT; Schema: network; Owner: network
--

ALTER TABLE ONLY bind_mx
    ADD CONSTRAINT master FOREIGN KEY (master) REFERENCES bind_master(name) DEFERRABLE;


--
-- Name: master; Type: FK CONSTRAINT; Schema: network; Owner: network
--

ALTER TABLE ONLY bind_cname
    ADD CONSTRAINT master FOREIGN KEY (master) REFERENCES bind_master(name) DEFERRABLE;


--
-- Name: master; Type: FK CONSTRAINT; Schema: network; Owner: network
--

ALTER TABLE ONLY bind_ns
    ADD CONSTRAINT master FOREIGN KEY (master) REFERENCES bind_master(name) DEFERRABLE;


--
-- Name: service; Type: ACL; Schema: network; Owner: network
--

REVOKE ALL ON TABLE service FROM PUBLIC;
REVOKE ALL ON TABLE service FROM network;
GRANT ALL ON TABLE service TO network;


--
-- Name: bind_a; Type: ACL; Schema: network; Owner: network
--

REVOKE ALL ON TABLE bind_a FROM PUBLIC;
REVOKE ALL ON TABLE bind_a FROM network;
GRANT ALL ON TABLE bind_a TO network;


--
-- Name: bind_a_conflict; Type: ACL; Schema: network; Owner: network
--

REVOKE ALL ON TABLE bind_a_conflict FROM PUBLIC;
REVOKE ALL ON TABLE bind_a_conflict FROM network;
GRANT ALL ON TABLE bind_a_conflict TO network;


--
-- Name: bind_cname; Type: ACL; Schema: network; Owner: network
--

REVOKE ALL ON TABLE bind_cname FROM PUBLIC;
REVOKE ALL ON TABLE bind_cname FROM network;
GRANT ALL ON TABLE bind_cname TO network;


--
-- Name: bind_master; Type: ACL; Schema: network; Owner: network
--

REVOKE ALL ON TABLE bind_master FROM PUBLIC;
REVOKE ALL ON TABLE bind_master FROM network;
GRANT ALL ON TABLE bind_master TO network;


--
-- Name: bind_master_stereotype; Type: ACL; Schema: network; Owner: network
--

REVOKE ALL ON TABLE bind_master_stereotype FROM PUBLIC;
REVOKE ALL ON TABLE bind_master_stereotype FROM network;
GRANT ALL ON TABLE bind_master_stereotype TO network;


--
-- Name: bind_mx; Type: ACL; Schema: network; Owner: network
--

REVOKE ALL ON TABLE bind_mx FROM PUBLIC;
REVOKE ALL ON TABLE bind_mx FROM network;
GRANT ALL ON TABLE bind_mx TO network;


--
-- Name: bind_ns; Type: ACL; Schema: network; Owner: network
--

REVOKE ALL ON TABLE bind_ns FROM PUBLIC;
REVOKE ALL ON TABLE bind_ns FROM network;
GRANT ALL ON TABLE bind_ns TO network;


--
-- Name: dns_; Type: ACL; Schema: network; Owner: network
--

REVOKE ALL ON TABLE dns_ FROM PUBLIC;
REVOKE ALL ON TABLE dns_ FROM network;
GRANT ALL ON TABLE dns_ TO network;


--
-- Name: ip_name; Type: ACL; Schema: network; Owner: network
--

REVOKE ALL ON TABLE ip_name FROM PUBLIC;
REVOKE ALL ON TABLE ip_name FROM network;
GRANT ALL ON TABLE ip_name TO network;


--
-- Name: ipv4_ranges; Type: ACL; Schema: network; Owner: network
--

REVOKE ALL ON TABLE ipv4_ranges FROM PUBLIC;
REVOKE ALL ON TABLE ipv4_ranges FROM network;
GRANT ALL ON TABLE ipv4_ranges TO network;


--
-- Name: mac_manufacturer; Type: ACL; Schema: network; Owner: network
--

REVOKE ALL ON TABLE mac_manufacturer FROM PUBLIC;
REVOKE ALL ON TABLE mac_manufacturer FROM network;
GRANT ALL ON TABLE mac_manufacturer TO network;


--
-- PostgreSQL database dump complete
--

