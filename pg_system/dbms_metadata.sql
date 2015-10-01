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
-- Name: dbms_metadata; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA dbms_metadata;


ALTER SCHEMA dbms_metadata OWNER TO postgres;

--
-- Name: SCHEMA dbms_metadata; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA dbms_metadata IS 'Database metadata and DDL export library';


SET search_path = dbms_metadata, pg_catalog;

--
-- Name: sql_identifier; Type: DOMAIN; Schema: dbms_metadata; Owner: postgres
--

CREATE DOMAIN sql_identifier AS text;


ALTER DOMAIN sql_identifier OWNER TO postgres;

--
-- Name: sql_object_type; Type: TYPE; Schema: dbms_metadata; Owner: postgres
--

CREATE TYPE sql_object_type AS ENUM (
    'CLASS',
    'CLASSES',
    'CONSTRAINT',
    'CONSTRAINTS',
    'DOMAIN',
    'DOMAINS',
    'FUNCTION',
    'FUNCTIONS',
    'ROLE',
    'SCHEMA',
    'SEQUENCE',
    'SEQUENCES',
    'TABLE',
    'TABLES',
    'TRIGGER',
    'TRIGGERS',
    'TYPE',
    'TYPES',
    'VIEW',
    'VIEWS'
);


ALTER TYPE sql_object_type OWNER TO postgres;

--
-- Name: sql_statement; Type: DOMAIN; Schema: dbms_metadata; Owner: postgres
--

CREATE DOMAIN sql_statement AS text;


ALTER DOMAIN sql_statement OWNER TO postgres;

--
-- Name: _pg_sv_acl_db_default(text); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_acl_db_default(text) RETURNS aclitem[]
    LANGUAGE sql STABLE STRICT
    AS $_$
    select ARRAY[ dbms_metadata._pg_sv_mkacl($1 || '=CT/' || $1),
                  dbms_metadata._pg_sv_mkacl('=CT/' || $1) ]
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_acl_db_default(text) OWNER TO postgres;

--
-- Name: _pg_sv_acl_func_default(text); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_acl_func_default(text) RETURNS aclitem[]
    LANGUAGE sql STABLE STRICT
    AS $_$
    select ARRAY[ dbms_metadata._pg_sv_mkacl($1 || '=X/' || $1),
                  dbms_metadata._pg_sv_mkacl('=X/' || $1) ]
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_acl_func_default(text) OWNER TO postgres;

--
-- Name: _pg_sv_acl_lang_default(text); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_acl_lang_default(text) RETURNS aclitem[]
    LANGUAGE sql STABLE STRICT
    AS $_$
    select ARRAY[ dbms_metadata._pg_sv_mkacl('=U/' || $1) ]
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_acl_lang_default(text) OWNER TO postgres;

--
-- Name: _pg_sv_acl_rel_default(text); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_acl_rel_default(text) RETURNS aclitem[]
    LANGUAGE sql STABLE STRICT
    AS $_$
    select ARRAY[ dbms_metadata._pg_sv_mkacl($1 || '=arwdRxt/' || $1) ]
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_acl_rel_default(text) OWNER TO postgres;

--
-- Name: _pg_sv_acl_schema_default(text); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_acl_schema_default(text) RETURNS aclitem[]
    LANGUAGE sql STABLE STRICT
    AS $_$
    select ARRAY[ dbms_metadata._pg_sv_mkacl($1 || '=CU/' || $1) ]
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_acl_schema_default(text) OWNER TO postgres;

--
-- Name: _pg_sv_acl_tablespace_default(text); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_acl_tablespace_default(text) RETURNS aclitem[]
    LANGUAGE sql STABLE STRICT
    AS $_$
    select ARRAY[ dbms_metadata._pg_sv_mkacl($1 || '=C/' || $1) ]
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_acl_tablespace_default(text) OWNER TO postgres;

--
-- Name: _pg_sv_aclitem_all_index(); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_aclitem_all_index() RETURNS SETOF integer
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $$
    select g.s
      from dbms_metadata._pg_sv_generate_series(1,
              (select max(coalesce(array_upper(object_acl,1),2))
                 from dbms_metadata._pg_all_grant_raw)) as g(s)
  $$;


ALTER FUNCTION dbms_metadata._pg_sv_aclitem_all_index() OWNER TO postgres;

--
-- Name: _pg_sv_aclitem_grantee(aclitem); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_aclitem_grantee(aclitem) RETURNS text
    LANGUAGE sql STABLE STRICT
    AS $_$
    select dbms_metadata._pg_sv_aclitem_grantee(dbms_metadata._pg_sv_aclitem_text($1))
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_aclitem_grantee(aclitem) OWNER TO postgres;

--
-- Name: _pg_sv_aclitem_grantee(text); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_aclitem_grantee(text) RETURNS text
    LANGUAGE sql STABLE STRICT
    AS $_$
    select case when $1 like '=%' then 'public'
                else dbms_metadata._pg_sv_dequote(dbms_metadata._pg_sv_aclitem_grantee_name($1))
           end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_aclitem_grantee(text) OWNER TO postgres;

--
-- Name: _pg_sv_aclitem_grantee_is_group(aclitem); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_aclitem_grantee_is_group(aclitem) RETURNS boolean
    LANGUAGE sql STABLE STRICT
    AS $_$
    select dbms_metadata._pg_sv_aclitem_text($1) ~ '^(group |=)'
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_aclitem_grantee_is_group(aclitem) OWNER TO postgres;

--
-- Name: _pg_sv_aclitem_grantee_name(text); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_aclitem_grantee_name(text) RETURNS text
    LANGUAGE sql STABLE STRICT
    AS $_$
    select substring($1 from E'^(?:group )?(\\w+|"(?:[^"]|"")*")=')
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_aclitem_grantee_name(text) OWNER TO postgres;

--
-- Name: _pg_sv_aclitem_grantor(aclitem); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_aclitem_grantor(aclitem) RETURNS text
    LANGUAGE sql STABLE STRICT
    AS $_$
    select dbms_metadata._pg_sv_aclitem_grantor(_pg_sv_aclitem_text($1))
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_aclitem_grantor(aclitem) OWNER TO postgres;

--
-- Name: _pg_sv_aclitem_grantor(text); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_aclitem_grantor(text) RETURNS text
    LANGUAGE sql STABLE STRICT
    AS $_$
    select dbms_metadata._pg_sv_dequote(substring($1
                                      from E'^.*/(\\w+|"(?:[^"]|"")*")$'))
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_aclitem_grantor(text) OWNER TO postgres;

--
-- Name: _pg_sv_aclitem_mode(aclitem); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_aclitem_mode(aclitem) RETURNS text[]
    LANGUAGE sql STABLE STRICT
    AS $_$
    select dbms_metadata._pg_sv_aclitem_mode(dbms_metadata._pg_sv_aclitem_modestr($1),'{}'::text[])
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_aclitem_mode(aclitem) OWNER TO postgres;

--
-- Name: _pg_sv_aclitem_mode(text, text[]); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_aclitem_mode(text, text[]) RETURNS text[]
    LANGUAGE sql STABLE STRICT
    AS $_$
    select case when $1 = '' then $2
                when $1 like '_*%' then
                  dbms_metadata._pg_sv_aclitem_mode(substring($1 from 3),
                                                  array_append($2,substring($1 from 1 for 2)))
                else
                  dbms_metadata._pg_sv_aclitem_mode(substring($1 from 2),
                                                  array_append($2,substring($1 from 1 for 1)))
           end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_aclitem_mode(text, text[]) OWNER TO postgres;

--
-- Name: _pg_sv_aclitem_modestr(aclitem); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_aclitem_modestr(aclitem) RETURNS text
    LANGUAGE sql STABLE STRICT
    AS $_$
    select substring(dbms_metadata._pg_sv_aclitem_text($1)
                     from E'^(?:(?:group )?(?:\\w+|"(?:[^"]|"")*"))?=([\\w*]*)/')
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_aclitem_modestr(aclitem) OWNER TO postgres;

--
-- Name: _pg_sv_aclitem_text(aclitem); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_aclitem_text(aclitem) RETURNS text
    LANGUAGE sql STABLE STRICT
    AS $_$
    select textin(aclitemout($1))
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_aclitem_text(aclitem) OWNER TO postgres;

--
-- Name: _pg_sv_argpositions(); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_argpositions() RETURNS SETOF integer
    LANGUAGE sql IMMUTABLE
    AS $$
    select g.s
      from generate_series(1,current_setting('max_function_args')::int,1)
             as g(s)
  $$;


ALTER FUNCTION dbms_metadata._pg_sv_argpositions() OWNER TO postgres;

--
-- Name: _pg_sv_array_uniq(smallint[]); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_array_uniq(smallint[]) RETURNS smallint[]
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select case when $1 = '{}' then '{}'
                else dbms_metadata._pg_sv_array_uniq2($1,'{}')
                end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_array_uniq(smallint[]) OWNER TO postgres;

--
-- Name: _pg_sv_array_uniq2(smallint[], smallint[]); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_array_uniq2(smallint[], smallint[]) RETURNS smallint[]
    LANGUAGE sql IMMUTABLE
    AS $_$
    select case when $1 is null then $2
                else dbms_metadata._pg_sv_array_uniq2($1[2:array_upper($1,1)],
                                                    case when $1[1] = ANY ($2) then $2
                                                         else array_append($2,$1[1]) end)
                end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_array_uniq2(smallint[], smallint[]) OWNER TO postgres;

--
-- Name: _pg_sv_basetype_oid(oid, pg_type); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_basetype_oid(oid, pg_type) RETURNS oid
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select case when $2.typtype='d' then
                  $2.typbasetype
                when $2.typelem != 0 and $2.typlen = -1 then
                  $2.typelem
                else
                  $1
                end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_basetype_oid(oid, pg_type) OWNER TO postgres;

--
-- Name: _pg_sv_basetype_typmod(oid, pg_type, integer); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_basetype_typmod(oid, pg_type, integer) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select case when $2.typtype='d' then
                  $2.typtypmod
                else
                  $3
                end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_basetype_typmod(oid, pg_type, integer) OWNER TO postgres;

--
-- Name: _pg_sv_column_array(oid, smallint[]); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_column_array(oid, smallint[]) RETURNS name[]
    LANGUAGE sql STABLE
    AS $_$
    select ARRAY(select a.attname
                   from pg_attribute a
                        join dbms_metadata._pg_sv_keypositions() s(i)
                          on (a.attnum = $2[i])
                  where attrelid=$1 order by i)
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_column_array(oid, smallint[]) OWNER TO postgres;

--
-- Name: _pg_sv_db_tablespace(); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_db_tablespace() RETURNS oid
    LANGUAGE sql STABLE
    AS $$
    select dattablespace from pg_database where datname=current_database()
  $$;


ALTER FUNCTION dbms_metadata._pg_sv_db_tablespace() OWNER TO postgres;

--
-- Name: _pg_sv_dbconfig_index(); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_dbconfig_index() RETURNS SETOF integer
    LANGUAGE sql STABLE
    AS $$
    select g.s
      from generate_series(1, (select max(array_upper(datconfig,1))
                                 from pg_database)) as g(s)
  $$;


ALTER FUNCTION dbms_metadata._pg_sv_dbconfig_index() OWNER TO postgres;

--
-- Name: _pg_sv_dequote(text); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_dequote(text) RETURNS text
    LANGUAGE sql STABLE STRICT
    AS $_$
    select case
             when $1 like '"%' then
               replace(substring($1 from 2 for length($1)-2),'""','"')
             else $1
           end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_dequote(text) OWNER TO postgres;

--
-- Name: _pg_sv_function_accessible(oid, oid); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_function_accessible(oid, oid) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select case when has_schema_privilege($1,'USAGE')
                then has_function_privilege($2,'EXECUTE')
                else false end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_function_accessible(oid, oid) OWNER TO postgres;

--
-- Name: _pg_sv_generate_series(integer, integer); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_generate_series(integer, integer) RETURNS SETOF integer
    LANGUAGE sql IMMUTABLE
    AS $_$
    select i from generate_series($1,$2) as s(i)
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_generate_series(integer, integer) OWNER TO postgres;

--
-- Name: _pg_sv_grolist_index(); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_grolist_index() RETURNS SETOF integer
    LANGUAGE sql STABLE
    AS $$
    select g.s
      from generate_series(1, (select max(array_upper(grolist,1))
                                 from pg_group)) as g(s)
  $$;


ALTER FUNCTION dbms_metadata._pg_sv_grolist_index() OWNER TO postgres;

--
-- Name: _pg_sv_index_prefix_count(smallint[], int2vector, smallint[], integer, integer); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_index_prefix_count(smallint[], int2vector, smallint[], integer, integer) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select case when $4>=$5 then $4
                when $2[$4] = ANY ($1) then
                  dbms_metadata._pg_sv_index_prefix_count($1,$2,
                                                        array_append($3,$2[$4]),
                                                        $4+1,$5)
                else $4 end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_index_prefix_count(smallint[], int2vector, smallint[], integer, integer) OWNER TO postgres;

--
-- Name: _pg_sv_keypositions(); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_keypositions() RETURNS SETOF integer
    LANGUAGE sql IMMUTABLE
    AS $$
    select g.s
      from generate_series(1,current_setting('max_index_keys')::int,1)
             as g(s)
  $$;


ALTER FUNCTION dbms_metadata._pg_sv_keypositions() OWNER TO postgres;

--
-- Name: _pg_sv_mkacl(text); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_mkacl(text) RETURNS aclitem
    LANGUAGE sql STABLE STRICT
    AS $_$
    select aclitemin(textout($1))
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_mkacl(text) OWNER TO postgres;

--
-- Name: _pg_sv_oidvector_array(oidvector, smallint); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_oidvector_array(oidvector, smallint) RETURNS oid[]
    LANGUAGE sql IMMUTABLE
    AS $_$
    select ARRAY(select $1[i] from generate_series(0,$2-1) s(i))
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_oidvector_array(oidvector, smallint) OWNER TO postgres;

--
-- Name: _pg_sv_pages_to_mb(numeric); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_pages_to_mb(numeric) RETURNS numeric
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select ($1 * current_setting('block_size')::int)/1048576.0
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_pages_to_mb(numeric) OWNER TO postgres;

