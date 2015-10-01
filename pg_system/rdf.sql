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
-- Name: rdf; Type: SCHEMA; Schema: -; Owner: rdf
--

CREATE SCHEMA rdf;


ALTER SCHEMA rdf OWNER TO rdf;

--
-- Name: SCHEMA rdf; Type: COMMENT; Schema: -; Owner: rdf
--

COMMENT ON SCHEMA rdf IS 'MyRDF - Resource Description Framework Toolkit for PostgreSQL';


SET search_path = rdf, pg_catalog;

--
-- Name: json; Type: DOMAIN; Schema: rdf; Owner: rdf
--

CREATE DOMAIN json AS text;


ALTER DOMAIN json OWNER TO rdf;

--
-- Name: lang; Type: DOMAIN; Schema: rdf; Owner: rdf
--

CREATE DOMAIN lang AS pg_catalog.name;


ALTER DOMAIN lang OWNER TO rdf;

--
-- Name: literal; Type: DOMAIN; Schema: rdf; Owner: rdf
--

CREATE DOMAIN literal AS text;


ALTER DOMAIN literal OWNER TO rdf;

--
-- Name: name; Type: DOMAIN; Schema: rdf; Owner: rdf
--

CREATE DOMAIN name AS pg_catalog.name;


ALTER DOMAIN name OWNER TO rdf;

--
-- Name: nid; Type: DOMAIN; Schema: rdf; Owner: rdf
--

CREATE DOMAIN nid AS bigint;


ALTER DOMAIN nid OWNER TO rdf;

--
-- Name: property_partition_type; Type: DOMAIN; Schema: rdf; Owner: rdf
--

CREATE DOMAIN property_partition_type AS pg_catalog.name
	CONSTRAINT property_partition_type_check CHECK ((VALUE = ANY (ARRAY['none'::pg_catalog.name, 'table'::pg_catalog.name, 'view'::pg_catalog.name])));


ALTER DOMAIN property_partition_type OWNER TO rdf;

--
-- Name: sid; Type: DOMAIN; Schema: rdf; Owner: rdf
--

CREATE DOMAIN sid AS bigint;


ALTER DOMAIN sid OWNER TO rdf;

--
-- Name: turtle; Type: DOMAIN; Schema: rdf; Owner: rdf
--

CREATE DOMAIN turtle AS text;


ALTER DOMAIN turtle OWNER TO rdf;

--
-- Name: uri; Type: DOMAIN; Schema: rdf; Owner: rdf
--

CREATE DOMAIN uri AS character varying;


ALTER DOMAIN uri OWNER TO rdf;

--
-- Name: url; Type: DOMAIN; Schema: rdf; Owner: rdf
--

CREATE DOMAIN url AS character varying;


ALTER DOMAIN url OWNER TO rdf;

--
-- Name: xid; Type: DOMAIN; Schema: rdf; Owner: rdf
--

CREATE DOMAIN xid AS bigint;


ALTER DOMAIN xid OWNER TO rdf;

--
-- Name: assert(nid, nid, nid, numeric); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION assert(model nid, subject nid, predicate nid, literal numeric) RETURNS nid
    LANGUAGE sql
    AS $_$
 select rdf.assert($1,$2,$3,cast($4 as text),rdf.datatype('xsd:decimal',$1));
$_$;


ALTER FUNCTION rdf.assert(model nid, subject nid, predicate nid, literal numeric) OWNER TO rdf;

--
-- Name: assert(nid, nid, nid, text); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION assert(model nid, subject nid, predicate nid, literal text) RETURNS nid
    LANGUAGE sql
    AS $_$
 select rdf.assert($1,$2,$3,$4,rdf.datatype('xsd:string',$1));
$_$;


ALTER FUNCTION rdf.assert(model nid, subject nid, predicate nid, literal text) OWNER TO rdf;

--
-- Name: assert(nid, nid, nid, nid); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION assert(my_model nid, my_subject nid, my_predicate nid, my_object nid) RETURNS nid
    LANGUAGE plpgsql
    AS $$declare
 my_sid rdf.nid;
begin
 insert into rdf.statement 
  (model,subject,predicate,object) 
 values 
  (my_model,my_subject,my_object)
 returning sid
 into my_sid;

 return my_sid;
end
$$;


ALTER FUNCTION rdf.assert(my_model nid, my_subject nid, my_predicate nid, my_object nid) OWNER TO rdf;

--
-- Name: assert(nid, turtle, turtle, turtle); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION assert(model nid, subject turtle, predicate turtle, object turtle) RETURNS nid
    LANGUAGE plperl IMMUTABLE
    AS $$$$;


ALTER FUNCTION rdf.assert(model nid, subject turtle, predicate turtle, object turtle) OWNER TO postgres;

--
-- Name: FUNCTION assert(model nid, subject turtle, predicate turtle, object turtle); Type: COMMENT; Schema: rdf; Owner: postgres
--

COMMENT ON FUNCTION assert(model nid, subject turtle, predicate turtle, object turtle) IS 'TODO!';


--
-- Name: assert(nid, uri, uri, uri); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION assert(model nid, subject uri, predicate uri, object uri) RETURNS nid
    LANGUAGE plperl IMMUTABLE
    AS $$$$;


ALTER FUNCTION rdf.assert(model nid, subject uri, predicate uri, object uri) OWNER TO postgres;

--
-- Name: FUNCTION assert(model nid, subject uri, predicate uri, object uri); Type: COMMENT; Schema: rdf; Owner: postgres
--

COMMENT ON FUNCTION assert(model nid, subject uri, predicate uri, object uri) IS 'TODO!';


--
-- Name: assert(nid, nid, nid, text, lang); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION assert(my_model nid, my_subject nid, my_predicate nid, my_literal text, my_language lang) RETURNS nid
    LANGUAGE plpgsql
    AS $$declare
 my_sid rdf.nid;
begin
 insert into rdf.statement 
  (model,subject,predicate,literal,lang) 
 values 
  (my_model,my_subject,my_predicate,my_literal,my_language)
 returning sid
 into my_sid;

 return my_sid;
end$$;


ALTER FUNCTION rdf.assert(my_model nid, my_subject nid, my_predicate nid, my_literal text, my_language lang) OWNER TO rdf;

--
-- Name: assert(nid, nid, nid, text, nid); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION assert(my_model nid, my_subject nid, my_predicate nid, my_literal text, my_datatype nid) RETURNS nid
    LANGUAGE plpgsql
    AS $$declare
 my_sid rdf.nid;
begin
 insert into rdf.statement 
  (model,subject,predicate,literal,literal_datatype) 
 values 
  (my_model,my_subject,my_predicate,my_literal,my_datatype)
 returning sid
 into my_sid;

 return my_sid;
end
$$;


ALTER FUNCTION rdf.assert(my_model nid, my_subject nid, my_predicate nid, my_literal text, my_datatype nid) OWNER TO rdf;

--
-- Name: count_resources(nid); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION count_resources(nid) RETURNS bigint
    LANGUAGE sql
    AS $_$select count(*)
  from rdf.resource
 where owner = $1
$_$;


ALTER FUNCTION rdf.count_resources(nid) OWNER TO postgres;

--
-- Name: count_statements(nid); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION count_statements(nid) RETURNS bigint
    LANGUAGE sql
    AS $_$select count(*)
  from rdf.statement
 where model = $1
$_$;


ALTER FUNCTION rdf.count_statements(nid) OWNER TO postgres;

--
-- Name: datatype(uri); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION datatype(uri) RETURNS nid
    LANGUAGE sql STABLE
    AS $_$
select nid 
  from rdf.datatype
 where nid = rdf.resource($1)
$_$;


ALTER FUNCTION rdf.datatype(uri) OWNER TO rdf;

--
-- Name: datatype(url, nid); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION datatype(url, nid) RETURNS nid
    LANGUAGE plpgsql
    AS $_$declare
 my_uri alias for $1;
 my_model alias for $2;
 my_datatype record;
 my_nid rdf.nid;
begin

 select * from rdf.resource r
   join rdf.datatype d using (nid)
  where r.uri=my_uri
   into my_datatype;

 if not found then
  my_nid := rdf.resource(my_uri,my_model);
  insert into rdf.datatype (nid) values (my_nid);
  return my_nid;
 end if;

 return my_datatype.nid;
end
$_$;


ALTER FUNCTION rdf.datatype(url, nid) OWNER TO rdf;

