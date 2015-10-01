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
-- Name: sparql; Type: SCHEMA; Schema: -; Owner: sparql
--

CREATE SCHEMA sparql;


ALTER SCHEMA sparql OWNER TO sparql;

--
-- Name: SCHEMA sparql; Type: COMMENT; Schema: -; Owner: sparql
--

COMMENT ON SCHEMA sparql IS 'Interface to Virtuoso SPARQL endpoint';


SET search_path = sparql, pg_catalog;

--
-- Name: iri; Type: DOMAIN; Schema: sparql; Owner: sparql
--

CREATE DOMAIN iri AS text;


ALTER DOMAIN iri OWNER TO sparql;

--
-- Name: compile_query(name, text, text); Type: FUNCTION; Schema: sparql; Owner: sparql
--

CREATE FUNCTION compile_query(endpoint_name name, identifier text, query text) RETURNS text
    LANGUAGE plperlu
    AS $_X$
my ($name,$func,$query)=@_;
use LWP::Simple;
use URI::Escape;
use JSON;

my $p=spi_prepare('select sparql.endpoint_url($1)','name');
my $baseUrl = spi_exec_prepared($p,$name)->{rows}->[0];
unless($baseUrl) {
  elog(ERROR,'No endpoint definition in sparql.endpoint for name "'.$name.'"');
}
$baseUrl = $baseUrl->{endpoint_url};
my $extras ="?debug=on&timeout=&save=display&fname=".
	    "&format=".uri_escape("application/sparql-results+json").
	    "&query=";

my $url = $baseUrl.$extras;
my $json = get($url.uri_escape($query));
my $data;
eval { $data = decode_json($json); } 
  or do { elog(ERROR,$@); };
my $vars = $data->{head}{vars};
if(!ref($vars)) { elog(ERROR,'bad result'); }
my $outputs = join(', ', map { qq{out "$_" text} } @{$vars});
my $bindings = $data->{results}{bindings};
$query=~s/^\s*//; $query=~s/\s*$//;

my $ddl = "create or replace function $func(endpoint_name name default '$name',$outputs) \nreturns setof record \nas ".'$sparql$'.'
use LWP::Simple;
use URI::Escape;
use Try::Tiny;
use JSON;

