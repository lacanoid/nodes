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
-- Name: px; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA px;


ALTER SCHEMA px OWNER TO postgres;

--
-- Name: SCHEMA px; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA px IS 'Portable eXpressions';


SET search_path = px, pg_catalog;

--
-- Name: is_valid_json(text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION is_valid_json(text) RETURNS boolean
    LANGUAGE plperlu
    AS $_X$if(!defined($_[0])) { return 1; }
use JSON;
my $obj=JSON->new->allow_nonref->decode($_[0]);
if(defined($obj)) { return 1; } 
return 0; 
$_X$;


ALTER FUNCTION px.is_valid_json(text) OWNER TO postgres;

--
-- Name: json; Type: DOMAIN; Schema: px; Owner: postgres
--

CREATE DOMAIN json AS text
	CONSTRAINT is_valid_json CHECK (is_valid_json(VALUE));


ALTER DOMAIN json OWNER TO postgres;

--
-- Name: lang; Type: DOMAIN; Schema: px; Owner: postgres
--

CREATE DOMAIN lang AS text;


ALTER DOMAIN lang OWNER TO postgres;

--
-- Name: is_valid_version(text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION is_valid_version(text) RETURNS boolean
    LANGUAGE plperl
    AS $_$my $v=shift;

# version number, debian style

if(!defined($v)) { return 1; } # this is handled by not-null

if($v=~s/^(\d+)://) { 
 # with epoch
 if($v=~/^([A-Za-z0-9\.\+\-\:]+?)-([A-Za-z0-9\.\+]+)?$/) {
  return 1;
 }
 elsif($v=~/^([A-Za-z0-9\.\+\:]+)$/) {
  return 1;
 }
}
# without epoch

if($v=~/^([A-Za-z0-9\.\+\-]+?)-([A-Za-z0-9\.\+]+)$/) {
 # with revision
 return 1;
}
elsif($v=~/^([A-Za-z0-9\.\+]+)$/) {
 # without revision
 return 1;
}

return 0;
$_$;


ALTER FUNCTION px.is_valid_version(text) OWNER TO postgres;

--
-- Name: version; Type: DOMAIN; Schema: px; Owner: postgres
--

CREATE DOMAIN version AS name
	CONSTRAINT "is valid Debian version" CHECK (is_valid_version((VALUE)::text));


ALTER DOMAIN version OWNER TO postgres;

--
-- Name: DOMAIN version; Type: COMMENT; Schema: px; Owner: postgres
--

COMMENT ON DOMAIN version IS 'Debian compatible version string';


--
-- Name: esc_xml(text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION esc_xml(string text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_$
my $str = shift;
$str=~s/&([^#])/&amp;$1/go;
$str=~s/&$/&amp;/o;
$str=~s/</&lt;/go;
$str=~s/>/&gt;/go;
return $str;
$_$;


ALTER FUNCTION px.esc_xml(string text) OWNER TO postgres;

--
-- Name: FUNCTION esc_xml(string text); Type: COMMENT; Schema: px; Owner: postgres
--

COMMENT ON FUNCTION esc_xml(string text) IS 'XML string escape';


--
-- Name: human_date(date); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION human_date(date) RETURNS text
    LANGUAGE sql
    SET search_path TO px
    AS $_$select
 case 
  when date($1) = date(now()) then px._('today')||', '
  else ''
 end || px._(trim(to_char($1,'day'))) || 
 ', '||extract(day from $1)||'. '||
 px._(trim(to_char($1,'month'))) ||        
 to_char($1,' YYYY')$_$;


ALTER FUNCTION px.human_date(date) OWNER TO postgres;

--
-- Name: human_text(date); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION human_text(date) RETURNS text
    LANGUAGE sql
    SET search_path TO px
    AS $_$select
 case 
  when date($1) = date(now()) then px._('today')||', '
  else ''
 end || px._(trim(to_char($1,'day'))) || 
 ', '||extract(day from $1)||'. '||
 px._(trim(to_char($1,'month'))) ||        
 to_char($1,' YYYY')$_$;


ALTER FUNCTION px.human_text(date) OWNER TO postgres;

--
-- Name: wrap(text, text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION wrap(text, text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_X$
 return defined($_[1])?"$_[0]$_[1]":"";
$_X$;


ALTER FUNCTION px.wrap(text, text) OWNER TO postgres;

--
-- Name: _(text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION _(text) RETURNS text
    LANGUAGE sql STABLE
    AS $_$select coalesce( 
(select text from px.strings where name = $1 and lang = px.config('lc_time')), 
$1)$_$;


ALTER FUNCTION px._(text) OWNER TO postgres;

--
-- Name: _(text, integer); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION _(text, integer) RETURNS text
    LANGUAGE sql
    AS $_$select px._($1,$2::text)$_$;


ALTER FUNCTION px._(text, integer) OWNER TO postgres;

--
-- Name: _(text, text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION _(text, text) RETURNS text
    LANGUAGE plperl
    AS $_X$
 return sprintf($_[0],$_[1]);
$_X$;


ALTER FUNCTION px._(text, text) OWNER TO postgres;

--
-- Name: _(text, text, integer); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION _(singular text, plural text, n integer) RETURNS text
    LANGUAGE sql
    AS $_$select px._($1,$2,$3::text)$_$;


ALTER FUNCTION px._(singular text, plural text, n integer) OWNER TO postgres;

--
-- Name: _(text, text, text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION _(singular text, plural text, n text) RETURNS text
    LANGUAGE plperl
    AS $_X$
if(int($_[2])==1) {
 # plural
 return sprintf($_[0],$_[2]);
} else {
 # singular
 return sprintf($_[1],$_[2]);
}
$_X$;


ALTER FUNCTION px._(singular text, plural text, n text) OWNER TO postgres;

--
-- Name: array_uniq(anyarray); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION array_uniq(anyarray) RETURNS text[]
    LANGUAGE sql
    AS $_$
 select px.array_agg(distinct i)
  from px.unnest($1) unnest(i)
$_$;


ALTER FUNCTION px.array_uniq(anyarray) OWNER TO postgres;

--
-- Name: FUNCTION array_uniq(anyarray); Type: COMMENT; Schema: px; Owner: postgres
--

COMMENT ON FUNCTION array_uniq(anyarray) IS 'Remove duplicates from array';


--
-- Name: awrap(text, boolean); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION awrap(text, boolean) RETURNS text
    LANGUAGE plperlu
    AS $_$my ($attribute,$value)=@_;
if(!defined($value)) { return ''; }

use WDBI::P;
return awrap($attribute,$value eq 't'?'true':'false');
$_$;


ALTER FUNCTION px.awrap(text, boolean) OWNER TO postgres;

--
-- Name: awrap(text, text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION awrap(text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
select case 
       when $2 is not null then ' '||$1||'='||px.esc_attr($2)
       else ''
       end
$_$;


ALTER FUNCTION px.awrap(text, text) OWNER TO postgres;

--
-- Name: basename(text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION basename(text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_$
  my $str=shift; $str=~s|^(.*/)([^/]*)$|$2|; return $str;
$_$;


ALTER FUNCTION px.basename(text) OWNER TO postgres;

--
-- Name: cardinality(anyarray); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION cardinality(anyarray) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
select coalesce(array_upper($1,1)-array_lower($1,1)+1,0);
$_$;


ALTER FUNCTION px.cardinality(anyarray) OWNER TO postgres;

--
-- Name: concat(text[]); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION concat(VARIADIC arr text[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT array_to_string($1, '');
$_$;


ALTER FUNCTION px.concat(VARIADIC arr text[]) OWNER TO postgres;

--
-- Name: concat_ws(text, text[]); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION concat_ws(delim text, VARIADIC arr text[]) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT array_to_string($2, $1);
$_$;


ALTER FUNCTION px.concat_ws(delim text, VARIADIC arr text[]) OWNER TO postgres;

--
-- Name: config(text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION config(text) RETURNS text
    LANGUAGE sql STABLE
    AS $_$select coalesce( 
 (select setting from pg_settings where name = $1), 
 (select value from px.config where name = $1) 
)::text as value$_$;


ALTER FUNCTION px.config(text) OWNER TO postgres;

--
-- Name: crypt(text, text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION crypt(string text, salt text) RETURNS text
    LANGUAGE plperl
    AS $_X$return crypt($_[0],$_[1]);$_X$;


ALTER FUNCTION px.crypt(string text, salt text) OWNER TO postgres;

--
-- Name: esc_attr(text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION esc_attr(string text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_$
my $str = shift;
if(!defined($str)) { return undef; }
$str=~s/&/&amp;/go;
$str=~s/\n/&#13;/go;
$str=~s/</&lt;/go;
$str=~s/>/&gt;/go;
$str=~s/"/&quot;/go;
return qq{"$str"};
$_$;


ALTER FUNCTION px.esc_attr(string text) OWNER TO postgres;

--
-- Name: FUNCTION esc_attr(string text); Type: COMMENT; Schema: px; Owner: postgres
--

COMMENT ON FUNCTION esc_attr(string text) IS 'XML attribute escape';


--
-- Name: esc_sh(text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION esc_sh(string text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_$
 my $s=shift; 
 if($s=~/[^a-zA-Z0-9_\-]/ || $s=~s/'/\\'/g) {
  return qq{'$s'};
 }
 return $s;
$_$;


ALTER FUNCTION px.esc_sh(string text) OWNER TO postgres;

--
-- Name: FUNCTION esc_sh(string text); Type: COMMENT; Schema: px; Owner: postgres
--

COMMENT ON FUNCTION esc_sh(string text) IS 'Shell string escape';


--
-- Name: esc_unac(text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION esc_unac(u text) RETURNS text
    LANGUAGE plperlu IMMUTABLE STRICT
    AS $_$
use Text::Unaccent;
my $str = shift;
$str = unac_string("utf8",$str);
return $str;
$_$;


ALTER FUNCTION px.esc_unac(u text) OWNER TO postgres;

--
-- Name: FUNCTION esc_unac(u text); Type: COMMENT; Schema: px; Owner: postgres
--

COMMENT ON FUNCTION esc_unac(u text) IS 'Remove accents from text';


--
-- Name: esc_uri(text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION esc_uri(string text) RETURNS text
    LANGUAGE plperlu IMMUTABLE
    AS $_$
 use URI::Escape;
 my $s=shift; 
 $s=URI::Escape::uri_escape_utf8($s,"^A-Za-z0-9\-:_\./");
 return $s;
$_$;


ALTER FUNCTION px.esc_uri(string text) OWNER TO postgres;

--
-- Name: FUNCTION esc_uri(string text); Type: COMMENT; Schema: px; Owner: postgres
--

COMMENT ON FUNCTION esc_uri(string text) IS 'URI string escape';


--
-- Name: esc_uri_args(record); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION esc_uri_args(data record) RETURNS text
    LANGUAGE plperlu IMMUTABLE
    AS $_$
my ($data)=@_;

use URI::Escape;
my @data;

for my $k (sort(keys($data))) { 
  push @data,
       URI::Escape::uri_escape_utf8($k,"^A-Za-z0-9\-:_\./") . "=" .
       URI::Escape::uri_escape_utf8($data->{$k},"^A-Za-z0-9\-:_\./");
};
return join('&',@data);

$_$;


ALTER FUNCTION px.esc_uri_args(data record) OWNER TO postgres;

--
-- Name: eval(text); Type: FUNCTION; Schema: px; Owner: postgres
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


ALTER FUNCTION px.eval(sql_expression text) OWNER TO postgres;

--
-- Name: FUNCTION eval(sql_expression text); Type: COMMENT; Schema: px; Owner: postgres
--

COMMENT ON FUNCTION eval(sql_expression text) IS 'Evaluate SQL expression';


--
-- Name: hex_to_int(character varying); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION hex_to_int(hexval character varying) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
DECLARE
   result  int;
BEGIN
 EXECUTE 'SELECT x''' || hexval || '''::int' INTO result;  RETURN result;
END; $$;


ALTER FUNCTION px.hex_to_int(hexval character varying) OWNER TO postgres;

--
-- Name: human_size(bigint); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION human_size(bigint) RETURNS text
    LANGUAGE plperl
    AS $_$my ($size)=@_; 
if(!defined($size)) { return undef; }
$size+=0; 
if($size==0) { return 'empty'; } 
if($size<1024) { return $size; } 
$size/=1024.0; 
if($size<1024) { return int($size+0.5)."K"; } 
$size/=1024.0; 
return sprintf("%.1fM",$size+0.05); 
$_$;


ALTER FUNCTION px.human_size(bigint) OWNER TO postgres;

--
-- Name: human_text(interval); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION human_text(interval) RETURNS text
    LANGUAGE sql
    AS $_$
select
 case
 when $1 < interval'1 day' then to_char($1,'HH24:MI:SS')::text
 else px._('%d day','%d days',extract(days from $1)::int)
 end
$_$;


ALTER FUNCTION px.human_text(interval) OWNER TO postgres;

--
-- Name: iif(boolean, anyelement, anyelement); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION iif(boolean, anyelement, anyelement) RETURNS anyelement
    LANGUAGE sql IMMUTABLE
    AS $_$ SELECT case $1 when true then $2 else $3 end $_$;


ALTER FUNCTION px.iif(boolean, anyelement, anyelement) OWNER TO postgres;

--
-- Name: is_valid_email(text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION is_valid_email(text) RETURNS boolean
    LANGUAGE sql
    AS $_$select $1 ~ '^[^@\s]+@[^@\s]+(\.[^@\s]+)+$' as result
$_$;


ALTER FUNCTION px.is_valid_email(text) OWNER TO postgres;

--
-- Name: join(text[]); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION "join"(text[]) RETURNS text
    LANGUAGE sql
    AS $_$
select px.concat(unnest)
from px.unnest($1);
$_$;


ALTER FUNCTION px."join"(text[]) OWNER TO postgres;

--
-- Name: join(text, text[]); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION "join"(separator text, text[]) RETURNS text
    LANGUAGE sql
    AS $_$
select trim($1 from px.concat(unnest||$1))
from px.unnest($2);
$_$;


ALTER FUNCTION px."join"(separator text, text[]) OWNER TO postgres;

--
-- Name: json_get(json, integer); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION json_get(json, integer) RETURNS json
    LANGUAGE plperlu
    AS $_$my ($json,$selector)=@_;

use JSON;

my $m=JSON->new->allow_nonref->decode($json);
JSON->new->allow_nonref->encode($m->[$selector]);
$_$;


ALTER FUNCTION px.json_get(json, integer) OWNER TO postgres;

--
-- Name: json_get(json, text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION json_get(json, text) RETURNS json
    LANGUAGE plperlu
    AS $_X$
use Data::Dumper;
use JSON;

#elog(error,$_[0]);
#return '["foo"]';
# $json = new JSON;

my $m=JSON->new->allow_nonref->decode($_[0]);
elog(NOTICE,Dumper($m));
#my $m=from_json($_[0]);
elog(NOTICE,JSON->new->allow_nonref->encode($m->{$_[1]}));
return JSON->new->allow_nonref->encode($m->{$_[1]});
$_X$;


ALTER FUNCTION px.json_get(json, text) OWNER TO postgres;

--
-- Name: json_get_scalar(json, integer); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION json_get_scalar(json, integer) RETURNS text
    LANGUAGE plperlu
    AS $_$my ($json,$selector)=@_;

use JSON;

my $m=JSON->new->allow_nonref->decode($json);
return $m->[$selector];
$_$;


ALTER FUNCTION px.json_get_scalar(json, integer) OWNER TO postgres;

--
-- Name: json_get_scalar(json, text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION json_get_scalar(json, text) RETURNS text
    LANGUAGE plperlu
    AS $_$my ($json,$selector)=@_;

use JSON;

my $m=JSON->new->allow_nonref->decode($json);
return $m->{$selector};
$_$;


ALTER FUNCTION px.json_get_scalar(json, text) OWNER TO postgres;

--
-- Name: json_keys(json, boolean); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION json_keys(my_json json, recursive boolean) RETURNS SETOF text
    LANGUAGE plperlu
    AS $_X$
use JSON;
my $m=from_json($_[0]);
for my $key (sort(keys(%{$m}))) {
 return_next($key);
}
return undef;
$_X$;


ALTER FUNCTION px.json_keys(my_json json, recursive boolean) OWNER TO postgres;

--
-- Name: json_keys_values(json); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION json_keys_values(json json, OUT k text, OUT v text, OUT t text) RETURNS SETOF record
    LANGUAGE plperlu
    AS $_X$
use JSON;
my $m=from_json($_[0]);

if(ref($m) eq 'ARRAY') {
for(my $key=0;$key<@{$m};$key++) {
 return_next({
   'k'=>$key,
   'v'=>JSON->new->allow_nonref->encode($m->[$key]),
   't'=>ref($m->[$key])
  });
 }
}

if(ref($m) eq 'HASH') {
 for my $key (sort(keys(%{$m}))) {
  return_next({
   'k'=>$key,
   'v'=>JSON->new->allow_nonref->encode($m->{$key}),
   't'=>ref($m->{$key})
  });
 }
}

return undef;
$_X$;


ALTER FUNCTION px.json_keys_values(json json, OUT k text, OUT v text, OUT t text) OWNER TO postgres;

--
-- Name: json_scalar(json); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION json_scalar(json) RETURNS text
    LANGUAGE plperlu
    AS $_X$use JSON;
 
my $json = JSON->new->allow_nonref;
my $data=$json->decode($_[0]);

return ref($data)?undef:$data;
$_X$;


ALTER FUNCTION px.json_scalar(json) OWNER TO postgres;

--
-- Name: l10n(text, text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION l10n(text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$select coalesce((select text from px.strings where name = $1 and lang = $2), $1)$_$;


ALTER FUNCTION px.l10n(text, text) OWNER TO postgres;

--
-- Name: lcfirst(text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION lcfirst(text) RETURNS text
    LANGUAGE plperl
    AS $_X$
  return lcfirst($_[0]);
$_X$;


ALTER FUNCTION px.lcfirst(text) OWNER TO postgres;

--
-- Name: nul(text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION nul(text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_X$return($_[0]?$_[0]:undef);$_X$;


ALTER FUNCTION px.nul(text) OWNER TO postgres;

--
-- Name: nuls(text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION nuls(text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_X$return ((defined($_[0])&&($_[0]=~/[^\s]/))?$_[0]:undef);$_X$;


ALTER FUNCTION px.nuls(text) OWNER TO postgres;

--
-- Name: preg_replace(text, text, text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION preg_replace(text, text, text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_$
  my ($from,$to,$str)=@_;
  $str=~s/$from/$to/g;
  return $str;
$_$;


ALTER FUNCTION px.preg_replace(text, text, text) OWNER TO postgres;

--
-- Name: split(text, text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION split(my_regexp text, my_string text) RETURNS text[]
    LANGUAGE plperl
    AS $_X$
 my @a=split($_[0],$_[1]);
 return \@a;
$_X$;


ALTER FUNCTION px.split(my_regexp text, my_string text) OWNER TO postgres;

--
-- Name: template(text, pg_catalog.json); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION template(text, pg_catalog.json) RETURNS text
    LANGUAGE plperlu IMMUTABLE
    AS $_X$
 our ($text,$data)=@_;
 my $i=1000; # runaway guard!

 use JSON;
 $data = decode_json($data);

 sub apply_item_3 {
   my ($t)=@_;
   $t =~ s/^\s+|\s+$//g; # trim both
   if($t =~ m/^".*"$/) { return $1; } # literal
   return $data->{$t};
 };

 sub apply_item_2 {
   my ($t)=@_;
   my @b = split('\s*\|\|\s*',$t);
   my $v;
   for my $bi (@b) {
	$v = apply_item_3($bi); 
        if(defined($v)) { return $v; }
    }
    return undef;
 };
 
 sub apply_item_1 {
   my ($t)=@_;
   my @a = split('\s*\&\&\s*',$t);
   my $v;
   for my $ai (@a) { 
	$v = apply_item_2($ai); 
        return undef unless $v;
   }
   return $v;
 };

 sub escape_html { $_[0]=~s/&/&amp;/g; $_[0]=~s/</&lt;/g; $_[0]=~s/>/&gt;/g; $_[0]=~s/"/&quot;/g; $_[0]; }

 while($text=~s/\{\{\{(.+?)\}\}\}/apply_item_1($1)/e && $i>0) { $i--; }
 while($text=~s/\{\{(.+?)\}\}/escape_html(apply_item_1($1))/e && $i>0) { $i--; }

 return $text;
$_X$;


ALTER FUNCTION px.template(text, pg_catalog.json) OWNER TO postgres;

--
-- Name: FUNCTION template(text, pg_catalog.json); Type: COMMENT; Schema: px; Owner: postgres
--

COMMENT ON FUNCTION template(text, pg_catalog.json) IS 'Apply arguments to a template';


--
-- Name: ucfirst(text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION ucfirst(text) RETURNS text
    LANGUAGE plperl
    AS $_X$
  return ucfirst($_[0]);
$_X$;


ALTER FUNCTION px.ucfirst(text) OWNER TO postgres;

--
-- Name: unique_bigint(); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION unique_bigint() RETURNS bigint
    LANGUAGE sql
    AS $$
select extract(epoch from now())::bigint*100000000 + (100000000*random())::bigint;
$$;


ALTER FUNCTION px.unique_bigint() OWNER TO postgres;

--
-- Name: unnest(anyarray); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION unnest(anyarray) RETURNS SETOF text
    LANGUAGE plpgsql
    AS $_$
declare
 i integer;
begin
 i := array_lower($1,1);
 while (i <= array_upper($1,1)) loop
   return next $1[i];
   i:=i+1;
 end loop;
 
end
$_$;


ALTER FUNCTION px.unnest(anyarray) OWNER TO postgres;

--
-- Name: FUNCTION unnest(anyarray); Type: COMMENT; Schema: px; Owner: postgres
--

COMMENT ON FUNCTION unnest(anyarray) IS 'Turn array into set';


--
-- Name: uuid(); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION uuid() RETURNS uuid
    LANGUAGE plperlu
    AS $_$my $foo=`uuid`;
$foo=~y|\s\n\r||d;
return $foo;$_$;


ALTER FUNCTION px.uuid() OWNER TO postgres;

--
-- Name: wiki_clean(text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION wiki_clean(wikitext text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_$
    my $text = shift;
    if($text=~/^\{\{/) { return ''; }
    $text=~s/\[\[.+?\|//g;
    $text=~s/\[\[.+?:://g;
    $text=~s/\[\[//g;
    $text=~s/\]\]//g;
    $text=~s/''+//g;
    return $text;
$_$;


ALTER FUNCTION px.wiki_clean(wikitext text) OWNER TO postgres;

--
-- Name: FUNCTION wiki_clean(wikitext text); Type: COMMENT; Schema: px; Owner: postgres
--

COMMENT ON FUNCTION wiki_clean(wikitext text) IS 'Remove wiki markup';


--
-- Name: wiki_deurl(text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION wiki_deurl(u text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$ select replace($1,'_',' ') $_$;


ALTER FUNCTION px.wiki_deurl(u text) OWNER TO postgres;

--
-- Name: FUNCTION wiki_deurl(u text); Type: COMMENT; Schema: px; Owner: postgres
--

COMMENT ON FUNCTION wiki_deurl(u text) IS 'Remove _ from wiki page titles';


--
-- Name: wiki_link(text, text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION wiki_link(wikitext text, base text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_X$
    my ($text,$base,$target) = @_;
    if($text=~/^\{\{/) { return ''; }
    $text=~s/''+//g;
    sub rpl { 
	my ($link,$label)=split('\|',$_[0]);
	if(!$label) { $label=$link; }
	$link = $_[1].$link;
	return qq{<a target="$_[1]" href="$link">$label</a>}; 
    };
    
    $text=~s/\[\[(.+?)\]\]/rpl($1,$base)/ge;
    return $text;
$_X$;


ALTER FUNCTION px.wiki_link(wikitext text, base text) OWNER TO postgres;

--
-- Name: FUNCTION wiki_link(wikitext text, base text); Type: COMMENT; Schema: px; Owner: postgres
--

COMMENT ON FUNCTION wiki_link(wikitext text, base text) IS 'Resolve wiki links';


--
-- Name: wrap(text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION wrap(text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_X$
 return defined($_[0])?"$_[0]":"";
$_X$;


ALTER FUNCTION px.wrap(text) OWNER TO postgres;

--
-- Name: wrap(text, integer); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION wrap(text, integer) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_X$ 
 return defined($_[1])?"$_[0]$_[1]":""; 
$_X$;


ALTER FUNCTION px.wrap(text, integer) OWNER TO postgres;

--
-- Name: wrap(text, integer, text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION wrap(text, integer, text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_X$ 
 return defined($_[1])?"$_[0]$_[1]$_[2]":""; 
$_X$;


ALTER FUNCTION px.wrap(text, integer, text) OWNER TO postgres;

--
-- Name: wrap(text, numeric, text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION wrap(text, numeric, text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_X$ 
 return defined($_[1])?"$_[0]$_[1]$_[2]":""; 
$_X$;


ALTER FUNCTION px.wrap(text, numeric, text) OWNER TO postgres;

--
-- Name: wrap(text, text, text); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION wrap(text, text, text) RETURNS text
    LANGUAGE plperl IMMUTABLE
    AS $_X$
 return defined($_[1])?"$_[0]$_[1]$_[2]":"";
$_X$;


ALTER FUNCTION px.wrap(text, text, text) OWNER TO postgres;

--
-- Name: xml_localize(xml, lang); Type: FUNCTION; Schema: px; Owner: postgres
--

CREATE FUNCTION xml_localize(xml, lang) RETURNS xml
    LANGUAGE plperlu
    AS $_$
my ($xml,$lang)=@_;

use XML::LibXML;
my $parser = XML::LibXML->new();
my $tree;

eval { $tree = $parser->parse_string($xml); };
if($@) {
    my $err=$@; $err=~s/Stack:.*$//s;
    elog(ERROR,"XML Parse Error\n".$err."\n");
    return;
} 

my $root = $tree->getDocumentElement;
foreach my $node ($root->findnodes('//*[@lang]')) {
    if($node->getAttribute('lang') ne $lang) {
#	elog(NOTICE,"Deleting ".$node->toString());
	$node->unbindNode();
    }
}

return $root->toString();
$_$;


ALTER FUNCTION px.xml_localize(xml, lang) OWNER TO postgres;

--
-- Name: FUNCTION xml_localize(xml, lang); Type: COMMENT; Schema: px; Owner: postgres
--

COMMENT ON FUNCTION xml_localize(xml, lang) IS 'Extract only relevant language from XML file';


--
-- Name: array_agg(anyelement); Type: AGGREGATE; Schema: px; Owner: postgres
--

CREATE AGGREGATE array_agg(anyelement) (
    SFUNC = array_append,
    STYPE = anyarray,
    INITCOND = '{}'
);


ALTER AGGREGATE px.array_agg(anyelement) OWNER TO postgres;

--
-- Name: concat(text); Type: AGGREGATE; Schema: px; Owner: postgres
--

CREATE AGGREGATE concat(text) (
    SFUNC = textcat,
    STYPE = text
);


ALTER AGGREGATE px.concat(text) OWNER TO postgres;

--
-- Name: AGGREGATE concat(text); Type: COMMENT; Schema: px; Owner: postgres
--

COMMENT ON AGGREGATE concat(text) IS 'String concatenation aggregate';


SET default_tablespace = '';

SET default_with_oids = true;

--
-- Name: config; Type: TABLE; Schema: px; Owner: postgres; Tablespace: 
--

CREATE TABLE config (
    name text NOT NULL,
    value text NOT NULL,
    type regtype NOT NULL,
    comment text
);


ALTER TABLE config OWNER TO postgres;

--
-- Name: TABLE config; Type: COMMENT; Schema: px; Owner: postgres
--

COMMENT ON TABLE config IS 'Various configuration parameters';


--
-- Name: strings; Type: TABLE; Schema: px; Owner: postgres; Tablespace: 
--

CREATE TABLE strings (
    name text NOT NULL,
    lang text NOT NULL,
    text text
);


ALTER TABLE strings OWNER TO postgres;

--
-- Name: TABLE strings; Type: COMMENT; Schema: px; Owner: postgres
--

COMMENT ON TABLE strings IS 'l10n strings';


--
-- Name: config_pkey; Type: CONSTRAINT; Schema: px; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY config
    ADD CONSTRAINT config_pkey PRIMARY KEY (name);


--
-- Name: strings_pkey; Type: CONSTRAINT; Schema: px; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY strings
    ADD CONSTRAINT strings_pkey PRIMARY KEY (name, lang);


--
-- Name: px; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA px FROM PUBLIC;
REVOKE ALL ON SCHEMA px FROM postgres;
GRANT ALL ON SCHEMA px TO postgres;
GRANT USAGE ON SCHEMA px TO PUBLIC;


--
-- Name: config; Type: ACL; Schema: px; Owner: postgres
--

REVOKE ALL ON TABLE config FROM PUBLIC;
REVOKE ALL ON TABLE config FROM postgres;
GRANT ALL ON TABLE config TO postgres;
GRANT SELECT ON TABLE config TO PUBLIC;


--
-- Name: strings; Type: ACL; Schema: px; Owner: postgres
--

REVOKE ALL ON TABLE strings FROM PUBLIC;
REVOKE ALL ON TABLE strings FROM postgres;
GRANT ALL ON TABLE strings TO postgres;
GRANT SELECT ON TABLE strings TO PUBLIC;


--
-- PostgreSQL database dump complete
--