--
-- Name: datatype_isa_resource(); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION datatype_isa_resource() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin

 if TG_OP in ('INSERT','UPDATE') then
  return NEW;
 end if;

 if TG_OP in ('DELETE') then
  return OLD;
 end if;

end;
$$;


ALTER FUNCTION rdf.datatype_isa_resource() OWNER TO postgres;

--
-- Name: domain_from_uri(uri); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION domain_from_uri(uri) RETURNS character varying
    LANGUAGE plperl IMMUTABLE
    AS $_$my $url=shift;
my $domain;
if($url=~m|^\w+://([^/]+)|) {
 $domain=lc($1);
}
return $domain;
$_$;


ALTER FUNCTION rdf.domain_from_uri(uri) OWNER TO postgres;

--
-- Name: iri_ident(text); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION iri_ident(text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_$
  my ($url)=@_;
  if($url=~s!([/#])([_\-a-zA-Z0-9]+)$!$1!) { return $2; }
  return undef;
$_$;


ALTER FUNCTION rdf.iri_ident(text) OWNER TO rdf;

--
-- Name: iri_prefix(text); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION iri_prefix(text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_$
  my ($url)=@_;
  if($url=~s!([/#])([_\-a-zA-Z0-9]+)$!$1!) { return $url; }
  return undef;
$_$;


ALTER FUNCTION rdf.iri_prefix(text) OWNER TO rdf;

--
-- Name: language(text); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION language(text) RETURNS lang
    LANGUAGE plpgsql STRICT
    AS $_$declare
 my_language text;
begin
 select language
   from rdf.language 
  where language=$1
   into my_language;
 if not found then
  insert into rdf.language (language) values ($1);
 end if;
 return $1::rdf.lang;
end
$_$;


ALTER FUNCTION rdf.language(text) OWNER TO postgres;

--
-- Name: nid(); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION nid() RETURNS nid
    LANGUAGE sql
    AS $$select nextval('rdf.nid_seq')::rdf.nid$$;


ALTER FUNCTION rdf.nid() OWNER TO rdf;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: model; Type: TABLE; Schema: rdf; Owner: rdf; Tablespace: 
--

CREATE TABLE model (
    nid nid DEFAULT nid() NOT NULL,
    source url,
    loaded boolean DEFAULT false NOT NULL
);


ALTER TABLE model OWNER TO rdf;

--
-- Name: TABLE model; Type: COMMENT; Schema: rdf; Owner: rdf
--

COMMENT ON TABLE model IS 'RDF models';


--
-- Name: load(model); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION load(model) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
begin
 update rdf.model set loaded=true where nid=$1.nid;
 return 1;
end
$_$;


ALTER FUNCTION rdf.load(model) OWNER TO postgres;

--
-- Name: resource; Type: TABLE; Schema: rdf; Owner: rdf; Tablespace: 
--

CREATE TABLE resource (
    nid nid DEFAULT nid() NOT NULL,
    uri uri,
    owner nid
);


ALTER TABLE resource OWNER TO rdf;

--
-- Name: TABLE resource; Type: COMMENT; Schema: rdf; Owner: rdf
--

COMMENT ON TABLE resource IS 'RDF resources';


--
-- Name: load(resource); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION load(resource) RETURNS integer
    LANGUAGE sql
    AS $_$
select rdf.model_load($1.uri)
$_$;


ALTER FUNCTION rdf.load(resource) OWNER TO postgres;

--
-- Name: model(); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION model() RETURNS nid
    LANGUAGE sql
    AS $$
select rdf.model('user:'||user)
$$;


ALTER FUNCTION rdf.model() OWNER TO rdf;

--
-- Name: model(url); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION model(url) RETURNS nid
    LANGUAGE plpgsql
    AS $_$declare
 my_uri text;
 my_model record;
 my_nid rdf.nid;
begin
 my_uri := rdf.url_canonical($1);

 select * from rdf.model where source=my_uri
 into my_model;

 if not found then
  my_nid := rdf.resource(my_uri,null);
  
  insert into rdf.model (nid,source) values (my_nid,my_uri);

  return my_nid;
 end if;

 return my_model.nid;
end
$_$;


ALTER FUNCTION rdf.model(url) OWNER TO postgres;

--
-- Name: model_isa_resource(); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION model_isa_resource() RETURNS trigger
    LANGUAGE plpgsql
    AS $$begin

 if TG_OP in ('INSERT','UPDATE') then
   return NEW;
 end if;

 if TG_OP in ('DELETE') then
  delete from rdf.resource where nid = OLD.nid;
  return OLD;
 end if;

end;
$$;


ALTER FUNCTION rdf.model_isa_resource() OWNER TO postgres;

--
-- Name: model_load(url); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION model_load(url) RETURNS integer
    LANGUAGE plpgsql
    AS $_$declare
 my_model rdf.nid;
begin
 my_model := rdf.model($1);
 update rdf.model set loaded=true where nid=my_model;
 return 1;
end
$_$;


ALTER FUNCTION rdf.model_load(url) OWNER TO postgres;

--
-- Name: model_loader(); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION model_loader() RETURNS trigger
    LANGUAGE plpgsql
    AS $$begin

 if TG_OP='INSERT' and new.loaded then
   raise notice 'LOAD NEW %',new.source;
   perform rdf.model_update(new.source);
 end if;

 if TG_OP='UPDATE' then
   if not new.loaded and old.loaded then
     raise notice 'UNLOAD %',new.source;
-- delete statements
     delete from rdf.statement 
       where model=new.nid;
-- delete blank nodes
     delete from rdf.resource 
      where uri like '_:%'
        and owner=new.nid;
   elsif new.loaded and not old.loaded then
     raise notice 'LOAD %',new.source;
     perform rdf.model_update(new.source);
   end if;
 end if;

 if TG_OP='DELETE' then
   raise notice 'UNLOAD_DELETE %',old.source;
-- delete statements
   delete from rdf.statement 
    where model=old.nid;
-- delete blank nodes
   delete from rdf.resource 
    where uri like '_:%'
      and owner=old.nid;
 end if;

 if TG_OP='DELETE' then return old;
 else return new; end if;

end;
$$;


ALTER FUNCTION rdf.model_loader() OWNER TO postgres;

--
-- Name: model_replace(url); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION model_replace(url) RETURNS integer
    LANGUAGE plperl IMMUTABLE
    AS $$$$;


ALTER FUNCTION rdf.model_replace(url) OWNER TO postgres;

--
-- Name: FUNCTION model_replace(url); Type: COMMENT; Schema: rdf; Owner: postgres
--

COMMENT ON FUNCTION model_replace(url) IS 'TODO!';


--
-- Name: model_update(url); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION model_update(url) RETURNS integer
    LANGUAGE plperlu
    AS $_$
use RDF::Redland;

my $url = shift;
my $uri    = new RDF::Redland::URI($url);
my $parser = new RDF::Redland::Parser("rdfxml");
my $stream = $parser->parse_as_stream($uri);

my %q=(
 model_id =>spi_prepare('SELECT rdf.model($1) AS model','rdf.url'),
 resource2=>spi_prepare('SELECT rdf.resource($1,$2) AS subj, rdf.property($3,$4) AS pred',
                        'rdf.url','rdf.nid','rdf.url','rdf.nid'),
 resource3=>spi_prepare('SELECT rdf.resource($1,$2) AS subj, rdf.property($3,$4) AS pred, rdf.resource($5,$6) AS obj',
                        'rdf.url','rdf.nid','rdf.url','rdf.nid','rdf.url','rdf.nid'),
 statementC=>spi_prepare('DELETE FROM rdf.statement WHERE model=$1','rdf.nid'),
 statement2=>spi_prepare('INSERT INTO rdf.statement (model,subject,predicate,literal,lang) 
                          VALUES ($1,rdf.resource($2,$1),rdf.property($3,$1),$4,$5)',
                         'rdf.nid','rdf.url','rdf.url','rdf.literal','rdf.lang'),
 statement3=>spi_prepare('INSERT INTO rdf.statement (model,subject,predicate,object) 
                          VALUES ($1,rdf.resource($2,$1),rdf.property($3,$1),rdf.resource($4,$1))',
                         'rdf.nid','rdf.url','rdf.url','rdf.url')
);

my $model_id = spi_exec_prepared($q{model_id},$url)->{rows}->[0]->{model};

elog(NOTICE,"Model #$model_id");
spi_exec_prepared($q{statementC},$model_id);

my $i=0;

while($stream && !$stream->end()) {
  my $st = $stream->current;
  my $sub  = $st->subject();
  my $pred = $st->predicate();
  my $obj  = $st->object();
  my ($urls,$urlp,$urlo);

  $urlp=$pred->uri()->as_string();

  if($sub->is_resource()) {
    $urls=$sub->uri()->as_string();
  }
  elsif($sub->is_blank()) {
    $urls="_:".$sub->blank_identifier();
  }
  else {
    elog(ERROR,$st->as_string());
  }

  if($obj->is_literal()) {
    my $value=$obj->literal_value();
    my $lang =$obj->literal_value_language();
    if(!defined($value)) { 
#      elog(ERROR,$st->as_string());
      $value=""; 
    } ### WHAT'S THIS THEN!!!
#    elog(NOTICE,"<$urls> <$urlp> \"$value\"@$lang");  
    spi_exec_prepared($q{statement2},$model_id,$urls,$urlp,$value,$lang);
  } else {
    if($obj->is_resource()) {
      $urlo=$obj->uri()->as_string();
    }
    elsif($obj->is_blank()) {
      $urlo="_:".$obj->blank_identifier();
    }
#    elog(NOTICE,"<$urls> <$urlp> <$urlo>");  
    spi_exec_prepared($q{statement3},$model_id,$urls,$urlp,$urlo);
  }

  $stream->next; $i++;
}

return $i;
$_$;


ALTER FUNCTION rdf.model_update(url) OWNER TO postgres;

--
-- Name: namespace_isa_resource(); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION namespace_isa_resource() RETURNS trigger
    LANGUAGE plpgsql
    AS $$begin
 if TG_OP = 'UPDATE' then
   if new.uri is distinct from old.uri then
      raise exception 'Cannot modify namespace URI. Delete and reinsert.';
   end if;
 end if;

 if TG_OP in ('INSERT','UPDATE') then
  NEW.nid=rdf.resource(NEW.uri,NULL);
  return NEW;
 end if;

 if TG_OP in ('DELETE') then
  return OLD;
 end if;

end;
$$;


ALTER FUNCTION rdf.namespace_isa_resource() OWNER TO postgres;

--
-- Name: namespace_touch(); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION namespace_touch() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
 if tg_op in ('INSERT','UPDATE') then
  update rdf.property
     set nid=nid
   where uri like new.uri||'%';
  return new;
 end if;

 if tg_op = 'DELETE' then
  update rdf.property
     set nid=nid
   where uri like old.uri||'%';
  return old;
 end if;

end
$$;


ALTER FUNCTION rdf.namespace_touch() OWNER TO postgres;

--
-- Name: predicate(url); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION predicate(url) RETURNS nid
    LANGUAGE sql STABLE STRICT
    AS $_$select nid from rdf.property where uri=$1$_$;


ALTER FUNCTION rdf.predicate(url) OWNER TO postgres;

--
-- Name: property(text); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION property(text) RETURNS nid
    LANGUAGE sql STABLE
    AS $_$select nid from rdf.property where name=$1 or uri=$1$_$;


ALTER FUNCTION rdf.property(text) OWNER TO postgres;

--
-- Name: property(url, nid); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION property(url, nid) RETURNS nid
    LANGUAGE plpgsql
    AS $_$declare
 my_uri alias for $1;
 my_model alias for $2;
 my_property record;
 my_nid rdf.nid;
begin

 select p.* from rdf.property p 
  where p.uri=my_uri
   into my_property;

 if not found then
  my_nid := rdf.resource(my_uri,my_model);
  insert into rdf.property (nid,uri) values (my_nid,my_uri);
  return my_nid;
 end if;

 return my_property.nid;
end
$_$;


ALTER FUNCTION rdf.property(url, nid) OWNER TO postgres;

--
-- Name: property_isa_resource(); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION property_isa_resource() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin

 if TG_OP in ('INSERT','UPDATE') then
  return NEW;
 end if;

 if TG_OP in ('DELETE') then
  return OLD;
 end if;

end;
$$;


ALTER FUNCTION rdf.property_isa_resource() OWNER TO postgres;

--
-- Name: property_partition(); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION property_partition() RETURNS trigger
    LANGUAGE plpgsql
    AS $$declare
 my_ident varchar;
begin

 if tg_op = 'UPDATE' then
  if old.partition = new.partition then
   return new;
  end if;
 end if;

 if tg_op in ('UPDATE','DELETE') then
  my_ident = 'rdf.'||quote_ident(old.name);
  if old.partition = 'view' then
   execute 'drop view ' || my_ident;
  elsif old.partition = 'table' then
   execute 'insert into rdf.statement select * from ' || my_ident;
   execute 'drop table ' || my_ident;
  end if;
 end if;

 if tg_op in ('INSERT','UPDATE') then
  if new.partition in ('view','table') then
   my_ident = 'rdf.'||quote_ident(new.name);
   if my_ident is null then 
     raise exception 'Property must have a name. Perhaps you need to define a namespace for this property?';
   end if;
   if new.partition = 'view' then
    raise notice 'PARTITION VIEW %',my_ident;
    execute 'create view ' || my_ident ||
            ' as select 
               rdf.turtle_uri(subject) as turtle_subject,
               rdf.turtle_object(s) as turtle_object,
               *
              from rdf.statement s ' ||
            ' where predicate=rdf.predicate(' || quote_literal(new.uri) || ')';
   elsif new.partition = 'table' then
    raise notice 'PARTITION TABLE %',my_ident;
    execute 'create table ' || my_ident || '() inherits(rdf.statement)';
    execute 'alter table ' || my_ident || ' add primary key (sid)';
    execute 'alter table ' || my_ident || ' add constraint "partition" ' ||
            ' check(predicate=rdf.predicate(' || quote_literal(new.uri) || '))';
    execute 'insert into ' || my_ident || ' select * from rdf.statement ' ||
            ' where predicate=rdf.predicate(' || quote_literal(new.uri) || ')';
    execute 'delete from only rdf.statement ' ||
            ' where predicate=rdf.predicate(' || quote_literal(new.uri) || ')';
   end if;
  end if;
 end if;

 if tg_op = 'DELETE' then return old;
 else return new; end if;
end
$$;


ALTER FUNCTION rdf.property_partition() OWNER TO postgres;

--
-- Name: property_touch(); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION property_touch() RETURNS trigger
    LANGUAGE plpgsql
    AS $$declare
 my_namespace record;
begin
 if TG_OP in ('INSERT','UPDATE') then
  select into my_namespace * 
    from rdf.namespace n
   where NEW.uri like n.uri || '%';
  if found then
    NEW.name := my_namespace.name||':'||substr(NEW.uri,length(my_namespace.uri)+1);
  else
    NEW.name := NULL;
  end if;
  return NEW;
 end if;
end
$$;


ALTER FUNCTION rdf.property_touch() OWNER TO postgres;

--
-- Name: purge(); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION purge() RETURNS integer
    LANGUAGE plpgsql
    AS $$declare
 n integer;
 i integer;
begin
 n := 0;

 delete from rdf.resource
  where ( not ( 
    nid in (select nid from rdf.model)
    or nid in (select nid from rdf.namespace)
    or owner in (select nid from rdf.model where loaded)
    or nid in (select nid from rdf.property)
    or nid in (select distinct subject from rdf.statement)
    or nid in (select distinct predicate from rdf.statement)
    or nid in (select distinct object from rdf.statement where object is not null)
  ));
 get diagnostics i = row_count;
 n := n + i;

 return n;
end
$$;


ALTER FUNCTION rdf.purge() OWNER TO postgres;

--
-- Name: sid(); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION sid() RETURNS nid
    LANGUAGE sql
    AS $$select nextval('rdf.sid_seq')::rdf.nid$$;


ALTER FUNCTION rdf.sid() OWNER TO rdf;

--
-- Name: datatype; Type: TABLE; Schema: rdf; Owner: rdf; Tablespace: 
--

CREATE TABLE datatype (
    nid nid DEFAULT nid() NOT NULL
);


ALTER TABLE datatype OWNER TO rdf;

--
-- Name: TABLE datatype; Type: COMMENT; Schema: rdf; Owner: rdf
--

COMMENT ON TABLE datatype IS 'RDF datatypes';


--
-- Name: property; Type: TABLE; Schema: rdf; Owner: rdf; Tablespace: 
--

CREATE TABLE property (
    nid nid DEFAULT nid() NOT NULL,
    name pg_catalog.name,
    uri uri NOT NULL,
    partition property_partition_type DEFAULT 'none'::pg_catalog.name,
    view_name name
);


ALTER TABLE property OWNER TO rdf;

--
-- Name: TABLE property; Type: COMMENT; Schema: rdf; Owner: rdf
--

COMMENT ON TABLE property IS 'RDF properties';


--
-- Name: statement; Type: TABLE; Schema: rdf; Owner: rdf; Tablespace: 
--

CREATE TABLE statement (
    sid nid DEFAULT sid() NOT NULL,
    subject nid NOT NULL,
    predicate nid NOT NULL,
    object nid,
    literal literal,
    literal_datatype nid,
    lang lang,
    context nid,
    model nid NOT NULL,
    ord integer DEFAULT 1 NOT NULL,
    CONSTRAINT validator CHECK ((((object IS NULL) AND (literal IS NOT NULL)) OR ((object IS NOT NULL) AND (literal IS NULL))))
);


ALTER TABLE statement OWNER TO rdf;

--
-- Name: TABLE statement; Type: COMMENT; Schema: rdf; Owner: rdf
--

COMMENT ON TABLE statement IS 'RDF statements';


--
-- Name: statement_view; Type: VIEW; Schema: rdf; Owner: rdf
--

CREATE VIEW statement_view AS
 SELECT sub.uri AS subject,
    pred.uri AS predicate,
    obj.uri AS object,
    st.literal,
    NULL::unknown AS literal_datatype,
    st.lang
   FROM ((((statement st
     JOIN resource sub ON (((sub.nid)::bigint = (st.subject)::bigint)))
     JOIN property pred ON (((pred.nid)::bigint = (st.predicate)::bigint)))
     LEFT JOIN resource obj ON (((obj.nid)::bigint = (st.object)::bigint)))
     LEFT JOIN datatype dt ON (((dt.nid)::bigint = (st.literal_datatype)::bigint)));


ALTER TABLE statement_view OWNER TO rdf;

--
-- Name: query_subject(nid, uri); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION query_subject(my_model nid, my_url uri) RETURNS SETOF statement_view
    LANGUAGE sql
    AS $_$
 SELECT sub.uri AS subject, pred.uri AS predicate, obj.uri AS object, st.literal, NULL::unknown AS literal_datatype, st.lang
   FROM rdf.statement st
   JOIN rdf.resource sub ON sub.nid::bigint = st.subject::bigint
   JOIN rdf.property pred ON pred.nid::bigint = st.predicate::bigint
   LEFT JOIN rdf.resource obj ON obj.nid::bigint = st.object::bigint
   LEFT JOIN rdf.datatype dt ON dt.nid::bigint = st.literal_datatype::bigint
  WHERE model = $1
    AND (sub.uri = $2 OR sub.uri LIKE $2||'#%');
$_$;


ALTER FUNCTION rdf.query_subject(my_model nid, my_url uri) OWNER TO rdf;

--
-- Name: replace(nid, nid, nid, text); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION replace(model nid, subject nid, predicate nid, literal text) RETURNS nid
    LANGUAGE sql
    AS $_$
 select rdf.replace($1,$2,$3,$4,rdf.datatype('xsd:string',$1));
$_$;


ALTER FUNCTION rdf.replace(model nid, subject nid, predicate nid, literal text) OWNER TO rdf;

--
-- Name: replace(nid, nid, nid, text, lang); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION replace(my_model nid, my_subject nid, my_predicate nid, my_literal text, my_language lang) RETURNS nid
    LANGUAGE plpgsql
    AS $$declare
 my_sid rdf.nid;
begin
 perform rdf.retract(my_model, my_subject, my_predicate,my_language);
 my_sid := rdf.assert(my_model, my_subject, my_predicate, my_literal, my_language);
 return my_sid;
end
$$;


ALTER FUNCTION rdf.replace(my_model nid, my_subject nid, my_predicate nid, my_literal text, my_language lang) OWNER TO rdf;

--
-- Name: replace(nid, nid, nid, text, nid); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION replace(my_model nid, my_subject nid, my_predicate nid, my_literal text, my_datatype nid) RETURNS nid
    LANGUAGE plpgsql
    AS $$declare
 my_sid rdf.nid;
begin
 perform rdf.retract(my_model, my_subject, my_predicate);
 my_sid := rdf.assert(my_model, my_subject, my_predicate, my_literal, my_datatype);
 return my_sid;
end
$$;


ALTER FUNCTION rdf.replace(my_model nid, my_subject nid, my_predicate nid, my_literal text, my_datatype nid) OWNER TO rdf;

--
-- Name: request_json(nid, json); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION request_json(my_model nid, my_json json) RETURNS json
    LANGUAGE plperlu
    AS $_X$
my ($model_id)=@_;

use strict;
use JSON;
use Data::Dumper;

my $json=JSON->new->relaxed->allow_nonref;
my $req=$json->decode($_[1]);
my $res={};

if(!defined($req)) { elog(ERROR,'Empty JSON request'); return undef; } 
my $obj = $req->{rdf}; if(!$obj) { $obj={}; }
if(ref($obj) ne 'HASH') { elog(ERROR,'RDF JSON not HASH'); return undef; }
my $load = $req->{load}; if(!$load) { $load=[]; }
if(ref($load) ne 'ARRAY') { elog(ERROR,'LOAD JSON not ARRAY'); return undef; }

my $n=0;
my %nid;
my %q=(
 'resource'     => spi_prepare('select rdf.resource($1,$2) as nid','rdf.url','rdf.nid'),
 'predicate'    => spi_prepare('select rdf.property($1,$2) as nid','rdf.url','rdf.nid'),
 'retract'      => spi_prepare('select rdf.retract($1,$2,$3)','rdf.nid','rdf.nid','rdf.nid'),
 'assert'       => spi_prepare('select rdf.assert($1,$2,$3,cast($4 as text)) as sid','rdf.nid','rdf.nid','rdf.nid','text'),
 'query'        => spi_prepare('select * from rdf.query_subject($1,$2)','rdf.nid','rdf.url'),
 'xid'          => spi_prepare('select rdf.xid()')
);

# get net transaction id
 $res->{xid}=100;
# FIXME: get proper xid
# $res->{xid}=spi_query_prepared($q{xid})->{rows}->[0]->{xid};
# replace 
for my $si (sort(keys(%{$obj}))) {
  my $subject_id;
  if(defined($nid{$si})) { $subject_id = $nid{$si}; }
  else { 
    $subject_id = spi_exec_prepared($q{resource},$si,$model_id)->{rows}->[0]->{nid}; 
    $nid{$si}=$subject_id; 
  }
  my $s = $obj->{$si};
  for my $pi (sort(keys(%{$s}))) {
    my $predicate_id;
    if(defined($nid{$pi})) { $predicate_id = $nid{$pi}; }
    else { 
      $predicate_id = spi_exec_prepared($q{predicate},$pi,$model_id)->{rows}->[0]->{nid}; 
      $nid{$pi}=$predicate_id; 
    }
    my $sp = $s->{$pi};
    spi_exec_prepared($q{retract},$model_id,$subject_id,$predicate_id);
    for my $oi (@{$sp}) {
      my $v=$oi->{value};
      if(defined($v)) {
        spi_exec_prepared($q{assert},$model_id,$subject_id,$predicate_id,"$oi->{value}");
        elog(NOTICE,"$si($subject_id) -> $pi($predicate_id) -> $v");
	$n++;
      }
    }
  }
}
$res->{updates}=$n;

# load 
# FIXME: load all URL, not only first one!
if($load->[0]) {
 my $rdf;
 my $subject = $load->[0];
 my $sth = spi_query_prepared($q{query},$model_id,$subject);
 while (defined (my $row = spi_fetchrow($sth))) {
    my $tripl={};
    if(defined($row->{object})) {
      $tripl={value=>$row->{object},type=>'uri'};
    } else {
      $tripl={value=>$row->{literal},type=>'literal'};
      if(defined($row->{literal_datatype})) { 
        $tripl->{datatype}=$row->{literal_datatype};
      }
    }
    if(!$rdf->{$row->{subject}}) { $rdf->{$row->{subject}}={}; }
    my $s=$rdf->{$row->{subject}};
    if(!$s->{$row->{predicate}}) { $s->{$row->{predicate}}=[]; }
    push @{$s->{$row->{predicate}}},$tripl;
 }
 $res->{rdf}=$rdf;
}

return to_json($res);
$_X$;


ALTER FUNCTION rdf.request_json(my_model nid, my_json json) OWNER TO rdf;

--
-- Name: resource(uri); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION resource(uri) RETURNS nid
    LANGUAGE sql
    AS $_$select nid from rdf.resource where uri=$1$_$;


ALTER FUNCTION rdf.resource(uri) OWNER TO postgres;

--
-- Name: resource(url, nid); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION resource(url, nid) RETURNS nid
    LANGUAGE plpgsql
    AS $_$declare
 my_uri alias for $1;
 my_model rdf.nid;
 my_model_url text;
 my_resource record;
 my_nid rdf.nid;
begin
 my_model := $2;

/*
 if my_model is null then
  my_model_url := 'user:'||current_user;
  raise notice 'Model not specified, using %',my_model_url;
  my_model := rdf.model(my_model_url);
 end if;
*/

 if my_uri is not null then
  -- resource with URL
   select * from rdf.resource 
    where uri=my_uri
     into my_resource;
   if found then
     my_nid := my_resource.nid;
   else
     insert into rdf.resource (uri,owner) values (my_uri,my_model) 
     returning nid
     into strict my_nid;
   end if;
 else
   -- blank node
   insert into rdf.resource (uri,owner) values (my_uri,my_model) 
   returning nid
   into strict my_nid;
 end if;

 return my_nid;
end
$_$;


ALTER FUNCTION rdf.resource(url, nid) OWNER TO postgres;

--
-- Name: resource_recycle(); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION resource_recycle() RETURNS integer
    LANGUAGE plpgsql
    AS $$declare
 n bigint;
begin

 delete from rdf.resource
  where not ( 
    nid in (select nid from rdf.model)
    or nid in (select nid from rdf.namespace)
    or owner in (select nid from rdf.model where loaded)
  );

 get diagnostics n = row_count;
 return n;
end
$$;


ALTER FUNCTION rdf.resource_recycle() OWNER TO postgres;

--
-- Name: retract(nid, nid, nid); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION retract(my_model nid, my_subject nid, my_predicate nid) RETURNS bigint
    LANGUAGE plpgsql
    AS $$declare
 my_model0 rdf.nid;
 my_sid rdf.nid;
 n bigint;
begin
 my_model0 := my_model;
 if my_model0 is null then
   my_model0 := rdf.model();
 end if;

 if my_subject is not null then
  if my_predicate is not null then
    delete from rdf.statement
     where model = my_model0
       and subject = my_subject
       and predicate = my_predicate;
  else
    delete from rdf.statement
     where model = my_model0
       and subject = my_subject;
  end if;
 else
  if my_predicate is not null then
    delete from rdf.statement
     where model = my_model0
       and predicate = my_predicate;
  else
    delete from rdf.statement
     where model = my_model0;
  end if;
 end if;
 
 get diagnostics n = row_count;
 return n;
end
$$;


ALTER FUNCTION rdf.retract(my_model nid, my_subject nid, my_predicate nid) OWNER TO rdf;

--
-- Name: retract(nid, nid, nid, lang); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION retract(my_model nid, my_subject nid, my_predicate nid, my_language lang) RETURNS bigint
    LANGUAGE plpgsql
    AS $$declare
 my_model0 rdf.nid;
 my_sid rdf.nid;
 n bigint;
begin
 my_model0 := my_model;
 if my_model0 is null then
   my_model0 := rdf.model();
 end if;

 if my_subject is not null then
  if my_predicate is not null then
    delete from rdf.statement
     where model = my_model0
       and lang is not distinct from my_language
       and subject = my_subject
       and predicate = my_predicate;
  else
    delete from rdf.statement
     where model = my_model0
       and lang is not distinct from my_language
       and subject = my_subject;
  end if;
 else
  if my_predicate is not null then
    delete from rdf.statement
     where model = my_model0
       and lang is not distinct from my_language
       and predicate = my_predicate;
  else
    delete from rdf.statement
     where model = my_model0
       and lang is not distinct from my_language;
  end if;
 end if;
 
 get diagnostics n = row_count;
 return n;
end
$$;


ALTER FUNCTION rdf.retract(my_model nid, my_subject nid, my_predicate nid, my_language lang) OWNER TO rdf;

--
-- Name: retract(nid, turtle, turtle, turtle); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION retract(model nid, subject turtle, predicate turtle, object turtle) RETURNS integer
    LANGUAGE plperl IMMUTABLE
    AS $$$$;


ALTER FUNCTION rdf.retract(model nid, subject turtle, predicate turtle, object turtle) OWNER TO postgres;

--
-- Name: FUNCTION retract(model nid, subject turtle, predicate turtle, object turtle); Type: COMMENT; Schema: rdf; Owner: postgres
--

COMMENT ON FUNCTION retract(model nid, subject turtle, predicate turtle, object turtle) IS 'TODO!';


--
-- Name: retract(nid, uri, uri, uri); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION retract(model nid, subject uri, predicate uri, object uri) RETURNS integer
    LANGUAGE plperl IMMUTABLE
    AS $$$$;


ALTER FUNCTION rdf.retract(model nid, subject uri, predicate uri, object uri) OWNER TO postgres;

--
-- Name: FUNCTION retract(model nid, subject uri, predicate uri, object uri); Type: COMMENT; Schema: rdf; Owner: postgres
--

COMMENT ON FUNCTION retract(model nid, subject uri, predicate uri, object uri) IS 'TODO!';


--
-- Name: statement_touch(); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION statement_touch() RETURNS trigger
    LANGUAGE plpgsql
    AS $$begin

 if tg_op = 'UPDATE' then
  if new.model is distinct from old.model then
    raise exception 'Cannot change model!';
  end if;
 end if;

 if tg_op = 'INSERT' then

  if new.model is null then
    new.model := rdf.model();
  end if;

  select coalesce(max(ord),0)+1
    from rdf.statement s
   where s.subject=new.subject 
     and s.predicate=new.predicate
     and s.lang is not distinct from new.lang
    into new.ord;

 end if;

 if tg_op = 'DELETE' then
  return old;
 end if;

 return new;
end
$$;


ALTER FUNCTION rdf.statement_touch() OWNER TO postgres;

--
-- Name: turtle_data(text, uri); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION turtle_data(text, uri) RETURNS turtle
    LANGUAGE plperl IMMUTABLE
    AS $$$$;


ALTER FUNCTION rdf.turtle_data(text, uri) OWNER TO postgres;

--
-- Name: FUNCTION turtle_data(text, uri); Type: COMMENT; Schema: rdf; Owner: postgres
--

COMMENT ON FUNCTION turtle_data(text, uri) IS 'TODO!';


--
-- Name: turtle_object(statement); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION turtle_object(statement) RETURNS turtle
    LANGUAGE sql STABLE STRICT
    AS $_$select coalesce(rdf.turtle_uri($1.object),rdf.turtle_text($1.literal))::rdf.turtle$_$;


ALTER FUNCTION rdf.turtle_object(statement) OWNER TO postgres;

--
-- Name: turtle_property(nid); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION turtle_property(nid) RETURNS turtle
    LANGUAGE sql STABLE
    AS $_$select coalesce(name,rdf.turtle_uri(uri))::rdf.turtle from rdf.property where nid=$1$_$;


ALTER FUNCTION rdf.turtle_property(nid) OWNER TO postgres;

--
-- Name: turtle_statement(statement); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION turtle_statement(statement) RETURNS turtle
    LANGUAGE sql STABLE
    AS $_$select 
 cast(
  coalesce(rdf.turtle_uri($1.subject),'#'||$1.subject)||' '||
  rdf.turtle_property($1.predicate)||' '||
  coalesce(
    coalesce(rdf.turtle_uri($1.object),'#'||$1.object),
    rdf.turtle_text($1.literal)
  )||'.'
  as rdf.turtle)
$_$;


ALTER FUNCTION rdf.turtle_statement(statement) OWNER TO postgres;

--
-- Name: turtle_text(text); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION turtle_text(text) RETURNS turtle
    LANGUAGE plperl IMMUTABLE
    AS $_$my $text=shift; 
$text=~s!(\\|"|\n|\r|\t)!{"\t"=>'\t',"\n"=>'\n',"\r"=>'\r','"'=>'\"','\\'=>'\\\\' }->{$1}!ges; 
return qq{"$text"}; 
$_$;


ALTER FUNCTION rdf.turtle_text(text) OWNER TO postgres;

--
-- Name: turtle_text(text, lang); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION turtle_text(text, lang) RETURNS turtle
    LANGUAGE plperl IMMUTABLE
    AS $$$$;


ALTER FUNCTION rdf.turtle_text(text, lang) OWNER TO postgres;

--
-- Name: FUNCTION turtle_text(text, lang); Type: COMMENT; Schema: rdf; Owner: postgres
--

COMMENT ON FUNCTION turtle_text(text, lang) IS 'TODO!';


--
-- Name: turtle_uri(nid); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION turtle_uri(nid) RETURNS turtle
    LANGUAGE sql
    AS $_$select rdf.turtle_uri(uri::rdf.uri) from rdf.resource where nid=$1$_$;


ALTER FUNCTION rdf.turtle_uri(nid) OWNER TO postgres;

--
-- Name: turtle_uri(uri); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION turtle_uri(uri) RETURNS turtle
    LANGUAGE plperl IMMUTABLE
    AS $_$my $text=shift; 
$text=~s!(\\|>|\n|\r|\t)!{"\t"=>'\t',"\n"=>'\n',"\r"=>'\r','>'=>'\>','\\'=>'\\\\' }->{$1}!ges; 
return qq{<$text>}; 
$_$;


ALTER FUNCTION rdf.turtle_uri(uri) OWNER TO postgres;

--
-- Name: unload(model); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION unload(model) RETURNS integer
    LANGUAGE plpgsql
    AS $_$declare
 n integer;
 i integer;
begin
 if not $1.loaded then
   raise exception 'Model % is not loaded',$1.source;
 end if;

 n := 0;

 update rdf.model set loaded=false where nid=$1.nid;

 delete from rdf.statement
  where model=$1.nid;
 get diagnostics i = row_count;
 n := n + i;

 delete from rdf.resource
  where ( not ( 
    nid in (select nid from rdf.model)
    or nid in (select nid from rdf.namespace)
    or owner in (select nid from rdf.model where loaded)
    or nid in (select nid from rdf.property)
    or nid in (select distinct subject from rdf.statement)
    or nid in (select distinct predicate from rdf.statement)
    or nid in (select distinct object from rdf.statement where object is not null)
  ))
  and owner=$1.nid;
 get diagnostics i = row_count;
 n := n + i;

 return n;
end
$_$;


ALTER FUNCTION rdf.unload(model) OWNER TO postgres;

--
-- Name: uri(nid); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION uri(nid) RETURNS uri
    LANGUAGE sql STABLE STRICT
    AS $_$select uri from rdf.resource where nid=$1$_$;


ALTER FUNCTION rdf.uri(nid) OWNER TO postgres;

--
-- Name: url_canonical(url); Type: FUNCTION; Schema: rdf; Owner: postgres
--

CREATE FUNCTION url_canonical(url) RETURNS url
    LANGUAGE plperlu
    AS $_X$use URI; 
my $u=URI->new($_[0]); 
if($u->query() eq '') { $u->query(undef); }
if($u->fragment() eq '') { $u->fragment(undef); }
return $u->canonical;
$_X$;


ALTER FUNCTION rdf.url_canonical(url) OWNER TO postgres;

--
-- Name: FUNCTION url_canonical(url); Type: COMMENT; Schema: rdf; Owner: postgres
--

COMMENT ON FUNCTION url_canonical(url) IS 'return canonical form of URL';


--
-- Name: xid(); Type: FUNCTION; Schema: rdf; Owner: rdf
--

CREATE FUNCTION xid() RETURNS xid
    LANGUAGE sql
    AS $$select nextval('rdf.xid_seq')::rdf.xid$$;


ALTER FUNCTION rdf.xid() OWNER TO rdf;

--
-- Name: class_view; Type: VIEW; Schema: rdf; Owner: rdf
--

CREATE VIEW class_view AS
 SELECT s.subject,
    turtle_uri(s.subject) AS turtle_uri,
    count(*) AS count
   FROM statement s
  WHERE (((s.predicate)::bigint = (resource(('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'::character varying)::uri))::bigint) AND ((s.object)::bigint = (resource(('http://www.w3.org/2002/07/owl#Class'::character varying)::uri))::bigint))
  GROUP BY s.subject
  ORDER BY count(*) DESC;


ALTER TABLE class_view OWNER TO rdf;

--
-- Name: dbpedia_view; Type: VIEW; Schema: rdf; Owner: rdf
--

CREATE VIEW dbpedia_view AS
 SELECT r.uri,
    r.nid,
    m.nid AS model,
    ( SELECT count(*) AS count
           FROM statement s1
          WHERE ((s1.subject)::bigint = (r.nid)::bigint)) AS count
   FROM (resource r
     LEFT JOIN model m ON (((r.nid)::bigint = (m.nid)::bigint)))
  WHERE ((r.uri)::text ~~ 'http://dbpedia.org/resource/%'::text);


ALTER TABLE dbpedia_view OWNER TO rdf;

--
-- Name: endpoint; Type: TABLE; Schema: rdf; Owner: rdf; Tablespace: 
--

CREATE TABLE endpoint (
    nid nid DEFAULT nid() NOT NULL,
    name pg_catalog.name NOT NULL,
    href url NOT NULL
);


ALTER TABLE endpoint OWNER TO rdf;

--
-- Name: TABLE endpoint; Type: COMMENT; Schema: rdf; Owner: rdf
--

COMMENT ON TABLE endpoint IS 'SPARQL endpoints';


--
-- Name: image_view; Type: VIEW; Schema: rdf; Owner: rdf
--

CREATE VIEW image_view AS
 SELECT sub.uri AS resource_uri,
    obj.uri AS image,
    pred.uri AS predicate_uri,
    st.sid,
    st.subject,
    st.predicate,
    st.object,
    st.literal,
    st.literal_datatype,
    st.lang,
    st.context,
    st.model,
    st.ord
   FROM ((((statement st
     JOIN resource sub ON (((sub.nid)::bigint = (st.subject)::bigint)))
     JOIN property pred ON (((pred.nid)::bigint = (st.predicate)::bigint)))
     LEFT JOIN resource obj ON (((obj.nid)::bigint = (st.object)::bigint)))
     LEFT JOIN datatype dt ON (((dt.nid)::bigint = (st.literal_datatype)::bigint)))
  WHERE ((st.predicate)::bigint IN ( SELECT property.nid
           FROM property
          WHERE ((property.view_name)::pg_catalog.name = 'image_view'::pg_catalog.name)))
  ORDER BY sub.uri, pred.uri, obj.uri;


ALTER TABLE image_view OWNER TO rdf;

--
-- Name: label_view; Type: VIEW; Schema: rdf; Owner: rdf
--

CREATE VIEW label_view AS
 SELECT sub.uri AS resource_uri,
    st.literal AS label,
    pred.uri AS predicate_uri,
    st.sid,
    st.subject,
    st.predicate,
    st.object,
    st.literal,
    st.literal_datatype,
    st.lang,
    st.context,
    st.model,
    st.ord
   FROM ((((statement st
     JOIN resource sub ON (((sub.nid)::bigint = (st.subject)::bigint)))
     JOIN property pred ON (((pred.nid)::bigint = (st.predicate)::bigint)))
     LEFT JOIN resource obj ON (((obj.nid)::bigint = (st.object)::bigint)))
     LEFT JOIN datatype dt ON (((dt.nid)::bigint = (st.literal_datatype)::bigint)))
  WHERE ((st.predicate)::bigint IN ( SELECT property.nid
           FROM property
          WHERE ((property.view_name)::pg_catalog.name = 'label_view'::pg_catalog.name)))
  ORDER BY sub.uri, pred.uri, st.literal;


ALTER TABLE label_view OWNER TO rdf;

--
-- Name: language; Type: TABLE; Schema: rdf; Owner: rdf; Tablespace: 
--

CREATE TABLE language (
    language lang NOT NULL
);


ALTER TABLE language OWNER TO rdf;

--
-- Name: TABLE language; Type: COMMENT; Schema: rdf; Owner: rdf
--

COMMENT ON TABLE language IS 'RDF languages';


--
-- Name: location_view; Type: VIEW; Schema: rdf; Owner: rdf
--

CREATE VIEW location_view AS
 SELECT sub.uri AS resource_uri,
    obj.uri AS image,
    pred.uri AS predicate_uri,
    st.sid,
    st.subject,
    st.predicate,
    st.object,
    st.literal,
    st.literal_datatype,
    st.lang,
    st.context,
    st.model,
    st.ord
   FROM ((((statement st
     JOIN resource sub ON (((sub.nid)::bigint = (st.subject)::bigint)))
     JOIN property pred ON (((pred.nid)::bigint = (st.predicate)::bigint)))
     LEFT JOIN resource obj ON (((obj.nid)::bigint = (st.object)::bigint)))
     LEFT JOIN datatype dt ON (((dt.nid)::bigint = (st.literal_datatype)::bigint)))
  WHERE ((st.predicate)::bigint IN ( SELECT property.nid
           FROM property
          WHERE ((property.view_name)::pg_catalog.name = 'location_view'::pg_catalog.name)))
  ORDER BY sub.uri, pred.uri, obj.uri;


ALTER TABLE location_view OWNER TO rdf;

--
-- Name: model_count; Type: VIEW; Schema: rdf; Owner: rdf
--

CREATE VIEW model_count AS
 SELECT m.nid,
    m.source,
    ( SELECT count(*) AS count
           FROM resource r
          WHERE ((r.owner)::bigint = (m.nid)::bigint)) AS resources,
    ( SELECT count(DISTINCT s.predicate) AS count
           FROM statement s
          WHERE ((s.model)::bigint = (m.nid)::bigint)) AS predicates,
    ( SELECT count(*) AS count
           FROM statement s
          WHERE ((s.model)::bigint = (m.nid)::bigint)) AS statements,
    ( SELECT count(*) AS count
           FROM statement s
          WHERE (((s.model)::bigint = (m.nid)::bigint) AND (s.object IS NOT NULL))) AS objects,
    ( SELECT count(*) AS count
           FROM statement s
          WHERE (((s.model)::bigint = (m.nid)::bigint) AND (s.literal IS NOT NULL))) AS literals,
    ( SELECT sum(length((s.literal)::text)) AS sum
           FROM statement s
          WHERE (((s.model)::bigint = (m.nid)::bigint) AND (s.literal IS NOT NULL))) AS literals_size
   FROM model m
  ORDER BY ( SELECT count(*) AS count
           FROM statement s
          WHERE ((s.model)::bigint = (m.nid)::bigint)) DESC;


ALTER TABLE model_count OWNER TO rdf;

--
-- Name: namespace; Type: TABLE; Schema: rdf; Owner: rdf; Tablespace: 
--

CREATE TABLE namespace (
    nid nid DEFAULT nid() NOT NULL,
    name pg_catalog.name NOT NULL,
    uri uri NOT NULL
);


ALTER TABLE namespace OWNER TO rdf;

--
-- Name: TABLE namespace; Type: COMMENT; Schema: rdf; Owner: rdf
--

COMMENT ON TABLE namespace IS 'RDF namespaces';


--
-- Name: nid_seq; Type: SEQUENCE; Schema: rdf; Owner: rdf
--

CREATE SEQUENCE nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE nid_seq OWNER TO rdf;

--
-- Name: predicate_count; Type: VIEW; Schema: rdf; Owner: rdf
--

CREATE VIEW predicate_count AS
 SELECT statement.predicate,
    turtle_property(statement.predicate) AS turtle_property,
    count(*) AS count,
    count(statement.object) AS objects,
    count(statement.literal) AS literals,
    sum(length((statement.literal)::text)) AS size
   FROM statement
  GROUP BY statement.predicate
  ORDER BY count(*) DESC;


ALTER TABLE predicate_count OWNER TO rdf;

--
-- Name: resource_count; Type: VIEW; Schema: rdf; Owner: rdf
--

CREATE VIEW resource_count AS
 SELECT domain_from_uri(r.uri) AS domain_from_uri,
    count(*) AS count
   FROM resource r
  GROUP BY domain_from_uri(r.uri)
  ORDER BY count(*) DESC;


ALTER TABLE resource_count OWNER TO rdf;

--
-- Name: sid_seq; Type: SEQUENCE; Schema: rdf; Owner: rdf
--

CREATE SEQUENCE sid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sid_seq OWNER TO rdf;

--
-- Name: xid_seq; Type: SEQUENCE; Schema: rdf; Owner: rdf
--

CREATE SEQUENCE xid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE xid_seq OWNER TO rdf;

--
-- Name: datatype_pkey; Type: CONSTRAINT; Schema: rdf; Owner: rdf; Tablespace: 
--

ALTER TABLE ONLY datatype
    ADD CONSTRAINT datatype_pkey PRIMARY KEY (nid);


--
-- Name: endpoint_name_key; Type: CONSTRAINT; Schema: rdf; Owner: rdf; Tablespace: 
--

ALTER TABLE ONLY endpoint
    ADD CONSTRAINT endpoint_name_key UNIQUE (name);


--
-- Name: endpoint_pkey; Type: CONSTRAINT; Schema: rdf; Owner: rdf; Tablespace: 
--

ALTER TABLE ONLY endpoint
    ADD CONSTRAINT endpoint_pkey PRIMARY KEY (nid);


--
-- Name: language_pkey; Type: CONSTRAINT; Schema: rdf; Owner: rdf; Tablespace: 
--

ALTER TABLE ONLY language
    ADD CONSTRAINT language_pkey PRIMARY KEY (language);


--
-- Name: model_pkey; Type: CONSTRAINT; Schema: rdf; Owner: rdf; Tablespace: 
--

ALTER TABLE ONLY model
    ADD CONSTRAINT model_pkey PRIMARY KEY (nid);


--
-- Name: namespace_name_key; Type: CONSTRAINT; Schema: rdf; Owner: rdf; Tablespace: 
--

ALTER TABLE ONLY namespace
    ADD CONSTRAINT namespace_name_key UNIQUE (name);


--
-- Name: namespace_pkey; Type: CONSTRAINT; Schema: rdf; Owner: rdf; Tablespace: 
--

ALTER TABLE ONLY namespace
    ADD CONSTRAINT namespace_pkey PRIMARY KEY (nid);


--
-- Name: namespace_uri_key; Type: CONSTRAINT; Schema: rdf; Owner: rdf; Tablespace: 
--

ALTER TABLE ONLY namespace
    ADD CONSTRAINT namespace_uri_key UNIQUE (uri);


--
-- Name: property_pkey; Type: CONSTRAINT; Schema: rdf; Owner: rdf; Tablespace: 
--

ALTER TABLE ONLY property
    ADD CONSTRAINT property_pkey PRIMARY KEY (nid);


--
-- Name: property_uri_key; Type: CONSTRAINT; Schema: rdf; Owner: rdf; Tablespace: 
--

ALTER TABLE ONLY property
    ADD CONSTRAINT property_uri_key UNIQUE (uri);


--
-- Name: resource_pkey; Type: CONSTRAINT; Schema: rdf; Owner: rdf; Tablespace: 
--

ALTER TABLE ONLY resource
    ADD CONSTRAINT resource_pkey PRIMARY KEY (nid);


--
-- Name: resource_uri_key; Type: CONSTRAINT; Schema: rdf; Owner: rdf; Tablespace: 
--

ALTER TABLE ONLY resource
    ADD CONSTRAINT resource_uri_key UNIQUE (uri);


--
-- Name: statement_pkey; Type: CONSTRAINT; Schema: rdf; Owner: rdf; Tablespace: 
--

ALTER TABLE ONLY statement
    ADD CONSTRAINT statement_pkey PRIMARY KEY (sid);


--
-- Name: statement_subject_key; Type: CONSTRAINT; Schema: rdf; Owner: rdf; Tablespace: 
--

ALTER TABLE ONLY statement
    ADD CONSTRAINT statement_subject_key UNIQUE (subject, predicate, ord, lang);


--
-- Name: statement_lang_idx; Type: INDEX; Schema: rdf; Owner: rdf; Tablespace: 
--

CREATE INDEX statement_lang_idx ON statement USING btree (lang);


--
-- Name: statement_model_idx; Type: INDEX; Schema: rdf; Owner: rdf; Tablespace: 
--

CREATE INDEX statement_model_idx ON statement USING btree (model);


--
-- Name: statement_object_idx; Type: INDEX; Schema: rdf; Owner: rdf; Tablespace: 
--

CREATE INDEX statement_object_idx ON statement USING btree (object);


--
-- Name: statement_predicate_idx; Type: INDEX; Schema: rdf; Owner: rdf; Tablespace: 
--

CREATE INDEX statement_predicate_idx ON statement USING btree (predicate);


--
-- Name: statement_subject_idx; Type: INDEX; Schema: rdf; Owner: rdf; Tablespace: 
--

CREATE INDEX statement_subject_idx ON statement USING btree (subject);


--
-- Name: $ISA resource; Type: TRIGGER; Schema: rdf; Owner: rdf
--

CREATE TRIGGER "$ISA resource" BEFORE INSERT OR UPDATE ON datatype FOR EACH ROW EXECUTE PROCEDURE datatype_isa_resource();


--
-- Name: $ISA resource; Type: TRIGGER; Schema: rdf; Owner: rdf
--

CREATE TRIGGER "$ISA resource" BEFORE INSERT OR UPDATE ON property FOR EACH ROW EXECUTE PROCEDURE property_isa_resource();


--
-- Name: $ISA resource; Type: TRIGGER; Schema: rdf; Owner: rdf
--

CREATE TRIGGER "$ISA resource" BEFORE INSERT OR UPDATE ON namespace FOR EACH ROW EXECUTE PROCEDURE namespace_isa_resource();


--
-- Name: $ISA resource; Type: TRIGGER; Schema: rdf; Owner: rdf
--

CREATE TRIGGER "$ISA resource" BEFORE INSERT OR UPDATE ON model FOR EACH ROW EXECUTE PROCEDURE model_isa_resource();


--
-- Name: $LOADER; Type: TRIGGER; Schema: rdf; Owner: rdf
--

CREATE TRIGGER "$LOADER" AFTER INSERT OR UPDATE ON model FOR EACH ROW EXECUTE PROCEDURE model_loader();


--
-- Name: ordering; Type: TRIGGER; Schema: rdf; Owner: rdf
--

CREATE TRIGGER ordering BEFORE INSERT ON statement FOR EACH ROW EXECUTE PROCEDURE statement_touch();


--
-- Name: partition_trigger; Type: TRIGGER; Schema: rdf; Owner: rdf
--

CREATE TRIGGER partition_trigger AFTER INSERT OR DELETE OR UPDATE ON property FOR EACH ROW EXECUTE PROCEDURE property_partition();


--
-- Name: touch; Type: TRIGGER; Schema: rdf; Owner: rdf
--

CREATE TRIGGER touch BEFORE INSERT OR UPDATE ON property FOR EACH ROW EXECUTE PROCEDURE property_touch();


--
-- Name: touch; Type: TRIGGER; Schema: rdf; Owner: rdf
--

CREATE TRIGGER touch AFTER INSERT OR DELETE OR UPDATE ON namespace FOR EACH ROW EXECUTE PROCEDURE namespace_touch();


--
-- Name: ~ISA resource; Type: TRIGGER; Schema: rdf; Owner: rdf
--

CREATE TRIGGER "~ISA resource" AFTER DELETE ON model FOR EACH ROW EXECUTE PROCEDURE model_isa_resource();


--
-- Name: ~ISA resource; Type: TRIGGER; Schema: rdf; Owner: rdf
--

CREATE TRIGGER "~ISA resource" AFTER DELETE ON datatype FOR EACH ROW EXECUTE PROCEDURE datatype_isa_resource();


--
-- Name: ~ISA resource; Type: TRIGGER; Schema: rdf; Owner: rdf
--

CREATE TRIGGER "~ISA resource" AFTER DELETE ON property FOR EACH ROW EXECUTE PROCEDURE property_isa_resource();


--
-- Name: ~ISA resource; Type: TRIGGER; Schema: rdf; Owner: rdf
--

CREATE TRIGGER "~ISA resource" AFTER DELETE ON namespace FOR EACH ROW EXECUTE PROCEDURE namespace_isa_resource();


--
-- Name: ~LOADER; Type: TRIGGER; Schema: rdf; Owner: rdf
--

CREATE TRIGGER "~LOADER" BEFORE DELETE ON model FOR EACH ROW EXECUTE PROCEDURE model_loader();


--
-- Name: ISA model; Type: FK CONSTRAINT; Schema: rdf; Owner: rdf
--

ALTER TABLE ONLY endpoint
    ADD CONSTRAINT "ISA model" FOREIGN KEY (nid) REFERENCES model(nid) ON UPDATE CASCADE ON DELETE RESTRICT DEFERRABLE INITIALLY DEFERRED;


--
-- Name: ISA resource; Type: FK CONSTRAINT; Schema: rdf; Owner: rdf
--

ALTER TABLE ONLY datatype
    ADD CONSTRAINT "ISA resource" FOREIGN KEY (nid) REFERENCES resource(nid) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: ISA resource; Type: FK CONSTRAINT; Schema: rdf; Owner: rdf
--

ALTER TABLE ONLY property
    ADD CONSTRAINT "ISA resource" FOREIGN KEY (nid) REFERENCES resource(nid) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: ISA resource; Type: FK CONSTRAINT; Schema: rdf; Owner: rdf
--

ALTER TABLE ONLY model
    ADD CONSTRAINT "ISA resource" FOREIGN KEY (nid) REFERENCES resource(nid) ON UPDATE CASCADE ON DELETE RESTRICT DEFERRABLE INITIALLY DEFERRED;


--
-- Name: ISA resource; Type: FK CONSTRAINT; Schema: rdf; Owner: rdf
--

ALTER TABLE ONLY namespace
    ADD CONSTRAINT "ISA resource" FOREIGN KEY (nid) REFERENCES resource(nid) ON UPDATE CASCADE ON DELETE RESTRICT DEFERRABLE INITIALLY DEFERRED;


--
-- Name: resource_owner_fkey; Type: FK CONSTRAINT; Schema: rdf; Owner: rdf
--

ALTER TABLE ONLY resource
    ADD CONSTRAINT resource_owner_fkey FOREIGN KEY (owner) REFERENCES model(nid) ON DELETE SET DEFAULT DEFERRABLE INITIALLY DEFERRED;


--
-- Name: statement_context_fkey; Type: FK CONSTRAINT; Schema: rdf; Owner: rdf
--

ALTER TABLE ONLY statement
    ADD CONSTRAINT statement_context_fkey FOREIGN KEY (context) REFERENCES resource(nid);


--
-- Name: statement_lang_fkey; Type: FK CONSTRAINT; Schema: rdf; Owner: rdf
--

ALTER TABLE ONLY statement
    ADD CONSTRAINT statement_lang_fkey FOREIGN KEY (lang) REFERENCES language(language);


--
-- Name: statement_literal_datatype_fkey; Type: FK CONSTRAINT; Schema: rdf; Owner: rdf
--

ALTER TABLE ONLY statement
    ADD CONSTRAINT statement_literal_datatype_fkey FOREIGN KEY (literal_datatype) REFERENCES datatype(nid);


--
-- Name: statement_model_fkey; Type: FK CONSTRAINT; Schema: rdf; Owner: rdf
--

ALTER TABLE ONLY statement
    ADD CONSTRAINT statement_model_fkey FOREIGN KEY (model) REFERENCES model(nid) ON DELETE CASCADE;


--
-- Name: statement_object_fkey; Type: FK CONSTRAINT; Schema: rdf; Owner: rdf
--

ALTER TABLE ONLY statement
    ADD CONSTRAINT statement_object_fkey FOREIGN KEY (object) REFERENCES resource(nid);


--
-- Name: statement_predicate_fkey; Type: FK CONSTRAINT; Schema: rdf; Owner: rdf
--

ALTER TABLE ONLY statement
    ADD CONSTRAINT statement_predicate_fkey FOREIGN KEY (predicate) REFERENCES property(nid);


--
-- Name: statement_subject_fkey; Type: FK CONSTRAINT; Schema: rdf; Owner: rdf
--

ALTER TABLE ONLY statement
    ADD CONSTRAINT statement_subject_fkey FOREIGN KEY (subject) REFERENCES resource(nid);


--
-- Name: rdf; Type: ACL; Schema: -; Owner: rdf
--

REVOKE ALL ON SCHEMA rdf FROM PUBLIC;
REVOKE ALL ON SCHEMA rdf FROM rdf;
GRANT ALL ON SCHEMA rdf TO rdf;
GRANT USAGE ON SCHEMA rdf TO PUBLIC;


--
-- PostgreSQL database dump complete
--