my ($name) = @_;
my $p = spi_prepare(\'select sparql.endpoint_url($1)\',\'name\');
my $endpoint_url = spi_exec_prepared($p,$name)->{rows}->[0]->{endpoint_url};
unless($endpoint_url) {
  elog(ERROR,\'No endpoint definition in sparql.endpoint for name "\'.$name.\'"\');
}
my $extras="?debug=on&timeout=&save=display&fname=".
	   "&format=".uri_escape("application/sparql-results+json").
	   "&query=";
	   
my $query = <<"SPARQL";
'.$query.'
SPARQL

my $url  = $endpoint_url.$extras.uri_escape_utf8($query);
my $json = get($url); 
# $json=~s!\\U([0-9A-F]+)!chr(hex($1))!ge;
try { my $data = decode_json($json);
  my $vars = $data->{head}{vars};
  my $bindings = $data->{results}{bindings};
  for my $row (@{$bindings}) {
	my $r = {};
	for my $var (@{$vars}) { $r->{$var}=$row->{$var}{value}; }
	return_next $r;
  }
  return undef;
} catch {
  elog(ERROR,"SPARQL ENDPOINT FAILURE\n$_");
}
'.'$sparql$'." language plperlu cost 5000;
comment on function $func(name) is 'Compiled with sparql.compile_query()';
create or replace view ${func} as select * from $func();
comment on view ${func} is 'Compiled with sparql.compile_query()';
";

# elog(ERROR,$ddl);
spi_exec_query($ddl,1);
return  $ddl;

$_X$;


ALTER FUNCTION sparql.compile_query(endpoint_name name, identifier text, query text) OWNER TO sparql;

--
-- Name: FUNCTION compile_query(endpoint_name name, identifier text, query text); Type: COMMENT; Schema: sparql; Owner: sparql
--

COMMENT ON FUNCTION compile_query(endpoint_name name, identifier text, query text) IS 'Compile SPARQL endpoint query to function+view combination';


--
-- Name: config(text); Type: FUNCTION; Schema: sparql; Owner: sparql
--

CREATE FUNCTION config(var text) RETURNS text
    LANGUAGE sql
    AS $_$
select "value" from sparql.config where "name"=$1;
$_$;


ALTER FUNCTION sparql.config(var text) OWNER TO sparql;

--
-- Name: FUNCTION config(var text); Type: COMMENT; Schema: sparql; Owner: sparql
--

COMMENT ON FUNCTION config(var text) IS 'Return configuration setting';


--
-- Name: endpoint_url(name); Type: FUNCTION; Schema: sparql; Owner: sparql
--

CREATE FUNCTION endpoint_url(endpoint_name name) RETURNS text
    LANGUAGE sql
    AS $_$
select url from sparql.endpoint where name = $1
$_$;


ALTER FUNCTION sparql.endpoint_url(endpoint_name name) OWNER TO sparql;

--
-- Name: FUNCTION endpoint_url(endpoint_name name); Type: COMMENT; Schema: sparql; Owner: sparql
--

COMMENT ON FUNCTION endpoint_url(endpoint_name name) IS 'Return SPARQL endpoint url for named endpoint';


--
-- Name: get_properties(text); Type: FUNCTION; Schema: sparql; Owner: sparql
--

CREATE FUNCTION get_properties(iri text, OUT predicate text, OUT label text, OUT object text, OUT value text) RETURNS SETOF record
    LANGUAGE plperlu ROWS 5000
    AS $_$
use LWP::Simple;
use URI::Escape;
use JSON;

my ($iri)=shift(@_);
unless($iri) { return; }

$iri=~s!(\\|>|\n|\r|\t)!{"\t"=>'\t',"\n"=>'\n',"\r"=>'\r','>'=>'\>','\\'=>'\\\\' }->{$1}!ges; 
$iri=qq{<$iri>};
my $query = <<"SPARQL";
prefix csip:  <http://culture.si/en/Special:URIResolver/Property-3A> 
prefix csic:  <http://culture.si/en/Special:URIResolver/Category-3A> 
prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema#>
prefix rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
prefix vc:    <http://www.w3.org/2006/vcard/ns#>
prefix swivt: <http://semantic-mediawiki.org/swivt/1.0#>
prefix dc:    <http://purl.org/dc/elements/1.1/>
prefix foaf:  <http://xmlns.com/foaf/0.1/>

select distinct 
 (?p as ?predicate), 
 (?l as ?label), 
 (?o as ?object),
 (coalesce(?lo, ?o) as ?value)
where {
  $iri ?p ?o.
  OPTIONAL {?p rdfs:label ?l}.
  OPTIONAL {?o rdfs:label ?lo}.
}
order by ?p
SPARQL

my $url  = "http://virtuoso.ljudmila.net:8890/sparql/?debug=on&timeout=&save=display&fname=&format=application%2Fsparql-results%2Bjson&query=".uri_escape($query);
my $json = get($url);
my $data = decode_json($json);
my $vars = $data->{head}{vars};
my $bindings = $data->{results}{bindings};
for my $row (@{$bindings}) {
	my $r = {};
	for my $var (@{$vars}) { $r->{$var}=$row->{$var}{value}; }
	return_next $r;
}
return undef;
$_$;


ALTER FUNCTION sparql.get_properties(iri text, OUT predicate text, OUT label text, OUT object text, OUT value text) OWNER TO sparql;

--
-- Name: FUNCTION get_properties(iri text, OUT predicate text, OUT label text, OUT object text, OUT value text); Type: COMMENT; Schema: sparql; Owner: sparql
--

COMMENT ON FUNCTION get_properties(iri text, OUT predicate text, OUT label text, OUT object text, OUT value text) IS 'Get properties for RDF resource from SPARQL endpoint';


--
-- Name: get_properties(name, text); Type: FUNCTION; Schema: sparql; Owner: sparql
--

CREATE FUNCTION get_properties(endpoint_name name, iri text, OUT predicate text, OUT object text, OUT value text, OUT lang text) RETURNS SETOF record
    LANGUAGE plperlu STABLE STRICT ROWS 5000
    AS $_$
use LWP::Simple;
use URI::Escape;
use JSON;

my ($name,$iri)=@_;
unless($iri) { return; }
my $p=spi_prepare('select sparql.endpoint_url($1)','name');
my $baseUrl = spi_exec_prepared($p,$name)->{rows}->[0]->{endpoint_url};
unless($baseUrl) {
  elog(ERROR,'No endpoint definition in sparql.endpoint for name "'.$name.'"');
}

$iri=~s!(\\|>|\n|\r|\t)!{"\t"=>'\t',"\n"=>'\n',"\r"=>'\r','>'=>'\>','\\'=>'\\\\' }->{$1}!ges; 
$iri=qq{<$iri>};
my $query = <<"SPARQL";
prefix csip:  <http://culture.si/en/Special:URIResolver/Property-3A> 
prefix csic:  <http://culture.si/en/Special:URIResolver/Category-3A> 
prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema#>
prefix rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
prefix vc:    <http://www.w3.org/2006/vcard/ns#>
prefix swivt: <http://semantic-mediawiki.org/swivt/1.0#>
prefix dc:    <http://purl.org/dc/elements/1.1/>
prefix foaf:  <http://xmlns.com/foaf/0.1/>

select distinct 
 (?p as ?predicate), 
 (?o as ?object),
 (coalesce(?lo, ?o) as ?value),
 (lang(?lo) as ?lang)
where {
  $iri ?p ?o.
  OPTIONAL {?o rdfs:label ?lo}.
}
order by ?p
SPARQL

my $url  = $baseUrl."?debug=on&timeout=&save=display&fname=&format=application%2Fsparql-results%2Bjson&query=".uri_escape_utf8($query);
my $json = get($url);
my $data = decode_json($json);
my $vars = $data->{head}{vars};
my $bindings = $data->{results}{bindings};
for my $row (@{$bindings}) {
	my $r = {};
	for my $var (@{$vars}) { $r->{$var}=$row->{$var}{value}; }
	return_next $r;
}
return undef;
$_$;


ALTER FUNCTION sparql.get_properties(endpoint_name name, iri text, OUT predicate text, OUT object text, OUT value text, OUT lang text) OWNER TO sparql;

--
-- Name: FUNCTION get_properties(endpoint_name name, iri text, OUT predicate text, OUT object text, OUT value text, OUT lang text); Type: COMMENT; Schema: sparql; Owner: sparql
--

COMMENT ON FUNCTION get_properties(endpoint_name name, iri text, OUT predicate text, OUT object text, OUT value text, OUT lang text) IS 'Get properties for RDF resource from SPARQL endpoint';


--
-- Name: iri_ident(text); Type: FUNCTION; Schema: sparql; Owner: sparql
--

CREATE FUNCTION iri_ident(text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_$
  my ($url)=@_;
  if($url=~s!([/#])([_\-a-zA-Z0-9]+)$!$1!) { return $2; }
  return undef;
$_$;


ALTER FUNCTION sparql.iri_ident(text) OWNER TO sparql;

--
-- Name: iri_prefix(text); Type: FUNCTION; Schema: sparql; Owner: sparql
--

CREATE FUNCTION iri_prefix(text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_$
  my ($url)=@_;
  if($url=~s!([/#])([_\-a-zA-Z0-9]+)$!$1!) { return $url; }
  return undef;
$_$;


ALTER FUNCTION sparql.iri_prefix(text) OWNER TO sparql;

--
-- Name: properties(name); Type: FUNCTION; Schema: sparql; Owner: sparql
--

CREATE FUNCTION properties(endpoint_name name, OUT pred text, OUT label text, OUT comment text, OUT cardinality text, OUT range text, OUT "isDefinedBy" text) RETURNS SETOF record
    LANGUAGE plperlu COST 5000
    AS $_X$
use LWP::Simple;
use URI::Escape;
use Try::Tiny;
use JSON;

my ($name) = @_;
my $p = spi_prepare('select sparql.endpoint_url($1)','name');
my $endpoint_url = spi_exec_prepared($p,$name)->{rows}->[0]->{endpoint_url};
unless($endpoint_url) {
  elog(ERROR,'No endpoint definition in sparql.endpoint for name "'.$name.'"');
}
my $extras="?debug=on&timeout=&save=display&fname=".
	   "&format=".uri_escape("application/sparql-results+json").
	   "&query=";
	   
my $query = <<"SPARQL";
select distinct ?pred, ?label, ?comment, ?cardinality, ?range, ?isDefinedBy
WHERE {
  ?pred a rdf:Property.
  ?pred rdfs:label ?label.
  optional {?pred rdfs:comment ?comment}.
  optional {?pred rdfs:range ?range}.
  optional {?pred rdfs:cardinality ?cardinality}.
  optional {?pred rdfs:isDefinedBy ?isDefinedBy}.
}
SPARQL

my $url  = $endpoint_url.$extras.uri_escape_utf8($query);
my $json = get($url); 
# $json=~s!\U([0-9A-F]+)!chr(hex($1))!ge;
try { my $data = decode_json($json);
  my $vars = $data->{head}{vars};
  my $bindings = $data->{results}{bindings};
  for my $row (@{$bindings}) {
	my $r = {};
	for my $var (@{$vars}) { $r->{$var}=$row->{$var}{value}; }
	return_next $r;
  }
  return undef;
} catch {
  elog(ERROR,"SPARQL ENDPOINT FAILURE\n$_");
}
$_X$;


ALTER FUNCTION sparql.properties(endpoint_name name, OUT pred text, OUT label text, OUT comment text, OUT cardinality text, OUT range text, OUT "isDefinedBy" text) OWNER TO sparql;

--
-- Name: FUNCTION properties(endpoint_name name, OUT pred text, OUT label text, OUT comment text, OUT cardinality text, OUT range text, OUT "isDefinedBy" text); Type: COMMENT; Schema: sparql; Owner: sparql
--

COMMENT ON FUNCTION properties(endpoint_name name, OUT pred text, OUT label text, OUT comment text, OUT cardinality text, OUT range text, OUT "isDefinedBy" text) IS 'Compiled with sparql.compile_query()';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: config; Type: TABLE; Schema: sparql; Owner: sparql; Tablespace: 
--

CREATE TABLE config (
    name text NOT NULL,
    value text,
    regtype regtype DEFAULT 'text'::regtype NOT NULL,
    comment text
);


ALTER TABLE config OWNER TO sparql;

--
-- Name: TABLE config; Type: COMMENT; Schema: sparql; Owner: sparql
--

COMMENT ON TABLE config IS 'Various configuration options';


--
-- Name: endpoint; Type: TABLE; Schema: sparql; Owner: sparql; Tablespace: 
--

CREATE TABLE endpoint (
    name name NOT NULL,
    url text NOT NULL
);


ALTER TABLE endpoint OWNER TO sparql;

--
-- Name: TABLE endpoint; Type: COMMENT; Schema: sparql; Owner: sparql
--

COMMENT ON TABLE endpoint IS 'SPARQL endpoint definitions';


--
-- Name: namespace; Type: TABLE; Schema: sparql; Owner: sparql; Tablespace: 
--

CREATE TABLE namespace (
    name name NOT NULL,
    uri iri
);


ALTER TABLE namespace OWNER TO sparql;

--
-- Name: TABLE namespace; Type: COMMENT; Schema: sparql; Owner: sparql
--

COMMENT ON TABLE namespace IS 'Table of common RDF namespaces';


--
-- Name: properties; Type: VIEW; Schema: sparql; Owner: sparql
--

CREATE VIEW properties AS
 SELECT properties.pred,
    properties.label,
    properties.comment,
    properties.cardinality,
    properties.range,
    properties."isDefinedBy"
   FROM properties('dbpedia'::name) properties(pred, label, comment, cardinality, range, "isDefinedBy");


ALTER TABLE properties OWNER TO sparql;

--
-- Name: VIEW properties; Type: COMMENT; Schema: sparql; Owner: sparql
--

COMMENT ON VIEW properties IS 'Compiled with sparql.compile_query()';


--
-- Name: namespace_js; Type: VIEW; Schema: sparql; Owner: sparql
--

CREATE VIEW namespace_js AS
 SELECT aa.uri,
    (((((('var '::text || (aa.name)::text) || ' = new RDF.Namespace(
	'::text) || to_json(aa.uri)) || ',
	'::text) || aa.json_agg) || ');
'::text) AS js
   FROM ( SELECT a.name,
            a.uri,
            json_agg(a.ident) AS json_agg
           FROM ( WITH q AS (
                         SELECT DISTINCT properties.pred AS p
                           FROM properties
                        )
                 SELECT iri_prefix(q.p) AS uri,
                    n.name,
                    iri_ident(q.p) AS ident
                   FROM (q
                     LEFT JOIN namespace n ON (((n.uri)::text = iri_prefix(q.p))))) a
          GROUP BY a.name, a.uri
          ORDER BY a.name) aa;


ALTER TABLE namespace_js OWNER TO sparql;

--
-- Name: config_pkey; Type: CONSTRAINT; Schema: sparql; Owner: sparql; Tablespace: 
--

ALTER TABLE ONLY config
    ADD CONSTRAINT config_pkey PRIMARY KEY (name);


--
-- Name: endpoint_pkey; Type: CONSTRAINT; Schema: sparql; Owner: sparql; Tablespace: 
--

ALTER TABLE ONLY endpoint
    ADD CONSTRAINT endpoint_pkey PRIMARY KEY (name);


--
-- Name: namespace_pkey; Type: CONSTRAINT; Schema: sparql; Owner: sparql; Tablespace: 
--

ALTER TABLE ONLY namespace
    ADD CONSTRAINT namespace_pkey PRIMARY KEY (name);


--
-- PostgreSQL database dump complete
--