--
-- Name: _pg_sv_rule_get_action(text); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_rule_get_action(text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select substring($1 from
      E'^CREATE RULE [^\\n]*\\n[^\\n]*(?:\\n *WHERE .*?)? DO '
      '(?:INSTEAD)?  ?([(]?(?:NOTHING|SELECT|UPDATE|INSERT|DELETE|NOTIFY).*);$')
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_rule_get_action(text) OWNER TO postgres;

--
-- Name: _pg_sv_rule_get_where(text); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_rule_get_where(text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select substring($1 from
      E'^CREATE RULE [^\\n]*\\n[^\\n]*\\n *WHERE (.*) '
      'DO (?:INSTEAD)?  ?[(]?(?:NOTHING|SELECT|UPDATE|INSERT|DELETE|NOTIFY)')
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_rule_get_where(text) OWNER TO postgres;

--
-- Name: _pg_sv_schema_accessible(oid); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_schema_accessible(oid) RETURNS boolean
    LANGUAGE sql STABLE STRICT
    AS $_$
  SELECT has_schema_privilege( $1, 'USAGE')
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_schema_accessible(oid) OWNER TO postgres;

--
-- Name: _pg_sv_system_schema(name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_system_schema(name) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select $1 in (name 'pg_catalog', name 'pg_toast',
                  name 'dbms_metadata', name 'information_schema')
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_system_schema(name) OWNER TO postgres;

--
-- Name: _pg_sv_table_accessible(oid, oid); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_table_accessible(oid, oid) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select case when has_schema_privilege($1,'USAGE')
                then (has_table_privilege($2,'SELECT')
                      or has_table_privilege($2,'INSERT')
                      or has_table_privilege($2,'UPDATE')
                      or has_table_privilege($2,'DELETE')
                      or has_table_privilege($2,'RULE')
                      or has_table_privilege($2,'REFERENCES')
                      or has_table_privilege($2,'TRIGGER'))
                else false end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_table_accessible(oid, oid) OWNER TO postgres;

--
-- Name: _pg_sv_tablespace(pg_class); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_tablespace(pg_class) RETURNS oid
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select $1.reltablespace
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_tablespace(pg_class) OWNER TO postgres;

--
-- Name: _pg_sv_tablespace(pg_database); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_tablespace(pg_database) RETURNS oid
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select $1.dattablespace
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_tablespace(pg_database) OWNER TO postgres;

--
-- Name: _pg_sv_tablespace_match(pg_class, oid); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_tablespace_match(pg_class, oid) RETURNS boolean
    LANGUAGE sql STABLE
    AS $_$
    select $2 = CASE WHEN $1.reltablespace = 0
                       THEN dbms_metadata._pg_sv_db_tablespace()
                     ELSE $1.reltablespace END
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_tablespace_match(pg_class, oid) OWNER TO postgres;

--
-- Name: _pg_sv_tablespace_usage(oid); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_tablespace_usage(oid) RETURNS oid[]
    LANGUAGE sql STRICT
    AS $_$
    select ARRAY(select oid from pg_tablespace_databases($1) d(oid))
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_tablespace_usage(oid) OWNER TO postgres;

--
-- Name: _pg_sv_temp_schema(name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_temp_schema(name) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select $1 like 'pg!_temp!_%' escape '!' 
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_temp_schema(name) OWNER TO postgres;

--
-- Name: _pg_sv_type_baseoid(oid, pg_type); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_type_baseoid(oid, pg_type) RETURNS oid
    LANGUAGE sql STABLE STRICT
    AS $_$
    select case when $2.typtype='d' then
                  $2.typbasetype
                else 
                  $1
           end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_type_baseoid(oid, pg_type) OWNER TO postgres;

--
-- Name: _pg_sv_type_bit_length(oid, integer); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_type_bit_length(oid, integer) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select case when $1 in ('pg_catalog.bit'::regtype,
                            'pg_catalog.varbit'::regtype) then
                  $2
                else
                  null
                end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_type_bit_length(oid, integer) OWNER TO postgres;

--
-- Name: _pg_sv_type_char_length(oid, integer); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_type_char_length(oid, integer) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select case when $1 in ('pg_catalog.bpchar'::regtype,
                            'pg_catalog.varchar'::regtype) then
                  case when $2 > 3 then ($2 - 4) else -1 end
                when $1 in ('pg_catalog.name'::regtype) then
                  (select typlen-1 from pg_type
                   where oid='pg_catalog.name'::regtype)
                when $1 in ('pg_catalog."char"'::regtype) then
                  1
                when $1 in ('pg_catalog.text'::regtype) then
                  -1
                else
                  null
                end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_type_char_length(oid, integer) OWNER TO postgres;

--
-- Name: _pg_sv_type_float_precision(oid, integer); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_type_float_precision(oid, integer) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select case when $1 = 'pg_catalog.float4'::regtype then
                  24
                when $1 = 'pg_catalog.float8'::regtype then
                  53
                else
                  null
                end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_type_float_precision(oid, integer) OWNER TO postgres;

--
-- Name: _pg_sv_type_integer_precision(oid, integer); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_type_integer_precision(oid, integer) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select case when $1 = 'pg_catalog.int2'::regtype then
                  16
                when $1 = 'pg_catalog.int4'::regtype then
                  32
                when $1 = 'pg_catalog.int8'::regtype then
                  64
                else
                  null
                end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_type_integer_precision(oid, integer) OWNER TO postgres;

--
-- Name: _pg_sv_type_interval_fields(oid, integer); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_type_interval_fields(oid, integer) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select case when $1 = 'pg_catalog.interval'::regtype then
                  coalesce(substring(format_type($1,$2) from ' (.*)$'),'')
                else
                  null
                end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_type_interval_fields(oid, integer) OWNER TO postgres;

--
-- Name: _pg_sv_type_interval_precision(oid, integer); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_type_interval_precision(oid, integer) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select case when $1 = 'pg_catalog.interval'::regtype then
                  case when ($2 & 65535) = 65535 then -1 else ($2 & 65535) end
                else
                  null
                end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_type_interval_precision(oid, integer) OWNER TO postgres;

--
-- Name: _pg_sv_type_name(oid, pg_type); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_type_name(oid, pg_type) RETURNS text
    LANGUAGE sql STABLE STRICT
    AS $_$
    select case when $2.typtype = 'd' then
                  format_type($2.typbasetype,NULL)
                when $2.typtype = 'c' then
                  $2.typname
                else 
                  format_type($1,NULL)
           end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_type_name(oid, pg_type) OWNER TO postgres;

--
-- Name: _pg_sv_type_numeric_precision(oid, integer); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_type_numeric_precision(oid, integer) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select case when $1 = 'pg_catalog.numeric'::regtype and $2 >= 0 then
                  (($2 - 4) >> 16) & 65535
                else
                  null
                end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_type_numeric_precision(oid, integer) OWNER TO postgres;

--
-- Name: _pg_sv_type_numeric_scale(oid, integer); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_type_numeric_scale(oid, integer) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select case when $1 = 'pg_catalog.numeric'::regtype and $2 >= 0 then
                  ($2 - 4) & 65535
                else
                  null
                end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_type_numeric_scale(oid, integer) OWNER TO postgres;

--
-- Name: _pg_sv_type_sql(oid, pg_type, integer); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_type_sql(oid, pg_type, integer) RETURNS text
    LANGUAGE sql STABLE STRICT
    AS $_$
    select case when $2.typtype='d' then
                  format_type($2.typbasetype,$2.typtypmod)
                else 
                  format_type($1,$3)
           end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_type_sql(oid, pg_type, integer) OWNER TO postgres;

--
-- Name: _pg_sv_type_time_precision(oid, integer); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_type_time_precision(oid, integer) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
    select case when $1 in ('pg_catalog.time'::regtype,
                            'pg_catalog.timetz'::regtype,
                            'pg_catalog.timestamp'::regtype,
                            'pg_catalog.timestamptz'::regtype) then
                  $2
                else
                  null
                end
  $_$;


ALTER FUNCTION dbms_metadata._pg_sv_type_time_precision(oid, integer) OWNER TO postgres;

--
-- Name: _pg_sv_userconfig_index(); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION _pg_sv_userconfig_index() RETURNS SETOF integer
    LANGUAGE sql STABLE
    AS $$
    select g.s
      from generate_series(1, (select max(array_upper(useconfig,1))
                                 from pg_user)) as g(s)
  $$;


ALTER FUNCTION dbms_metadata._pg_sv_userconfig_index() OWNER TO postgres;

--
-- Name: ansi_ddl_domain(name, name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION ansi_ddl_domain(name, name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE 
 my_schema ALIAS FOR $1; 
 my_domain ALIAS FOR $2; 
 identifier varchar; 
 nl varchar; 
 r record;
 ddl text; 
 
BEGIN 
 nl := E'\n'; 
 identifier := quote_ident(my_schema)||'.'||quote_ident(my_domain); 

 SELECT INTO r *
 FROM information_schema.domains
 WHERE domain_name=my_domain
   AND domain_schema=my_schema
   AND domain_catalog=current_database();
 
 RETURN  
  'CREATE DOMAIN '||identifier||' '||ddl||';'||nl; 
END 
$_$;


ALTER FUNCTION dbms_metadata.ansi_ddl_domain(name, name) OWNER TO postgres;

--
-- Name: ansi_ddl_table(name, name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION ansi_ddl_table(name, name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE 
 my_schema ALIAS FOR $1; 
 my_table ALIAS FOR $2; 
 identifier varchar; 
 nl varchar; 
 ddl_pk text; 
 ddl_constraints text; 
 ddl_columns text; 
 
BEGIN 
 nl := E'\n'; 
 identifier := quote_ident(my_schema)||'.'||quote_ident(my_table); 
 
 SELECT INTO ddl_columns 
  dbms_metadata.concat( 
              '    ' 
              ||quote_ident(dd.column_name)||' ' 
              ||quote_ident(coalesce(dd.domain_name,dd.data_type)) 
              ||case when dd.character_maximum_length is not null then ' ('||dd.character_maximum_length||')' else '' end 
              ||case when dd.is_nullable = 'NO' then ' NOT NULL' else '' end 
              ||case when dd.column_default is not null then ' DEFAULT '||dd.column_default else '' end 
              ||','||nl 
             ) 
 FROM ( 
  SELECT *, 
         trim('::'||quote_ident(coalesce(domain_name,udt_name)) from column_default) as column_default_fixed 
    FROM information_schema.columns 
   WHERE table_name = my_table 
     AND table_schema = my_schema 
     AND table_catalog = current_database() 
   ORDER BY ordinal_position 
 ) AS dd; 
 
  SELECT INTO ddl_pk 
         dbms_metadata.wrap('    CONSTRAINT '||quote_ident(constraint_name)||' PRIMARY KEY (', 
         dbms_metadata.nuls(trim(',' from dbms_metadata.concat(quote_ident(column_name)||','))), 
         '),'||nl) 
 FROM ( 
  SELECT * 
    FROM information_schema.key_column_usage 
   WHERE table_name = my_table 
     AND table_schema = my_schema 
     AND table_catalog = current_database() 
   ORDER BY ordinal_position 
 ) AS dd 
 GROUP BY constraint_name; 
 
 SELECT INTO ddl_constraints 
  dbms_metadata.concat( 
              '    CONSTRAINT ' 
              ||quote_ident(constraint_name)||' ' 
              ||constraint_type 
              ||case when dd.is_deferrable = 'YES' then ' DEFERRABLE' else '' end 
              ||case when dd.initially_deferred = 'YES' then ' INITIALLY DEFERRED' else '' end 
              ||','||nl 
             ) 
 FROM ( 
  SELECT * 
    FROM information_schema.table_constraints 
   WHERE table_name = my_table 
     AND table_schema = my_schema 
     AND table_catalog = current_database() 
   ORDER BY constraint_type desc, constraint_name 
 ) AS dd; 
 
 ddl_constraints := coalesce(ddl_pk,'')||coalesce(ddl_constraints,''); 
 
 RETURN  
  'CREATE TABLE '||identifier||' ('||nl|| 
     trim(','||nl from coalesce(ddl_columns,'')||ddl_constraints) 
  ||nl||');'||nl; 
END 
$_$;


ALTER FUNCTION dbms_metadata.ansi_ddl_table(name, name) OWNER TO postgres;

--
-- Name: ddl_header(); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION ddl_header() RETURNS text
    LANGUAGE sql STABLE
    AS $$
select cast(
 'dbms_metadata (v ' || version || ') on ' || current_time 
 as text)
  from dbms_metadata.version 
 limit 1
$$;


ALTER FUNCTION dbms_metadata.ddl_header() OWNER TO postgres;

--
-- Name: ddl_header(text, name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION ddl_header(ddl_type text, namespace name) RETURNS text
    LANGUAGE sql STABLE
    AS $_$
select cast(
  '----------------------------------------------------------------' || E'\n' ||
  '-- ' || upper($1) || ' in ' || current_database() || '.' || $2 || E'\n' ||
  '-- generated by dbms_metadata (v ' || date(version) || ') ' || E'\n' ||
  '-- on ' || current_time  || E'\n' ||
  '-- by ' || current_role  || E'\n' ||
  '----------------------------------------------------------------' || E'\n\n'
 as text)
  from dbms_metadata.version 
 limit 1
$_$;


ALTER FUNCTION dbms_metadata.ddl_header(ddl_type text, namespace name) OWNER TO postgres;

--
-- Name: get_ddl(name, name, name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION get_ddl(object_type name, name name, schema name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$declare
 my_object_type alias for $1;
 my_object_name alias for $2;
 my_object_namespace alias for $3;
 my_script text;
begin
 select 
  'ddl_'||lower(type)
 into strict my_script
 from dbms_metadata.object_type
 where type=upper(my_object_type);

 return my_script::dbms_metadata.sql_statement;
end
$_$;


ALTER FUNCTION dbms_metadata.get_ddl(object_type name, name name, schema name) OWNER TO postgres;

--
-- Name: get_dependent_ddl(name, name, name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION get_dependent_ddl(type name, object name, schema name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$declare
 my_object_type alias for $1;
 my_object_name alias for $2;
 my_object_namespace alias for $3;
begin

 return ';'::dbms_metadata.sql_statement;
end
$_$;


ALTER FUNCTION dbms_metadata.get_dependent_ddl(type name, object name, schema name) OWNER TO postgres;

--
-- Name: pg_ddl_alter_owner(regclass); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_alter_owner(regclass) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE 
 ddl text; 
 
BEGIN 
 SELECT INTO ddl 
  dbms_metadata.concat( 
   'ALTER TABLE '||text($1)||' OWNER TO '||quote_ident(pg_get_userbyid(c.relowner))||E';\n' 
 ) 
 FROM pg_class c
 WHERE oid = $1;

 return coalesce(ddl,'');
END 
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_alter_owner(regclass) OWNER TO postgres;

--
-- Name: pg_ddl_alter_sequence(regclass); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_alter_sequence(regclass) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE
  r RECORD;
  result text;
  sql_identifier text;
BEGIN
 sql_identifier := dbms_metadata.sql_identifier($1);
 result := '';
 FOR r IN EXECUTE 'SELECT * FROM '||sql_identifier LOOP
  result := 'ALTER SEQUENCE ' || sql_identifier || 
            ' INCREMENT BY ' || r.increment_by ||
            case 
             when r.min_value is null then ' NO MINVALUE'
             else ' MINVALUE '|| r.min_value
            end ||
            case 
             when r.max_value is null then ' NO MAXVALUE'
             else ' MAXVALUE '|| r.max_value
            end ||
            ' RESTART WITH ' || r.last_value ||
            case 
             when r.is_cycled then ' CYCLE'
             else ' NO CYCLE'
            end ||
            E';\n';
 END LOOP;
 RETURN result;
END;
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_alter_sequence(regclass) OWNER TO postgres;

--
-- Name: pg_ddl_alter_sequences(name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_alter_sequences(name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE
 def text;

BEGIN

 SELECT INTO def '
----------------------------------------------------------------
-- SEQUENCE SETTINGS ' || current_database() || '.' || $1 || '
-- generated by dbms_metadata on ' || current_time || '
----------------------------------------------------------------

' ||
 dbms_metadata.concat(ddl)
 FROM (
  SELECT dbms_metadata.ddl_alter_sequence(cast(sysid as regclass)) as ddl
  FROM dbms_metadata.sequence
  WHERE namespace=$1
  ORDER BY name
 ) AS f;

 RETURN def;
END;$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_alter_sequences(name) OWNER TO postgres;

--
-- Name: pg_ddl_alter_table_defaults(regclass); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_alter_table_defaults(regclass) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE 
 object ALIAS FOR $1; 
 ddl text; 
 
BEGIN 
 SELECT INTO ddl 
  dbms_metadata.concat( 
   'ALTER TABLE '||text(regclass::regclass)|| 
  ' ALTER '||quote_ident(name)|| 
  ' SET DEFAULT '||"default"||E';\n' 
 ) 
 FROM dbms_metadata.pg_get_columns(object)
 WHERE regclass = object 
 AND "default" is not null; 

 return coalesce(ddl||E'\n','');
END 
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_alter_table_defaults(regclass) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_alter_table_defaults(regclass); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_alter_table_defaults(regclass) IS 'dump column defaults for a particular class';


--
-- Name: pg_ddl_create_all_roles(); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_create_all_roles() RETURNS sql_statement
    LANGUAGE plpgsql
    AS $$
DECLARE 
 ddl text; 
 grants text;
BEGIN 
 
 SELECT INTO ddl ' 
---------------------------------------------------------------- 
-- Roles in database ' || current_database() || ' as seen by user ' || current_role || ' 
-- created by dbms_metadata.ddl_roles() on ' || current_timestamp || '
---------------------------------------------------------------- 
 
' || 
   dbms_metadata.concat (dbms_metadata.pg_ddl_create_role(rolname)) 
   FROM (
     SELECT *
       FROM pg_roles
      ORDER BY oid
   ) as roles;

 SELECT INTO grants
  dbms_metadata.concat(dbms_metadata.pg_ddl_grants_to_role(rolname)||E'\n')
   FROM (
     SELECT *
       FROM pg_roles
      ORDER BY oid
   ) as roles;
    
 RETURN ddl||coalesce(grants,''); 
END 

$$;


ALTER FUNCTION dbms_metadata.pg_ddl_create_all_roles() OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_create_all_roles(); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_create_all_roles() IS 'Dump SQL DDL statements needed to create all roles';


--
-- Name: pg_ddl_create_class(regclass); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_create_class(regclass) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE 
 object ALIAS FOR $1; 
 ddl TEXT; 
 
BEGIN 
 SELECT INTO ddl 

'--
-- Name: '||coalesce(c.relname,'')||'; Type: '||coalesce(tt.column2,c.relkind)||'; Schema: '||n.nspname||'; Owner: '||coalesce(pg_get_userbyid(c.relowner),'')||'
--

' ||

 CASE relkind
  WHEN 'v' THEN dbms_metadata.pg_ddl_create_view(object) 
  ELSE dbms_metadata.pg_ddl_create_table(object) || E';\n' 
 END ||
  'COMMENT ON '||coalesce(tt.column2,c.relkind) || '  '  || (c.oid::regclass::text) ||
  ' IS ' || coalesce(quote_ident(obj_description(c.oid)),'NULL') || E';\n'  || 
 coalesce((select dbms_metadata.concat(
           'COMMENT ON COLUMN ' || (c.oid::regclass::text) || '.' || quote_ident(name) ||
           ' IS ' || coalesce(quote_literal(comment),'NULL') || E';\n'
         ) 
    from dbms_metadata.pg_get_columns(object) 
   where regclass = $1 
     and comment IS NOT NULL 
 ) || E'\n',
         '') 

-- E'\nALTER TABLE '||sql_identifier||' OWNER TO '||owner||';' || 
-- E'\nREVOKE ALL ON '||sql_identifier||E' FROM PUBLIC;\n\n'|| 
-- dbms_metadata.ddl_grants(object) 

   from pg_class c 
   join pg_namespace n on n.oid=c.relnamespace
   left join (
     values ('r','TABLE'),
            ('v','VIEW'),
            ('i','INDEX'),
            ('S','SEQUENCE'),
            ('s','SPECIAL')
   ) as tt on tt.column1 = c.relkind
  where c.oid = object; 

 return ddl; 
END 
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_create_class(regclass) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_create_class(regclass); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_create_class(regclass) IS 'dump a particular class (table or view)';


--
-- Name: pg_ddl_create_constraints(regclass); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_create_constraints(regclass) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE
 object alias for $1;
 definition RECORD;
 definitions TEXT;
 sql_identifier TEXT;
BEGIN  
 definitions := '';
 FOR definition IN 
 SELECT
 'ALTER TABLE ' || text(regclass(regclass)) ||  ' ADD CONSTRAINT ' || quote_ident(constraint_name) || 
 E'\n  ' || constraint_definition || E';\n'
  AS sql
 FROM dbms_metadata.pg_get_constraints()
 WHERE regclass=$1
 ORDER BY constraint_type DESC, sysid
 LOOP
  definitions := definitions || definition.sql;
 END LOOP;

 RETURN coalesce(definitions || E'\n','');
END;
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_create_constraints(regclass) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_create_constraints(regclass); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_create_constraints(regclass) IS 'dump constraints on a particular class';


--
-- Name: pg_ddl_create_domain(regtype); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_create_domain(regtype) RETURNS sql_statement
    LANGUAGE sql
    AS $_$
select dbms_metadata.pg_ddl_create_type($1)
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_create_domain(regtype) OWNER TO postgres;

--
-- Name: pg_ddl_create_function(regproc); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_create_function(regproc) RETURNS sql_statement
    LANGUAGE sql
    AS $_$ SELECT CAST ( 
'--
-- Name: '||coalesce(sql_identifier,'')||'; Type: FUNCTION; Schema: '||namespace||'; Owner: '||coalesce(owner,'')||'
--

' ||
E'CREATE OR REPLACE FUNCTION ' || sql_identifier || ' 
  RETURNS ' || 
  CASE retset
  WHEN true THEN 'SETOF ' ELSE '' END || 
  returns ||  
  coalesce(' 
  '||attributes,'') || coalesce(' 
  '||is_strict,'') || ' 
  LANGUAGE ' || quote_literal(language) || ' 
  SECURITY ' || security || ' 
  AS '||quote_literal(definition)|| '; 
' || coalesce(' 
COMMENT ON FUNCTION ' || sql_identifier || '  
  IS '||quote_literal(comment)||'; 
','') || 
 E'\nALTER FUNCTION '||sql_identifier||' OWNER TO '||quote_ident(owner)||';'|| 
 E'\nREVOKE ALL ON FUNCTION '||sql_identifier||E' FROM PUBLIC;\n\n' 
AS dbms_metadata.sql_statement) AS ddl 
FROM dbms_metadata.pg_get_functions()
WHERE sysid = $1 
 
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_create_function(regproc) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_create_function(regproc); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_create_function(regproc) IS 'dump a particular function';


--
-- Name: pg_ddl_create_indexes(regclass); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_create_indexes(regclass) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE
 object ALIAS FOR $1;
 ddl TEXT;

BEGIN
 SELECT INTO ddl
  dbms_metadata.concat(indexdef||E';\n')
 FROM dbms_metadata.pg_get_indexes()
 WHERE sysid = object
 AND constraint_name is null
 ;
 
 RETURN coalesce(ddl||E'\n','');
END
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_create_indexes(regclass) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_create_indexes(regclass); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_create_indexes(regclass) IS 'dump indices on a particular class';


--
-- Name: pg_ddl_create_role(name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_create_role(name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$
declare 
 my_role alias for $1; 
 ddl text; 
 ddl_config text;
begin

 select 
   'CREATE ROLE '||
   quote_ident(rolname)||E';\n'||
   case 
     when description is not null 
     then 'COMMENT ON ROLE '||quote_ident(rolname)||' IS '||quote_literal(description)||E';\n'
     else ''
   end ||
   'ALTER ROLE '||
   quote_ident(rolname)||
   case when rolcanlogin then ' LOGIN' else ' NOLOGIN' end || E'\n  ' ||
   case when rolpassword is not null then 'ENCRYPTED PASSWORD '||quote_literal(rolpassword)||E'\n  ' else '' end ||
   case when rolsuper then 'SUPERUSER' else 'NOSUPERUSER' end || ' ' ||
   case when rolinherit then 'INHERIT' else 'NOINHERIT' end || ' ' ||
   case when rolcreatedb then 'CREATEDB' else 'NOCREATEDB' end || ' ' ||
   case when rolcreaterole then 'CREATEROLE' else 'NOCREATEROLE' end || 
   E';\n'
   from pg_authid a
   left join pg_shdescription d on d.objoid=a.oid
  where a.rolname=my_role
   into ddl;

 select 
   dbms_metadata.concat('ALTER ROLE '||quote_ident(my_role)||' SET '||pg_roles.rolconfig[i]||E';\n')
  from pg_roles,
  generate_series(
     (select array_lower(rolconfig,1) from pg_roles where rolname=my_role),
     (select array_upper(rolconfig,1) from pg_roles where rolname=my_role)
  ) as generate_series(i)
 where rolname=my_role
  into ddl_config;
 
 return ddl||coalesce(ddl_config,'')||E'\n'; 
end

$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_create_role(name) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_create_role(name); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_create_role(name) IS 'Dump SQL DDL statements needed to create a particular role';


--
-- Name: pg_ddl_create_rules(regclass); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_create_rules(regclass) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE
 class ALIAS FOR $1;
 ddl text;
BEGIN

 SELECT INTO ddl 
  dbms_metadata.concat(rule_definition||E'\n')
 FROM dbms_metadata.pg_get_rules()
 WHERE regclass = class
 AND rule_definition IS NOT NULL;

 RETURN coalesce(ddl||E'\n','');

END;$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_create_rules(regclass) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_create_rules(regclass); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_create_rules(regclass) IS 'dump rules on a particular class';


--
-- Name: pg_ddl_create_schema(name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_create_schema(name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE
 s record;
BEGIN
 SELECT INTO s *,obj_description(oid) AS comment FROM pg_namespace WHERE nspname=$1;
 IF FOUND THEN
 RETURN '
SET client_encoding = ''UNICODE'';
SET check_function_bodies = false;

CREATE ROLE '||quote_ident($1)||';
CREATE SCHEMA AUTHORIZATION '||quote_ident($1)||';
'||
 coalesce('COMMENT ON SCHEMA '||quote_ident($1)||' IS '||quote_literal(s.comment),'')||';

';
 END IF;
 RETURN NULL;
END$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_create_schema(name) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_create_schema(name); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_create_schema(name) IS 'dump schema creation';


--
-- Name: pg_ddl_create_table(regclass); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_create_table(regclass) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE
 object ALIAS FOR $1;
 ddl TEXT;

BEGIN
 SELECT INTO ddl
'CREATE TABLE '||(oid::regclass::text)||E' (\n'||
  coalesce(''||(SELECT coalesce(
   TRIM (E',\n' FROM dbms_metadata.concat('    '||definition||E',\n')), '')
  FROM dbms_metadata.pg_get_columns(object)
  WHERE regclass = $1 AND is_local)||E'\n','')||
  ')'||
 (SELECT 
  coalesce(' INHERITS(' || TRIM (', ' FROM dbms_metadata.concat(i.inhparent::regclass::text||', ')) || ')', '')
  FROM pg_inherits i
  WHERE i.inhrelid = $1) ||
 CASE relhasoids
  WHEN true THEN ' WITH OIDS'
  ELSE ''
 END 
 FROM pg_class c
 WHERE oid = object
 AND relkind='r';

 RETURN ddl;
END
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_create_table(regclass) OWNER TO postgres;

--
-- Name: pg_ddl_create_triggers(regclass); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_create_triggers(regclass) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE 
 object ALIAS FOR $1; 
 definition RECORD; 
 definitions TEXT; 
 sql_identifier TEXT; 
BEGIN 
 sql_identifier:=dbms_metadata.sql_identifier(object); 
 definitions := '';
 FOR definition IN  
 SELECT 
  'CREATE TRIGGER '||quote_ident(trigger_name)||' '|| 
  action_order||' '||event_manipulation|| 
  ' ON '|| sql_identifier ||' 
  FOR EACH '|| action_orientation ||  
  ' EXECUTE PROCEDURE '||action_statement||E';\n' AS sql 
 FROM dbms_metadata.pg_get_triggers()
 WHERE regclass=object 
 AND is_constraint IS NULL 
 LOOP 
   definitions := definitions || definition.sql; 
 END LOOP; 
 
 RETURN coalesce(definitions||E'\n',''); 
END; 
 
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_create_triggers(regclass) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_create_triggers(regclass); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_create_triggers(regclass) IS 'dump triggers on a particular class';


--
-- Name: pg_ddl_create_type(regtype); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_create_type(regtype) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$
declare 
 object alias for $1; 
 inf record; 
 
begin
 select into inf
'--
-- Name: '||coalesce(t.typname,'')||'; Type: '||coalesce(tt.column2,t.typtype)||'; Schema: '||n.nspname||'; Owner: '||coalesce(pg_get_userbyid(t.typowner),'')||'
--
'
   as ddl,
      t.typtype
 from pg_type t
 join pg_namespace n on (n.oid = t.typnamespace)
 left join (
   values ('d','DOMAIN'),
          ('c','CLASS'),
          ('b','BASE'),
          ('v','VIEW')
 ) as tt on tt.column1=t.typtype
 where t.oid=$1;

 if inf.typtype = 'd' then
   inf.ddl := inf.ddl ||
               'CREATE DOMAIN '||text(object);
 end if;
 
 return (inf.ddl); 
end 
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_create_type(regtype) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_create_type(regtype); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_create_type(regtype) IS 'dump a type';


--
-- Name: pg_ddl_create_type(name, name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_create_type(name, name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE 
 my_schema ALIAS FOR $1; 
 my_domain ALIAS FOR $2; 
 identifier varchar; 
 nl varchar; 
 r record;
 ddl text; 
 
BEGIN 
 nl := E'\n'; 
 identifier := quote_ident(my_schema)||'.'||quote_ident(my_domain); 

 SELECT INTO r *
 FROM information_schema.domains
 WHERE domain_name=my_domain
   AND domain_schema=my_schema
   AND domain_catalog=current_database();
 
 RETURN  
  'CREATE DOMAIN '||identifier||' '||ddl||';'||nl; 
END 
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_create_type(name, name) OWNER TO postgres;

--
-- Name: pg_ddl_create_view(regclass); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_create_view(regclass) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE
 object ALIAS FOR $1;
 ddl TEXT;

BEGIN
 SELECT INTO ddl
 'CREATE OR REPLACE VIEW '||(oid::regclass::text)||E' AS\n'||
  pg_catalog.pg_get_viewdef(oid,true)||E'\n'
 FROM pg_class t
 WHERE oid = object
 AND relkind = 'v';

 RETURN ddl;
END
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_create_view(regclass) OWNER TO postgres;

--
-- Name: pg_ddl_depends(regclass, boolean); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_depends(my_class regclass, drops boolean) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $$declare 
 script text; 
 res text; 
begin 
 if drops then
   with d as (
   select *
     from dbms_metadata.pg_get_depends_recursive(my_class)
    order by level desc, sysid desc
   ) 
   select dbms_metadata.concat('DROP '||d.dep_type||' '||d.dep_name||E';\n')
     from d
     into script;
  else
   with d as (
   select *
     from dbms_metadata.pg_get_depends_recursive(my_class)
    order by level, sysid
   ) 
   select dbms_metadata.concat(dbms_metadata.pg_ddl_script(sysid::oid)||E'\n')
     from d
     into script;
  end if;
  return script;
end 
$$;


ALTER FUNCTION dbms_metadata.pg_ddl_depends(my_class regclass, drops boolean) OWNER TO postgres;

--
-- Name: pg_ddl_grants_on_class(regclass); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_grants_on_class(regclass) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$BEGIN
 RETURN dbms_metadata.pg_ddl_grants_on_class($1,null);
END
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_grants_on_class(regclass) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_grants_on_class(regclass); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_grants_on_class(regclass) IS 'dump grants for a particular class';


--
-- Name: pg_ddl_grants_on_class(regclass, name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_grants_on_class(regclass, name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE 
 ddl text; 
 namespace name; 
 class name; 
 sql_identifier text; 
BEGIN 
 namespace := dbms_metadata.pg_nspname($1); 
 class     := dbms_metadata.pg_relname($1); 
 
 sql_identifier=coalesce($2,text($1)); 
 
 SELECT INTO ddl  
   dbms_metadata.concat ('GRANT '||privilege_type|| 
                ' ON '||sql_identifier||' TO '|| 
                CASE grantee  
                 WHEN 'PUBLIC' THEN 'PUBLIC' 
                 ELSE quote_ident(grantee) 
                END || 
                CASE is_grantable  
                 WHEN 'YES' THEN ' WITH GRANT OPTION' 
                 ELSE '' 
                END || 
                E';\n') 
 FROM information_schema.table_privileges g 
 WHERE table_schema=namespace 
   AND table_name=class; 
 
 RETURN 'REVOKE ALL ON '||text($1)||' FROM PUBLIC;'||E'\n'||coalesce(ddl,''); 
END 
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_grants_on_class(regclass, name) OWNER TO postgres;

--
-- Name: pg_ddl_grants_to_role(name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_grants_to_role(name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$
declare 
 my_role alias for $1; 
 ddl text; 
begin

 select dbms_metadata.concat(ddl1||E';\n')
   from ( 
   select
    'GRANT '||quote_ident("role")||
    ' TO '||quote_ident("member")||
    case 
    when admin_option then ' WITH ADMIN OPTION'
    else ''
    end as ddl1
    from (
      select 
           r.rolname as "role",
           m.rolname as "member",
           g.rolname as "grantor",
           mem.admin_option
        from pg_auth_members mem
        join pg_authid r on r.oid=mem.roleid
        join pg_authid m on m.oid=mem.member
        join pg_authid g on g.oid=mem.grantor
       where m.rolname=my_role
       order by r.oid
    ) as r
   ) as r2
 into ddl;

 return ddl;
end

$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_grants_to_role(name) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_grants_to_role(name); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_grants_to_role(name) IS 'Dump SQL GRANT statements for all roles granted to given role';


--
-- Name: pg_ddl_schema(name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_schema(name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE
 r dbms_metadata.sql_statement; 
 res1 text;
BEGIN
 EXECUTE 'SET search_path='||quote_ident($1)||',pg_catalog';

 SELECT INTO r (
  dbms_metadata.pg_ddl_create_schema(schema_name) ||
  dbms_metadata.pg_ddl_schema_types(schema_name) ||
  dbms_metadata.pg_ddl_schema_tables(schema_name) ||
  dbms_metadata.pg_ddl_schema_functions(schema_name) ||
  dbms_metadata.pg_ddl_schema_views(schema_name) ||
  dbms_metadata.pg_ddl_schema_constraints(schema_name) ||
  dbms_metadata.pg_ddl_schema_defaults(schema_name) ||
  dbms_metadata.pg_ddl_schema_rules(schema_name) ||
  dbms_metadata.pg_ddl_schema_triggers(schema_name)
 )::dbms_metadata.sql_statement AS sql
 FROM (
  SELECT nspname AS schema_name FROM pg_namespace
   WHERE nspname=$1
 ) n;
 RETURN r;
END;
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_schema(name) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_schema(name); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_schema(name) IS 'dump a whole schema as one neat SQL.';


--
-- Name: pg_ddl_schema_constraints(name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_schema_constraints(name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE 
 namespace ALIAS FOR $1; 
 def text; 
 dom text; 
BEGIN 
 return E'-- NOT YET: constraints\n';
 
 SELECT INTO def 
  dbms_metadata.concat(sql) 
 FROM ( 
  SELECT 
   'ALTER TABLE ' || dbms_metadata.sql_identifier(table_schema,table_name) || 
   ' ADD CONSTRAINT ' || dbms_metadata.sqlqi(constraint_name) ||  
   ' ' || constraint_definition || E';\n' 
  AS sql 
  FROM dbms_metadata.constraints 
  WHERE constraint_schema=namespace 
    OR table_schema=namespace 
  ORDER BY sysid 
 ) AS c; 
 
 SELECT INTO dom 
  dbms_metadata.concat( 
   dbms_metadata.wrap('ALTER DOMAIN '||dbms_metadata.text(sysid::regtype)||' ADD',dbms_metadata.nuls( 
    dbms_metadata.wrap(' CONSTRAINT ',dbms_metadata.sqlqi(constraint_name))|| 
    dbms_metadata.wrap(' CHECK (',check_constraint,')') 
   ),E';\n')) 
 FROM dbms_metadata.domains 
 WHERE schema_name=namespace 
 AND check_constraint IS NOT NULL; 
 
 RETURN dbms_metadata.ddl_header('constraints',namespace) ||
        coalesce(dom || E'\n','') || coalesce(def || E'\n',''); 
END;$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_schema_constraints(name) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_schema_constraints(name); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_schema_constraints(name) IS 'dump constraints for a whole schema';


--
-- Name: pg_ddl_schema_defaults(name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_schema_defaults(name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE
 ddl2 text;
BEGIN
 select into ddl2
        dbms_metadata.concat(ddl1||E';\n')
   from (
     select dbms_metadata.pg_ddl_alter_table_defaults(c.oid) as ddl1
       from pg_class c
       join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = $1
        and c.relkind = 'r'
      order by c.oid
   ) as d;
       
 return coalesce(ddl2||E'\n','');
END
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_schema_defaults(name) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_schema_defaults(name); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_schema_defaults(name) IS 'dump column defaults for a whole schema';


--
-- Name: pg_ddl_schema_functions(name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_schema_functions(name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE
 schema_name ALIAS FOR $1;
 def_functions text;
 def_aggregates text;
BEGIN

 SELECT INTO def_functions 
  dbms_metadata.concat(ddl)
 FROM (
  SELECT dbms_metadata.pg_ddl_create_function(sysid) as ddl
  FROM dbms_metadata.pg_get_functions()
  WHERE namespace=schema_name
  AND language NOT IN ('internal','c')
  ORDER BY language,sysid,sql_identifier
 ) AS f;

 SELECT INTO def_aggregates dbms_metadata.concat(
 'CREATE AGGREGATE '||quote_ident(name)||' ('||
 ' BASETYPE = '||text(basetype)||','||
 ' SFUNC = '||text(sfunc)||','||
 ' STYPE = '||text(stype)||''||
  coalesce(', FINALFUNC = '||text(finalfunc),'')||
  coalesce(', INITCOND = '||quote_literal(initcond),'')||
 E' );\n'
 )
 FROM dbms_metadata.pg_get_aggregates()
 WHERE namespace=$1;

 RETURN 
  dbms_metadata.ddl_header('functions',schema_name) ||
  coalesce(
   'SET check_function_bodies = false;' || E'\n\n' ||
   def_functions,'-- no functions') || E'\n' ||
  dbms_metadata.ddl_header('aggregates',schema_name) ||
  coalesce(def_aggregates,'-- no aggregates') || E'\n'
 ;

END;
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_schema_functions(name) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_schema_functions(name); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_schema_functions(name) IS 'dump functions for a whole schema';


--
-- Name: pg_ddl_schema_grants(name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_schema_grants(name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE 
 namespace ALIAS FOR $1; 
 def text; 
 
BEGIN 
 SELECT INTO def ' 
---------------------------------------------------------------- 
-- GRANTS ' || current_database() || '.' || namespace || ' 
-- generated by dbms_metadata on ' || current_time || ' 
---------------------------------------------------------------- 
 
' || 
 dbms_metadata.concat( 
  E'\nREVOKE ALL ON '||sql_identifier||E' FROM PUBLIC;\n' || ddl 
 ) 
 FROM ( 
  SELECT  
   dbms_metadata.ddl_grants(sysid) as ddl, 
   sql_identifier 
  FROM dbms_metadata.tables 
  WHERE "schema"=namespace 
--  WHERE type='table' 
  ORDER BY sysid 
 ) AS f; 
 
 RETURN def; 
END;$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_schema_grants(name) OWNER TO postgres;

--
-- Name: pg_ddl_schema_indexes(name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_schema_indexes(name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE
 namespace ALIAS FOR $1;
 def text;
BEGIN

 SELECT INTO def 
  dbms_metadata.concat(ddl)
 FROM (
  SELECT 
   dbms_metadata.ddl_indexes(sysid) as ddl
  FROM dbms_metadata.tables
  WHERE "schema"=namespace
  ORDER BY sysid
 ) AS f;

 RETURN dbms_metadata.wrap('
----------------------------------------------------------------
-- INDEXES ' || current_database() || '.' || namespace || '
-- generated by dbms_metadata on ' || current_time || '
----------------------------------------------------------------

',def,E'\n');
END;$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_schema_indexes(name) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_schema_indexes(name); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_schema_indexes(name) IS 'dump indexes for a whole schema';


--
-- Name: pg_ddl_schema_rules(name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_schema_rules(namespace name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE
 namespace ALIAS FOR $1;
 ddl text;

BEGIN

 SELECT INTO ddl
'----------------------------------------------------------------
-- RULES ' || current_database() || '.' || namespace || '
-- generated by dbms_metadata on ' || current_time || '
----------------------------------------------------------------

' ||
   coalesce(dbms_metadata.concat (rule_definition||E'\n'),'')
 FROM dbms_metadata.pg_get_rules()
 WHERE regclass IN ( 
     select c.oid
       from pg_class c
       join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = $1 and c.relkind = 'r')
 AND rule_definition IS NOT NULL;

 RETURN ddl;
END
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_schema_rules(namespace name) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_schema_rules(namespace name); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_schema_rules(namespace name) IS 'dump rules for a whole schema';


--
-- Name: pg_ddl_schema_tables(name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_schema_tables(name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$
DECLARE
 ddl2 text;
BEGIN
 select into ddl2
        dbms_metadata.concat(ddl1||E';\n')
   from (
     select dbms_metadata.pg_ddl_create_class(c.oid) as ddl1
       from pg_class c
       join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = $1
        and c.relkind = 'r'
      order by c.oid
   ) as d;
       
 return coalesce(ddl2||E'\n','');
END;$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_schema_tables(name) OWNER TO postgres;

--
-- Name: pg_ddl_schema_triggers(name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_schema_triggers(name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE
 namespace ALIAS FOR $1;
 def text;
BEGIN

 SELECT INTO def 
  dbms_metadata.concat(f.ddlt)
 FROM (
  select 
   dbms_metadata.pg_ddl_create_triggers(c.oid::regclass) as ddlt
   from pg_class c
   join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = $1 and c.relkind = 'r'
   order by c.oid
 ) AS f;

 RETURN '
----------------------------------------------------------------
-- TRIGGERS ' || current_database() || '.' || namespace || '
-- generated by dbms_metadata on ' || current_time || '
----------------------------------------------------------------

'||coalesce(def)||E'\n';
END;$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_schema_triggers(name) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_schema_triggers(name); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_schema_triggers(name) IS 'dump triggers for a whole schema';


--
-- Name: pg_ddl_schema_types(name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_schema_types(name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$DECLARE 
 ddl2 text; 
BEGIN 

select into ddl2
 dbms_metadata.concat(ddl1||E';\n')
  from (
    select dbms_metadata.pg_ddl_create_type(t.oid::regtype) as ddl1
      from pg_type t
      join pg_namespace n on n.oid=t.typnamespace
     where n.nspname=$1
     order by t.oid
   ) as d;
   
 return coalesce(ddl2||E'\n',''); 
END; 
$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_schema_types(name) OWNER TO postgres;

--
-- Name: FUNCTION pg_ddl_schema_types(name); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_ddl_schema_types(name) IS 'dump types for a whole schema';


--
-- Name: pg_ddl_schema_views(name); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_schema_views(name) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$
DECLARE
 ddl2 text;
BEGIN
 select into ddl2
        dbms_metadata.concat(ddl1||E';\n')
   from (
     select dbms_metadata.pg_ddl_create_class(c.oid) as ddl1
       from pg_class c
       join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = $1
        and c.relkind = 'v'
      order by c.oid
   ) as d;
       
 return coalesce(ddl2||E'\n','');
END;$_$;


ALTER FUNCTION dbms_metadata.pg_ddl_schema_views(name) OWNER TO postgres;

--
-- Name: pg_ddl_script(oid); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_script(my_class oid) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $$declare 
 script text; 
 res text; 
 oid1 oid;
begin 
 select oid from pg_class where oid=my_class into oid1;
 if found then
   select into script 
    (dbms_metadata.pg_ddl_create_class(my_class)|| 
     dbms_metadata.pg_ddl_alter_table_defaults(my_class)|| 
     dbms_metadata.pg_ddl_create_constraints(my_class)|| 
     dbms_metadata.pg_ddl_create_rules(my_class) || 
     dbms_metadata.pg_ddl_create_triggers(my_class) ||
     dbms_metadata.pg_ddl_create_indexes(my_class) ||
     dbms_metadata.pg_ddl_alter_owner(my_class) ||
     dbms_metadata.pg_ddl_grants_on_class(my_class)
    )::dbms_metadata.sql_statement; 
   return cast(script as dbms_metadata.sql_statement); 
 end if;

 select oid from pg_proc where oid=my_class into oid1;
 if found then
   select into script 
    (dbms_metadata.pg_ddl_create_function(my_class)
    )::dbms_metadata.sql_statement; 
   return cast(script as dbms_metadata.sql_statement); 
 end if;

 raise exception 'UNSUPPORTED OBJECT %',my_class;   
end 
$$;


ALTER FUNCTION dbms_metadata.pg_ddl_script(my_class oid) OWNER TO postgres;

--
-- Name: pg_ddl_script_depends(regclass, boolean); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_ddl_script_depends(my_class regclass, drops boolean) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $$declare 
 script text; 
 res text; 
begin 
 if drops then
   with d as (
   select *
     from dbms_metadata.pg_get_depends_recursive(my_class)
    order by level desc, sysid desc
   ) 
   select dbms_metadata.concat('DROP '||d.dep_type||' '||d.dep_name||E';\n')
     from d
     into script;
  else
   with d as (
   select *
     from dbms_metadata.pg_get_depends_recursive(my_class)
    order by level, sysid
   ) 
   select dbms_metadata.concat(dbms_metadata.pg_ddl_script(sysid::oid))
     from d
     into script;
  end if;
  return script;
end 
$$;


ALTER FUNCTION dbms_metadata.pg_ddl_script_depends(my_class regclass, drops boolean) OWNER TO postgres;

--
-- Name: pg_get_aggregates(); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_get_aggregates(OUT namespace text, OUT name text, OUT basetype regtype, OUT sfunc regprocedure, OUT stype regtype, OUT finalfunc regprocedure, OUT initcond text) RETURNS SETOF record
    LANGUAGE sql
    AS $$
 SELECT n.nspname::text AS namespace, p.proname::text AS name, 
 p.proargtypes[0]::regtype AS basetype, a.aggtransfn AS sfunc, a.aggtranstype::regtype AS stype, a.aggfinalfn AS finalfunc, a.agginitval AS initcond
   FROM pg_aggregate a
   JOIN pg_proc p ON a.aggfnoid::oid = p.oid
   JOIN pg_namespace n ON n.oid = p.pronamespace;
$$;


ALTER FUNCTION dbms_metadata.pg_get_aggregates(OUT namespace text, OUT name text, OUT basetype regtype, OUT sfunc regprocedure, OUT stype regtype, OUT finalfunc regprocedure, OUT initcond text) OWNER TO postgres;

--
-- Name: pg_get_columns(regclass); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_get_columns(regclass, OUT name name, OUT type text, OUT size integer, OUT not_null boolean, OUT "default" text, OUT comment text, OUT primary_key name, OUT is_local boolean, OUT attstorage text, OUT ord smallint, OUT namespace name, OUT class_name name, OUT sql_identifier sql_identifier, OUT nuls boolean, OUT "NullF" real, OUT "DistF" real, OUT "DistN" numeric, OUT regclass oid, OUT definition text) RETURNS SETOF record
    LANGUAGE sql
    AS $_$
 SELECT a.attname AS name, format_type(t.oid, NULL::integer) AS type, 
        CASE
            WHEN (a.atttypmod - 4) > 0 THEN a.atttypmod - 4
            ELSE NULL::integer
        END AS size, a.attnotnull AS not_null, def.adsrc AS "default", col_description(c.oid, a.attnum::integer) AS comment, 
        con.conname AS primary_key, 
        a.attislocal AS is_local, a.attstorage::text, a.attnum AS ord, s.nspname AS namespace, 
        c.relname AS class_name, 
        ((c.oid::regclass)::text || '.' || quote_ident(a.attname))::dbms_metadata.sql_identifier AS sql_identifier,
        CASE t.typname
            WHEN 'numeric'::name THEN false
            WHEN 'bool'::name THEN false
            ELSE true
        END AS nuls, 
         st.stanullfrac AS "NullF", 
        CASE
            WHEN st.stadistinct < 0::double precision THEN - st.stadistinct
            ELSE NULL::real
        END AS "DistF", 
        CASE
            WHEN st.stadistinct >= 0::double precision THEN st.stadistinct
            ELSE NULL::real
        END::numeric AS "DistN", 
        c.oid AS regclass, 
        (((quote_ident(a.attname::text) || ' '::text) || format_type(t.oid, NULL::integer)) || 
        CASE
            WHEN (a.atttypmod - 4) > 65536 THEN ((('('::text || (((a.atttypmod - 4) / 65536)::text)) || ','::text) || (((a.atttypmod - 4) % 65536)::text)) || ')'::text
            WHEN (a.atttypmod - 4) > 0 THEN ('('::text || ((a.atttypmod - 4)::text)) || ')'::text
            ELSE ''::text
        END) || 
        CASE
            WHEN a.attnotnull THEN ' NOT NULL'::text
            ELSE ''::text
        END AS definition
   FROM pg_class c
   JOIN pg_namespace s ON s.oid = c.relnamespace
   JOIN pg_attribute a ON c.oid = a.attrelid
   LEFT JOIN pg_attrdef def ON c.oid = def.adrelid AND a.attnum = def.adnum
   LEFT JOIN pg_constraint con ON con.conrelid = c.oid AND (a.attnum = ANY (con.conkey)) AND con.contype = 'p'::"char"
   LEFT JOIN pg_type t ON t.oid = a.atttypid
   JOIN pg_namespace tn ON tn.oid = t.typnamespace
   LEFT JOIN pg_statistic st ON st.starelid = c.oid AND st.staattnum = a.attnum
  WHERE (c.relkind = ANY (ARRAY['r'::"char", 'v'::"char", ''::"char", 'c'::"char"])) AND a.attnum > 0 AND NOT a.attisdropped AND has_table_privilege(c.oid, 'select'::text) AND has_schema_privilege(s.oid, 'usage'::text)
    AND c.oid = $1
  ORDER BY s.nspname, c.relname, a.attnum;
$_$;


ALTER FUNCTION dbms_metadata.pg_get_columns(regclass, OUT name name, OUT type text, OUT size integer, OUT not_null boolean, OUT "default" text, OUT comment text, OUT primary_key name, OUT is_local boolean, OUT attstorage text, OUT ord smallint, OUT namespace name, OUT class_name name, OUT sql_identifier sql_identifier, OUT nuls boolean, OUT "NullF" real, OUT "DistF" real, OUT "DistN" numeric, OUT regclass oid, OUT definition text) OWNER TO postgres;

--
-- Name: FUNCTION pg_get_columns(regclass, OUT name name, OUT type text, OUT size integer, OUT not_null boolean, OUT "default" text, OUT comment text, OUT primary_key name, OUT is_local boolean, OUT attstorage text, OUT ord smallint, OUT namespace name, OUT class_name name, OUT sql_identifier sql_identifier, OUT nuls boolean, OUT "NullF" real, OUT "DistF" real, OUT "DistN" numeric, OUT regclass oid, OUT definition text); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON FUNCTION pg_get_columns(regclass, OUT name name, OUT type text, OUT size integer, OUT not_null boolean, OUT "default" text, OUT comment text, OUT primary_key name, OUT is_local boolean, OUT attstorage text, OUT ord smallint, OUT namespace name, OUT class_name name, OUT sql_identifier sql_identifier, OUT nuls boolean, OUT "NullF" real, OUT "DistF" real, OUT "DistN" numeric, OUT regclass oid, OUT definition text) IS 'Table columns';


--
-- Name: pg_get_constraints(); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_get_constraints(OUT namespace name, OUT class_name name, OUT constraint_name name, OUT constraint_type text, OUT constraint_definition text, OUT is_deferrable boolean, OUT initially_deferred boolean, OUT regclass oid, OUT sysid oid) RETURNS SETOF record
    LANGUAGE sql
    AS $$
 SELECT nc.nspname AS namespace, 
        r.relname AS class_name, 
        c.conname AS constraint_name, 
        CASE c.contype
            WHEN 'c'::"char" THEN 'CHECK'::text
            WHEN 'f'::"char" THEN 'FOREIGN KEY'::text
            WHEN 'p'::"char" THEN 'PRIMARY KEY'::text
            WHEN 'u'::"char" THEN 'UNIQUE'::text
            ELSE NULL::text
        END AS constraint_type, pg_get_constraintdef(c.oid) AS constraint_definition, 
        c.condeferrable AS is_deferrable, 
        c.condeferred  AS initially_deferred, 
        r.oid as regclass, c.oid AS sysid
   FROM pg_namespace nc, pg_namespace nr, pg_constraint c, pg_class r
  WHERE nc.oid = c.connamespace AND nr.oid = r.relnamespace AND c.conrelid = r.oid;
$$;


ALTER FUNCTION dbms_metadata.pg_get_constraints(OUT namespace name, OUT class_name name, OUT constraint_name name, OUT constraint_type text, OUT constraint_definition text, OUT is_deferrable boolean, OUT initially_deferred boolean, OUT regclass oid, OUT sysid oid) OWNER TO postgres;

--
-- Name: pg_get_constraints(regclass); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_get_constraints(klass regclass, OUT namespace name, OUT class_name name, OUT constraint_name name, OUT constraint_type text, OUT constraint_definition text, OUT is_deferrable boolean, OUT initially_deferred boolean, OUT regclass oid, OUT sysid oid) RETURNS SETOF record
    LANGUAGE sql
    AS $_$
 SELECT nc.nspname AS namespace, 
        r.relname AS class_name, 
        c.conname AS constraint_name, 
        CASE c.contype
            WHEN 'c'::"char" THEN 'CHECK'::text
            WHEN 'f'::"char" THEN 'FOREIGN KEY'::text
            WHEN 'p'::"char" THEN 'PRIMARY KEY'::text
            WHEN 'u'::"char" THEN 'UNIQUE'::text
            ELSE NULL::text
        END AS constraint_type, pg_get_constraintdef(c.oid) AS constraint_definition, 
        c.condeferrable AS is_deferrable, 
        c.condeferred  AS initially_deferred, 
        r.oid as regclass, c.oid AS sysid
   FROM pg_namespace nc, pg_namespace nr, pg_constraint c, pg_class r
  WHERE r.oid = $1 AND nc.oid = c.connamespace AND nr.oid = r.relnamespace AND c.conrelid = r.oid;
$_$;


ALTER FUNCTION dbms_metadata.pg_get_constraints(klass regclass, OUT namespace name, OUT class_name name, OUT constraint_name name, OUT constraint_type text, OUT constraint_definition text, OUT is_deferrable boolean, OUT initially_deferred boolean, OUT regclass oid, OUT sysid oid) OWNER TO postgres;

--
-- Name: pg_get_depends(regclass); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_get_depends(myclass regclass, OUT level integer, OUT oid oid, OUT class_id regclass, OUT typ text, OUT sql_identifier text, OUT path text[], OUT deptype "char") RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
begin
  return query 
  with recursive dep as (
    select myclass::oid as oid,
           myclass::regclass as class_id,
           null::text as typ,
           myclass::regclass::text as sql_identifier,
           array[myclass::text] as path,
           0 as level,
           'pg_class'::regclass as classid,
           myclass as objid,
           0 as objsubid,
           ' '::"char" as deptype
    union all
    select coalesce(r.ev_class,pg_depend.objid) as oid,
           pg_depend.classid::regclass as class_id, 
           case pg_depend.classid::regclass
             when 'pg_rewrite'::regclass then 'VIEW'
             when 'pg_proc'::regclass then 'FUNCTION'
             else null
           end as typ,
           case pg_depend.classid::regclass
             when 'pg_rewrite'::regclass then r.ev_class::regclass::text
             when 'pg_proc'::regclass then pg_depend.objid::regprocedure::text
             else null
           end as typ,
           pg_describe_object(pg_depend.classid, pg_depend.objid, pg_depend.objsubid) || dep.path,
           dep.level+1,
           pg_depend.classid,
           coalesce(r.ev_class,pg_depend.objid) as objid,
           case 
             when r.ev_class is not null then 0
             else pg_depend.objsubid
           end as objsubid,
           case 
             when r.ev_class is not null then 'v'
             else pg_depend.deptype
           end as deptype
      from dep
      join pg_depend on ( dep.classid = pg_depend.refclassid
                     and dep.objid = pg_depend.refobjid
                     and (dep.objsubid = pg_depend.refobjsubid or dep.objsubid = 0))
      left join pg_rewrite r on (r.oid=pg_depend.objid and pg_depend.classid='pg_rewrite'::regclass)
  )
  select distinct
         dep.level,
         dep.oid,
         dep.class_id,
         dep.typ,
         dep.sql_identifier,
         dep.path,
         dep.deptype
  from dep
  where dep.level < 10
    and dep.deptype <> 'i'
  order by dep.level desc, dep.oid desc;
end
$$;


ALTER FUNCTION dbms_metadata.pg_get_depends(myclass regclass, OUT level integer, OUT oid oid, OUT class_id regclass, OUT typ text, OUT sql_identifier text, OUT path text[], OUT deptype "char") OWNER TO postgres;

--
-- Name: pg_get_depends0(regclass); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_get_depends0(myclass regclass, OUT level integer, OUT oid oid, OUT class_id regclass, OUT typ text, OUT sql_identifier text, OUT path text[], OUT deptype "char") RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
begin
  return query 
  with recursive dep as (
    select myclass::oid as oid,
           myclass::regclass as class_id,
           array[myclass::text] as path,
           0 as level,
           'pg_class'::regclass as classid,
           myclass as objid,
           0 as objsubid,
           ' '::"char" as deptype
    union all
    select coalesce(r.ev_class,pg_depend.objid) as oid,
           pg_depend.classid::regclass as class_id, 
           pg_describe_object(pg_depend.classid, pg_depend.objid, pg_depend.objsubid) || dep.path,
           dep.level+1,
           pg_depend.classid,
           pg_depend.objid,
           pg_depend.objsubid,
           pg_depend.deptype
      from dep
      join pg_depend on ( dep.classid = pg_depend.refclassid
                     and dep.objid = pg_depend.refobjid
                     and (dep.objsubid = pg_depend.refobjsubid or dep.objsubid = 0))
      left join pg_rewrite r on (r.oid=pg_depend.objid and pg_depend.classid='pg_rewrite'::regclass)
  )
  select distinct
         dep.level,
         dep.oid,
         dep.class_id,
         case dep.class_id
           when 'pg_rewrite'::regclass then 'VIEW'
           when 'pg_proc'::regclass then 'FUNCTION'
           else null
         end as typ,
         case dep.class_id
           when 'pg_rewrite'::regclass then dep.oid::regclass::text
           when 'pg_proc'::regclass then dep.oid::regprocedure::text
           else null
         end as sql_identifier,
         dep.path,
         dep.deptype
  from dep
  where dep.level < 10
    and dep.deptype <> 'i'
  order by dep.level desc, dep.oid desc;
end
$$;


ALTER FUNCTION dbms_metadata.pg_get_depends0(myclass regclass, OUT level integer, OUT oid oid, OUT class_id regclass, OUT typ text, OUT sql_identifier text, OUT path text[], OUT deptype "char") OWNER TO postgres;

--
-- Name: pg_get_depends_recursive(regclass); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_get_depends_recursive(myclass regclass, OUT level integer, OUT sysid oid, OUT dep_name text, OUT dep_table text, OUT dep_type text, OUT ref_names text[], OUT ref_types text[]) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
begin
return query
WITH RECURSIVE dep_recursive AS (

    -- Recursion: Initial Query
    SELECT
        0 AS "level",
        myclass::oid as sysid,
        myclass::text AS "dep_name",   --  <- define dependent object HERE
        '' AS "dep_table",
        '' AS "dep_type",
        '' AS "ref_name",
        '' AS "ref_type"

    UNION ALL

    -- Recursive Query
    SELECT
        dep_recursive.level + 1 AS "level",
        objid as sysid,
        depedencies.dep_name,
        depedencies.dep_table,
        depedencies.dep_type,
        depedencies.ref_name,
        depedencies.ref_type
    FROM (

        -- This function defines the type of any pg_class object
        WITH classType AS (
            SELECT
                pg_class.oid,
                CASE relkind
                    WHEN 'r' THEN 'TABLE'::text
                    WHEN 'i' THEN 'INDEX'::text
                    WHEN 'S' THEN 'SEQUENCE'::text
                    WHEN 'v' THEN 'VIEW'::text
                    WHEN 'c' THEN 'TYPE'::text      -- note: COMPOSITE type
                    WHEN 't' THEN 'TABLE'::text     -- note: TOAST table
                    WHEN 'm' THEN 'MATERIALIZED VIEW'::text
                END AS "type"
            FROM pg_class
        )

        -- Note: In pg_depend, the triple (classid,objid,objsubid) describes some object that depends
        -- on the object described by the tuple (refclassid,refobjid).
        -- So to drop the depending object, the referenced object (refclassid,refobjid) must be dropped first
        SELECT DISTINCT
            CASE classid
                WHEN 'pg_rewrite'::regclass THEN ( SELECT ev_class FROM pg_rewrite WHERE pg_rewrite.OID = objid)
                ELSE objid
            END AS objid,
            -- dep_name: Name of dependent object
            CASE classid
                WHEN 'pg_class'::regclass THEN objid::regclass::text
                WHEN 'pg_type'::regclass THEN objid::regtype::text
                WHEN 'pg_proc'::regclass THEN objid::regprocedure::text
                WHEN 'pg_constraint'::regclass THEN (SELECT conname FROM pg_constraint WHERE OID = objid)
                WHEN 'pg_attrdef'::regclass THEN 'default'
                WHEN 'pg_rewrite'::regclass THEN (SELECT ev_class::regclass::text FROM pg_rewrite WHERE OID = objid)
                WHEN 'pg_trigger'::regclass THEN (SELECT tgname FROM pg_trigger WHERE OID = objid)
                ELSE objid::text 
            END AS "dep_name",
            -- dep_table: Name of the table that is associated with the dependent object (for default values, triggers, rewrite rules)
            CASE classid
                WHEN 'pg_constraint'::regclass THEN (SELECT conrelid::regclass::text FROM pg_constraint WHERE OID = objid)
                WHEN 'pg_attrdef'::regclass THEN (SELECT adrelid::regclass::text FROM pg_attrdef WHERE OID = objid)
                WHEN 'pg_trigger'::regclass THEN (SELECT tgrelid::regclass::text FROM pg_trigger WHERE OID = objid)
                ELSE ''
            END AS "dep_table",
            -- dep_type: Type of the dependent object (TABLE, FUNCTION, VIEW, TYPE, TRIGGER, ...)
            CASE classid
                WHEN 'pg_class'::regclass THEN (SELECT TYPE FROM classType WHERE OID = objid)
                WHEN 'pg_type'::regclass THEN 'TYPE'
                WHEN 'pg_proc'::regclass THEN 'FUNCTION'
                WHEN 'pg_constraint'::regclass THEN 'TABLE CONSTRAINT'
                WHEN 'pg_attrdef'::regclass THEN 'TABLE DEFAULT'
                WHEN 'pg_rewrite'::regclass THEN (SELECT TYPE FROM classType WHERE OID = (SELECT ev_class FROM pg_rewrite WHERE OID = objid))
                WHEN 'pg_trigger'::regclass THEN 'TRIGGER'
                ELSE objid::text
            END AS "dep_type",
            -- ref_name: Name of referenced object (the object that depends on the dependent object)
            CASE refclassid
                WHEN 'pg_class'::regclass THEN refobjid::regclass::text
                WHEN 'pg_type'::regclass THEN refobjid::regtype::text
                WHEN 'pg_proc'::regclass THEN refobjid::regprocedure::text
                ELSE refobjid::text
            END AS "ref_name",
            -- ref_type: Type of the referenced object (TABLE, FUNCTION, VIEW, TYPE, TRIGGER, ...)
            CASE refclassid
                WHEN 'pg_class'::regclass THEN (SELECT TYPE FROM classType WHERE OID = refobjid)
                WHEN 'pg_type'::regclass THEN 'TYPE'
                WHEN 'pg_proc'::regclass THEN 'FUNCTION'
                ELSE refobjid::text
            END AS "ref_type",
            -- dependency type: Only 'normal' dependencies are relevant for DROP statements
            CASE deptype
                WHEN 'n' THEN 'normal'
                WHEN 'a' THEN 'automatic'
                WHEN 'i' THEN 'internal'
                WHEN 'e' THEN 'extension'
                WHEN 'p' THEN 'pinned'
            END AS "dependency type"
        FROM pg_catalog.pg_depend
        WHERE deptype = 'n'                 -- look at normal dependencies only
        AND refclassid NOT IN (2615, 2612)  -- schema and language are ignored as dependencies

    ) depedencies
    -- Recursion: Join with results of last query, search for dependencies recursively
    JOIN dep_recursive ON (dep_recursive.dep_name = depedencies.ref_name)
    WHERE depedencies.ref_name NOT IN(depedencies.dep_name, depedencies.dep_table) -- no self-references

)

-- Select and filter the results of the recursive query
SELECT
    MAX(d.level) AS "level",          -- drop highest level first, so no other objects depend on it
    d.sysid,
    d.dep_name,                       -- the object to drop
    MIN(d.dep_table) AS "dep_table",  -- the table that is associated with this object (constraints, triggers)
    MIN(d.dep_type) AS "dep_type",    -- the type of this object
    array_agg(d.ref_name) AS "ref_names",   -- list of objects that depend on this (just FYI)
    array_agg(d.ref_type) AS "ref_types"    -- list of their respective types (just FYI)
FROM dep_recursive d
WHERE d.level > 0                  -- ignore the initial object (level 0)
GROUP BY d.sysid,d.dep_name                -- ignore multiple references to dependent objects, dropping them once is enough
ORDER BY level desc, d.sysid desc;   -- level descending: deepest dependency first
end
$$;


ALTER FUNCTION dbms_metadata.pg_get_depends_recursive(myclass regclass, OUT level integer, OUT sysid oid, OUT dep_name text, OUT dep_table text, OUT dep_type text, OUT ref_names text[], OUT ref_types text[]) OWNER TO postgres;

--
-- Name: pg_get_functions(); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_get_functions(OUT sysid oid, OUT namespace name, OUT name name, OUT comment text, OUT owner name, OUT sql_identifier sql_identifier, OUT language name, OUT attributes text, OUT retset boolean, OUT is_trigger boolean, OUT returns text, OUT arguments text, OUT definition text, OUT security text, OUT is_strict text, OUT argtypes oidvector) RETURNS SETOF record
    LANGUAGE sql
    AS $$
 SELECT p.oid AS sysid, s.nspname AS namespace, p.proname AS name, pg_description.description AS comment, u.rolname AS owner,
  p.oid::regprocedure::dbms_metadata.sql_identifier AS sql_identifier, l.lanname AS language, 
        CASE p.provolatile
            WHEN 'i'::"char" THEN 'IMMUTABLE'::text
            WHEN 's'::"char" THEN 'STABLE'::text
            WHEN 'v'::"char" THEN 'VOLATILE'::text
            ELSE NULL::text
        END AS attributes, 
        p.proretset AS retset, 
        p.prorettype = 'trigger'::regtype::oid AS is_trigger, text(p.prorettype::regtype) AS returns, oidvectortypes(p.proargtypes) AS arguments, 
        p.prosrc AS definition, 
        CASE p.prosecdef
            WHEN true THEN 'DEFINER'::text
            ELSE 'INVOKER'::text
        END AS security, 
        case p.proisstrict 
            WHEN true THEN 'STRICT'::text
            ELSE NULL
        END AS is_strict, 
        p.proargtypes AS argtypes
   FROM pg_proc p
   LEFT JOIN pg_namespace s ON s.oid = p.pronamespace
   LEFT JOIN pg_language l ON l.oid = p.prolang
   LEFT JOIN pg_roles u ON p.proowner = u.oid
   LEFT JOIN pg_description ON p.oid = pg_description.objoid;
$$;


ALTER FUNCTION dbms_metadata.pg_get_functions(OUT sysid oid, OUT namespace name, OUT name name, OUT comment text, OUT owner name, OUT sql_identifier sql_identifier, OUT language name, OUT attributes text, OUT retset boolean, OUT is_trigger boolean, OUT returns text, OUT arguments text, OUT definition text, OUT security text, OUT is_strict text, OUT argtypes oidvector) OWNER TO postgres;

--
-- Name: pg_get_indexes(); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_get_indexes(OUT sysid oid, OUT namespace text, OUT class text, OUT name text, OUT tablespace text, OUT indexdef text, OUT constraint_name text) RETURNS SETOF record
    LANGUAGE sql
    AS $$
 SELECT c.oid AS sysid, n.nspname::text AS namespace, c.relname::text AS class, i.relname::text AS name, NULL::text AS tablespace, 
        CASE d.refclassid
            WHEN 'pg_constraint'::regclass THEN (((((('ALTER TABLE '::text || quote_ident(n.nspname::text)) || '.'::text) || quote_ident(c.relname::text)) || ' ADD CONSTRAINT '::text) || quote_ident(cc.conname::text)) || ' '::text) || pg_get_constraintdef(cc.oid)
            ELSE pg_get_indexdef(i.oid)
        END AS indexdef, cc.conname::text AS constraint_name
   FROM pg_index x
   JOIN pg_class c ON c.oid = x.indrelid
   JOIN pg_class i ON i.oid = x.indexrelid
   JOIN pg_depend d ON d.objid = x.indexrelid
   LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
   LEFT JOIN pg_constraint cc ON cc.oid = d.refobjid
  WHERE c.relkind = 'r'::"char" AND i.relkind = 'i'::"char"
  ORDER BY c.oid, n.nspname, c.relname, i.relname, NULL::text, 
CASE d.refclassid
    WHEN 'pg_constraint'::regclass THEN (((((('ALTER TABLE '::text || quote_ident(n.nspname::text)) || '.'::text) || quote_ident(c.relname::text)) || ' ADD CONSTRAINT '::text) || quote_ident(cc.conname::text)) || ' '::text) || pg_get_constraintdef(cc.oid)
    ELSE pg_get_indexdef(i.oid)
END, cc.conname
$$;


ALTER FUNCTION dbms_metadata.pg_get_indexes(OUT sysid oid, OUT namespace text, OUT class text, OUT name text, OUT tablespace text, OUT indexdef text, OUT constraint_name text) OWNER TO postgres;

--
-- Name: pg_get_rules(); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_get_rules(OUT namespace text, OUT class_name text, OUT rule_name text, OUT rule_event text, OUT is_instead boolean, OUT rule_definition text, OUT regclass regclass) RETURNS SETOF record
    LANGUAGE sql
    AS $$
 SELECT n.nspname::text AS namespace, c.relname::text AS class_name, r.rulename::text AS rule_name, 
        CASE
            WHEN r.ev_type = '1'::"char" THEN 'SELECT'::text
            WHEN r.ev_type = '2'::"char" THEN 'UPDATE'::text
            WHEN r.ev_type = '3'::"char" THEN 'INSERT'::text
            WHEN r.ev_type = '4'::"char" THEN 'DELETE'::text
            ELSE 'UNKNOWN'::text
        END AS rule_event, r.is_instead, pg_get_ruledef(r.oid, true) AS rule_definition, c.oid::regclass AS regclass
   FROM pg_rewrite r
   JOIN pg_class c ON c.oid = r.ev_class
   JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE NOT (r.ev_type = '1'::"char" AND r.rulename = '_RETURN'::name)
  ORDER BY r.oid
  $$;


ALTER FUNCTION dbms_metadata.pg_get_rules(OUT namespace text, OUT class_name text, OUT rule_name text, OUT rule_event text, OUT is_instead boolean, OUT rule_definition text, OUT regclass regclass) OWNER TO postgres;

--
-- Name: pg_get_rules(regclass); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_get_rules(klass regclass, OUT namespace text, OUT class_name text, OUT rule_name text, OUT rule_event text, OUT is_instead boolean, OUT rule_definition text, OUT regclass regclass) RETURNS SETOF record
    LANGUAGE sql
    AS $_$
 SELECT n.nspname::text AS namespace, c.relname::text AS class_name, r.rulename::text AS rule_name, 
        CASE
            WHEN r.ev_type = '1'::"char" THEN 'SELECT'::text
            WHEN r.ev_type = '2'::"char" THEN 'UPDATE'::text
            WHEN r.ev_type = '3'::"char" THEN 'INSERT'::text
            WHEN r.ev_type = '4'::"char" THEN 'DELETE'::text
            ELSE 'UNKNOWN'::text
        END AS rule_event, r.is_instead, pg_get_ruledef(r.oid, true) AS rule_definition, c.oid::regclass AS regclass
   FROM pg_rewrite r
   JOIN pg_class c ON c.oid = r.ev_class
   JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE c.oid = $1 AND 
    NOT (r.ev_type = '1'::"char" AND r.rulename = '_RETURN'::name)
  ORDER BY r.oid
  $_$;


ALTER FUNCTION dbms_metadata.pg_get_rules(klass regclass, OUT namespace text, OUT class_name text, OUT rule_name text, OUT rule_event text, OUT is_instead boolean, OUT rule_definition text, OUT regclass regclass) OWNER TO postgres;

--
-- Name: pg_get_triggers(); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_get_triggers(OUT is_constraint text, OUT trigger_name text, OUT action_order text, OUT event_manipulation text, OUT event_object_sql_identifier text, OUT action_statement text, OUT action_orientation text, OUT regclass regclass, OUT procid oid, OUT regprocedure regprocedure, OUT event_object_schema text, OUT event_object_table text, OUT trigger_key text) RETURNS SETOF record
    LANGUAGE sql
    AS $$
 SELECT 
        CASE t.tgisinternal
            WHEN true THEN 'CONSTRAINT'::text
            WHEN false THEN NULL::text
            ELSE NULL::text
        END AS is_constraint, t.tgname::text AS trigger_name, 
        CASE t.tgtype::integer & 2
            WHEN 2 THEN 'BEFORE'::text
            WHEN 0 THEN 'AFTER'::text
            ELSE NULL::text
        END AS action_order, 
        CASE (t.tgtype::integer / 4) & 7
            WHEN 1 THEN 'INSERT'::text
            WHEN 2 THEN 'DELETE'::text
            WHEN 3 THEN 'INSERT OR DELETE'::text
            WHEN 4 THEN 'UPDATE'::text
            WHEN 5 THEN 'INSERT OR UPDATE'::text
            WHEN 6 THEN 'UPDATE OR DELETE'::text
            WHEN 7 THEN 'INSERT OR UPDATE OR DELETE'::text
            ELSE NULL::text
        END AS event_manipulation, 
        c.oid::regclass::text AS event_object_sql_identifier, 
        p.oid::regprocedure::text AS action_statement, 
        CASE t.tgtype::integer & 1
            WHEN 1 THEN 'ROW'::text
            ELSE 'STATEMENT'::text
        END AS action_orientation, c.oid::regclass AS regclass, p.oid AS procid, p.oid::regprocedure AS regprocedure, s.nspname::text AS event_object_schema,
         c.relname::text AS event_object_table, (quote_ident(t.tgname::text) || ' ON '::text) || c.oid::regclass::text AS trigger_key
   FROM pg_trigger t
   LEFT JOIN pg_class c ON c.oid = t.tgrelid
   LEFT JOIN pg_namespace s ON s.oid = c.relnamespace
   LEFT JOIN pg_proc p ON p.oid = t.tgfoid
   LEFT JOIN pg_namespace s1 ON s1.oid = p.pronamespace
$$;


ALTER FUNCTION dbms_metadata.pg_get_triggers(OUT is_constraint text, OUT trigger_name text, OUT action_order text, OUT event_manipulation text, OUT event_object_sql_identifier text, OUT action_statement text, OUT action_orientation text, OUT regclass regclass, OUT procid oid, OUT regprocedure regprocedure, OUT event_object_schema text, OUT event_object_table text, OUT trigger_key text) OWNER TO postgres;

--
-- Name: pg_get_types(); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_get_types(OUT sql_identifier text, OUT type_type text, OUT owner text, OUT is_scalar boolean, OUT namespace text, OUT type_name text, OUT comment text) RETURNS SETOF record
    LANGUAGE sql
    AS $$
 select cast(t.oid::regtype as text) as sql_identifier,
        tt.column2 as type_type,
        cast(u.usename as text) AS owner, 
        CASE t.typtype
            WHEN 'c'::"char" THEN false
            WHEN 'd'::"char" THEN true
            WHEN 'b'::"char" THEN true
            WHEN 'e'::"char" THEN true
            ELSE NULL::boolean
        END AS is_scalar, 
        cast(s.nspname as text) as namespace, 
        cast(t.typname as text) as type_name, 
        pg_description.description AS comment
   FROM pg_type t
   LEFT JOIN pg_namespace s ON s.oid = t.typnamespace
   LEFT JOIN pg_user u ON t.typowner = u.usesysid
   LEFT JOIN pg_description ON t.oid = pg_description.objoid
   left join (
     values ('d','DOMAIN'),
            ('c','CLASS'),
            ('b','BASE'),
            ('e','ENUM')
   ) as tt on tt.column1=t.typtype    
  WHERE pg_description.description IS NOT NULL OR s.nspname !~~ 'pg_%'::text
  ORDER BY s.nspname, t.typname;
$$;


ALTER FUNCTION dbms_metadata.pg_get_types(OUT sql_identifier text, OUT type_type text, OUT owner text, OUT is_scalar boolean, OUT namespace text, OUT type_name text, OUT comment text) OWNER TO postgres;

--
-- Name: pg_nspname(regclass); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_nspname(regclass) RETURNS text
    LANGUAGE sql
    AS $_$select nspname::text
from pg_class c join pg_namespace n on (n.oid = c.relnamespace)
where c.oid=$1$_$;


ALTER FUNCTION dbms_metadata.pg_nspname(regclass) OWNER TO postgres;

--
-- Name: pg_relname(regclass); Type: FUNCTION; Schema: dbms_metadata; Owner: postgres
--

CREATE FUNCTION pg_relname(regclass) RETURNS text
    LANGUAGE sql
    AS $_$select relname::text
from pg_class
where oid=$1
$_$;


ALTER FUNCTION dbms_metadata.pg_relname(regclass) OWNER TO postgres;

--
-- Name: _pg_sv_array_accum(anyelement); Type: AGGREGATE; Schema: dbms_metadata; Owner: postgres
--

CREATE AGGREGATE _pg_sv_array_accum(anyelement) (
    SFUNC = array_append,
    STYPE = anyarray,
    INITCOND = '{}'
);


ALTER AGGREGATE dbms_metadata._pg_sv_array_accum(anyelement) OWNER TO postgres;

--
-- Name: concat(text); Type: AGGREGATE; Schema: dbms_metadata; Owner: postgres
--

CREATE AGGREGATE concat(text) (
    SFUNC = textcat,
    STYPE = text
);


ALTER AGGREGATE dbms_metadata.concat(text) OWNER TO postgres;

--
-- Name: AGGREGATE concat(text); Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON AGGREGATE concat(text) IS 'String concatenation aggregate';


--
-- Name: _pg_all_columns; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW _pg_all_columns AS
 SELECT n.nspname AS schema_name,
    c.relname AS relation_name,
    c.oid AS relation_oid,
    a.attname AS column_name,
    (a.attnum)::integer AS column_number,
    c.relkind,
    (NOT a.attnotnull) AS nullable,
    format_type(a.atttypid, a.atttypmod) AS declared_type,
    ad.adsrc AS default_value,
    col_description(c.oid, (a.attnum)::integer) AS comment
   FROM (((pg_class c
     JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
     JOIN pg_attribute a ON ((((a.attrelid = c.oid) AND (NOT a.attisdropped)) AND (a.attnum > 0))))
     LEFT JOIN pg_attrdef ad ON (((a.attrelid = ad.adrelid) AND (a.attnum = ad.adnum))))
  WHERE _pg_sv_table_accessible(n.oid, c.oid);


ALTER TABLE _pg_all_columns OWNER TO postgres;

--
-- Name: _pg_all_grant_raw; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW _pg_all_grant_raw AS
 SELECT o.object_type,
    o.object_oid,
    o.schema_oid,
    o.object_name,
    o.object_args,
    pg_get_userbyid(o.object_uid) AS owner,
    o.object_acl
   FROM ( SELECT pg_class.oid AS object_oid,
            pg_class.relnamespace AS schema_oid,
            pg_class.relowner AS object_uid,
            pg_class.relname AS object_name,
                CASE pg_class.relkind
                    WHEN 'r'::"char" THEN 'table'::name
                    WHEN 'v'::"char" THEN 'view'::name
                    WHEN 'S'::"char" THEN 'sequence'::name
                    ELSE NULL::name
                END AS object_type,
            NULL::text AS object_args,
            COALESCE(pg_class.relacl, _pg_sv_acl_rel_default((pg_get_userbyid(pg_class.relowner))::text)) AS object_acl
           FROM pg_class
          WHERE (pg_class.relkind = ANY (ARRAY['r'::"char", 'v'::"char", 'S'::"char"]))
        UNION ALL
         SELECT pg_proc.oid AS object_oid,
            pg_proc.pronamespace AS schema_oid,
            pg_proc.proowner AS object_uid,
            pg_proc.proname AS object_name,
            'function'::name AS object_type,
            oidvectortypes(pg_proc.proargtypes) AS object_args,
            COALESCE(pg_proc.proacl, _pg_sv_acl_func_default((pg_get_userbyid(pg_proc.proowner))::text)) AS object_acl
           FROM pg_proc
          WHERE (NOT pg_proc.proisagg)
        UNION ALL
         SELECT pg_namespace.oid AS object_oid,
            NULL::oid AS schema_oid,
            pg_namespace.nspowner AS object_uid,
            pg_namespace.nspname AS object_name,
            'schema'::name AS object_type,
            NULL::text AS object_args,
            COALESCE(pg_namespace.nspacl, _pg_sv_acl_schema_default((pg_get_userbyid(pg_namespace.nspowner))::text)) AS object_acl
           FROM pg_namespace
        UNION ALL
         SELECT pg_language.oid AS object_oid,
            NULL::oid AS schema_oid,
            1 AS object_uid,
            pg_language.lanname AS object_name,
            'language'::name AS object_type,
            NULL::text AS object_args,
            pg_language.lanacl AS object_acl
           FROM pg_language
        UNION ALL
         SELECT pg_database.oid AS object_oid,
            NULL::oid AS schema_oid,
            pg_database.datdba AS object_uid,
            pg_database.datname AS object_name,
            'database'::name AS object_type,
            NULL::text AS object_args,
            COALESCE(pg_database.datacl, _pg_sv_acl_db_default((pg_get_userbyid(pg_database.datdba))::text)) AS object_acl
           FROM pg_database
        UNION ALL
         SELECT pg_tablespace.oid AS object_oid,
            NULL::oid AS schema_oid,
            pg_tablespace.spcowner AS object_uid,
            pg_tablespace.spcname AS object_name,
            'tablespace'::name AS object_type,
            NULL::text AS object_args,
            COALESCE(pg_tablespace.spcacl, _pg_sv_acl_tablespace_default((pg_get_userbyid(pg_tablespace.spcowner))::text)) AS object_acl
           FROM pg_tablespace) o;


ALTER TABLE _pg_all_grant_raw OWNER TO postgres;

--
-- Name: _pg_all_grants_raw2; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW _pg_all_grants_raw2 AS
 SELECT o.object_type,
    o.object_oid,
    n.nspname AS schema_name,
    o.object_name,
    o.object_args,
    o.owner,
    _pg_sv_aclitem_grantor(o.object_acl[x1.i]) AS grantor,
    _pg_sv_aclitem_grantee(o.object_acl[x1.i]) AS grantee,
    _pg_sv_aclitem_grantee_is_group(o.object_acl[x1.i]) AS is_group,
    _pg_sv_aclitem_modestr(o.object_acl[x1.i]) AS mode
   FROM ((_pg_all_grant_raw o
     LEFT JOIN pg_namespace n ON ((n.oid = o.schema_oid)))
     JOIN _pg_sv_aclitem_all_index() x1(i) ON ((x1.i <= array_upper(o.object_acl, 1))));


ALTER TABLE _pg_all_grants_raw2 OWNER TO postgres;

--
-- Name: _pg_all_relation_column_type_raw; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW _pg_all_relation_column_type_raw AS
 SELECT n.nspname AS schema_name,
    c.relname AS relation_name,
    a.attname AS column_name,
    c.oid AS relation_oid,
    (a.attnum)::integer AS column_number,
    (c.relkind = 'v'::"char") AS is_view,
    (NOT a.attnotnull) AS nullable,
        CASE
            WHEN (t1.typtype = 'd'::"char") THEN tn1.nspname
            ELSE NULL::name
        END AS domain_schema,
        CASE
            WHEN (t1.typtype = 'd'::"char") THEN t1.typname
            ELSE NULL::name
        END AS domain_name,
    _pg_sv_type_name(t1.oid, t1.*) AS type_sqlname,
    _pg_sv_type_sql(t1.oid, t1.*, a.atttypmod) AS type_sqldef,
    tn2.nspname AS type_schema,
    t2.typname AS type_name,
    t2.oid AS type_oid,
    t2.typlen AS type_length,
    ((t2.typelem <> (0)::oid) AND (t2.typlen = (-1))) AS is_array,
        CASE
            WHEN (a.attndims > 0) THEN a.attndims
            ELSE t1.typndims
        END AS array_dimensions,
    _pg_sv_type_name(t3.oid, t3.*) AS element_sqlname,
    _pg_sv_type_sql(t3.oid, t3.*, _pg_sv_basetype_typmod(t1.oid, t1.*, a.atttypmod)) AS element_sqldef,
    tn3.nspname AS element_schema,
    t3.typname AS element_name,
    t3.oid AS element_oid,
    t3.typlen AS element_length,
    _pg_sv_basetype_oid(t2.oid, t2.*) AS basetype_oid,
    _pg_sv_basetype_typmod(t1.oid, t1.*, a.atttypmod) AS basetype_typmod
   FROM ((((((((pg_class c
     JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
     JOIN pg_attribute a ON ((((a.attrelid = c.oid) AND (NOT a.attisdropped)) AND (a.attnum > 0))))
     JOIN pg_type t1 ON ((t1.oid = a.atttypid)))
     JOIN pg_namespace tn1 ON ((tn1.oid = t1.typnamespace)))
     JOIN pg_type t2 ON ((t2.oid = _pg_sv_type_baseoid(t1.oid, t1.*))))
     JOIN pg_namespace tn2 ON ((tn2.oid = t2.typnamespace)))
     LEFT JOIN pg_type t3 ON ((t3.oid = t2.typelem)))
     LEFT JOIN pg_namespace tn3 ON ((tn3.oid = t3.typnamespace)))
  WHERE (_pg_sv_table_accessible(n.oid, c.oid) AND (c.relkind = ANY (ARRAY['r'::"char", 'v'::"char"])));


ALTER TABLE _pg_all_relation_column_type_raw OWNER TO postgres;

--
-- Name: _pg_all_rules_raw; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW _pg_all_rules_raw AS
 SELECT n.nspname AS schema_name,
    c.relname AS relation_name,
    r.rulename AS rule_name,
        CASE r.ev_type
            WHEN '1'::"char" THEN 'SELECT'::text
            WHEN '2'::"char" THEN 'UPDATE'::text
            WHEN '3'::"char" THEN 'INSERT'::text
            WHEN '4'::"char" THEN 'DELETE'::text
            ELSE 'UNKNOWN'::text
        END AS rule_event,
    r.is_instead,
    pg_get_ruledef(r.oid, true) AS def
   FROM ((pg_rewrite r
     JOIN pg_class c ON ((c.oid = r.ev_class)))
     JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE (_pg_sv_table_accessible(n.oid, c.oid) AND (NOT ((r.ev_type = '1'::"char") AND (r.rulename = '_RETURN'::name))));


ALTER TABLE _pg_all_rules_raw OWNER TO postgres;

--
-- Name: _pg_all_views_raw; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW _pg_all_views_raw AS
 SELECT n.nspname AS schema_name,
    c.relname AS view_name,
    bit_or((1 << (ascii((r.ev_type)::text) - ascii('0'::text)))) AS flags,
    c.oid AS view_oid,
    c.relowner AS uid
   FROM ((pg_class c
     JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
     JOIN pg_rewrite r ON (((r.ev_class = c.oid) AND r.is_instead)))
  WHERE (((c.relkind = 'v'::"char") AND c.relhasrules) AND _pg_sv_table_accessible(n.oid, c.oid))
  GROUP BY n.nspname, c.relname, c.oid, c.relowner;


ALTER TABLE _pg_all_views_raw OWNER TO postgres;

--
-- Name: _pg_function_raw; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW _pg_function_raw AS
 SELECT p.oid AS function_oid,
    n.oid AS function_schema_oid,
    n.nspname AS function_schema,
    p.proname AS function_name,
    p.proargtypes AS function_argument_oidvector,
    oidvectortypes(p.proargtypes) AS function_arguments
   FROM (pg_namespace n
     JOIN pg_proc p ON ((n.oid = p.pronamespace)));


ALTER TABLE _pg_function_raw OWNER TO postgres;

--
-- Name: _pg_type_raw; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW _pg_type_raw AS
 SELECT t.oid AS type_oid,
    n.oid AS type_schema_oid,
    n.nspname AS type_schema,
    t.typname AS type_name
   FROM (pg_namespace n
     JOIN pg_type t ON ((n.oid = t.typnamespace)));


ALTER TABLE _pg_type_raw OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: changelog; Type: TABLE; Schema: dbms_metadata; Owner: postgres; Tablespace: 
--

CREATE TABLE changelog (
    "time" timestamp with time zone DEFAULT now() NOT NULL,
    username text DEFAULT "current_user"() NOT NULL,
    message text
);


ALTER TABLE changelog OWNER TO postgres;

--
-- Name: pg_acl_modes; Type: TABLE; Schema: dbms_metadata; Owner: postgres; Tablespace: 
--

CREATE TABLE pg_acl_modes (
    object_type text NOT NULL,
    mode text NOT NULL,
    granted text,
    description text
);


ALTER TABLE pg_acl_modes OWNER TO postgres;

--
-- Name: pg_all_aggregates; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_aggregates AS
 SELECT n.nspname AS schema_name,
    f.proname AS aggregate_name,
    it.type_schema AS input_type_schema,
    it.type_name AS input_type,
    ot.type_schema AS output_type_schema,
    ot.type_name AS output_type,
    a.agginitval AS initial_value,
    tf.function_schema AS trans_function_schema,
    tf.function_name AS trans_function_name,
    ff.function_schema AS final_function_schema,
    ff.function_name AS final_function_name,
    _pg_sv_system_schema(n.nspname) AS is_system_aggregate,
    pg_get_userbyid(f.proowner) AS owner
   FROM ((((((pg_aggregate a
     JOIN pg_proc f ON ((f.oid = (a.aggfnoid)::oid)))
     JOIN pg_namespace n ON ((n.oid = f.pronamespace)))
     JOIN _pg_type_raw it ON ((it.type_oid = f.proargtypes[0])))
     JOIN _pg_type_raw ot ON ((ot.type_oid = f.prorettype)))
     JOIN _pg_function_raw tf ON ((tf.function_oid = (a.aggtransfn)::oid)))
     LEFT JOIN _pg_function_raw ff ON ((((ff.function_oid)::regproc)::oid = (a.aggfinalfn)::oid)))
  WHERE _pg_sv_function_accessible(n.oid, f.oid);


ALTER TABLE pg_all_aggregates OWNER TO postgres;

--
-- Name: pg_all_basetype_details; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_basetype_details AS
 SELECT n.nspname AS schema_name,
    t.typname AS type_name,
    t.oid AS type_oid,
    pg_get_userbyid(t.typowner) AS owner,
    t.typlen AS type_length,
    ( SELECT
                CASE
                    WHEN (t.typtype = 'b'::"char") THEN 'base'::text
                    ELSE ( SELECT
                            CASE
                                WHEN (t.typtype = 'd'::"char") THEN 'domain'::text
                                ELSE NULL::text
                            END AS "case")
                END AS "case") AS type_type,
    t.typbyval AS passed_by_value,
    ( SELECT
                CASE
                    WHEN (t.typalign = 'c'::"char") THEN 'char'::text
                    ELSE ( SELECT
                            CASE
                                WHEN (t.typalign = 's'::"char") THEN 'short'::text
                                ELSE ( SELECT
CASE
 WHEN (t.typalign = 'i'::"char") THEN 'integer'::text
 ELSE ( SELECT
   CASE
    WHEN (t.typalign = 'd'::"char") THEN 'double'::text
    ELSE 'oops'::text
   END AS "case")
END AS "case")
                            END AS "case")
                END AS "case") AS type_alignment,
    ( SELECT
                CASE
                    WHEN (t.typstorage = 'p'::"char") THEN 'plain'::text
                    ELSE ( SELECT
                            CASE
                                WHEN (t.typstorage = 'x'::"char") THEN 'externally toastable'::text
                                ELSE ( SELECT
CASE
 WHEN (t.typstorage = 'm'::"char") THEN 'in-line compressable'::text
 ELSE ( SELECT
   CASE
    WHEN (t.typstorage = 'e'::"char") THEN 'in-line or external toastable'::text
    ELSE 'oops'::text
   END AS "case")
END AS "case")
                            END AS "case")
                END AS "case") AS type_storage,
    _pg_sv_system_schema(n.nspname) AS is_builtin,
    t.typinput AS input_function,
    t.typoutput AS output_function,
    t.typsend AS send_function,
    t.typreceive AS receive_function,
    t.typanalyze AS analyze_function,
    obj_description(t.oid, 'pg_type'::name) AS comment
   FROM (pg_type t
     JOIN pg_namespace n ON ((t.typnamespace = n.oid)))
  WHERE ((t.typtype = 'b'::"char") OR (t.typtype = 'd'::"char"));


ALTER TABLE pg_all_basetype_details OWNER TO postgres;

--
-- Name: pg_all_types; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_types AS
 SELECT n.nspname AS schema_name,
    t.typname AS type_name,
    t.oid AS type_oid,
    pg_get_userbyid(t.typowner) AS owner,
    t.typlen AS type_length,
    ( SELECT
                CASE
                    WHEN (t.typtype = 'b'::"char") THEN 'BASE'::text
                    ELSE ( SELECT
                            CASE
                                WHEN (t.typtype = 'c'::"char") THEN 'COMPOSITE'::text
                                ELSE ( SELECT
CASE
 WHEN (t.typtype = 'd'::"char") THEN 'DOMAIN'::text
 ELSE ( SELECT
   CASE
    WHEN (t.typtype = 'p'::"char") THEN 'PSEUDO'::text
    ELSE 'OOPS'::text
   END AS "case")
END AS "case")
                            END AS "case")
                END AS "case") AS type_type,
    _pg_sv_system_schema(n.nspname) AS is_builtin,
    obj_description(t.oid, 'pg_type'::name) AS comment
   FROM ((pg_type t
     JOIN pg_namespace n ON ((t.typnamespace = n.oid)))
     LEFT JOIN pg_class c ON ((t.typrelid = c.oid)))
  WHERE (((c.oid IS NULL) OR (c.relkind = 'c'::"char")) AND (substr((t.typname)::text, 1, 1) <> '_'::text));


ALTER TABLE pg_all_types OWNER TO postgres;

--
-- Name: pg_all_basetypes; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_basetypes AS
 SELECT t.schema_name,
    t.type_name,
    t.type_oid,
    t.owner,
    t.type_length,
    t.type_type,
    t.is_builtin,
    t.comment
   FROM pg_all_types t
  WHERE ((t.type_type = 'base'::text) OR (t.type_type = 'domain'::text));


ALTER TABLE pg_all_basetypes OWNER TO postgres;

--
-- Name: pg_all_casts; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_casts AS
 SELECT s.type_schema AS source_schema,
    s.type_name AS source_type,
    t.type_schema AS target_schema,
    t.type_name AS target_type,
    f.function_schema,
    f.function_name,
    f.function_arguments,
        CASE c.castcontext
            WHEN 'e'::"char" THEN 'explicit'::text
            WHEN 'a'::"char" THEN 'assignment'::text
            WHEN 'i'::"char" THEN 'implicit'::text
            ELSE 'Woah! Invalid value! Call the doctor!'::text
        END AS context,
    ((_pg_sv_system_schema(s.type_schema) AND _pg_sv_system_schema(t.type_schema)) AND _pg_sv_system_schema(f.function_schema)) AS is_system_cast
   FROM (((pg_cast c
     JOIN _pg_type_raw s ON ((s.type_oid = c.castsource)))
     JOIN _pg_type_raw t ON ((t.type_oid = c.casttarget)))
     LEFT JOIN _pg_function_raw f ON ((f.function_oid = c.castfunc)));


ALTER TABLE pg_all_casts OWNER TO postgres;

--
-- Name: pg_all_composite_type_columns; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_composite_type_columns AS
 SELECT c.schema_name,
    t.typname AS type_name,
    t.oid AS type_oid,
    c.column_name,
    c.column_number,
    c.nullable,
    c.declared_type,
    c.default_value,
    _pg_sv_system_schema(c.schema_name) AS is_builtin,
    obj_description(t.oid, 'pg_type'::name) AS comment
   FROM (pg_type t
     JOIN _pg_all_columns c ON (((t.typrelid = c.relation_oid) AND (c.relkind = 'c'::"char"))))
  WHERE (t.typtype = 'c'::"char");


ALTER TABLE pg_all_composite_type_columns OWNER TO postgres;

--
-- Name: pg_all_composite_types; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_composite_types AS
 SELECT n.nspname AS schema_name,
    t.typname AS type_name,
    t.oid AS type_oid,
    pg_get_userbyid(t.typowner) AS owner,
    _pg_sv_system_schema(n.nspname) AS is_builtin,
    obj_description(t.oid, 'pg_type'::name) AS comment
   FROM ((pg_type t
     JOIN pg_namespace n ON ((t.typnamespace = n.oid)))
     JOIN pg_class c ON (((t.typrelid = c.oid) AND (c.relkind = 'c'::"char"))))
  WHERE (t.typtype = 'c'::"char");


ALTER TABLE pg_all_composite_types OWNER TO postgres;

--
-- Name: pg_all_conversions; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_conversions AS
 SELECT n.nspname AS schema_name,
    c.conname AS conversion_name,
    pg_encoding_to_char(c.conforencoding) AS source_encoding,
    pg_encoding_to_char(c.contoencoding) AS destination_encoding,
    c.condefault AS is_default,
    f.function_schema,
    f.function_name,
    _pg_sv_system_schema(n.nspname) AS is_system_conversion,
    pg_get_userbyid(c.conowner) AS owner
   FROM ((pg_conversion c
     JOIN pg_namespace n ON ((n.oid = c.connamespace)))
     JOIN _pg_function_raw f ON ((f.function_oid = (c.conproc)::oid)))
  WHERE _pg_sv_schema_accessible(n.oid);


ALTER TABLE pg_all_conversions OWNER TO postgres;

--
-- Name: pg_all_domains; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_domains AS
 SELECT n.nspname AS schema_name,
    t.typname AS domain_name,
    t.oid AS domain_oid,
    pg_get_userbyid(t.typowner) AS owner,
    t2.typname AS base_type,
    t.typlen AS domain_length,
    t.typdefault AS domain_default,
    c.conname AS constraint_name,
    c.consrc AS check_constraint,
    _pg_sv_system_schema(n.nspname) AS is_builtin,
    obj_description(t.oid, 'pg_type'::name) AS comment
   FROM ((((pg_type t
     JOIN pg_namespace n ON ((t.typnamespace = n.oid)))
     JOIN pg_type t2 ON ((t.typbasetype = t2.oid)))
     JOIN pg_namespace n2 ON ((t2.typnamespace = n2.oid)))
     LEFT JOIN pg_constraint c ON ((t.oid = c.contypid)))
  WHERE (t.typtype = 'd'::"char");


ALTER TABLE pg_all_domains OWNER TO postgres;

--
-- Name: pg_all_foreign_key_columns; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_foreign_key_columns AS
 SELECT n1.nspname AS foreign_key_schema_name,
    c1.relname AS foreign_key_table_name,
    k1.conname AS foreign_key_constraint_name,
    c1.oid AS foreign_key_table_oid,
    a1.attname AS foreign_key_column,
    s.i AS column_position,
    n2.nspname AS key_schema_name,
    c2.relname AS key_table_name,
    c2.oid AS key_table_oid,
    a2.attname AS key_column
   FROM (((((((pg_constraint k1
     JOIN pg_namespace n1 ON ((n1.oid = k1.connamespace)))
     JOIN pg_class c1 ON ((c1.oid = k1.conrelid)))
     JOIN pg_class c2 ON ((c2.oid = k1.confrelid)))
     JOIN pg_namespace n2 ON ((n2.oid = c2.relnamespace)))
     JOIN _pg_sv_keypositions() s(i) ON ((s.i <= array_upper(k1.conkey, 1))))
     JOIN pg_attribute a1 ON (((a1.attrelid = c1.oid) AND (a1.attnum = k1.conkey[s.i]))))
     JOIN pg_attribute a2 ON (((a2.attrelid = c2.oid) AND (a2.attnum = k1.confkey[s.i]))))
  WHERE ((((k1.conrelid <> (0)::oid) AND (k1.confrelid <> (0)::oid)) AND (k1.contype = 'f'::"char")) AND _pg_sv_table_accessible(n1.oid, c1.oid));


ALTER TABLE pg_all_foreign_key_columns OWNER TO postgres;

--
-- Name: pg_all_foreign_key_indexes; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_foreign_key_indexes AS
 SELECT n.nspname AS schema_name,
    c.relname AS table_name,
    k.conname AS constraint_name,
    array_upper(_pg_sv_array_uniq(k.conkey), 1) AS num_columns,
    COALESCE(_pg_sv_index_prefix_count(k.conkey, x.indkey, ARRAY[x.indkey[0]], 1, (x.indnatts)::integer), 0) AS num_indexed_columns,
    ci.relname AS index_name
   FROM ((((pg_constraint k
     JOIN pg_namespace n ON ((n.oid = k.connamespace)))
     JOIN pg_class c ON ((c.oid = k.conrelid)))
     LEFT JOIN pg_index x ON ((((x.indrelid = c.oid) AND (x.indkey[0] = ANY (k.conkey))) AND (x.indpred IS NULL))))
     LEFT JOIN pg_class ci ON ((ci.oid = x.indexrelid)))
  WHERE (((((k.conrelid <> (0)::oid) AND (k.confrelid <> (0)::oid)) AND (k.contype = 'f'::"char")) AND ((ci.relam IS NULL) OR (ci.relam = ( SELECT pg_am.oid
           FROM pg_am
          WHERE (pg_am.amname = 'btree'::name))))) AND _pg_sv_table_accessible(n.oid, c.oid));


ALTER TABLE pg_all_foreign_key_indexes OWNER TO postgres;

--
-- Name: pg_all_foreign_keys; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_foreign_keys AS
 SELECT n1.nspname AS foreign_key_schema_name,
    c1.relname AS foreign_key_table_name,
    k1.conname AS foreign_key_constraint_name,
    c1.oid AS foreign_key_table_oid,
    _pg_sv_column_array(k1.conrelid, k1.conkey) AS foreign_key_columns,
    n2.nspname AS key_schema_name,
    c2.relname AS key_table_name,
    k2.conname AS key_constraint_name,
    c2.oid AS key_table_oid,
    ci.relname AS key_index_name,
    _pg_sv_column_array(k1.confrelid, k1.confkey) AS key_columns,
        CASE k1.confmatchtype
            WHEN 'f'::"char" THEN 'FULL'::text
            WHEN 'p'::"char" THEN 'PARTIAL'::text
            WHEN 'u'::"char" THEN 'NONE'::text
            ELSE NULL::text
        END AS match_type,
        CASE k1.confdeltype
            WHEN 'a'::"char" THEN 'NO ACTION'::text
            WHEN 'c'::"char" THEN 'CASCADE'::text
            WHEN 'd'::"char" THEN 'SET DEFAULT'::text
            WHEN 'n'::"char" THEN 'SET NULL'::text
            WHEN 'r'::"char" THEN 'RESTRICT'::text
            ELSE NULL::text
        END AS on_delete,
        CASE k1.confupdtype
            WHEN 'a'::"char" THEN 'NO ACTION'::text
            WHEN 'c'::"char" THEN 'CASCADE'::text
            WHEN 'd'::"char" THEN 'SET DEFAULT'::text
            WHEN 'n'::"char" THEN 'SET NULL'::text
            WHEN 'r'::"char" THEN 'RESTRICT'::text
            ELSE NULL::text
        END AS on_update,
    k1.condeferrable AS is_deferrable,
    k1.condeferred AS is_deferred
   FROM ((((((((pg_constraint k1
     JOIN pg_namespace n1 ON ((n1.oid = k1.connamespace)))
     JOIN pg_class c1 ON ((c1.oid = k1.conrelid)))
     JOIN pg_class c2 ON ((c2.oid = k1.confrelid)))
     JOIN pg_namespace n2 ON ((n2.oid = c2.relnamespace)))
     JOIN pg_depend d ON (((((((d.classid = ('pg_constraint'::regclass)::oid) AND (d.objid = k1.oid)) AND (d.objsubid = 0)) AND (d.deptype = 'n'::"char")) AND (d.refclassid = ('pg_class'::regclass)::oid)) AND (d.refobjsubid = 0))))
     JOIN pg_class ci ON (((ci.oid = d.refobjid) AND (ci.relkind = 'i'::"char"))))
     LEFT JOIN pg_depend d2 ON (((((((d2.classid = ('pg_class'::regclass)::oid) AND (d2.objid = ci.oid)) AND (d2.objsubid = 0)) AND (d2.deptype = 'i'::"char")) AND (d2.refclassid = ('pg_constraint'::regclass)::oid)) AND (d2.refobjsubid = 0))))
     LEFT JOIN pg_constraint k2 ON (((k2.oid = d2.refobjid) AND (k2.contype = ANY (ARRAY['p'::"char", 'u'::"char"])))))
  WHERE ((((k1.conrelid <> (0)::oid) AND (k1.confrelid <> (0)::oid)) AND (k1.contype = 'f'::"char")) AND _pg_sv_table_accessible(n1.oid, c1.oid));


ALTER TABLE pg_all_foreign_keys OWNER TO postgres;

--
-- Name: pg_all_grants; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_grants AS
 SELECT pgr.object_type,
    pgr.object_oid,
    pgr.schema_name,
    pgr.object_name,
    pgr.object_args,
    pgr.owner,
    pgr.grantor,
    pgr.grantee,
    pgr.is_group,
    pam.granted AS privilege,
    (pgr.mode ~~ (('%'::text || pam.mode) || '*%'::text)) AS grant_option
   FROM (_pg_all_grants_raw2 pgr
     JOIN pg_acl_modes pam ON (((pgr.mode ~~ (('%'::text || pam.mode) || '%'::text)) AND ((pgr.object_type)::text = pam.object_type))))
  WHERE (((((( SELECT pg_user.usesuper
           FROM pg_user
          WHERE (pg_user.usename = "current_user"())) OR (pgr.grantor = ("current_user"())::text)) OR (pgr.grantee = ("current_user"())::text)) OR (pgr.is_group AND (pgr.grantee = 'public'::text))) OR (pgr.is_group AND (pgr.grantee IN ( SELECT pg_group.groname
           FROM pg_group
          WHERE (( SELECT pg_user.usesysid
                   FROM pg_user
                  WHERE (pg_user.usename = "current_user"())) = ANY (pg_group.grolist)))))) OR (pgr.owner = "current_user"()));


ALTER TABLE pg_all_grants OWNER TO postgres;

--
-- Name: pg_all_index_columns; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_index_columns AS
 SELECT n.nspname AS schema_name,
    ct.relname AS table_name,
    ci.relname AS index_name,
    a.attname AS column_name,
    s.i AS column_position,
    n2.nspname AS opclass_schema,
    o.opcname AS opclass_name,
    pg_get_indexdef(ci.oid, s.i, true) AS definition
   FROM (((((((pg_index x
     JOIN pg_class ct ON ((ct.oid = x.indrelid)))
     JOIN pg_class ci ON ((ci.oid = x.indexrelid)))
     JOIN pg_namespace n ON ((n.oid = ct.relnamespace)))
     JOIN _pg_sv_keypositions() s(i) ON ((s.i <= x.indnatts)))
     JOIN pg_opclass o ON ((o.oid = x.indclass[(s.i - 1)])))
     JOIN pg_namespace n2 ON ((n2.oid = o.opcnamespace)))
     LEFT JOIN pg_attribute a ON (((a.attrelid = ct.oid) AND (a.attnum = x.indkey[(s.i - 1)]))))
  WHERE ((_pg_sv_table_accessible(n.oid, ct.oid) AND (ct.relkind = 'r'::"char")) AND (ci.relkind = 'i'::"char"));


ALTER TABLE pg_all_index_columns OWNER TO postgres;

--
-- Name: pg_all_indexes; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_indexes AS
 SELECT n.nspname AS schema_name,
    ct.relname AS table_name,
    ci.relname AS index_name,
    t.spcname AS tablespace,
    am.amname AS index_method,
    x.indnatts AS num_columns,
    x.indisprimary AS is_primary_key,
    x.indisunique AS is_unique,
    x.indisclustered AS is_clustered,
    (x.indexprs IS NOT NULL) AS is_expression,
    (x.indpred IS NOT NULL) AS is_partial,
    ci.reltuples AS estimated_rows,
    (_pg_sv_pages_to_mb((ci.relpages)::numeric))::numeric(12,1) AS estimated_mb,
    _pg_sv_system_schema(n.nspname) AS is_system_table,
    ct.oid AS table_oid,
    pg_get_expr(x.indpred, ct.oid, true) AS predicate,
    pg_get_indexdef(ci.oid) AS definition,
    pg_get_userbyid(ci.relowner) AS owner,
    obj_description(ci.oid, 'pg_class'::name) AS comment
   FROM (((((pg_index x
     JOIN pg_class ct ON ((ct.oid = x.indrelid)))
     JOIN pg_class ci ON ((ci.oid = x.indexrelid)))
     JOIN pg_namespace n ON ((n.oid = ct.relnamespace)))
     JOIN pg_am am ON ((am.oid = ci.relam)))
     LEFT JOIN pg_tablespace t ON (_pg_sv_tablespace_match(ci.*, t.oid)))
  WHERE ((_pg_sv_table_accessible(n.oid, ct.oid) AND (ct.relkind = 'r'::"char")) AND (ci.relkind = 'i'::"char"));


ALTER TABLE pg_all_indexes OWNER TO postgres;

--
-- Name: pg_all_unique_constraint_columns; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_unique_constraint_columns AS
 SELECT n.nspname AS schema_name,
    c.relname AS table_name,
    con.conname AS constraint_name,
    (con.contype = 'p'::"char") AS is_primary_key,
    a.attname AS column_name,
    s.i AS column_position,
    c.oid AS table_oid
   FROM ((((pg_constraint con
     JOIN pg_namespace n ON ((n.oid = con.connamespace)))
     JOIN pg_class c ON ((c.oid = con.conrelid)))
     JOIN _pg_sv_keypositions() s(i) ON ((s.i <= array_upper(con.conkey, 1))))
     JOIN pg_attribute a ON (((a.attrelid = c.oid) AND (a.attnum = con.conkey[s.i]))))
  WHERE (((con.conrelid <> (0)::oid) AND (con.contype = ANY (ARRAY['p'::"char", 'u'::"char"]))) AND _pg_sv_table_accessible(n.oid, c.oid));


ALTER TABLE pg_all_unique_constraint_columns OWNER TO postgres;

--
-- Name: pg_all_primary_key_columns; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_primary_key_columns AS
 SELECT pg_all_unique_constraint_columns.schema_name,
    pg_all_unique_constraint_columns.table_name,
    pg_all_unique_constraint_columns.constraint_name,
    pg_all_unique_constraint_columns.column_name,
    pg_all_unique_constraint_columns.column_position,
    pg_all_unique_constraint_columns.table_oid
   FROM pg_all_unique_constraint_columns
  WHERE pg_all_unique_constraint_columns.is_primary_key;


ALTER TABLE pg_all_primary_key_columns OWNER TO postgres;

--
-- Name: pg_all_relation_column_type_info; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_relation_column_type_info AS
 SELECT _pg_all_relation_column_type_raw.schema_name,
    _pg_all_relation_column_type_raw.relation_name,
    _pg_all_relation_column_type_raw.column_name,
    _pg_all_relation_column_type_raw.relation_oid,
    _pg_all_relation_column_type_raw.column_number,
    _pg_all_relation_column_type_raw.is_view,
    _pg_all_relation_column_type_raw.nullable,
    _pg_all_relation_column_type_raw.domain_schema,
    _pg_all_relation_column_type_raw.domain_name,
    _pg_all_relation_column_type_raw.type_sqlname,
    _pg_all_relation_column_type_raw.type_sqldef,
    _pg_all_relation_column_type_raw.type_schema,
    _pg_all_relation_column_type_raw.type_name,
    _pg_all_relation_column_type_raw.type_oid,
    _pg_all_relation_column_type_raw.type_length,
    _pg_all_relation_column_type_raw.is_array,
    _pg_all_relation_column_type_raw.array_dimensions,
    _pg_all_relation_column_type_raw.element_sqlname,
    _pg_all_relation_column_type_raw.element_sqldef,
    _pg_all_relation_column_type_raw.element_schema,
    _pg_all_relation_column_type_raw.element_name,
    _pg_all_relation_column_type_raw.element_oid,
    _pg_all_relation_column_type_raw.element_length,
    _pg_sv_type_char_length(_pg_all_relation_column_type_raw.basetype_oid, _pg_all_relation_column_type_raw.basetype_typmod) AS character_length,
    _pg_sv_type_bit_length(_pg_all_relation_column_type_raw.basetype_oid, _pg_all_relation_column_type_raw.basetype_typmod) AS bit_length,
    _pg_sv_type_integer_precision(_pg_all_relation_column_type_raw.basetype_oid, _pg_all_relation_column_type_raw.basetype_typmod) AS integer_precision,
    _pg_sv_type_float_precision(_pg_all_relation_column_type_raw.basetype_oid, _pg_all_relation_column_type_raw.basetype_typmod) AS float_precision,
    _pg_sv_type_numeric_precision(_pg_all_relation_column_type_raw.basetype_oid, _pg_all_relation_column_type_raw.basetype_typmod) AS numeric_precision,
    _pg_sv_type_numeric_scale(_pg_all_relation_column_type_raw.basetype_oid, _pg_all_relation_column_type_raw.basetype_typmod) AS numeric_scale,
    _pg_sv_type_time_precision(_pg_all_relation_column_type_raw.basetype_oid, _pg_all_relation_column_type_raw.basetype_typmod) AS time_precision,
    _pg_sv_type_interval_precision(_pg_all_relation_column_type_raw.basetype_oid, _pg_all_relation_column_type_raw.basetype_typmod) AS interval_precision,
    _pg_sv_type_interval_fields(_pg_all_relation_column_type_raw.basetype_oid, _pg_all_relation_column_type_raw.basetype_typmod) AS interval_fields
   FROM _pg_all_relation_column_type_raw;


ALTER TABLE pg_all_relation_column_type_info OWNER TO postgres;

--
-- Name: pg_all_relation_columns; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_relation_columns AS
 SELECT _pg_all_columns.schema_name,
    _pg_all_columns.relation_name,
    _pg_all_columns.relation_oid,
    _pg_all_columns.column_name,
    _pg_all_columns.column_number,
    (_pg_all_columns.relkind = 'v'::"char") AS is_view,
    _pg_all_columns.nullable,
    _pg_all_columns.declared_type,
    _pg_all_columns.default_value,
    _pg_all_columns.comment
   FROM _pg_all_columns
  WHERE (_pg_all_columns.relkind = ANY (ARRAY['r'::"char", 'v'::"char"]));


ALTER TABLE pg_all_relation_columns OWNER TO postgres;

--
-- Name: pg_all_relations; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_relations AS
 SELECT n.nspname AS schema_name,
    c.relname AS relation_name,
    _pg_sv_system_schema(n.nspname) AS is_system_relation,
    _pg_sv_temp_schema(n.nspname) AS is_temporary,
    (c.relkind = 'v'::"char") AS is_view,
    c.oid AS relation_oid,
    pg_get_userbyid(c.relowner) AS owner,
    obj_description(c.oid, 'pg_class'::name) AS comment
   FROM (pg_class c
     JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE (_pg_sv_table_accessible(n.oid, c.oid) AND (c.relkind = ANY (ARRAY['r'::"char", 'v'::"char"])));


ALTER TABLE pg_all_relations OWNER TO postgres;

--
-- Name: pg_all_rules; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_rules AS
 SELECT _pg_all_rules_raw.schema_name,
    _pg_all_rules_raw.relation_name,
    _pg_all_rules_raw.rule_name,
    _pg_all_rules_raw.rule_event,
    _pg_all_rules_raw.is_instead,
    _pg_sv_rule_get_where(_pg_all_rules_raw.def) AS condition,
    _pg_sv_rule_get_action(_pg_all_rules_raw.def) AS action
   FROM _pg_all_rules_raw;


ALTER TABLE pg_all_rules OWNER TO postgres;

--
-- Name: pg_all_schema_contents; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_schema_contents AS
 SELECT n.nspname AS schema_name,
    pg_get_userbyid(o.object_uid) AS owner,
    o.object_type,
    o.object_name,
    o.object_args
   FROM (pg_namespace n
     JOIN ( SELECT pg_class.relnamespace AS schema_oid,
            pg_class.relowner AS object_uid,
            pg_class.relname AS object_name,
                CASE pg_class.relkind
                    WHEN 'i'::"char" THEN 'index'::name
                    WHEN 'r'::"char" THEN 'table'::name
                    WHEN 'v'::"char" THEN 'view'::name
                    WHEN 'S'::"char" THEN 'sequence'::name
                    ELSE 'internal'::name
                END AS object_type,
            NULL::text AS object_args
           FROM pg_class
        UNION ALL
         SELECT pg_type.typnamespace AS schema_oid,
            pg_type.typowner AS object_uid,
            pg_type.typname AS object_name,
                CASE
                    WHEN (pg_type.typtype = 'd'::"char") THEN 'domain'::name
                    WHEN (pg_type.typtype = 'c'::"char") THEN 'record type'::name
                    WHEN (pg_type.typtype = 'b'::"char") THEN 'base type'::name
                    ELSE 'unknown type'::name
                END AS object_type,
            NULL::text AS object_args
           FROM pg_type
          WHERE (pg_type.typrelid = (0)::oid)
        UNION ALL
         SELECT pg_proc.pronamespace AS schema_oid,
            pg_proc.proowner AS object_uid,
            pg_proc.proname AS object_name,
                CASE
                    WHEN pg_proc.proisagg THEN 'aggregate function'::name
                    ELSE 'function'::name
                END AS object_type,
            oidvectortypes(pg_proc.proargtypes) AS object_args
           FROM pg_proc
        UNION ALL
         SELECT pg_operator.oprnamespace AS schema_oid,
            pg_operator.oprowner AS object_uid,
            pg_operator.oprname AS object_name,
            'operator'::name AS object_type,
            ((
                CASE
                    WHEN (pg_operator.oprkind = 'l'::"char") THEN ''::text
                    ELSE (format_type(pg_operator.oprleft, NULL::integer) || ' '::text)
                END || (pg_operator.oprname)::text) ||
                CASE
                    WHEN (pg_operator.oprkind = 'r'::"char") THEN ''::text
                    ELSE (' '::text || format_type(pg_operator.oprright, NULL::integer))
                END) AS object_args
           FROM pg_operator
        UNION ALL
         SELECT pg_opclass.opcnamespace AS schema_oid,
            pg_opclass.opcowner AS object_uid,
            pg_opclass.opcname AS object_name,
            'operator class'::name AS object_type,
            (((pg_am.amname)::text || ', '::text) || format_type(pg_opclass.opcintype, NULL::integer)) AS object_args
           FROM (pg_opclass
             JOIN pg_am ON ((pg_opclass.opcmethod = pg_am.oid)))
        UNION ALL
         SELECT pg_conversion.connamespace AS schema_oid,
            pg_conversion.conowner AS object_uid,
            pg_conversion.conname AS object_name,
            'conversion'::name AS object_type,
            (((pg_encoding_to_char(pg_conversion.conforencoding))::text || ' => '::text) || (pg_encoding_to_char(pg_conversion.contoencoding))::text) AS object_args
           FROM pg_conversion) o ON ((o.schema_oid = n.oid)))
  WHERE has_schema_privilege(n.oid, 'USAGE'::text);


ALTER TABLE pg_all_schema_contents OWNER TO postgres;

--
-- Name: pg_all_schemas; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_schemas AS
 SELECT pg_namespace.nspname AS schema_name,
    _pg_sv_system_schema(pg_namespace.nspname) AS is_system_schema,
    _pg_sv_temp_schema(pg_namespace.nspname) AS is_temporary_schema,
    pg_get_userbyid(pg_namespace.nspowner) AS owner,
    obj_description(pg_namespace.oid, 'pg_namespace'::name) AS comment
   FROM pg_namespace
  WHERE has_schema_privilege(pg_namespace.oid, 'USAGE'::text);


ALTER TABLE pg_all_schemas OWNER TO postgres;

--
-- Name: pg_all_sequences; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_sequences AS
 SELECT n.nspname AS schema_name,
    c.relname AS sequence_name,
    _pg_sv_system_schema(n.nspname) AS is_system_sequence,
    _pg_sv_temp_schema(n.nspname) AS is_temporary
   FROM (pg_class c
     JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE (_pg_sv_table_accessible(n.oid, c.oid) AND (c.relkind = 'S'::"char"));


ALTER TABLE pg_all_sequences OWNER TO postgres;

--
-- Name: pg_all_table_check_constraints; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_table_check_constraints AS
 SELECT n.nspname AS schema_name,
    c.relname AS table_name,
    con.conname AS constraint_name,
    c.oid AS table_oid,
    _pg_sv_column_array(con.conrelid, con.conkey) AS columns,
    pg_get_expr(con.conbin, con.conrelid, true) AS predicate
   FROM ((pg_constraint con
     JOIN pg_namespace n ON ((n.oid = con.connamespace)))
     JOIN pg_class c ON ((c.oid = con.conrelid)))
  WHERE (((con.conrelid <> (0)::oid) AND (con.contype = 'c'::"char")) AND _pg_sv_table_accessible(n.oid, c.oid));


ALTER TABLE pg_all_table_check_constraints OWNER TO postgres;

--
-- Name: pg_all_table_column_type_info; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_table_column_type_info AS
 SELECT pg_all_relation_column_type_info.schema_name,
    pg_all_relation_column_type_info.relation_name AS table_name,
    pg_all_relation_column_type_info.column_name,
    pg_all_relation_column_type_info.relation_oid AS table_oid,
    pg_all_relation_column_type_info.column_number,
    pg_all_relation_column_type_info.nullable,
    pg_all_relation_column_type_info.domain_schema,
    pg_all_relation_column_type_info.domain_name,
    pg_all_relation_column_type_info.type_sqlname,
    pg_all_relation_column_type_info.type_sqldef,
    pg_all_relation_column_type_info.type_schema,
    pg_all_relation_column_type_info.type_name,
    pg_all_relation_column_type_info.type_oid,
    pg_all_relation_column_type_info.type_length,
    pg_all_relation_column_type_info.is_array,
    pg_all_relation_column_type_info.array_dimensions,
    pg_all_relation_column_type_info.element_sqlname,
    pg_all_relation_column_type_info.element_sqldef,
    pg_all_relation_column_type_info.element_schema,
    pg_all_relation_column_type_info.element_name,
    pg_all_relation_column_type_info.element_oid,
    pg_all_relation_column_type_info.element_length,
    pg_all_relation_column_type_info.character_length,
    pg_all_relation_column_type_info.bit_length,
    pg_all_relation_column_type_info.integer_precision,
    pg_all_relation_column_type_info.float_precision,
    pg_all_relation_column_type_info.numeric_precision,
    pg_all_relation_column_type_info.numeric_scale,
    pg_all_relation_column_type_info.time_precision,
    pg_all_relation_column_type_info.interval_precision,
    pg_all_relation_column_type_info.interval_fields
   FROM pg_all_relation_column_type_info
  WHERE (NOT pg_all_relation_column_type_info.is_view);


ALTER TABLE pg_all_table_column_type_info OWNER TO postgres;

--
-- Name: pg_all_table_columns; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_table_columns AS
 SELECT pg_all_relation_columns.schema_name,
    pg_all_relation_columns.relation_name AS table_name,
    pg_all_relation_columns.column_name,
    pg_all_relation_columns.relation_oid AS table_oid,
    pg_all_relation_columns.column_number,
    pg_all_relation_columns.nullable,
    pg_all_relation_columns.declared_type,
    pg_all_relation_columns.default_value,
    pg_all_relation_columns.comment
   FROM pg_all_relation_columns
  WHERE (NOT pg_all_relation_columns.is_view);


ALTER TABLE pg_all_table_columns OWNER TO postgres;

--
-- Name: pg_all_table_constraint_columns; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_table_constraint_columns AS
 SELECT n.nspname AS schema_name,
    c.relname AS table_name,
    con.conname AS constraint_name,
    a.attname AS column_name,
    s.i AS column_position,
        CASE con.contype
            WHEN 'p'::"char" THEN 'primary key'::text
            WHEN 'c'::"char" THEN 'check'::text
            WHEN 'f'::"char" THEN 'foreign key'::text
            WHEN 'u'::"char" THEN 'unique'::text
            ELSE 'unknown'::text
        END AS constraint_type,
    c.oid AS table_oid
   FROM ((((pg_constraint con
     JOIN pg_namespace n ON ((n.oid = con.connamespace)))
     JOIN pg_class c ON ((c.oid = con.conrelid)))
     JOIN _pg_sv_keypositions() s(i) ON ((s.i <= array_upper(con.conkey, 1))))
     JOIN pg_attribute a ON (((a.attrelid = c.oid) AND (a.attnum = con.conkey[s.i]))))
  WHERE ((con.conrelid <> (0)::oid) AND _pg_sv_table_accessible(n.oid, c.oid));


ALTER TABLE pg_all_table_constraint_columns OWNER TO postgres;

--
-- Name: pg_all_table_constraints; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_table_constraints AS
 SELECT n.nspname AS schema_name,
    c.relname AS table_name,
    con.conname AS constraint_name,
        CASE con.contype
            WHEN 'p'::"char" THEN 'primary key'::text
            WHEN 'c'::"char" THEN 'check'::text
            WHEN 'f'::"char" THEN 'foreign key'::text
            WHEN 'u'::"char" THEN 'unique'::text
            ELSE 'unknown'::text
        END AS constraint_type,
    c.oid AS table_oid,
    pg_get_constraintdef(con.oid, false) AS definition
   FROM ((pg_constraint con
     JOIN pg_namespace n ON ((n.oid = con.connamespace)))
     JOIN pg_class c ON ((c.oid = con.conrelid)))
  WHERE ((con.conrelid <> (0)::oid) AND _pg_sv_table_accessible(n.oid, c.oid));


ALTER TABLE pg_all_table_constraints OWNER TO postgres;

--
-- Name: pg_all_table_inheritance; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_table_inheritance AS
 SELECT n1.nspname AS schema_name,
    c1.relname AS table_name,
    c1.oid AS table_oid,
    n2.nspname AS descendent_schema,
    c2.relname AS descendent_table,
    c2.oid AS descendent_oid,
    i.inhseqno AS ordinal_position
   FROM ((((pg_inherits i
     JOIN pg_class c1 ON ((c1.oid = i.inhparent)))
     JOIN pg_namespace n1 ON ((n1.oid = c1.relnamespace)))
     JOIN pg_class c2 ON ((c2.oid = i.inhrelid)))
     JOIN pg_namespace n2 ON ((n2.oid = c2.relnamespace)))
  WHERE _pg_sv_table_accessible(n1.oid, c1.oid);


ALTER TABLE pg_all_table_inheritance OWNER TO postgres;

--
-- Name: pg_all_tables; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_tables AS
 SELECT n.nspname AS schema_name,
    c.relname AS table_name,
    t.spcname AS tablespace,
    c.relhasoids AS with_oids,
    c.reltuples AS estimated_rows,
    ((_pg_sv_pages_to_mb((c.relpages)::numeric) + _pg_sv_pages_to_mb((COALESCE(c2.relpages, 0))::numeric)))::numeric(12,1) AS estimated_mb,
    (c2.oid IS NOT NULL) AS has_toast_table,
    c.relhassubclass AS has_descendents,
    _pg_sv_system_schema(n.nspname) AS is_system_table,
    _pg_sv_temp_schema(n.nspname) AS is_temporary,
    c.oid AS table_oid,
    pg_get_userbyid(c.relowner) AS owner,
    obj_description(c.oid, 'pg_class'::name) AS comment
   FROM (((pg_class c
     JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
     LEFT JOIN pg_tablespace t ON (_pg_sv_tablespace_match(c.*, t.oid)))
     LEFT JOIN pg_class c2 ON ((c2.oid = c.reltoastrelid)))
  WHERE (_pg_sv_table_accessible(n.oid, c.oid) AND (c.relkind = 'r'::"char"));


ALTER TABLE pg_all_tables OWNER TO postgres;

--
-- Name: pg_tablespace_usage; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_tablespace_usage AS
 SELECT t.spcname AS tablespace,
    d.datname AS database
   FROM (pg_database d
     JOIN ( SELECT pg_tablespace.oid,
            pg_tablespace.spcname,
            _pg_sv_tablespace_usage(pg_tablespace.oid) AS dbs
           FROM pg_tablespace
          WHERE (pg_tablespace.spcname <> 'pg_global'::name)) t ON ((d.oid = ANY (t.dbs))));


ALTER TABLE pg_tablespace_usage OWNER TO postgres;

--
-- Name: pg_all_tablespace_contents; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_tablespace_contents AS
 SELECT t.spcname AS tablespace,
    o.object_type,
    o.object_owner AS owner,
    o.object_schema,
    o.object_name,
    (o.object_megs)::numeric(12,1) AS estimated_mb
   FROM (pg_tablespace t
     JOIN ( SELECT pg_all_tables.tablespace AS object_space,
            pg_all_tables.owner AS object_owner,
            'table'::text AS object_type,
            pg_all_tables.schema_name AS object_schema,
            pg_all_tables.table_name AS object_name,
            pg_all_tables.estimated_mb AS object_megs
           FROM pg_all_tables
        UNION ALL
         SELECT pg_all_indexes.tablespace AS object_space,
            pg_all_indexes.owner AS object_owner,
            'index'::text AS object_type,
            pg_all_indexes.schema_name AS object_schema,
            pg_all_indexes.index_name AS object_name,
            pg_all_indexes.estimated_mb AS object_megs
           FROM pg_all_indexes
        UNION ALL
         SELECT tu.tablespace AS object_space,
            pg_get_userbyid(d.datdba) AS object_owner,
            'database'::text AS object_type,
            NULL::name AS object_schema,
            tu.database AS object_name,
            NULL::numeric AS object_megs
           FROM (pg_tablespace_usage tu
             JOIN pg_database d ON ((d.datname = tu.database)))) o ON ((o.object_space = t.spcname)));


ALTER TABLE pg_all_tablespace_contents OWNER TO postgres;

--
-- Name: pg_all_view_column_type_info; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_view_column_type_info AS
 SELECT pg_all_relation_column_type_info.schema_name,
    pg_all_relation_column_type_info.relation_name AS view_name,
    pg_all_relation_column_type_info.column_name,
    pg_all_relation_column_type_info.relation_oid AS view_oid,
    pg_all_relation_column_type_info.column_number,
    pg_all_relation_column_type_info.nullable,
    pg_all_relation_column_type_info.domain_schema,
    pg_all_relation_column_type_info.domain_name,
    pg_all_relation_column_type_info.type_sqlname,
    pg_all_relation_column_type_info.type_sqldef,
    pg_all_relation_column_type_info.type_schema,
    pg_all_relation_column_type_info.type_name,
    pg_all_relation_column_type_info.type_oid,
    pg_all_relation_column_type_info.type_length,
    pg_all_relation_column_type_info.is_array,
    pg_all_relation_column_type_info.array_dimensions,
    pg_all_relation_column_type_info.element_sqlname,
    pg_all_relation_column_type_info.element_sqldef,
    pg_all_relation_column_type_info.element_schema,
    pg_all_relation_column_type_info.element_name,
    pg_all_relation_column_type_info.element_oid,
    pg_all_relation_column_type_info.element_length,
    pg_all_relation_column_type_info.character_length,
    pg_all_relation_column_type_info.bit_length,
    pg_all_relation_column_type_info.integer_precision,
    pg_all_relation_column_type_info.float_precision,
    pg_all_relation_column_type_info.numeric_precision,
    pg_all_relation_column_type_info.numeric_scale,
    pg_all_relation_column_type_info.time_precision,
    pg_all_relation_column_type_info.interval_precision,
    pg_all_relation_column_type_info.interval_fields
   FROM pg_all_relation_column_type_info
  WHERE pg_all_relation_column_type_info.is_view;


ALTER TABLE pg_all_view_column_type_info OWNER TO postgres;

--
-- Name: pg_all_view_columns; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_view_columns AS
 SELECT pg_all_relation_columns.schema_name,
    pg_all_relation_columns.relation_name AS view_name,
    pg_all_relation_columns.column_name,
    pg_all_relation_columns.relation_oid AS view_oid,
    pg_all_relation_columns.column_number,
    pg_all_relation_columns.nullable,
    pg_all_relation_columns.declared_type,
    pg_all_relation_columns.default_value,
    pg_all_relation_columns.comment
   FROM pg_all_relation_columns
  WHERE pg_all_relation_columns.is_view;


ALTER TABLE pg_all_view_columns OWNER TO postgres;

--
-- Name: pg_all_views; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_all_views AS
 SELECT _pg_all_views_raw.schema_name,
    _pg_all_views_raw.view_name,
    ((_pg_all_views_raw.flags & (1 << 3)) <> 0) AS is_insertable,
    ((_pg_all_views_raw.flags & (1 << 2)) <> 0) AS is_updateable,
    ((_pg_all_views_raw.flags & (1 << 4)) <> 0) AS is_deleteable,
    pg_get_viewdef(_pg_all_views_raw.view_oid, false) AS definition,
    _pg_sv_system_schema(_pg_all_views_raw.schema_name) AS is_system_view,
    _pg_all_views_raw.view_oid,
    pg_get_userbyid(_pg_all_views_raw.uid) AS owner,
    obj_description(_pg_all_views_raw.view_oid, 'pg_class'::name) AS comment
   FROM _pg_all_views_raw;


ALTER TABLE pg_all_views OWNER TO postgres;

--
-- Name: pg_databases; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_databases AS
 SELECT d.datname AS database_name,
    pg_encoding_to_char(d.encoding) AS encoding,
    t.spcname AS default_tablespace,
    d.datistemplate AS is_template,
    d.datallowconn AS can_connect,
    pg_get_userbyid(d.datdba) AS owner
   FROM (pg_database d
     LEFT JOIN pg_tablespace t ON ((t.oid = _pg_sv_tablespace(d.*))));


ALTER TABLE pg_databases OWNER TO postgres;

--
-- Name: pg_groups; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_groups AS
 SELECT pg_group.groname AS group_name,
    pg_group.grosysid AS gid
   FROM pg_group;


ALTER TABLE pg_groups OWNER TO postgres;

--
-- Name: pg_groups_users; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_groups_users AS
 SELECT pg_group.groname AS group_name,
    pg_shadow.usename AS user_name
   FROM ((pg_group
     JOIN _pg_sv_grolist_index() s(i) ON ((s.i <= array_upper(pg_group.grolist, 1))))
     JOIN pg_shadow ON ((pg_group.grolist[s.i] = pg_shadow.usesysid)));


ALTER TABLE pg_groups_users OWNER TO postgres;

--
-- Name: pg_user_aggregates; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_aggregates AS
 SELECT pg_all_aggregates.schema_name,
    pg_all_aggregates.aggregate_name,
    pg_all_aggregates.input_type_schema,
    pg_all_aggregates.input_type,
    pg_all_aggregates.output_type_schema,
    pg_all_aggregates.output_type,
    pg_all_aggregates.initial_value,
    pg_all_aggregates.trans_function_schema,
    pg_all_aggregates.trans_function_name,
    pg_all_aggregates.final_function_schema,
    pg_all_aggregates.final_function_name,
    pg_all_aggregates.owner
   FROM pg_all_aggregates
  WHERE (NOT pg_all_aggregates.is_system_aggregate);


ALTER TABLE pg_user_aggregates OWNER TO postgres;

--
-- Name: pg_user_basetype_details; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_basetype_details AS
 SELECT pg_all_basetype_details.schema_name,
    pg_all_basetype_details.type_name,
    pg_all_basetype_details.type_oid,
    pg_all_basetype_details.owner,
    pg_all_basetype_details.type_length,
    pg_all_basetype_details.type_type,
    pg_all_basetype_details.passed_by_value,
    pg_all_basetype_details.type_alignment,
    pg_all_basetype_details.type_storage,
    pg_all_basetype_details.is_builtin,
    pg_all_basetype_details.input_function,
    pg_all_basetype_details.output_function,
    pg_all_basetype_details.send_function,
    pg_all_basetype_details.receive_function,
    pg_all_basetype_details.analyze_function,
    pg_all_basetype_details.comment
   FROM pg_all_basetype_details
  WHERE (NOT pg_all_basetype_details.is_builtin);


ALTER TABLE pg_user_basetype_details OWNER TO postgres;

--
-- Name: pg_user_basetypes; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_basetypes AS
 SELECT pg_all_basetypes.schema_name,
    pg_all_basetypes.type_name,
    pg_all_basetypes.type_oid,
    pg_all_basetypes.owner,
    pg_all_basetypes.type_length,
    pg_all_basetypes.type_type,
    pg_all_basetypes.is_builtin,
    pg_all_basetypes.comment
   FROM pg_all_basetypes
  WHERE (NOT pg_all_basetypes.is_builtin);


ALTER TABLE pg_user_basetypes OWNER TO postgres;

--
-- Name: pg_user_casts; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_casts AS
 SELECT pg_all_casts.source_schema,
    pg_all_casts.source_type,
    pg_all_casts.target_schema,
    pg_all_casts.target_type,
    pg_all_casts.function_schema,
    pg_all_casts.function_name,
    pg_all_casts.function_arguments,
    pg_all_casts.context
   FROM pg_all_casts
  WHERE (NOT pg_all_casts.is_system_cast);


ALTER TABLE pg_user_casts OWNER TO postgres;

--
-- Name: pg_user_composite_type_columns; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_composite_type_columns AS
 SELECT pg_all_composite_type_columns.schema_name,
    pg_all_composite_type_columns.type_name,
    pg_all_composite_type_columns.type_oid,
    pg_all_composite_type_columns.column_name,
    pg_all_composite_type_columns.column_number,
    pg_all_composite_type_columns.nullable,
    pg_all_composite_type_columns.declared_type,
    pg_all_composite_type_columns.default_value,
    pg_all_composite_type_columns.is_builtin,
    pg_all_composite_type_columns.comment
   FROM pg_all_composite_type_columns
  WHERE (NOT pg_all_composite_type_columns.is_builtin);


ALTER TABLE pg_user_composite_type_columns OWNER TO postgres;

--
-- Name: pg_user_composite_types; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_composite_types AS
 SELECT pg_all_composite_types.schema_name,
    pg_all_composite_types.type_name,
    pg_all_composite_types.type_oid,
    pg_all_composite_types.owner,
    pg_all_composite_types.is_builtin,
    pg_all_composite_types.comment
   FROM pg_all_composite_types
  WHERE (NOT pg_all_composite_types.is_builtin);


ALTER TABLE pg_user_composite_types OWNER TO postgres;

--
-- Name: pg_user_config; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_config AS
 SELECT pg_shadow.usename AS user_name,
    "substring"(pg_shadow.useconfig[s.i], '^([^=]+)='::text) AS config_variable,
    "substring"(pg_shadow.useconfig[s.i], '=(.*)$'::text) AS config_value
   FROM (pg_shadow
     JOIN _pg_sv_userconfig_index() s(i) ON ((s.i <= array_upper(pg_shadow.useconfig, 1))));


ALTER TABLE pg_user_config OWNER TO postgres;

--
-- Name: pg_user_conversions; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_conversions AS
 SELECT pg_all_conversions.schema_name,
    pg_all_conversions.conversion_name,
    pg_all_conversions.source_encoding,
    pg_all_conversions.destination_encoding,
    pg_all_conversions.is_default,
    pg_all_conversions.function_schema,
    pg_all_conversions.function_name,
    pg_all_conversions.is_system_conversion,
    pg_all_conversions.owner
   FROM pg_all_conversions
  WHERE (NOT pg_all_conversions.is_system_conversion);


ALTER TABLE pg_user_conversions OWNER TO postgres;

--
-- Name: pg_user_domains; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_domains AS
 SELECT pg_all_domains.schema_name,
    pg_all_domains.domain_name,
    pg_all_domains.domain_oid,
    pg_all_domains.owner,
    pg_all_domains.base_type,
    pg_all_domains.domain_length,
    pg_all_domains.domain_default,
    pg_all_domains.constraint_name,
    pg_all_domains.check_constraint,
    pg_all_domains.is_builtin,
    pg_all_domains.comment
   FROM pg_all_domains
  WHERE (NOT pg_all_domains.is_builtin);


ALTER TABLE pg_user_domains OWNER TO postgres;

--
-- Name: pg_user_foreign_key_columns; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_foreign_key_columns AS
 SELECT pg_all_foreign_key_columns.foreign_key_schema_name,
    pg_all_foreign_key_columns.foreign_key_table_name,
    pg_all_foreign_key_columns.foreign_key_constraint_name,
    pg_all_foreign_key_columns.foreign_key_table_oid,
    pg_all_foreign_key_columns.foreign_key_column,
    pg_all_foreign_key_columns.column_position,
    pg_all_foreign_key_columns.key_schema_name,
    pg_all_foreign_key_columns.key_table_name,
    pg_all_foreign_key_columns.key_table_oid,
    pg_all_foreign_key_columns.key_column
   FROM pg_all_foreign_key_columns
  WHERE (NOT _pg_sv_system_schema(pg_all_foreign_key_columns.foreign_key_schema_name));


ALTER TABLE pg_user_foreign_key_columns OWNER TO postgres;

--
-- Name: pg_user_foreign_key_indexes; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_foreign_key_indexes AS
 SELECT pg_all_foreign_key_indexes.schema_name,
    pg_all_foreign_key_indexes.table_name,
    pg_all_foreign_key_indexes.constraint_name,
    pg_all_foreign_key_indexes.num_columns,
    pg_all_foreign_key_indexes.num_indexed_columns,
    pg_all_foreign_key_indexes.index_name
   FROM pg_all_foreign_key_indexes
  WHERE (NOT _pg_sv_system_schema(pg_all_foreign_key_indexes.schema_name));


ALTER TABLE pg_user_foreign_key_indexes OWNER TO postgres;

--
-- Name: pg_user_foreign_keys; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_foreign_keys AS
 SELECT pg_all_foreign_keys.foreign_key_schema_name,
    pg_all_foreign_keys.foreign_key_table_name,
    pg_all_foreign_keys.foreign_key_constraint_name,
    pg_all_foreign_keys.foreign_key_table_oid,
    pg_all_foreign_keys.foreign_key_columns,
    pg_all_foreign_keys.key_schema_name,
    pg_all_foreign_keys.key_table_name,
    pg_all_foreign_keys.key_constraint_name,
    pg_all_foreign_keys.key_table_oid,
    pg_all_foreign_keys.key_index_name,
    pg_all_foreign_keys.key_columns,
    pg_all_foreign_keys.match_type,
    pg_all_foreign_keys.on_delete,
    pg_all_foreign_keys.on_update,
    pg_all_foreign_keys.is_deferrable,
    pg_all_foreign_keys.is_deferred
   FROM pg_all_foreign_keys
  WHERE (NOT _pg_sv_system_schema(pg_all_foreign_keys.foreign_key_schema_name));


ALTER TABLE pg_user_foreign_keys OWNER TO postgres;

--
-- Name: pg_user_grants; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_grants AS
 SELECT pg_all_grants.object_type,
    pg_all_grants.object_oid,
    pg_all_grants.schema_name,
    pg_all_grants.object_name,
    pg_all_grants.object_args,
    pg_all_grants.owner,
    pg_all_grants.grantor,
    pg_all_grants.grantee,
    pg_all_grants.is_group,
    pg_all_grants.privilege,
    pg_all_grants.grant_option
   FROM pg_all_grants
  WHERE (NOT (_pg_sv_system_schema(pg_all_grants.schema_name) IS TRUE));


ALTER TABLE pg_user_grants OWNER TO postgres;

--
-- Name: pg_user_index_columns; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_index_columns AS
 SELECT pg_all_index_columns.schema_name,
    pg_all_index_columns.table_name,
    pg_all_index_columns.index_name,
    pg_all_index_columns.column_name,
    pg_all_index_columns.column_position,
    pg_all_index_columns.opclass_schema,
    pg_all_index_columns.opclass_name,
    pg_all_index_columns.definition
   FROM pg_all_index_columns
  WHERE (NOT _pg_sv_system_schema(pg_all_index_columns.schema_name));


ALTER TABLE pg_user_index_columns OWNER TO postgres;

--
-- Name: pg_user_indexes; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_indexes AS
 SELECT pg_all_indexes.schema_name,
    pg_all_indexes.table_name,
    pg_all_indexes.index_name,
    pg_all_indexes.tablespace,
    pg_all_indexes.index_method,
    pg_all_indexes.num_columns,
    pg_all_indexes.is_primary_key,
    pg_all_indexes.is_unique,
    pg_all_indexes.is_clustered,
    pg_all_indexes.is_expression,
    pg_all_indexes.is_partial,
    pg_all_indexes.estimated_rows,
    pg_all_indexes.estimated_mb,
    pg_all_indexes.predicate,
    pg_all_indexes.definition,
    pg_all_indexes.owner,
    pg_all_indexes.comment
   FROM pg_all_indexes
  WHERE (NOT pg_all_indexes.is_system_table);


ALTER TABLE pg_user_indexes OWNER TO postgres;

--
-- Name: pg_user_primary_key_columns; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_primary_key_columns AS
 SELECT pg_all_primary_key_columns.schema_name,
    pg_all_primary_key_columns.table_name,
    pg_all_primary_key_columns.constraint_name,
    pg_all_primary_key_columns.column_name,
    pg_all_primary_key_columns.column_position,
    pg_all_primary_key_columns.table_oid
   FROM pg_all_primary_key_columns
  WHERE (NOT _pg_sv_system_schema(pg_all_primary_key_columns.schema_name));


ALTER TABLE pg_user_primary_key_columns OWNER TO postgres;

--
-- Name: pg_user_relation_column_type_info; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_relation_column_type_info AS
 SELECT _pg_all_relation_column_type_raw.schema_name,
    _pg_all_relation_column_type_raw.relation_name,
    _pg_all_relation_column_type_raw.column_name,
    _pg_all_relation_column_type_raw.relation_oid,
    _pg_all_relation_column_type_raw.column_number,
    _pg_all_relation_column_type_raw.is_view,
    _pg_all_relation_column_type_raw.nullable,
    _pg_all_relation_column_type_raw.domain_schema,
    _pg_all_relation_column_type_raw.domain_name,
    _pg_all_relation_column_type_raw.type_sqlname,
    _pg_all_relation_column_type_raw.type_sqldef,
    _pg_all_relation_column_type_raw.type_schema,
    _pg_all_relation_column_type_raw.type_name,
    _pg_all_relation_column_type_raw.type_oid,
    _pg_all_relation_column_type_raw.type_length,
    _pg_all_relation_column_type_raw.is_array,
    _pg_all_relation_column_type_raw.array_dimensions,
    _pg_all_relation_column_type_raw.element_sqlname,
    _pg_all_relation_column_type_raw.element_sqldef,
    _pg_all_relation_column_type_raw.element_schema,
    _pg_all_relation_column_type_raw.element_name,
    _pg_all_relation_column_type_raw.element_oid,
    _pg_all_relation_column_type_raw.element_length,
    _pg_sv_type_char_length(_pg_all_relation_column_type_raw.basetype_oid, _pg_all_relation_column_type_raw.basetype_typmod) AS character_length,
    _pg_sv_type_bit_length(_pg_all_relation_column_type_raw.basetype_oid, _pg_all_relation_column_type_raw.basetype_typmod) AS bit_length,
    _pg_sv_type_integer_precision(_pg_all_relation_column_type_raw.basetype_oid, _pg_all_relation_column_type_raw.basetype_typmod) AS integer_precision,
    _pg_sv_type_float_precision(_pg_all_relation_column_type_raw.basetype_oid, _pg_all_relation_column_type_raw.basetype_typmod) AS float_precision,
    _pg_sv_type_numeric_precision(_pg_all_relation_column_type_raw.basetype_oid, _pg_all_relation_column_type_raw.basetype_typmod) AS numeric_precision,
    _pg_sv_type_numeric_scale(_pg_all_relation_column_type_raw.basetype_oid, _pg_all_relation_column_type_raw.basetype_typmod) AS numeric_scale,
    _pg_sv_type_time_precision(_pg_all_relation_column_type_raw.basetype_oid, _pg_all_relation_column_type_raw.basetype_typmod) AS time_precision,
    _pg_sv_type_interval_precision(_pg_all_relation_column_type_raw.basetype_oid, _pg_all_relation_column_type_raw.basetype_typmod) AS interval_precision,
    _pg_sv_type_interval_fields(_pg_all_relation_column_type_raw.basetype_oid, _pg_all_relation_column_type_raw.basetype_typmod) AS interval_fields
   FROM _pg_all_relation_column_type_raw
  WHERE (NOT _pg_sv_system_schema(_pg_all_relation_column_type_raw.schema_name));


ALTER TABLE pg_user_relation_column_type_info OWNER TO postgres;

--
-- Name: pg_user_relation_columns; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_relation_columns AS
 SELECT pg_all_relation_columns.schema_name,
    pg_all_relation_columns.relation_name,
    pg_all_relation_columns.relation_oid,
    pg_all_relation_columns.column_name,
    pg_all_relation_columns.column_number,
    pg_all_relation_columns.is_view,
    pg_all_relation_columns.nullable,
    pg_all_relation_columns.declared_type,
    pg_all_relation_columns.default_value,
    pg_all_relation_columns.comment
   FROM pg_all_relation_columns
  WHERE (NOT _pg_sv_system_schema(pg_all_relation_columns.schema_name));


ALTER TABLE pg_user_relation_columns OWNER TO postgres;

--
-- Name: pg_user_relations; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_relations AS
 SELECT pg_all_relations.schema_name,
    pg_all_relations.relation_name,
    pg_all_relations.is_temporary,
    pg_all_relations.is_view,
    pg_all_relations.owner,
    pg_all_relations.comment
   FROM pg_all_relations
  WHERE (NOT pg_all_relations.is_system_relation);


ALTER TABLE pg_user_relations OWNER TO postgres;

--
-- Name: pg_user_rules; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_rules AS
 SELECT _pg_all_rules_raw.schema_name,
    _pg_all_rules_raw.relation_name,
    _pg_all_rules_raw.rule_name,
    _pg_all_rules_raw.rule_event,
    _pg_all_rules_raw.is_instead,
    _pg_sv_rule_get_where(_pg_all_rules_raw.def) AS condition,
    _pg_sv_rule_get_action(_pg_all_rules_raw.def) AS action
   FROM _pg_all_rules_raw
  WHERE (NOT _pg_sv_system_schema(_pg_all_rules_raw.schema_name));


ALTER TABLE pg_user_rules OWNER TO postgres;

--
-- Name: pg_user_schema_contents; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_schema_contents AS
 SELECT pg_all_schema_contents.schema_name,
    pg_all_schema_contents.owner,
    pg_all_schema_contents.object_type,
    pg_all_schema_contents.object_name,
    pg_all_schema_contents.object_args
   FROM pg_all_schema_contents
  WHERE (NOT _pg_sv_system_schema(pg_all_schema_contents.schema_name));


ALTER TABLE pg_user_schema_contents OWNER TO postgres;

--
-- Name: pg_user_schemas; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_schemas AS
 SELECT pg_all_schemas.schema_name,
    pg_all_schemas.is_temporary_schema,
    pg_all_schemas.owner,
    pg_all_schemas.comment
   FROM pg_all_schemas
  WHERE (NOT pg_all_schemas.is_system_schema);


ALTER TABLE pg_user_schemas OWNER TO postgres;

--
-- Name: pg_user_sequences; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_sequences AS
 SELECT pg_all_sequences.schema_name,
    pg_all_sequences.sequence_name,
    pg_all_sequences.is_temporary
   FROM pg_all_sequences
  WHERE (NOT pg_all_sequences.is_system_sequence);


ALTER TABLE pg_user_sequences OWNER TO postgres;

--
-- Name: pg_user_table_check_constraints; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_table_check_constraints AS
 SELECT pg_all_table_constraints.schema_name,
    pg_all_table_constraints.table_name,
    pg_all_table_constraints.constraint_name,
    pg_all_table_constraints.constraint_type,
    pg_all_table_constraints.table_oid,
    pg_all_table_constraints.definition
   FROM pg_all_table_constraints
  WHERE (NOT _pg_sv_system_schema(pg_all_table_constraints.schema_name));


ALTER TABLE pg_user_table_check_constraints OWNER TO postgres;

--
-- Name: pg_user_table_column_type_info; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_table_column_type_info AS
 SELECT pg_all_table_column_type_info.schema_name,
    pg_all_table_column_type_info.table_name,
    pg_all_table_column_type_info.column_name,
    pg_all_table_column_type_info.table_oid,
    pg_all_table_column_type_info.column_number,
    pg_all_table_column_type_info.nullable,
    pg_all_table_column_type_info.domain_schema,
    pg_all_table_column_type_info.domain_name,
    pg_all_table_column_type_info.type_sqlname,
    pg_all_table_column_type_info.type_sqldef,
    pg_all_table_column_type_info.type_schema,
    pg_all_table_column_type_info.type_name,
    pg_all_table_column_type_info.type_oid,
    pg_all_table_column_type_info.type_length,
    pg_all_table_column_type_info.is_array,
    pg_all_table_column_type_info.array_dimensions,
    pg_all_table_column_type_info.element_sqlname,
    pg_all_table_column_type_info.element_sqldef,
    pg_all_table_column_type_info.element_schema,
    pg_all_table_column_type_info.element_name,
    pg_all_table_column_type_info.element_oid,
    pg_all_table_column_type_info.element_length,
    pg_all_table_column_type_info.character_length,
    pg_all_table_column_type_info.bit_length,
    pg_all_table_column_type_info.integer_precision,
    pg_all_table_column_type_info.float_precision,
    pg_all_table_column_type_info.numeric_precision,
    pg_all_table_column_type_info.numeric_scale,
    pg_all_table_column_type_info.time_precision,
    pg_all_table_column_type_info.interval_precision,
    pg_all_table_column_type_info.interval_fields
   FROM pg_all_table_column_type_info
  WHERE (NOT _pg_sv_system_schema(pg_all_table_column_type_info.schema_name));


ALTER TABLE pg_user_table_column_type_info OWNER TO postgres;

--
-- Name: pg_user_table_columns; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_table_columns AS
 SELECT pg_all_table_columns.schema_name,
    pg_all_table_columns.table_name,
    pg_all_table_columns.column_name,
    pg_all_table_columns.table_oid,
    pg_all_table_columns.column_number,
    pg_all_table_columns.nullable,
    pg_all_table_columns.declared_type,
    pg_all_table_columns.default_value,
    pg_all_table_columns.comment
   FROM pg_all_table_columns
  WHERE (NOT _pg_sv_system_schema(pg_all_table_columns.schema_name));


ALTER TABLE pg_user_table_columns OWNER TO postgres;

--
-- Name: pg_user_table_constraint_columns; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_table_constraint_columns AS
 SELECT pg_all_table_constraint_columns.schema_name,
    pg_all_table_constraint_columns.table_name,
    pg_all_table_constraint_columns.constraint_name,
    pg_all_table_constraint_columns.column_name,
    pg_all_table_constraint_columns.column_position,
    pg_all_table_constraint_columns.constraint_type,
    pg_all_table_constraint_columns.table_oid
   FROM pg_all_table_constraint_columns
  WHERE (NOT _pg_sv_system_schema(pg_all_table_constraint_columns.schema_name));


ALTER TABLE pg_user_table_constraint_columns OWNER TO postgres;

--
-- Name: pg_user_table_constraints; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_table_constraints AS
 SELECT pg_all_table_constraints.schema_name,
    pg_all_table_constraints.table_name,
    pg_all_table_constraints.constraint_name,
    pg_all_table_constraints.constraint_type,
    pg_all_table_constraints.table_oid,
    pg_all_table_constraints.definition
   FROM pg_all_table_constraints
  WHERE (NOT _pg_sv_system_schema(pg_all_table_constraints.schema_name));


ALTER TABLE pg_user_table_constraints OWNER TO postgres;

--
-- Name: pg_user_table_inheritance; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_table_inheritance AS
 SELECT pg_all_table_inheritance.schema_name,
    pg_all_table_inheritance.table_name,
    pg_all_table_inheritance.table_oid,
    pg_all_table_inheritance.descendent_schema,
    pg_all_table_inheritance.descendent_table,
    pg_all_table_inheritance.descendent_oid,
    pg_all_table_inheritance.ordinal_position
   FROM pg_all_table_inheritance
  WHERE (NOT _pg_sv_system_schema(pg_all_table_inheritance.descendent_schema));


ALTER TABLE pg_user_table_inheritance OWNER TO postgres;

--
-- Name: pg_user_tables; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_tables AS
 SELECT pg_all_tables.schema_name,
    pg_all_tables.table_name,
    pg_all_tables.tablespace,
    pg_all_tables.with_oids,
    pg_all_tables.estimated_rows,
    pg_all_tables.estimated_mb,
    pg_all_tables.has_toast_table,
    pg_all_tables.has_descendents,
    pg_all_tables.is_temporary,
    pg_all_tables.owner,
    pg_all_tables.comment
   FROM pg_all_tables
  WHERE (NOT pg_all_tables.is_system_table);


ALTER TABLE pg_user_tables OWNER TO postgres;

--
-- Name: pg_user_tablespace_contents; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_tablespace_contents AS
 SELECT pg_all_tablespace_contents.tablespace,
    pg_all_tablespace_contents.object_type,
    pg_all_tablespace_contents.owner,
    pg_all_tablespace_contents.object_schema,
    pg_all_tablespace_contents.object_name,
    pg_all_tablespace_contents.estimated_mb
   FROM pg_all_tablespace_contents
  WHERE (NOT (_pg_sv_system_schema(pg_all_tablespace_contents.object_schema) IS TRUE));


ALTER TABLE pg_user_tablespace_contents OWNER TO postgres;

--
-- Name: pg_user_types; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_types AS
 SELECT pg_all_types.schema_name,
    pg_all_types.type_name,
    pg_all_types.type_oid,
    pg_all_types.owner,
    pg_all_types.type_length,
    pg_all_types.type_type,
    pg_all_types.is_builtin,
    pg_all_types.comment
   FROM pg_all_types
  WHERE (NOT pg_all_types.is_builtin);


ALTER TABLE pg_user_types OWNER TO postgres;

--
-- Name: pg_user_unique_constraint_columns; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_unique_constraint_columns AS
 SELECT pg_all_unique_constraint_columns.schema_name,
    pg_all_unique_constraint_columns.table_name,
    pg_all_unique_constraint_columns.constraint_name,
    pg_all_unique_constraint_columns.is_primary_key,
    pg_all_unique_constraint_columns.column_name,
    pg_all_unique_constraint_columns.column_position,
    pg_all_unique_constraint_columns.table_oid
   FROM pg_all_unique_constraint_columns
  WHERE (NOT _pg_sv_system_schema(pg_all_unique_constraint_columns.schema_name));


ALTER TABLE pg_user_unique_constraint_columns OWNER TO postgres;

--
-- Name: pg_user_view_column_type_info; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_view_column_type_info AS
 SELECT pg_all_view_column_type_info.schema_name,
    pg_all_view_column_type_info.view_name,
    pg_all_view_column_type_info.column_name,
    pg_all_view_column_type_info.view_oid,
    pg_all_view_column_type_info.column_number,
    pg_all_view_column_type_info.nullable,
    pg_all_view_column_type_info.domain_schema,
    pg_all_view_column_type_info.domain_name,
    pg_all_view_column_type_info.type_sqlname,
    pg_all_view_column_type_info.type_sqldef,
    pg_all_view_column_type_info.type_schema,
    pg_all_view_column_type_info.type_name,
    pg_all_view_column_type_info.type_oid,
    pg_all_view_column_type_info.type_length,
    pg_all_view_column_type_info.is_array,
    pg_all_view_column_type_info.array_dimensions,
    pg_all_view_column_type_info.element_sqlname,
    pg_all_view_column_type_info.element_sqldef,
    pg_all_view_column_type_info.element_schema,
    pg_all_view_column_type_info.element_name,
    pg_all_view_column_type_info.element_oid,
    pg_all_view_column_type_info.element_length,
    pg_all_view_column_type_info.character_length,
    pg_all_view_column_type_info.bit_length,
    pg_all_view_column_type_info.integer_precision,
    pg_all_view_column_type_info.float_precision,
    pg_all_view_column_type_info.numeric_precision,
    pg_all_view_column_type_info.numeric_scale,
    pg_all_view_column_type_info.time_precision,
    pg_all_view_column_type_info.interval_precision,
    pg_all_view_column_type_info.interval_fields
   FROM pg_all_view_column_type_info
  WHERE (NOT _pg_sv_system_schema(pg_all_view_column_type_info.schema_name));


ALTER TABLE pg_user_view_column_type_info OWNER TO postgres;

--
-- Name: pg_user_view_columns; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_view_columns AS
 SELECT pg_all_view_columns.schema_name,
    pg_all_view_columns.view_name,
    pg_all_view_columns.column_name,
    pg_all_view_columns.view_oid,
    pg_all_view_columns.column_number,
    pg_all_view_columns.nullable,
    pg_all_view_columns.declared_type,
    pg_all_view_columns.default_value,
    pg_all_view_columns.comment
   FROM pg_all_view_columns
  WHERE (NOT _pg_sv_system_schema(pg_all_view_columns.schema_name));


ALTER TABLE pg_user_view_columns OWNER TO postgres;

--
-- Name: pg_user_views; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_user_views AS
 SELECT pg_all_views.schema_name,
    pg_all_views.view_name,
    pg_all_views.is_insertable,
    pg_all_views.is_updateable,
    pg_all_views.is_deleteable,
    pg_all_views.definition,
    pg_all_views.owner,
    pg_all_views.comment
   FROM pg_all_views
  WHERE (NOT pg_all_views.is_system_view);


ALTER TABLE pg_user_views OWNER TO postgres;

--
-- Name: pg_users; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_users AS
 SELECT pg_shadow.usename AS user_name,
    pg_shadow.usesysid AS uid,
    pg_shadow.usecreatedb AS create_datebase,
    pg_shadow.usesuper AS create_user,
    pg_shadow.usesuper AS superuser,
    pg_shadow.usecatupd AS update_system_catalogs,
    (pg_shadow.valuntil)::timestamp with time zone AS password_expires
   FROM pg_shadow;


ALTER TABLE pg_users OWNER TO postgres;

--
-- Name: pg_view_dependancies; Type: VIEW; Schema: dbms_metadata; Owner: postgres
--

CREATE VIEW pg_view_dependancies AS
 SELECT DISTINCT n2.nspname AS namespace,
    c2.relname AS name,
    n1.nspname AS ref_namespace,
    c1.relname AS ref_name,
    ((c2.oid)::regclass)::text AS sql_identifier,
    ((c1.oid)::regclass)::text AS ref_sql_identifier,
    c2.oid AS sysid,
    c1.oid AS ref_sysid
   FROM (((((pg_depend d1
     JOIN pg_rewrite r ON ((r.oid = d1.objid)))
     JOIN pg_class c1 ON ((c1.oid = d1.refobjid)))
     JOIN pg_namespace n1 ON ((n1.oid = c1.relnamespace)))
     JOIN pg_class c2 ON ((c2.oid = r.ev_class)))
     JOIN pg_namespace n2 ON ((n2.oid = c2.relnamespace)))
  WHERE (((true AND (d1.refclassid = ('pg_class'::regclass)::oid)) AND (d1.classid = ('pg_rewrite'::regclass)::oid)) AND (r.ev_class <> c1.oid))
  ORDER BY n1.nspname, c1.relname, n2.nspname, c2.relname, ((c2.oid)::regclass)::text, ((c1.oid)::regclass)::text, c2.oid, c1.oid;


ALTER TABLE pg_view_dependancies OWNER TO postgres;

--
-- Name: VIEW pg_view_dependancies; Type: COMMENT; Schema: dbms_metadata; Owner: postgres
--

COMMENT ON VIEW pg_view_dependancies IS 'Postgres class dependancies';


--
-- Name: version; Type: TABLE; Schema: dbms_metadata; Owner: postgres; Tablespace: 
--

CREATE TABLE version (
    version timestamp with time zone NOT NULL
);


ALTER TABLE version OWNER TO postgres;

--
-- Name: acl_mode_pk; Type: CONSTRAINT; Schema: dbms_metadata; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY pg_acl_modes
    ADD CONSTRAINT acl_mode_pk PRIMARY KEY (object_type, mode);


--
-- Name: changelog_pkey; Type: CONSTRAINT; Schema: dbms_metadata; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY changelog
    ADD CONSTRAINT changelog_pkey PRIMARY KEY ("time");


--
-- Name: version_pkey; Type: CONSTRAINT; Schema: dbms_metadata; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY version
    ADD CONSTRAINT version_pkey PRIMARY KEY (version);


--
-- Name: version_singleton; Type: INDEX; Schema: dbms_metadata; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX version_singleton ON version USING btree ((1));


--
-- Name: dbms_metadata; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA dbms_metadata FROM PUBLIC;
REVOKE ALL ON SCHEMA dbms_metadata FROM postgres;
GRANT ALL ON SCHEMA dbms_metadata TO postgres;
GRANT USAGE ON SCHEMA dbms_metadata TO PUBLIC;


--
-- Name: pg_acl_modes; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_acl_modes FROM PUBLIC;
REVOKE ALL ON TABLE pg_acl_modes FROM postgres;
GRANT ALL ON TABLE pg_acl_modes TO postgres;
GRANT SELECT ON TABLE pg_acl_modes TO PUBLIC;


--
-- Name: pg_all_aggregates; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_aggregates FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_aggregates FROM postgres;
GRANT ALL ON TABLE pg_all_aggregates TO postgres;
GRANT SELECT ON TABLE pg_all_aggregates TO PUBLIC;


--
-- Name: pg_all_basetype_details; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_basetype_details FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_basetype_details FROM postgres;
GRANT ALL ON TABLE pg_all_basetype_details TO postgres;
GRANT SELECT ON TABLE pg_all_basetype_details TO PUBLIC;


--
-- Name: pg_all_types; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_types FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_types FROM postgres;
GRANT ALL ON TABLE pg_all_types TO postgres;
GRANT SELECT ON TABLE pg_all_types TO PUBLIC;


--
-- Name: pg_all_basetypes; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_basetypes FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_basetypes FROM postgres;
GRANT ALL ON TABLE pg_all_basetypes TO postgres;
GRANT SELECT ON TABLE pg_all_basetypes TO PUBLIC;


--
-- Name: pg_all_casts; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_casts FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_casts FROM postgres;
GRANT ALL ON TABLE pg_all_casts TO postgres;
GRANT SELECT ON TABLE pg_all_casts TO PUBLIC;


--
-- Name: pg_all_composite_type_columns; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_composite_type_columns FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_composite_type_columns FROM postgres;
GRANT ALL ON TABLE pg_all_composite_type_columns TO postgres;
GRANT SELECT ON TABLE pg_all_composite_type_columns TO PUBLIC;


--
-- Name: pg_all_composite_types; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_composite_types FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_composite_types FROM postgres;
GRANT ALL ON TABLE pg_all_composite_types TO postgres;
GRANT SELECT ON TABLE pg_all_composite_types TO PUBLIC;


--
-- Name: pg_all_conversions; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_conversions FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_conversions FROM postgres;
GRANT ALL ON TABLE pg_all_conversions TO postgres;
GRANT SELECT ON TABLE pg_all_conversions TO PUBLIC;


--
-- Name: pg_all_domains; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_domains FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_domains FROM postgres;
GRANT ALL ON TABLE pg_all_domains TO postgres;
GRANT SELECT ON TABLE pg_all_domains TO PUBLIC;


--
-- Name: pg_all_foreign_key_columns; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_foreign_key_columns FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_foreign_key_columns FROM postgres;
GRANT ALL ON TABLE pg_all_foreign_key_columns TO postgres;
GRANT SELECT ON TABLE pg_all_foreign_key_columns TO PUBLIC;


--
-- Name: pg_all_foreign_key_indexes; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_foreign_key_indexes FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_foreign_key_indexes FROM postgres;
GRANT ALL ON TABLE pg_all_foreign_key_indexes TO postgres;
GRANT SELECT ON TABLE pg_all_foreign_key_indexes TO PUBLIC;


--
-- Name: pg_all_foreign_keys; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_foreign_keys FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_foreign_keys FROM postgres;
GRANT ALL ON TABLE pg_all_foreign_keys TO postgres;
GRANT SELECT ON TABLE pg_all_foreign_keys TO PUBLIC;


--
-- Name: pg_all_grants; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_grants FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_grants FROM postgres;
GRANT ALL ON TABLE pg_all_grants TO postgres;
GRANT SELECT ON TABLE pg_all_grants TO PUBLIC;


--
-- Name: pg_all_index_columns; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_index_columns FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_index_columns FROM postgres;
GRANT ALL ON TABLE pg_all_index_columns TO postgres;
GRANT SELECT ON TABLE pg_all_index_columns TO PUBLIC;


--
-- Name: pg_all_indexes; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_indexes FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_indexes FROM postgres;
GRANT ALL ON TABLE pg_all_indexes TO postgres;
GRANT SELECT ON TABLE pg_all_indexes TO PUBLIC;


--
-- Name: pg_all_unique_constraint_columns; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_unique_constraint_columns FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_unique_constraint_columns FROM postgres;
GRANT ALL ON TABLE pg_all_unique_constraint_columns TO postgres;
GRANT SELECT ON TABLE pg_all_unique_constraint_columns TO PUBLIC;


--
-- Name: pg_all_primary_key_columns; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_primary_key_columns FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_primary_key_columns FROM postgres;
GRANT ALL ON TABLE pg_all_primary_key_columns TO postgres;
GRANT SELECT ON TABLE pg_all_primary_key_columns TO PUBLIC;


--
-- Name: pg_all_relation_column_type_info; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_relation_column_type_info FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_relation_column_type_info FROM postgres;
GRANT ALL ON TABLE pg_all_relation_column_type_info TO postgres;
GRANT SELECT ON TABLE pg_all_relation_column_type_info TO PUBLIC;


--
-- Name: pg_all_relation_columns; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_relation_columns FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_relation_columns FROM postgres;
GRANT ALL ON TABLE pg_all_relation_columns TO postgres;
GRANT SELECT ON TABLE pg_all_relation_columns TO PUBLIC;


--
-- Name: pg_all_relations; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_relations FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_relations FROM postgres;
GRANT ALL ON TABLE pg_all_relations TO postgres;
GRANT SELECT ON TABLE pg_all_relations TO PUBLIC;


--
-- Name: pg_all_rules; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_rules FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_rules FROM postgres;
GRANT ALL ON TABLE pg_all_rules TO postgres;
GRANT SELECT ON TABLE pg_all_rules TO PUBLIC;


--
-- Name: pg_all_schema_contents; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_schema_contents FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_schema_contents FROM postgres;
GRANT ALL ON TABLE pg_all_schema_contents TO postgres;
GRANT SELECT ON TABLE pg_all_schema_contents TO PUBLIC;


--
-- Name: pg_all_schemas; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_schemas FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_schemas FROM postgres;
GRANT ALL ON TABLE pg_all_schemas TO postgres;
GRANT SELECT ON TABLE pg_all_schemas TO PUBLIC;


--
-- Name: pg_all_sequences; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_sequences FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_sequences FROM postgres;
GRANT ALL ON TABLE pg_all_sequences TO postgres;
GRANT SELECT ON TABLE pg_all_sequences TO PUBLIC;


--
-- Name: pg_all_table_check_constraints; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_table_check_constraints FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_table_check_constraints FROM postgres;
GRANT ALL ON TABLE pg_all_table_check_constraints TO postgres;
GRANT SELECT ON TABLE pg_all_table_check_constraints TO PUBLIC;


--
-- Name: pg_all_table_column_type_info; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_table_column_type_info FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_table_column_type_info FROM postgres;
GRANT ALL ON TABLE pg_all_table_column_type_info TO postgres;
GRANT SELECT ON TABLE pg_all_table_column_type_info TO PUBLIC;


--
-- Name: pg_all_table_columns; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_table_columns FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_table_columns FROM postgres;
GRANT ALL ON TABLE pg_all_table_columns TO postgres;
GRANT SELECT ON TABLE pg_all_table_columns TO PUBLIC;


--
-- Name: pg_all_table_constraint_columns; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_table_constraint_columns FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_table_constraint_columns FROM postgres;
GRANT ALL ON TABLE pg_all_table_constraint_columns TO postgres;
GRANT SELECT ON TABLE pg_all_table_constraint_columns TO PUBLIC;


--
-- Name: pg_all_table_constraints; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_table_constraints FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_table_constraints FROM postgres;
GRANT ALL ON TABLE pg_all_table_constraints TO postgres;
GRANT SELECT ON TABLE pg_all_table_constraints TO PUBLIC;


--
-- Name: pg_all_table_inheritance; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_table_inheritance FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_table_inheritance FROM postgres;
GRANT ALL ON TABLE pg_all_table_inheritance TO postgres;
GRANT SELECT ON TABLE pg_all_table_inheritance TO PUBLIC;


--
-- Name: pg_all_tables; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_tables FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_tables FROM postgres;
GRANT ALL ON TABLE pg_all_tables TO postgres;
GRANT SELECT ON TABLE pg_all_tables TO PUBLIC;


--
-- Name: pg_tablespace_usage; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_tablespace_usage FROM PUBLIC;
REVOKE ALL ON TABLE pg_tablespace_usage FROM postgres;
GRANT ALL ON TABLE pg_tablespace_usage TO postgres;
GRANT SELECT ON TABLE pg_tablespace_usage TO PUBLIC;


--
-- Name: pg_all_tablespace_contents; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_tablespace_contents FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_tablespace_contents FROM postgres;
GRANT ALL ON TABLE pg_all_tablespace_contents TO postgres;
GRANT SELECT ON TABLE pg_all_tablespace_contents TO PUBLIC;


--
-- Name: pg_all_view_column_type_info; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_view_column_type_info FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_view_column_type_info FROM postgres;
GRANT ALL ON TABLE pg_all_view_column_type_info TO postgres;
GRANT SELECT ON TABLE pg_all_view_column_type_info TO PUBLIC;


--
-- Name: pg_all_view_columns; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_view_columns FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_view_columns FROM postgres;
GRANT ALL ON TABLE pg_all_view_columns TO postgres;
GRANT SELECT ON TABLE pg_all_view_columns TO PUBLIC;


--
-- Name: pg_all_views; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_all_views FROM PUBLIC;
REVOKE ALL ON TABLE pg_all_views FROM postgres;
GRANT ALL ON TABLE pg_all_views TO postgres;
GRANT SELECT ON TABLE pg_all_views TO PUBLIC;


--
-- Name: pg_databases; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_databases FROM PUBLIC;
REVOKE ALL ON TABLE pg_databases FROM postgres;
GRANT ALL ON TABLE pg_databases TO postgres;
GRANT SELECT ON TABLE pg_databases TO PUBLIC;


--
-- Name: pg_groups; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_groups FROM PUBLIC;
REVOKE ALL ON TABLE pg_groups FROM postgres;
GRANT ALL ON TABLE pg_groups TO postgres;
GRANT SELECT ON TABLE pg_groups TO PUBLIC;


--
-- Name: pg_groups_users; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_groups_users FROM PUBLIC;
REVOKE ALL ON TABLE pg_groups_users FROM postgres;
GRANT ALL ON TABLE pg_groups_users TO postgres;
GRANT SELECT ON TABLE pg_groups_users TO PUBLIC;


--
-- Name: pg_user_aggregates; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_aggregates FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_aggregates FROM postgres;
GRANT ALL ON TABLE pg_user_aggregates TO postgres;
GRANT SELECT ON TABLE pg_user_aggregates TO PUBLIC;


--
-- Name: pg_user_basetype_details; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_basetype_details FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_basetype_details FROM postgres;
GRANT ALL ON TABLE pg_user_basetype_details TO postgres;
GRANT SELECT ON TABLE pg_user_basetype_details TO PUBLIC;


--
-- Name: pg_user_basetypes; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_basetypes FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_basetypes FROM postgres;
GRANT ALL ON TABLE pg_user_basetypes TO postgres;
GRANT SELECT ON TABLE pg_user_basetypes TO PUBLIC;


--
-- Name: pg_user_casts; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_casts FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_casts FROM postgres;
GRANT ALL ON TABLE pg_user_casts TO postgres;
GRANT SELECT ON TABLE pg_user_casts TO PUBLIC;


--
-- Name: pg_user_composite_type_columns; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_composite_type_columns FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_composite_type_columns FROM postgres;
GRANT ALL ON TABLE pg_user_composite_type_columns TO postgres;
GRANT SELECT ON TABLE pg_user_composite_type_columns TO PUBLIC;


--
-- Name: pg_user_composite_types; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_composite_types FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_composite_types FROM postgres;
GRANT ALL ON TABLE pg_user_composite_types TO postgres;
GRANT SELECT ON TABLE pg_user_composite_types TO PUBLIC;


--
-- Name: pg_user_config; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_config FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_config FROM postgres;
GRANT ALL ON TABLE pg_user_config TO postgres;
GRANT SELECT ON TABLE pg_user_config TO PUBLIC;


--
-- Name: pg_user_conversions; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_conversions FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_conversions FROM postgres;
GRANT ALL ON TABLE pg_user_conversions TO postgres;
GRANT SELECT ON TABLE pg_user_conversions TO PUBLIC;


--
-- Name: pg_user_domains; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_domains FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_domains FROM postgres;
GRANT ALL ON TABLE pg_user_domains TO postgres;
GRANT SELECT ON TABLE pg_user_domains TO PUBLIC;


--
-- Name: pg_user_foreign_key_columns; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_foreign_key_columns FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_foreign_key_columns FROM postgres;
GRANT ALL ON TABLE pg_user_foreign_key_columns TO postgres;
GRANT SELECT ON TABLE pg_user_foreign_key_columns TO PUBLIC;


--
-- Name: pg_user_foreign_key_indexes; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_foreign_key_indexes FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_foreign_key_indexes FROM postgres;
GRANT ALL ON TABLE pg_user_foreign_key_indexes TO postgres;
GRANT SELECT ON TABLE pg_user_foreign_key_indexes TO PUBLIC;


--
-- Name: pg_user_foreign_keys; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_foreign_keys FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_foreign_keys FROM postgres;
GRANT ALL ON TABLE pg_user_foreign_keys TO postgres;
GRANT SELECT ON TABLE pg_user_foreign_keys TO PUBLIC;


--
-- Name: pg_user_grants; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_grants FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_grants FROM postgres;
GRANT ALL ON TABLE pg_user_grants TO postgres;
GRANT SELECT ON TABLE pg_user_grants TO PUBLIC;


--
-- Name: pg_user_index_columns; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_index_columns FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_index_columns FROM postgres;
GRANT ALL ON TABLE pg_user_index_columns TO postgres;
GRANT SELECT ON TABLE pg_user_index_columns TO PUBLIC;


--
-- Name: pg_user_indexes; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_indexes FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_indexes FROM postgres;
GRANT ALL ON TABLE pg_user_indexes TO postgres;
GRANT SELECT ON TABLE pg_user_indexes TO PUBLIC;


--
-- Name: pg_user_primary_key_columns; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_primary_key_columns FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_primary_key_columns FROM postgres;
GRANT ALL ON TABLE pg_user_primary_key_columns TO postgres;
GRANT SELECT ON TABLE pg_user_primary_key_columns TO PUBLIC;


--
-- Name: pg_user_relation_column_type_info; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_relation_column_type_info FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_relation_column_type_info FROM postgres;
GRANT ALL ON TABLE pg_user_relation_column_type_info TO postgres;
GRANT SELECT ON TABLE pg_user_relation_column_type_info TO PUBLIC;


--
-- Name: pg_user_relation_columns; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_relation_columns FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_relation_columns FROM postgres;
GRANT ALL ON TABLE pg_user_relation_columns TO postgres;
GRANT SELECT ON TABLE pg_user_relation_columns TO PUBLIC;


--
-- Name: pg_user_relations; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_relations FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_relations FROM postgres;
GRANT ALL ON TABLE pg_user_relations TO postgres;
GRANT SELECT ON TABLE pg_user_relations TO PUBLIC;


--
-- Name: pg_user_rules; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_rules FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_rules FROM postgres;
GRANT ALL ON TABLE pg_user_rules TO postgres;
GRANT SELECT ON TABLE pg_user_rules TO PUBLIC;


--
-- Name: pg_user_schema_contents; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_schema_contents FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_schema_contents FROM postgres;
GRANT ALL ON TABLE pg_user_schema_contents TO postgres;
GRANT SELECT ON TABLE pg_user_schema_contents TO PUBLIC;


--
-- Name: pg_user_schemas; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_schemas FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_schemas FROM postgres;
GRANT ALL ON TABLE pg_user_schemas TO postgres;
GRANT SELECT ON TABLE pg_user_schemas TO PUBLIC;


--
-- Name: pg_user_sequences; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_sequences FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_sequences FROM postgres;
GRANT ALL ON TABLE pg_user_sequences TO postgres;
GRANT SELECT ON TABLE pg_user_sequences TO PUBLIC;


--
-- Name: pg_user_table_check_constraints; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_table_check_constraints FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_table_check_constraints FROM postgres;
GRANT ALL ON TABLE pg_user_table_check_constraints TO postgres;
GRANT SELECT ON TABLE pg_user_table_check_constraints TO PUBLIC;


--
-- Name: pg_user_table_column_type_info; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_table_column_type_info FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_table_column_type_info FROM postgres;
GRANT ALL ON TABLE pg_user_table_column_type_info TO postgres;
GRANT SELECT ON TABLE pg_user_table_column_type_info TO PUBLIC;


--
-- Name: pg_user_table_columns; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_table_columns FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_table_columns FROM postgres;
GRANT ALL ON TABLE pg_user_table_columns TO postgres;
GRANT SELECT ON TABLE pg_user_table_columns TO PUBLIC;


--
-- Name: pg_user_table_constraint_columns; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_table_constraint_columns FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_table_constraint_columns FROM postgres;
GRANT ALL ON TABLE pg_user_table_constraint_columns TO postgres;
GRANT SELECT ON TABLE pg_user_table_constraint_columns TO PUBLIC;


--
-- Name: pg_user_table_constraints; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_table_constraints FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_table_constraints FROM postgres;
GRANT ALL ON TABLE pg_user_table_constraints TO postgres;
GRANT SELECT ON TABLE pg_user_table_constraints TO PUBLIC;


--
-- Name: pg_user_table_inheritance; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_table_inheritance FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_table_inheritance FROM postgres;
GRANT ALL ON TABLE pg_user_table_inheritance TO postgres;
GRANT SELECT ON TABLE pg_user_table_inheritance TO PUBLIC;


--
-- Name: pg_user_tables; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_tables FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_tables FROM postgres;
GRANT ALL ON TABLE pg_user_tables TO postgres;
GRANT SELECT ON TABLE pg_user_tables TO PUBLIC;


--
-- Name: pg_user_tablespace_contents; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_tablespace_contents FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_tablespace_contents FROM postgres;
GRANT ALL ON TABLE pg_user_tablespace_contents TO postgres;
GRANT SELECT ON TABLE pg_user_tablespace_contents TO PUBLIC;


--
-- Name: pg_user_types; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_types FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_types FROM postgres;
GRANT ALL ON TABLE pg_user_types TO postgres;
GRANT SELECT ON TABLE pg_user_types TO PUBLIC;


--
-- Name: pg_user_unique_constraint_columns; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_unique_constraint_columns FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_unique_constraint_columns FROM postgres;
GRANT ALL ON TABLE pg_user_unique_constraint_columns TO postgres;
GRANT SELECT ON TABLE pg_user_unique_constraint_columns TO PUBLIC;


--
-- Name: pg_user_view_column_type_info; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_view_column_type_info FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_view_column_type_info FROM postgres;
GRANT ALL ON TABLE pg_user_view_column_type_info TO postgres;
GRANT SELECT ON TABLE pg_user_view_column_type_info TO PUBLIC;


--
-- Name: pg_user_view_columns; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_view_columns FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_view_columns FROM postgres;
GRANT ALL ON TABLE pg_user_view_columns TO postgres;
GRANT SELECT ON TABLE pg_user_view_columns TO PUBLIC;


--
-- Name: pg_user_views; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_user_views FROM PUBLIC;
REVOKE ALL ON TABLE pg_user_views FROM postgres;
GRANT ALL ON TABLE pg_user_views TO postgres;
GRANT SELECT ON TABLE pg_user_views TO PUBLIC;


--
-- Name: pg_users; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_users FROM PUBLIC;
REVOKE ALL ON TABLE pg_users FROM postgres;
GRANT ALL ON TABLE pg_users TO postgres;
GRANT SELECT ON TABLE pg_users TO PUBLIC;


--
-- Name: pg_view_dependancies; Type: ACL; Schema: dbms_metadata; Owner: postgres
--

REVOKE ALL ON TABLE pg_view_dependancies FROM PUBLIC;
REVOKE ALL ON TABLE pg_view_dependancies FROM postgres;
GRANT ALL ON TABLE pg_view_dependancies TO postgres;
GRANT SELECT ON TABLE pg_view_dependancies TO PUBLIC;


--
-- PostgreSQL database dump complete
--

