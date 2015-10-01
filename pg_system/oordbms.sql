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
-- Name: oordbms; Type: SCHEMA; Schema: -; Owner: oordbms
--

CREATE SCHEMA oordbms;


ALTER SCHEMA oordbms OWNER TO oordbms;

--
-- Name: SCHEMA oordbms; Type: COMMENT; Schema: -; Owner: oordbms
--

COMMENT ON SCHEMA oordbms IS 'Object-oriented approach';


SET search_path = oordbms, pg_catalog;

--
-- Name: cardinal; Type: DOMAIN; Schema: oordbms; Owner: oordbms
--

CREATE DOMAIN cardinal AS integer
	CONSTRAINT cardinal_check CHECK ((VALUE >= 0));


ALTER DOMAIN cardinal OWNER TO oordbms;

--
-- Name: method; Type: DOMAIN; Schema: oordbms; Owner: oordbms
--

CREATE DOMAIN method AS text;


ALTER DOMAIN method OWNER TO oordbms;

--
-- Name: nid; Type: DOMAIN; Schema: oordbms; Owner: oordbms
--

CREATE DOMAIN nid AS integer;


ALTER DOMAIN nid OWNER TO oordbms;

--
-- Name: DOMAIN nid; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON DOMAIN nid IS 'Numerical id';


--
-- Name: set_json_values_mode; Type: TYPE; Schema: oordbms; Owner: postgres
--

CREATE TYPE set_json_values_mode AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'SET'
);


ALTER TYPE set_json_values_mode OWNER TO postgres;

--
-- Name: sql_expression; Type: DOMAIN; Schema: oordbms; Owner: oordbms
--

CREATE DOMAIN sql_expression AS text;


ALTER DOMAIN sql_expression OWNER TO oordbms;

--
-- Name: DOMAIN sql_expression; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON DOMAIN sql_expression IS 'SQL expression, which can be evaluated as a scalar';


--
-- Name: sql_expressions; Type: DOMAIN; Schema: oordbms; Owner: oordbms
--

CREATE DOMAIN sql_expressions AS text[];


ALTER DOMAIN sql_expressions OWNER TO oordbms;

--
-- Name: sql_identifier; Type: DOMAIN; Schema: oordbms; Owner: oordbms
--

CREATE DOMAIN sql_identifier AS text;


ALTER DOMAIN sql_identifier OWNER TO oordbms;

--
-- Name: DOMAIN sql_identifier; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON DOMAIN sql_identifier IS 'SQL object identifier';


--
-- Name: sql_name; Type: DOMAIN; Schema: oordbms; Owner: oordbms
--

CREATE DOMAIN sql_name AS text;


ALTER DOMAIN sql_name OWNER TO oordbms;

--
-- Name: DOMAIN sql_name; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON DOMAIN sql_name IS 'SQL object name';


--
-- Name: sql_statement; Type: DOMAIN; Schema: oordbms; Owner: oordbms
--

CREATE DOMAIN sql_statement AS text;


ALTER DOMAIN sql_statement OWNER TO oordbms;

--
-- Name: DOMAIN sql_statement; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON DOMAIN sql_statement IS 'SQL query statement';


--
-- Name: stereotype; Type: TYPE; Schema: oordbms; Owner: postgres
--

CREATE TYPE stereotype AS ENUM (
    'schema',
    'table',
    'view',
    'query',
    'type',
    'enum',
    'class',
    'method',
    'function',
    'interface'
);


ALTER TYPE stereotype OWNER TO postgres;

--
-- Name: thing; Type: TYPE; Schema: oordbms; Owner: postgres
--

CREATE TYPE thing AS (
	title text,
	description text,
	image text,
	iri text,
	data json,
	section text
);


ALTER TYPE thing OWNER TO postgres;

--
-- Name: uri; Type: DOMAIN; Schema: oordbms; Owner: oordbms
--

CREATE DOMAIN uri AS text;


ALTER DOMAIN uri OWNER TO oordbms;

--
-- Name: DOMAIN uri; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON DOMAIN uri IS 'Universal Resource Locator (web address)';


--
-- Name: $atom_touch(); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION "$atom_touch"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$declare
 r integer;
begin
 if TG_OP in ('INSERT','UPDATE') then
  NEW.mtime=now();
 end if;
 return NEW;
end$$;


ALTER FUNCTION oordbms."$atom_touch"() OWNER TO postgres;

--
-- Name: $class_isa_$atom(); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION "$class_isa_$atom"() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$declare
 r integer;
 my_iri text;
 my_nid oordbms.nid;
begin
 if TG_OP in ('INSERT','UPDATE') then
  my_iri:='/'||current_database()||
          '/'||oordbms.esc_uri(NEW.schema_name)||
          '/'||oordbms.esc_uri(NEW.class_name)||'/';
  raise notice '$class ISA $atom(%)',my_iri;

  select into my_nid id from "$atom" where iri=my_iri;
  if not found then
   NEW.id:=oordbms.nid();
   insert into oordbms.resource (id,iri,stereotype) values (NEW.id,my_iri,'class');
  else
   NEW.id:=my_id;
   update oordbms.resource set iri=my_iri,stereotype='class' where id=NEW.id;
  end if;

  return NEW;
 end if;

 IF TG_OP = 'DELETE' THEN
  delete from oordbms.resource where id=OLD.id;
  RETURN OLD;
 END IF;

 return OLD;
end$_$;


ALTER FUNCTION oordbms."$class_isa_$atom"() OWNER TO postgres;

--
-- Name: $class_refresh(); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION "$class_refresh"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
 regclass oid;
 rows NUMERIC;
BEGIN 
 regclass := NULL;
 IF TG_OP = 'INSERT' THEN
  IF NEW.search_expression IS NOT NULL THEN 
   regclass := NEW.regclass::oid; 
  END IF;
 END IF;

 IF TG_OP = 'UPDATE' THEN
   IF NEW.search_expression IS NOT NULL THEN
     IF OLD.search_expression IS NOT NULL THEN
       IF NEW.search_expression <> OLD.search_expression 
         OR NEW.label_expression <> OLD.label_expression
       THEN regclass := NEW.regclass::oid; END IF;
     ELSE
       regclass := NEW.regclass::oid;
     END IF;
   ELSE
     IF OLD.search_expression IS NOT NULL THEN
       DELETE FROM oordbms_data.search WHERE regclass = OLD.regclass;
     END IF;
   END IF;
 END IF;

 IF TG_OP = 'DELETE' THEN
   DELETE FROM oordbms_data.search WHERE regclass = OLD.regclass;
 END IF;

 IF regclass IS NOT NULL THEN
   SELECT INTO rows oordbms.execute(sql_advice) 
     FROM oordbms.search_updates su
     WHERE su.regclass=NEW.regclass;
   RAISE NOTICE 'tsearch index update: %',rows;
 END IF;

 IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
  RETURN NEW; 
 ELSE
  RETURN OLD; 
 END IF;

END; 
$$;


ALTER FUNCTION oordbms."$class_refresh"() OWNER TO postgres;

--
-- Name: $class_touch(); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION "$class_touch"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
 oid regclass;
 q text;
 oordbms_trigger name;
 r text;
BEGIN 
 oordbms_trigger := 'oordbms_undo_trigger';
 NEW.regclass := oordbms.regclass(NEW.schema_name,NEW.class_name);
 IF NEW.regclass IS NULL THEN
  RAISE WARNING 'Class not found';
 ELSE

-- Check syntax of SQL expressions

  NEW.label_expression := coalesce(NEW.label_expression,oordbms.sql_def_label(NEW.regclass));
  q := ' SELECT ' || NEW.label_expression || 

-- search is broken, sorry
--     coalesce(', ' || NEW.search_expression, '') ||
       ' FROM ' || oordbms.ref(NEW.regclass) ||
       coalesce(' ORDER BY ' || NEW.order_expression, '') ||
       ' LIMIT 1'; 
  EXECUTE q;

  IF NEW.group_expressions[1] IS NOT NULL THEN
   q := ' SELECT ' || NEW.group_expressions[1] || ',count(*) ' || 
        ' FROM ' || oordbms.ref(NEW.regclass) ||
        ' GROUP BY ' || NEW.group_expressions[1];
   EXECUTE q;
  END IF;

 IF NEW."hasUndo" THEN
   SELECT INTO q trigger_name 
          FROM oordbms.triggers 
         WHERE trigger_name=oordbms_trigger 
           AND regclass=NEW.regclass;

   IF NOT FOUND THEN
     q := ' CREATE TRIGGER ' || quote_ident(oordbms_trigger) || 
          ' BEFORE INSERT OR UPDATE OR DELETE ON ' || oordbms.ref(NEW.regclass) ||
          ' FOR EACH ROW EXECUTE PROCEDURE oordbms.changelog_trigger() ';
     EXECUTE q;
   END IF;

 ELSE
    SELECT INTO r oordbms.execute('DROP TRIGGER '||quote_ident(trigger_name)||' ON '||oordbms.ref(regclass))
    FROM oordbms.triggers
    WHERE trigger_name=oordbms_trigger
    AND regclass=NEW.regclass;
 END IF;

 END IF;

 NOTIFY oordbms;
 RETURN NEW; 
END; 
$$;


ALTER FUNCTION oordbms."$class_touch"() OWNER TO postgres;

--
-- Name: bless(regclass, regclass); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION bless(regclass, regclass) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$
declare 
 subclass alias for $1; 
 superclass alias for $2; 
 sql_statement text; 
 isa_proc text; 
begin 
 isa_proc := oordbms.sql_identifier(oordbms.sql_schema(subclass),
                                    oordbms.sql_class(subclass)||'_isa_'||oordbms.sql_class(superclass))||'()'; 
 
 sql_statement := 
 'create trigger "_ISA" '|| 
 ' before insert on '||oordbms.sql_identifier(subclass)|| 
 ' for each row execute procedure '||isa_proc||' ;\n'|| 
 'create trigger "_ISA~" '|| 
 ' after delete on '||oordbms.sql_identifier(subclass)|| 
 ' for each row execute procedure '||isa_proc||' ;\n'|| 
 'update '||oordbms.sql_identifier(subclass)||' set nid=nid;\n'|| 
 'alter table '||oordbms.sql_identifier(subclass)||' add constraint "_ISA"'|| 
 ' foreign key (nid) references '||oordbms.sql_identifier(superclass)|| 
 ' on update cascade on delete cascade '|| 
 ' deferrable initially deferred ;\n'
 ; 
 
 perform oordbms.execute(sql_statement); 
 return sql_statement; 
end$_$;


ALTER FUNCTION oordbms.bless(regclass, regclass) OWNER TO postgres;

--
-- Name: FUNCTION bless(regclass, regclass); Type: COMMENT; Schema: oordbms; Owner: postgres
--

COMMENT ON FUNCTION bless(regclass, regclass) IS 'Create triggers on a subclass';


--
-- Name: data_get_json_values(text, text, json); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION data_get_json_values(namespace text, name text, key json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
 q text;
 qi text;
 j text;
begin
 q := 'select row_to_json(r) ' ||
       '  from ' || oordbms.sql_identifier(namespace,name) || ' as r ' ||
       ' where ' || oordbms.sql_json_where(key) ||
       ' limit 1';

 execute q
    into j;

 return j;
end
$$;


ALTER FUNCTION oordbms.data_get_json_values(namespace text, name text, key json) OWNER TO postgres;

--
-- Name: FUNCTION data_get_json_values(namespace text, name text, key json); Type: COMMENT; Schema: oordbms; Owner: postgres
--

COMMENT ON FUNCTION data_get_json_values(namespace text, name text, key json) IS 'Get object attribute values';


--
-- Name: data_set_json_values(text, text, json, set_json_values_mode, json); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION data_set_json_values(namespace text, name text, key json, mode set_json_values_mode, data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
 q text;
 qi text;
 j text;
 n text;
 w text;
 r record;
begin
 n := oordbms.sql_identifier(namespace,name);
 w := oordbms.sql_json_where(key);

 if mode = 'UPDATE' then
 q := 'update ' || n || E'\n' ||
      ' set ' || oordbms.sql_json_set(data) || E'\n' ||
      ' where ' || w || E'\n' ||
      ' returning *';
 end if;

 if q is null then
 q := 'select row_to_json(r) ' || E'\n' ||
       '  from ' || n || ' as r ' || E'\n' ||
       ' where ' || w || E'\n' ||
       ' limit 1';
 end if;

 execute q
    into r;
 j := row_to_json(r);

 return j;
end
$$;


ALTER FUNCTION oordbms.data_set_json_values(namespace text, name text, key json, mode set_json_values_mode, data json) OWNER TO postgres;

--
-- Name: FUNCTION data_set_json_values(namespace text, name text, key json, mode set_json_values_mode, data json); Type: COMMENT; Schema: oordbms; Owner: postgres
--

COMMENT ON FUNCTION data_set_json_values(namespace text, name text, key json, mode set_json_values_mode, data json) IS 'Set object attribute values';


--
-- Name: db_functions_trigger(); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION db_functions_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
 q text;
begin
  if tg_op = 'INSERT' then
    raise exception 'Not implemented';
  end if; 

  if tg_op = 'UPDATE' then
    if old.definition is distinct from new.definition then
      q :=
       'create or replace function '||old.sql_identifier||
       ' returns '||(case when old.retset then 'setof ' else '' end)||old.returns||
       ' language '||new.language||
       ' as '||quote_literal(new.definition);
      execute q;
    end if;
    if old.description is distinct from new.description then
      q :=
       'comment on function '||old.sql_identifier||
       ' is '||quote_nullable(new.description);
      execute q;
    end if;
    if old.name is distinct from new.name then
      q :=
       'alter function '||old.sql_identifier||
       ' rename to '||quote_ident(new.name);
      execute q;
    end if;
    return new;
  end if; 

  if tg_op = 'UPDATE' then
    raise exception 'Not implemented';
  end if; 
end
$$;


ALTER FUNCTION oordbms.db_functions_trigger() OWNER TO postgres;

--
-- Name: esc_uri(text); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION esc_uri(in_str text, OUT _result text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
DECLARE
    _i      int4;
    _temp   varchar;
    _ascii  int4;
BEGIN
    _result = '';
    FOR _i IN 1 .. length(in_str) LOOP
        _temp := substr(in_str, _i, 1);
        IF _temp ~ '[0-9a-zA-Z:/@._?#-]+' THEN
            _result := _result || _temp;
        ELSE
            _ascii := ascii(_temp);
            IF _ascii > x'07ff'::int4 THEN
                RAISE EXCEPTION 'Won''t deal with 3 (or more) byte sequences.';
            END IF;
            IF _ascii <= x'07f'::int4 THEN
                _temp := '%'||to_hex(_ascii);
            ELSE
                _temp := '%'||to_hex((_ascii & x'03f'::int4)+x'80'::int4);
                _ascii := _ascii >> 6;
                _temp := '%'||to_hex((_ascii & x'01f'::int4)+x'c0'::int4)
                            ||_temp;
            END IF;
            _result := _result || upper(_temp);
        END IF;
    END LOOP;
    RETURN ;
END;
$$;


ALTER FUNCTION oordbms.esc_uri(in_str text, OUT _result text) OWNER TO postgres;

--
-- Name: FUNCTION esc_uri(in_str text, OUT _result text); Type: COMMENT; Schema: oordbms; Owner: postgres
--

COMMENT ON FUNCTION esc_uri(in_str text, OUT _result text) IS 'URI string escape';


--
-- Name: execute(sql_statement); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION execute(sql_statement sql_statement) RETURNS integer
    LANGUAGE plpgsql STRICT
    AS $_$DECLARE 
   body ALIAS FOR $1; 
   result INT; 
 BEGIN 
   RAISE NOTICE 'Execute: %', body; 
   EXECUTE body; 
   GET DIAGNOSTICS result = ROW_COUNT; 
   RETURN result; 
 END; 
 $_$;


ALTER FUNCTION oordbms.execute(sql_statement sql_statement) OWNER TO postgres;

--
-- Name: FUNCTION execute(sql_statement sql_statement); Type: COMMENT; Schema: oordbms; Owner: postgres
--

COMMENT ON FUNCTION execute(sql_statement sql_statement) IS 'Execute SQL statement';


--
-- Name: get_class_info(text, text); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION get_class_info(namespace text, name text, OUT sysid oid, OUT sql_identifier text, OUT names text[], OUT types text[], OUT primary_key text[], OUT comment text, OUT has_http_acl boolean, OUT references_to json, OUT referenced_by json) RETURNS record
    LANGUAGE plpgsql
    AS $$
declare 
 p  record;
 pa record;
 c  record;
 r  record;
begin

 begin
   sysid := regclass(oordbms.sql_identifier(namespace,name))::oid;
   sql_identifier := regclass(sysid)::text;
   exception when others then
   return;
 end;
 
 select * 
   from pg_class
  where pg_class.oid = get_class_info.sysid	
   into p;
   
 select * 
   from oordbms.db_class_details d
  where d.sysid = get_class_info.sysid	
   into c;

   primary_key := c.primary_key;

 select array_agg(ca.name),array_agg(ca.type) 
   from oordbms.pg_get_columns(sysid) ca
   into names,types;

 select exists (
   select a
    from unnest(p.relacl) as a
   where a::text like 'http=%X%/%'
 ) into has_http_acl;

 comment := obj_description(sysid);

 select json_agg(data)
   from oordbms.get_class_references(sysid)
   into references_to;

 select json_agg(data)
   from oordbms.get_class_referenced_by(sysid)
   into referenced_by;

 return;
end
$$;


ALTER FUNCTION oordbms.get_class_info(namespace text, name text, OUT sysid oid, OUT sql_identifier text, OUT names text[], OUT types text[], OUT primary_key text[], OUT comment text, OUT has_http_acl boolean, OUT references_to json, OUT referenced_by json) OWNER TO postgres;

--
-- Name: get_class_referenced_by(regclass); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION get_class_referenced_by(myclass regclass) RETURNS SETOF thing
    LANGUAGE sql
    AS $_$
with q as (
select sysid::regclass::text||' '||(conkey::text) as title,
       sysid::regclass::text as sql_identifier,
       oordbms.sql_def_label(sysid) as label_expression,
       order_expression,
       constraint_name,
       count_estimate,
       conkey,
       confkey,
       c.description
  from oordbms.db_foreign_keys
  join oordbms.db_class c using (sysid)
 where ref_sysid = $1
 order by namespace,name
)
select sql_identifier||' '||(conkey::text)||' '||quote_ident(constraint_name)||coalesce(' <tt>('||label_expression||')</tt>','') as title,
       description,
       null::text as image,
       null::text as iri,
       row_to_json(q) as data,
       null::text as section
  from q;
$_$;


ALTER FUNCTION oordbms.get_class_referenced_by(myclass regclass) OWNER TO postgres;

--
-- Name: get_class_references(regclass); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION get_class_references(myclass regclass) RETURNS SETOF thing
    LANGUAGE sql
    AS $_$
with q as (
select ref_sysid::regclass::text||' '||(confkey::text) as title,
       ref_sysid::regclass::text as sql_identifier,
       oordbms.sql_def_label(ref_sysid) as label_expression,
       order_expression,
       constraint_name,
       count_estimate,
       conkey,
       confkey,
       c.description
  from oordbms.db_foreign_keys f
  join oordbms.db_class c on (c.sysid=f.ref_sysid)
 where f.sysid = $1
 order by namespace,name
)
select title||' '||quote_ident(constraint_name)||coalesce(' <tt>('||label_expression||')</tt>','') as title,
       description,
       null::text as image,
       null::text as iri,
       row_to_json(q) as data,
       null::text as section
  from q;
$_$;


ALTER FUNCTION oordbms.get_class_references(myclass regclass) OWNER TO postgres;

--
-- Name: get_proc_info(text, text); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION get_proc_info(namespace text, name text, OUT sysid oid, OUT sql_identifier text, OUT argnames text[], OUT argtypes text[], OUT comment text, OUT has_http_acl boolean) RETURNS record
    LANGUAGE plpgsql
    AS $$
declare 
 p  record;
 pa record;
 r  record;
begin

 begin
   sysid := regproc(oordbms.sql_identifier(namespace,name))::oid;
   sql_identifier := regproc(sysid)::text;
 exception when others then
   return;
 end;
 
 select * 
   from pg_proc
  where pg_proc.oid = sysid	
   into p;
   
 if p.proargmodes is not null then
  select array_agg(p.proargnames[i]) as iproargnames
  from (
    select i, p.proargmodes[i] as mode
      from generate_series(1,array_length(p.proargmodes,1)) i
     where p.proargmodes[i] in ('i','b')
  ) as pam 
  into pa;
  argnames := pa.iproargnames;
 else
  argnames := p.proargnames;
 end if;

 select array_agg(typ)
 from ( 
   select at::regtype::text as typ
     from unnest(p.proargtypes) as at
 ) as at1 
 into argtypes;

 select exists (
   select a
    from unnest(p.proacl) as a
   where a::text like 'http=%X%/%'
 ) into has_http_acl;

 comment := obj_description(sysid);

 return;
end
$$;


ALTER FUNCTION oordbms.get_proc_info(namespace text, name text, OUT sysid oid, OUT sql_identifier text, OUT argnames text[], OUT argtypes text[], OUT comment text, OUT has_http_acl boolean) OWNER TO postgres;

--
-- Name: FUNCTION get_proc_info(namespace text, name text, OUT sysid oid, OUT sql_identifier text, OUT argnames text[], OUT argtypes text[], OUT comment text, OUT has_http_acl boolean); Type: COMMENT; Schema: oordbms; Owner: postgres
--

COMMENT ON FUNCTION get_proc_info(namespace text, name text, OUT sysid oid, OUT sql_identifier text, OUT argnames text[], OUT argtypes text[], OUT comment text, OUT has_http_acl boolean) IS 'Inquire about a function';


--
-- Name: human_label(text, text, text, text); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION human_label(simplelabel text, stererotype text, iri text, owner text) RETURNS xml
    LANGUAGE sql IMMUTABLE
    AS $_$
  select 
    xmlelement(name li, 
     coalesce('«' || $2 || '» '::text,''), 
     xmlelement(name a, 
       xmlattributes('?iri='::text || $3 as href, $3 as target), 
       $1
      ),
      coalesce(' by '||$4)
     ) as label
$_$;


ALTER FUNCTION oordbms.human_label(simplelabel text, stererotype text, iri text, owner text) OWNER TO postgres;

--
-- Name: iri(json); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION iri(data json) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
with q as (
select oordbms.esc_uri(key)||'='||oordbms.esc_uri(value) as item
  from json_each_text($1) as j
 where value is not null
 order by key
)
select string_agg(item,'&')
  from q
$_$;


ALTER FUNCTION oordbms.iri(data json) OWNER TO postgres;

--
-- Name: iri_pkey_expression(regclass); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION iri_pkey_expression(regclass) RETURNS text
    LANGUAGE sql
    AS $_$SELECT 
           '''' || 
           substr( 
            string_agg( 
             '||' || quote_literal('&'||oordbms.esc_uri(name)||'=') || 
             '||oordbms.esc_uri(text('||quote_ident(name)||'))', ''
            ),5) 
FROM ( 
 SELECT name
 FROM oordbms.pg_get_columns($1)
 WHERE primary_key IS NOT NULL
 ORDER BY ord
) AS R 
$_$;


ALTER FUNCTION oordbms.iri_pkey_expression(regclass) OWNER TO postgres;

--
-- Name: list_functions(text); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION list_functions(search text) RETURNS SETOF thing
    LANGUAGE plpgsql
    AS $_$
begin
 return query
 select q.sql_identifier::text,
        q.description,
        null::text as image,
        'data:/oordbms/db_functions?sysid='||q.sysid as iri,
        null::json as data,
        namespace::text as section
   from oordbms.db_functions q
  where sql_identifier ilike '%'||$1||'%'
     or definition ilike '%'||$1||'%'
  order by namespace,name;
end
$_$;


ALTER FUNCTION oordbms.list_functions(search text) OWNER TO postgres;

--
-- Name: FUNCTION list_functions(search text); Type: COMMENT; Schema: oordbms; Owner: postgres
--

COMMENT ON FUNCTION list_functions(search text) IS 'List or search for functions';


--
-- Name: list_namespaces(); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION list_namespaces() RETURNS TABLE(label xml, namespace text, owner text, sysid oid, description text)
    LANGUAGE sql
    AS $$
 SELECT 
    oordbms.label(s.nspname, 'schema', 
    'data:/oordbms/list_queries&action&search='||s.nspname||'.' , 
    r.rolname) as label,
    s.nspname::text AS namespace,
    r.rolname::text AS owner, 
    s.oid AS sysid, c.description 
   FROM pg_namespace s
   JOIN pg_roles r ON r.oid = s.nspowner
   LEFT JOIN pg_description c ON c.objoid = s.oid
  WHERE has_schema_privilege("current_user"(), s.oid, 'usage'::text) AND s.nspname !~~ 'pg_t%'::text
  ORDER BY nspname
$$;


ALTER FUNCTION oordbms.list_namespaces() OWNER TO postgres;

--
-- Name: FUNCTION list_namespaces(); Type: COMMENT; Schema: oordbms; Owner: postgres
--

COMMENT ON FUNCTION list_namespaces() IS 'List all user accessible namespaces';


--
-- Name: list_objects(); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION list_objects(OUT section_title text, OUT text text, OUT detail_text text, OUT iri text) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
begin
  return query
  select c.namespace as section_title,
         oordbms.human_label(sql_identifier,stereotype,null,owner)::text as text, 
         c.description as detail_text,
         'data:/oordbms/db_class?sysid='||c.sysid as iri
    from oordbms.db_class c
   where has_schema_privilege(c.namespace,'usage')
     and has_table_privilege(c.sysid, 'select, insert, update, delete');
end
$$;


ALTER FUNCTION oordbms.list_objects(OUT section_title text, OUT text text, OUT detail_text text, OUT iri text) OWNER TO postgres;

--
-- Name: list_queries(text); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION list_queries(search text) RETURNS SETOF thing
    LANGUAGE plpgsql
    AS $_$
begin
if search is not null and length(search)>0 then 
 return query
 select q.label::text,
        q.description,
        null::text as image,
        null::text as iri,
        null::json as data,
        query_namespace::text as section
   from oordbms.pg_query_proc q
  where sql_identifier ilike '%'||$1||'%'
     or query_definition ilike '%'||$1||'%'
  order by query_namespace,query_name;
 else
 return query
 select q.label::text,
        q.description,
        null::text as image,
        null::text as iri,
        null::json as data,
        query_namespace::text as section
   from oordbms.pg_query_proc q
  where query_namespace = any (current_schemas(false))
  order by query_namespace,query_name;
 end if; 
end
$_$;


ALTER FUNCTION oordbms.list_queries(search text) OWNER TO postgres;

--
-- Name: FUNCTION list_queries(search text); Type: COMMENT; Schema: oordbms; Owner: postgres
--

COMMENT ON FUNCTION list_queries(search text) IS 'List or search for runnable queries';


--
-- Name: nid(); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION nid() RETURNS nid
    LANGUAGE sql
    AS $$select nextval('oordbms.seq')::oordbms.nid$$;


ALTER FUNCTION oordbms.nid() OWNER TO postgres;

--
-- Name: FUNCTION nid(); Type: COMMENT; Schema: oordbms; Owner: postgres
--

COMMENT ON FUNCTION nid() IS 'Generate new unique id';


--
-- Name: pg_attribute_names(regclass, smallint[]); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION pg_attribute_names(regclass, smallint[]) RETURNS name[]
    LANGUAGE sql STABLE
    AS $_$
select array_agg(column_name::name)
from (
 select 
  a.attname as column_name
 from pg_attribute a
 join unnest($2) unnest(i) on (i=a.attnum)
 where a.attrelid=$1
) as n
$_$;


ALTER FUNCTION oordbms.pg_attribute_names(regclass, smallint[]) OWNER TO postgres;

--
-- Name: pg_attribute_types(regclass, smallint[]); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION pg_attribute_types(regclass, smallint[]) RETURNS text[]
    LANGUAGE sql STABLE
    AS $_$
select array_agg(column_type::text)
from (
 select 
  a.attname as column_name,
  format_type(a.atttypid,NULL) as column_type
 from pg_attribute a
 join unnest($2) unnest(i) on (i=a.attnum)
 where a.attrelid=$1
) as n
$_$;


ALTER FUNCTION oordbms.pg_attribute_types(regclass, smallint[]) OWNER TO postgres;

--
-- Name: pg_get_args(pg_proc); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION pg_get_args(p pg_proc, OUT argnames text[], OUT argtypes text[]) RETURNS record
    LANGUAGE plpgsql
    AS $$
declare 
 pa record;
 r  record;
begin
 if p.proargmodes is not null then
  select array_agg(p.proargnames[i]) as iproargnames
  from (
    select i, p.proargmodes[i] as mode
      from generate_series(1,array_length(p.proargmodes,1)) i
     where p.proargmodes[i] in ('i','b')
  ) as pam 
  into pa;
  argnames := pa.iproargnames;
 else
  argnames := p.proargnames;
 end if;

 select array_agg(typ)
 from ( 
   select at::regtype::text as typ
     from unnest(p.proargtypes) as at
 ) as at1 
 into argtypes;

 return;
end
$$;


ALTER FUNCTION oordbms.pg_get_args(p pg_proc, OUT argnames text[], OUT argtypes text[]) OWNER TO postgres;

--
-- Name: FUNCTION pg_get_args(p pg_proc, OUT argnames text[], OUT argtypes text[]); Type: COMMENT; Schema: oordbms; Owner: postgres
--

COMMENT ON FUNCTION pg_get_args(p pg_proc, OUT argnames text[], OUT argtypes text[]) IS 'Deobfuscate function arguments';


--
-- Name: pg_get_colnames(regclass, smallint[]); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION pg_get_colnames(relation regclass, indices smallint[]) RETURNS text[]
    LANGUAGE sql
    AS $_$
with q as (
select i, indices[i] as ai
  from generate_series(1,array_upper(indices,1)) i
 order by i
)
select array_agg(attname::text)
  from (
  select a.attname
    from q,
         pg_attribute a
   where a.attrelid = $1 and a.attnum = ai
   order by i
  ) qq
$_$;


ALTER FUNCTION oordbms.pg_get_colnames(relation regclass, indices smallint[]) OWNER TO postgres;

--
-- Name: pg_get_columns(regclass); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION pg_get_columns(regclass, OUT name name, OUT type text, OUT size integer, OUT not_null boolean, OUT "default" text, OUT comment text, OUT primary_key name, OUT is_local boolean, OUT attstorage text, OUT ord smallint, OUT namespace name, OUT class_name name, OUT sql_identifier sql_identifier, OUT nuls boolean, OUT regclass oid, OUT definition text) RETURNS SETOF record
    LANGUAGE sql
    AS $_$
 SELECT a.attname AS name, format_type(t.oid, NULL::integer) AS type, 
        CASE
            WHEN (a.atttypmod - 4) > 0 THEN a.atttypmod - 4
            ELSE NULL::integer
        END AS size, a.attnotnull AS not_null, def.adsrc AS "default", 
	col_description(c.oid, a.attnum::integer) AS comment, 
        con.conname AS primary_key, 
        a.attislocal AS is_local, a.attstorage::text, a.attnum AS ord, s.nspname AS namespace, 
        c.relname AS class_name, 
        ((c.oid::regclass)::text || '.' || quote_ident(a.attname))::oordbms.sql_identifier AS sql_identifier,
        CASE t.typname
            WHEN 'numeric'::name THEN false
            WHEN 'bool'::name THEN false
            ELSE true
        END AS nuls, 
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
  WHERE (c.relkind = ANY (ARRAY['r'::"char", 'v'::"char", ''::"char", 'c'::"char"])) AND a.attnum > 0 
  AND NOT a.attisdropped AND has_table_privilege(c.oid, 'select'::text) AND has_schema_privilege(s.oid, 'usage'::text)
  AND c.oid = $1
  ORDER BY s.nspname, c.relname, a.attnum;
$_$;


ALTER FUNCTION oordbms.pg_get_columns(regclass, OUT name name, OUT type text, OUT size integer, OUT not_null boolean, OUT "default" text, OUT comment text, OUT primary_key name, OUT is_local boolean, OUT attstorage text, OUT ord smallint, OUT namespace name, OUT class_name name, OUT sql_identifier sql_identifier, OUT nuls boolean, OUT regclass oid, OUT definition text) OWNER TO postgres;

--
-- Name: FUNCTION pg_get_columns(regclass, OUT name name, OUT type text, OUT size integer, OUT not_null boolean, OUT "default" text, OUT comment text, OUT primary_key name, OUT is_local boolean, OUT attstorage text, OUT ord smallint, OUT namespace name, OUT class_name name, OUT sql_identifier sql_identifier, OUT nuls boolean, OUT regclass oid, OUT definition text); Type: COMMENT; Schema: oordbms; Owner: postgres
--

COMMENT ON FUNCTION pg_get_columns(regclass, OUT name name, OUT type text, OUT size integer, OUT not_null boolean, OUT "default" text, OUT comment text, OUT primary_key name, OUT is_local boolean, OUT attstorage text, OUT ord smallint, OUT namespace name, OUT class_name name, OUT sql_identifier sql_identifier, OUT nuls boolean, OUT regclass oid, OUT definition text) IS 'Table columns';


--
-- Name: pg_get_primary_key(regclass); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION pg_get_primary_key(regclass) RETURNS text[]
    LANGUAGE sql
    AS $_$SELECT 
 case 
 when count(*) > 0 then array_agg(name::text)
 end
FROM ( 
 SELECT name
 FROM oordbms.pg_get_columns($1)
 WHERE primary_key IS NOT NULL
 ORDER BY ord
) AS R 
$_$;


ALTER FUNCTION oordbms.pg_get_primary_key(regclass) OWNER TO postgres;

--
-- Name: FUNCTION pg_get_primary_key(regclass); Type: COMMENT; Schema: oordbms; Owner: postgres
--

COMMENT ON FUNCTION pg_get_primary_key(regclass) IS 'Return primary key for a table as an array of column names';


--
-- Name: pg_get_queries(); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION pg_get_queries(OUT oid oid, OUT regclass regclass, OUT stereotype text, OUT sql_identifier text, OUT owner name, OUT namespace name, OUT name name, OUT language text, OUT argnames text[], OUT argtypes text[], OUT description text, OUT has_http_acl boolean, OUT body text, OUT sql_ddl text) RETURNS SETOF record
    LANGUAGE sql
    AS $$
WITH pg_query AS (
 SELECT 
  q.oid, q.regclass, q.stereotype, q.sql_identifier, 
  r.rolname AS owner, n.nspname AS namespace, q.name, 
  q.language, q.argnames, q.argtypes, q.description, 
  (EXISTS ( SELECT a.a FROM unnest(q.acl) a(a) WHERE a.a::text ~~ 'http=%X%/%'::text)) 
   AS has_http_acl, 
  q.body, 
  CAST(
   ('-- Name: '::text || q.name::text || '; Type: '::text || q.stereotype || 
    '; Schema: '::text || n.nspname::text || '; Owner: '::text || r.rolname::text || E'\n\n'::text
   ) || 
   ('-- DROP '::text || q.stereotype || ' IF EXISTS '::text || q.sql_identifier || E';\n\n') ||
   (q.sql_ddl || E';\n\n') ||
   ('ALTER '::text || q.stereotype || ' '::text || q.sql_identifier || 
' OWNER TO '::text || quote_ident(r.rolname::text) || E';\n\n'::text ) ||
   COALESCE(
    'COMMENT ON '::text || q.stereotype || ' '::text || q.sql_identifier || 
    ' IS '::text || quote_literal(q.description) || E';\n'::text, 
   '') AS text) 
    AS sql_ddl
 FROM (         
  SELECT 	
   c.oid, 'pg_class'::regclass AS regclass, 'VIEW'::text AS stereotype, c.oid::regclass::text AS sql_identifier, 
   c.relname AS name, 'sql'::text AS language, obj_description(c.oid, 'pg_class'::name) AS description, 
   pg_get_viewdef(c.oid, true) AS body, 
   cast('CREATE OR REPLACE VIEW '::text || c.oid::regclass::text || E' AS \n'::text || pg_get_viewdef(c.oid, true) 
    AS text) AS sql_ddl, 
   c.relacl AS acl, c.relowner AS _owner, c.relnamespace AS _namespace, 
   NULL::text[] AS argnames, NULL::text[] AS argtypes
  FROM pg_class c
  WHERE c.relkind = 'v'::char AND has_table_privilege(c.oid, 'select'::text)
  UNION ALL 
  SELECT
   p.oid, 'pg_proc'::regclass AS regclass, 'FUNCTION'::text AS stereotype, p.oid::regprocedure::text AS sql_identifier, 
   p.proname AS name, l.lanname AS language, obj_description(p.oid, 'pg_proc'::name) AS description, 
   p.prosrc AS body, pg_get_functiondef(p.oid) AS sql_ddl, 
   p.proacl AS acl, p.proowner AS _owner, p.pronamespace AS _namespace, 
   (
    SELECT array_agg(p.proargnames[pam.i]) AS array_agg
    FROM ( SELECT i.i, p.proargmodes[i.i] AS mode
     FROM generate_series(1, array_length(p.proargmodes, 1)) i(i) WHERE p.proargmodes[i.i] IN ('i','b')
    ) AS pam
   ) AS argnames, 
   ( 
    SELECT array_agg(((('{'::text || oidvectortypes(p.proargtypes)) || '}'::text)::text[])[pam.i]) AS array_agg
    FROM ( SELECT i.i, p.proargmodes[i.i] AS mode
     FROM generate_series(1, array_length(p.proargmodes, 1)) i(i) WHERE p.proargmodes[i.i] IN ('i','b')
    ) AS pam
   ) AS argtypes
  FROM pg_proc p
  JOIN pg_language l ON l.oid = p.prolang
  WHERE p.proretset AND has_function_privilege(p.oid, 'execute'::text)
 ) AS q
 JOIN pg_roles r ON r.oid = q._owner
 JOIN pg_namespace n ON n.oid = q._namespace
)

SELECT
 *
FROM pg_query
$$;


ALTER FUNCTION oordbms.pg_get_queries(OUT oid oid, OUT regclass regclass, OUT stereotype text, OUT sql_identifier text, OUT owner name, OUT namespace name, OUT name name, OUT language text, OUT argnames text[], OUT argtypes text[], OUT description text, OUT has_http_acl boolean, OUT body text, OUT sql_ddl text) OWNER TO postgres;

--
-- Name: FUNCTION pg_get_queries(OUT oid oid, OUT regclass regclass, OUT stereotype text, OUT sql_identifier text, OUT owner name, OUT namespace name, OUT name name, OUT language text, OUT argnames text[], OUT argtypes text[], OUT description text, OUT has_http_acl boolean, OUT body text, OUT sql_ddl text); Type: COMMENT; Schema: oordbms; Owner: postgres
--

COMMENT ON FUNCTION pg_get_queries(OUT oid oid, OUT regclass regclass, OUT stereotype text, OUT sql_identifier text, OUT owner name, OUT namespace name, OUT name name, OUT language text, OUT argnames text[], OUT argtypes text[], OUT description text, OUT has_http_acl boolean, OUT body text, OUT sql_ddl text) IS 'get queries (views and functions) in a database';


--
-- Name: ref(oid); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION ref(oid) RETURNS sql_identifier
    LANGUAGE sql IMMUTABLE
    AS $_$
SELECT oordbms.sql_full_identifier(nspname,relname)
  FROM pg_class c 
  JOIN pg_namespace n ON (c.relnamespace=n.oid) 
 WHERE c.oid = $1
 UNION 
SELECT oordbms.sql_full_identifier(nspname,typname)
  FROM pg_type t 
  JOIN pg_namespace n ON (t.typnamespace=n.oid) 
 WHERE t.oid = $1
 UNION 
SELECT cast(quote_ident(nspname) as oordbms.sql_identifier)
  FROM pg_namespace
 WHERE oid = $1
$_$;


ALTER FUNCTION oordbms.ref(oid) OWNER TO postgres;

--
-- Name: FUNCTION ref(oid); Type: COMMENT; Schema: oordbms; Owner: postgres
--

COMMENT ON FUNCTION ref(oid) IS 'Return full SQL name from object id';


--
-- Name: regclass(name, name); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION regclass(name, name) RETURNS regclass
    LANGUAGE sql
    AS $_$select c.oid as sysid

from pg_catalog.pg_class c

join pg_catalog.pg_namespace n on c.relnamespace = n.oid

and n.nspname=coalesce($1,current_schema())

and c.relname=$2$_$;


ALTER FUNCTION oordbms.regclass(name, name) OWNER TO postgres;

--
-- Name: session_info(); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION session_info(OUT label text, OUT description text) RETURNS SETOF record
    LANGUAGE sql
    AS $$
with q as (
select
 'role' as name, (current_role||' '||current_schemas(true)::text)::text as value
union select
 'current_time', now()::text
union select
 'current_database', (current_database()||' @ '||inet_server_addr()||' : '||inet_server_port()||' ['||pg_backend_pid()||']')::text
union select
 'version', version()::text
)
select name, value
  from q
 order by 1 
$$;


ALTER FUNCTION oordbms.session_info(OUT label text, OUT description text) OWNER TO postgres;

--
-- Name: sql_class(regclass); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION sql_class(regclass) RETURNS text
    LANGUAGE sql
    AS $_$select relname::text from pg_class where oid=$1$_$;


ALTER FUNCTION oordbms.sql_class(regclass) OWNER TO postgres;

--
-- Name: sql_def_label(regclass); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION sql_def_label(regclass) RETURNS sql_expression
    LANGUAGE sql
    AS $_$
SELECT 
  string_agg('text('||quote_ident(name)||')', 
             '||'',''||')::oordbms.sql_expression
FROM (
 SELECT name
 FROM oordbms.pg_get_columns($1)
 WHERE primary_key IS NOT NULL
 ORDER BY ord
) AS R

$_$;


ALTER FUNCTION oordbms.sql_def_label(regclass) OWNER TO postgres;

--
-- Name: sql_full_identifier(name, name); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION sql_full_identifier(schema_name name, object_name name) RETURNS sql_identifier
    LANGUAGE sql IMMUTABLE
    AS $_$
select cast(
 case
 when $1 is null then quote_ident($2)
 else quote_ident($1)||'.'||quote_ident($2)
 end as oordbms.sql_identifier)
$_$;


ALTER FUNCTION oordbms.sql_full_identifier(schema_name name, object_name name) OWNER TO postgres;

--
-- Name: sql_identifier(oid); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION sql_identifier(oid) RETURNS sql_identifier
    LANGUAGE sql IMMUTABLE
    AS $_$
select cast(pg_catalog.format_type(oid,null) as oordbms.sql_identifier)
  from pg_catalog.pg_type where typrelid = $1
 union 
select cast(oordbms.sql_identifier(n.nspname,p.proname) as oordbms.sql_identifier)
  from pg_catalog.pg_proc p 
  join pg_namespace n on (n.oid=p.pronamespace)
 where p.oid = $1
$_$;


ALTER FUNCTION oordbms.sql_identifier(oid) OWNER TO postgres;

--
-- Name: sql_identifier(name, name); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION sql_identifier(name, name) RETURNS sql_identifier
    LANGUAGE sql STABLE
    AS $_$

SELECT cast(
  coalesce(quote_ident(nullif($1 , current_schema()))||'.', '') || quote_ident($2)
as oordbms.sql_identifier);

$_$;


ALTER FUNCTION oordbms.sql_identifier(name, name) OWNER TO postgres;

--
-- Name: sql_json_set(json); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION sql_json_set(val json) RETURNS sql_statement
    LANGUAGE sql
    AS $_$
select cast(
         string_agg(quote_ident(key)||'='||quote_nullable(value),', ')
       as oordbms.sql_statement)
  from json_each_text($1)
$_$;


ALTER FUNCTION oordbms.sql_json_set(val json) OWNER TO postgres;

--
-- Name: sql_json_where(json); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION sql_json_where(restriction json) RETURNS sql_statement
    LANGUAGE sql
    AS $_$
select cast(
         string_agg(quote_ident(key)||'='||quote_literal(value),' AND ')
       as oordbms.sql_statement)
  from json_each_text($1)
$_$;


ALTER FUNCTION oordbms.sql_json_where(restriction json) OWNER TO postgres;

--
-- Name: sql_schema(regclass); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION sql_schema(regclass) RETURNS text
    LANGUAGE sql
    AS $_$select nspname::text from pg_class c join pg_namespace n on (n.oid = c.relnamespace) where c.oid=$1$_$;


ALTER FUNCTION oordbms.sql_schema(regclass) OWNER TO postgres;

--
-- Name: sql_tgargs(bytea); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION sql_tgargs(bytea) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
select case
        when length(text($1))>0 then string_agg(quote_literal(decode(t,'escape')),',')
        else ''
       end
  from regexp_split_to_table(regexp_replace(text($1),'\\000$',''), '\\000') t
$_$;


ALTER FUNCTION oordbms.sql_tgargs(bytea) OWNER TO postgres;

--
-- Name: version(); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION version(OUT major integer, OUT minor integer, OUT notes text) RETURNS record
    LANGUAGE sql IMMUTABLE
    AS $$
 select 
   0,1,
   'alpha'::text
$$;


ALTER FUNCTION oordbms.version(OUT major integer, OUT minor integer, OUT notes text) OWNER TO postgres;

--
-- Name: wb_get_schemata(); Type: FUNCTION; Schema: oordbms; Owner: postgres
--

CREATE FUNCTION wb_get_schemata(OUT text text, OUT detail_text text, OUT accessory_text text, OUT href text) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
begin
  return query

  select namespace as text,
         comment as detail_text,
         count::text as accessory_text,
	 '/api/pg/proc/wb_get_schema_objects?schema='||oordbms.esc_uri(namespace) as href
  from (
  select c.namespace,
         count(*)
    from oordbms.db_class c
   where has_schema_privilege(c.namespace,'usage')
     and has_table_privilege(c.id, 'select, insert, update, delete')
  group by namespace
  ) g
  join oordbms.namespace s using (namespace)
  order by 1;
end
$$;


ALTER FUNCTION oordbms.wb_get_schemata(OUT text text, OUT detail_text text, OUT accessory_text text, OUT href text) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: $atom; Type: TABLE; Schema: oordbms; Owner: oordbms; Tablespace: 
--

CREATE TABLE "$atom" (
    id nid DEFAULT nid() NOT NULL,
    iri uri,
    ctime timestamp with time zone DEFAULT now() NOT NULL,
    mtime timestamp with time zone DEFAULT now() NOT NULL,
    stereotype text,
    owner text DEFAULT "current_user"() NOT NULL
);


ALTER TABLE "$atom" OWNER TO oordbms;

--
-- Name: TABLE "$atom"; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON TABLE "$atom" IS 'All resources';


--
-- Name: $class; Type: TABLE; Schema: oordbms; Owner: oordbms; Tablespace: 
--

CREATE TABLE "$class" (
    regclass regclass,
    schema_name text NOT NULL,
    class_name text NOT NULL,
    label_expression sql_expression NOT NULL,
    order_expression sql_expression,
    class_expression sql_identifier,
    group_expressions sql_expressions,
    search_expression sql_expression,
    is_assoc boolean DEFAULT false NOT NULL,
    form_display text,
    list_display text,
    primary_key text[],
    rdf_class uri,
    is_enum boolean DEFAULT false NOT NULL,
    is_entity boolean DEFAULT false NOT NULL,
    has_undo boolean DEFAULT false NOT NULL,
    limit_modifications cardinal,
    id nid DEFAULT nid() NOT NULL
);


ALTER TABLE "$class" OWNER TO oordbms;

--
-- Name: TABLE "$class"; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON TABLE "$class" IS 'Class definitions';


--
-- Name: COLUMN "$class".regclass; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON COLUMN "$class".regclass IS 'Corresponding entry from pg_class (computed)';


--
-- Name: COLUMN "$class".schema_name; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON COLUMN "$class".schema_name IS 'Class schema name';


--
-- Name: COLUMN "$class".class_name; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON COLUMN "$class".class_name IS 'Class name';


--
-- Name: COLUMN "$class".label_expression; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON COLUMN "$class".label_expression IS 'Displayed label SQL expression';


--
-- Name: COLUMN "$class".order_expression; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON COLUMN "$class".order_expression IS 'Default SQL ordering expression';


--
-- Name: COLUMN "$class".class_expression; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON COLUMN "$class".class_expression IS 'Class SQL identifier';


--
-- Name: COLUMN "$class".group_expressions; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON COLUMN "$class".group_expressions IS 'Grouping SQL expressions';


--
-- Name: COLUMN "$class".search_expression; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON COLUMN "$class".search_expression IS 'SQL expression which calculates ts_vector';


--
-- Name: COLUMN "$class".is_assoc; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON COLUMN "$class".is_assoc IS 'Marks class as association';


--
-- Name: COLUMN "$class".form_display; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON COLUMN "$class".form_display IS 'Fields, shown in a form';


--
-- Name: COLUMN "$class".is_enum; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON COLUMN "$class".is_enum IS 'Marks class as enumeration (save data with DDL)';


--
-- Name: COLUMN "$class".is_entity; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON COLUMN "$class".is_entity IS 'Marks class as business entity';


--
-- Name: COLUMN "$class".has_undo; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON COLUMN "$class".has_undo IS 'Enable logging of data changes';


--
-- Name: db_class; Type: VIEW; Schema: oordbms; Owner: oordbms
--

CREATE VIEW db_class AS
 SELECT c.oid AS sysid,
    (c.relname)::text AS name,
        CASE
            WHEN (d.is_assoc = true) THEN 'association'::text
            WHEN (d.is_assoc = false) THEN
            CASE
                WHEN (d.is_enum = true) THEN 'enum'::text
                ELSE
                CASE
                    WHEN (d.is_entity = true) THEN 'entity'::text
                    WHEN (d.is_entity = false) THEN 'class'::text
                    ELSE 'class'::text
                END
            END
            ELSE
            CASE
                WHEN (c.relkind = 'r'::"char") THEN 'table'::text
                WHEN (c.relkind = 'v'::"char") THEN 'view'::text
                WHEN (c.relkind = 'i'::"char") THEN 'index'::text
                WHEN (c.relkind = 'S'::"char") THEN 'sequence'::text
                WHEN (c.relkind = 's'::"char") THEN 'special'::text
                ELSE NULL::text
            END
        END AS stereotype,
    ((c.relname)::text || COALESCE(((' (from '::text || (NULLIF(n.nspname, "current_schema"()))::text) || ')'::text), ''::text)) AS label,
    (n.nspname)::text AS namespace,
    u.usename AS owner,
    sql_identifier(n.nspname, c.relname) AS sql_identifier,
    (c.reltuples)::bigint AS count_estimate,
    obj_description(c.oid) AS description,
    d.order_expression,
    d.group_expressions,
    d.search_expression,
    (c.oid)::regclass AS regclass,
    c.relhasoids AS hasoids,
    (( SELECT count(*) AS count
           FROM pg_inherits
          WHERE (pg_inherits.inhrelid = c.oid)) = 0) AS is_root,
    (( SELECT count(*) AS count
           FROM pg_inherits
          WHERE (pg_inherits.inhparent = c.oid)) = 0) AS is_leaf,
    d.is_enum,
        CASE
            WHEN (c.relkind = 'r'::"char") THEN true
            ELSE false
        END AS hastableoid,
    has_table_privilege(c.oid, 'select'::text) AS readable,
    has_table_privilege(c.oid, 'insert,update,delete'::text) AS writeable,
    d.list_display,
    d.form_display
   FROM (((pg_class c
     LEFT JOIN pg_user u ON ((c.relowner = u.usesysid)))
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
     LEFT JOIN "$class" d ON (((d.regclass)::oid = c.oid)))
  WHERE (((((c.relkind = 'r'::"char") OR (c.relkind = 'v'::"char")) OR (c.relkind = ''::"char")) AND has_table_privilege(c.oid, 'select, insert, update, delete'::text)) AND has_schema_privilege(n.oid, 'usage'::text))
  ORDER BY n.nspname, c.relname;


ALTER TABLE db_class OWNER TO oordbms;

--
-- Name: VIEW db_class; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON VIEW db_class IS 'Classes';


--
-- Name: db_class_details; Type: VIEW; Schema: oordbms; Owner: oordbms
--

CREATE VIEW db_class_details AS
 SELECT c.oid AS sysid,
    c.relname AS name,
    (
        CASE
            WHEN (d.is_assoc = true) THEN 'association'::text
            WHEN (d.is_assoc = false) THEN
            CASE
                WHEN (d.is_enum = true) THEN 'enum'::text
                ELSE
                CASE
                    WHEN (d.is_entity = true) THEN 'entity'::text
                    WHEN (d.is_entity = false) THEN 'class'::text
                    ELSE 'class'::text
                END
            END
            ELSE
            CASE
                WHEN (c.relkind = 'r'::"char") THEN 'table'::text
                WHEN (c.relkind = 'v'::"char") THEN 'view'::text
                WHEN (c.relkind = 'i'::"char") THEN 'index'::text
                WHEN (c.relkind = 'S'::"char") THEN 'sequence'::text
                WHEN (c.relkind = 's'::"char") THEN 'special'::text
                ELSE NULL::text
            END
        END)::name AS stereotype,
    ((c.relname)::text || COALESCE(((' (from '::text || (NULLIF(n.nspname, "current_schema"()))::text) || ')'::text), ''::text)) AS label,
    n.nspname AS namespace,
    u.usename AS owner,
    sql_identifier(n.nspname, c.relname) AS sql_identifier,
    obj_description(c.oid) AS comment,
    COALESCE((d.label_expression)::text, (sql_def_label((c.oid)::regclass))::text) AS label_expression,
    d.order_expression,
    d.group_expressions,
    d.search_expression,
    COALESCE(d.primary_key, pg_get_primary_key((c.oid)::regclass),
        CASE
            WHEN c.relhasoids THEN ARRAY['oid'::text]
            ELSE NULL::text[]
        END) AS primary_key,
    (c.oid)::regclass AS regclass,
    c.relhasoids AS hasoids,
    (( SELECT count(*) AS count
           FROM pg_inherits
          WHERE (pg_inherits.inhrelid = c.oid)) = 0) AS is_root,
    (( SELECT count(*) AS count
           FROM pg_inherits
          WHERE (pg_inherits.inhparent = c.oid)) = 0) AS is_leaf,
    d.is_enum,
        CASE
            WHEN (c.relkind = 'r'::"char") THEN true
            ELSE false
        END AS hastableoid,
    d.list_display,
    d.form_display
   FROM (((pg_class c
     LEFT JOIN pg_user u ON ((c.relowner = u.usesysid)))
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
     LEFT JOIN "$class" d ON (((d.regclass)::oid = c.oid)))
  WHERE (((((c.relkind = 'r'::"char") OR (c.relkind = 'v'::"char")) OR (c.relkind = ''::"char")) AND has_table_privilege(c.oid, 'select'::text)) AND has_schema_privilege(n.oid, 'usage'::text))
  ORDER BY n.nspname, c.relname;


ALTER TABLE db_class_details OWNER TO oordbms;

--
-- Name: db_foreign_keys; Type: VIEW; Schema: oordbms; Owner: postgres
--

CREATE VIEW db_foreign_keys AS
 SELECT c.conname AS constraint_name,
    s1.nspname AS constraint_schema,
    c1.relname AS constraint_table,
    s2.nspname AS ref_table_schema,
    c2.relname AS ref_table_name,
    array_upper(c.conkey, 1) AS size,
    pg_get_colnames((c1.oid)::regclass, c.conkey) AS conkey,
    pg_get_colnames((c2.oid)::regclass, c.confkey) AS confkey,
    c1.oid AS sysid,
    c2.oid AS ref_sysid,
    c.oid AS constraint_sysid
   FROM ((((pg_constraint c
     JOIN pg_class c1 ON ((c1.oid = c.conrelid)))
     JOIN pg_namespace s1 ON ((s1.oid = c1.relnamespace)))
     JOIN pg_class c2 ON ((c2.oid = c.confrelid)))
     JOIN pg_namespace s2 ON ((s2.oid = c2.relnamespace)))
  WHERE (((((c1.relkind = 'r'::"char") OR (c1.relkind = 'v'::"char")) OR (c1.relkind = ''::"char")) AND (c.contype = 'f'::"char")) AND (c1.relname !~~ 'pg%_'::text));


ALTER TABLE db_foreign_keys OWNER TO postgres;

--
-- Name: VIEW db_foreign_keys; Type: COMMENT; Schema: oordbms; Owner: postgres
--

COMMENT ON VIEW db_foreign_keys IS 'Database foreign keys';


--
-- Name: db_functions; Type: VIEW; Schema: oordbms; Owner: postgres
--

CREATE VIEW db_functions AS
 SELECT p.oid AS sysid,
    s.nspname AS namespace,
    p.proname AS name,
    pg_description.description,
    u.rolname AS owner,
    ((p.oid)::regprocedure)::sql_identifier AS sql_identifier,
    l.lanname AS language,
        CASE p.provolatile
            WHEN 'i'::"char" THEN 'IMMUTABLE'::text
            WHEN 's'::"char" THEN 'STABLE'::text
            WHEN 'v'::"char" THEN 'VOLATILE'::text
            ELSE NULL::text
        END AS attributes,
    p.proretset AS retset,
    (p.prorettype = ('trigger'::regtype)::oid) AS is_trigger,
    ((p.prorettype)::regtype)::text AS returns,
    oidvectortypes(p.proargtypes) AS arguments,
    p.prosrc AS definition,
        CASE p.prosecdef
            WHEN true THEN 'DEFINER'::text
            ELSE 'INVOKER'::text
        END AS security,
        CASE p.proisstrict
            WHEN true THEN 'STRICT'::text
            ELSE ''::text
        END AS is_strict,
        CASE p.proisstrict
            WHEN true THEN 'NO'::text
            WHEN false THEN 'YES'::text
            ELSE NULL::text
        END AS is_null_call,
    p.proargtypes AS argtypes,
    p.proacl
   FROM ((((pg_proc p
     LEFT JOIN pg_namespace s ON ((s.oid = p.pronamespace)))
     LEFT JOIN pg_language l ON ((l.oid = p.prolang)))
     LEFT JOIN pg_roles u ON ((p.proowner = u.oid)))
     LEFT JOIN pg_description ON ((p.oid = pg_description.objoid)));


ALTER TABLE db_functions OWNER TO postgres;

--
-- Name: VIEW db_functions; Type: COMMENT; Schema: oordbms; Owner: postgres
--

COMMENT ON VIEW db_functions IS 'Database functions';


--
-- Name: db_schemas; Type: VIEW; Schema: oordbms; Owner: postgres
--

CREATE VIEW db_schemas AS
 SELECT (s.nspname)::text AS namespace,
    (r.rolname)::text AS owner,
    s.oid AS sysid,
    c.description AS comment
   FROM ((pg_namespace s
     JOIN pg_roles r ON ((r.oid = s.nspowner)))
     LEFT JOIN pg_description c ON ((c.objoid = s.oid)))
  WHERE (has_schema_privilege("current_user"(), s.oid, 'usage'::text) AND (s.nspname !~~ 'pg_t%'::text));


ALTER TABLE db_schemas OWNER TO postgres;

--
-- Name: db_unique_keys; Type: VIEW; Schema: oordbms; Owner: postgres
--

CREATE VIEW db_unique_keys AS
 SELECT s.nspname AS table_schema,
    c.relname AS table_name,
    c2.conname AS constraint_name,
        CASE c2.contype
            WHEN 'p'::"char" THEN 'PRIMARY KEY'::text
            WHEN 'u'::"char" THEN 'UNIQUE'::text
            ELSE NULL::text
        END AS constraint_type,
    pg_attribute_names((c.oid)::regclass, c2.conkey) AS attribute_names,
    pg_attribute_types((c.oid)::regclass, c2.conkey) AS attribute_types,
    c.oid AS sysid
   FROM (((pg_constraint c2
     JOIN pg_class c ON ((c.oid = c2.conrelid)))
     JOIN pg_namespace s ON ((s.oid = c.relnamespace)))
     JOIN pg_namespace s2 ON ((s2.oid = c2.connamespace)))
  WHERE ((c.relkind = ANY (ARRAY['r'::"char", 'v'::"char", ''::"char"])) AND (c2.contype = ANY (ARRAY['p'::"char", 'u'::"char"])))
UNION
 SELECT s.nspname AS table_schema,
    c.relname AS table_name,
    (('$OID_'::text || c.oid))::name AS constraint_name,
    '$OID'::text AS constraint_type,
    ARRAY['oid'::text] AS attribute_names,
    ARRAY['oid'::text] AS attribute_types,
    c.oid AS sysid
   FROM (pg_class c
     JOIN pg_namespace s ON ((s.oid = c.relnamespace)))
  WHERE ((c.relkind = 'r'::"char") AND c.relhasoids);


ALTER TABLE db_unique_keys OWNER TO postgres;

--
-- Name: pg_query; Type: VIEW; Schema: oordbms; Owner: postgres
--

CREATE VIEW pg_query AS
 SELECT q.oid,
    q.regclass,
    q.stereotype,
    q.sql_identifier,
    r.rolname AS owner,
    n.nspname AS namespace,
    q.name,
    q.language,
    q.argnames,
    q.argtypes,
    q.description,
    (EXISTS ( SELECT a.a
           FROM unnest(q.acl) a(a)
          WHERE ((a.a)::text ~~ 'http=%X%/%'::text))) AS has_http_acl,
    q.body,
    (((((((((((('-- Name: '::text || (q.name)::text) || '; Type: '::text) || q.stereotype) || '; Schema: '::text) || (n.nspname)::text) || '; Owner: '::text) || (r.rolname)::text) || '

'::text) || (((('-- DROP '::text || q.stereotype) || ' IF EXISTS '::text) || q.sql_identifier) || ';

'::text)) || (q.sql_ddl || ';

'::text)) || (((((('ALTER '::text || q.stereotype) || ' '::text) || q.sql_identifier) || ' OWNER TO '::text) || quote_ident((r.rolname)::text)) || ';
'::text)) || COALESCE((((((('COMMENT ON '::text || q.stereotype) || ' '::text) || q.sql_identifier) || ' IS '::text) || quote_literal(q.description)) || ';
'::text), ''::text)) AS sql_ddl
   FROM ((( SELECT c.oid,
            'pg_class'::regclass AS regclass,
            'VIEW'::text AS stereotype,
            ((c.oid)::regclass)::text AS sql_identifier,
            c.relname AS name,
            'sql'::text AS language,
            obj_description(c.oid, 'pg_class'::name) AS description,
            pg_get_viewdef(c.oid, true) AS body,
            ((('CREATE OR REPLACE VIEW '::text || ((c.oid)::regclass)::text) || ' AS
'::text) || pg_get_viewdef(c.oid, true)) AS sql_ddl,
            c.relacl AS acl,
            c.relowner AS _owner,
            c.relnamespace AS _namespace,
            NULL::text[] AS argnames,
            NULL::text[] AS argtypes0,
            NULL::text[] AS argtypes
           FROM pg_class c
          WHERE ((c.relkind = 'v'::"char") AND has_table_privilege(c.oid, 'select'::text))
        UNION ALL
         SELECT p.oid,
            'pg_proc'::regclass AS regclass,
            'FUNCTION'::text AS stereotype,
            ((p.oid)::regprocedure)::text AS sql_identifier,
            p.proname AS name,
            l.lanname AS language,
            obj_description(p.oid, 'pg_proc'::name) AS description,
            p.prosrc AS body,
            pg_get_functiondef(p.oid) AS sql_ddl,
            p.proacl AS acl,
            p.proowner AS _owner,
            p.pronamespace AS _namespace,
            ( SELECT array_agg(p.proargnames[pam.i]) AS array_agg
                   FROM ( SELECT i.i,
                            p.proargmodes[i.i] AS mode
                           FROM generate_series(1, array_length(p.proargmodes, 1)) i(i)
                          WHERE (p.proargmodes[i.i] = ANY (ARRAY['i'::"char", 'b'::"char"]))) pam) AS argnames,
            ((('{'::text || oidvectortypes(p.proargtypes)) || '}'::text))::text[] AS argtypes0,
            ( SELECT array_agg((((('{'::text || oidvectortypes(p.proargtypes)) || '}'::text))::text[])[pam.i]) AS array_agg
                   FROM ( SELECT i.i,
                            p.proargmodes[i.i] AS mode
                           FROM generate_series(1, array_length(p.proargmodes, 1)) i(i)
                          WHERE (p.proargmodes[i.i] = ANY (ARRAY['i'::"char", 'b'::"char"]))) pam) AS argtypes
           FROM (pg_proc p
             JOIN pg_language l ON ((l.oid = p.prolang)))
          WHERE (p.proretset AND has_function_privilege(p.oid, 'execute'::text))) q
     JOIN pg_roles r ON ((r.oid = q._owner)))
     JOIN pg_namespace n ON ((n.oid = q._namespace)))
  WHERE has_schema_privilege(n.oid, 'usage'::text);


ALTER TABLE pg_query OWNER TO postgres;

--
-- Name: pg_query_class; Type: VIEW; Schema: oordbms; Owner: postgres
--

CREATE VIEW pg_query_class AS
 SELECT c.oid,
    'view'::text AS query_type,
    r.rolname AS query_owner,
    n.nspname AS query_namespace,
    'sql'::text AS query_language,
    c.relname AS query_name,
    obj_description(c.oid, 'pg_class'::name) AS query_comment,
    pg_get_viewdef(c.oid, true) AS query_body,
    (((((('-- DROP VIEW IF EXISTS '::text || ((c.oid)::regclass)::text) || ';
'::text) || 'CREATE OR REPLACE VIEW '::text) || ((c.oid)::regclass)::text) || ' AS 
'::text) || pg_get_viewdef(c.oid, true)) AS query_definition
   FROM ((pg_class c
     JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
     JOIN pg_roles r ON ((r.oid = c.relowner)))
  WHERE ((c.relkind = 'v'::"char") AND has_table_privilege(c.oid, 'select'::text));


ALTER TABLE pg_query_class OWNER TO postgres;

--
-- Name: pg_query_proc; Type: VIEW; Schema: oordbms; Owner: postgres
--

CREATE VIEW pg_query_proc AS
 WITH q AS (
         SELECT ((('data:/'::text || (n.nspname)::text) || '/'::text) || (p.proname)::text) AS iri,
            p.oid,
            ((p.oid)::regprocedure)::text AS sql_identifier,
            obj_description(p.oid, 'pg_proc'::name) AS description,
            'function'::text AS query_type,
            r.rolname AS query_owner,
            n.nspname AS query_namespace,
            l.lanname AS query_language,
            p.proname AS query_name,
            p.prosrc AS query_body,
            (((('-- DROP FUNCTION '::text || ((p.oid)::regprocedure)::text) || ';
'::text) || pg_get_functiondef(p.oid)) || ';
'::text) AS query_definition,
            pg_get_args(p.*) AS args
           FROM (((pg_proc p
             JOIN pg_namespace n ON ((p.pronamespace = n.oid)))
             JOIN pg_language l ON ((l.oid = p.prolang)))
             JOIN pg_roles r ON ((r.oid = p.proowner)))
          WHERE ((p.proretset AND has_schema_privilege(n.oid, 'usage'::text)) AND has_function_privilege(p.oid, 'execute'::text))
        )
 SELECT human_label((((((q.query_namespace)::text || '.'::text) || (q.query_name)::text) || ' '::text) || COALESCE(((q.args).argnames)::text, ''::text)), q.query_type, q.iri, (q.query_owner)::text) AS label,
    q.iri,
    q.oid,
    q.sql_identifier,
    q.description,
    q.query_type,
    q.query_owner,
    q.query_namespace,
    q.query_language,
    q.query_name,
    q.query_body,
    q.query_definition,
    (q.args).argnames AS argnames,
    (q.args).argtypes AS argtypes
   FROM q;


ALTER TABLE pg_query_proc OWNER TO postgres;

--
-- Name: seq; Type: SEQUENCE; Schema: oordbms; Owner: oordbms
--

CREATE SEQUENCE seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq OWNER TO oordbms;

--
-- Name: triggers; Type: VIEW; Schema: oordbms; Owner: oordbms
--

CREATE VIEW triggers AS
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
    sql_identifier(s.nspname, c.relname) AS event_object_sql_identifier,
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


ALTER TABLE triggers OWNER TO oordbms;

--
-- Name: VIEW triggers; Type: COMMENT; Schema: oordbms; Owner: oordbms
--

COMMENT ON VIEW triggers IS 'Triggers';


--
-- Name: class_def_pkey; Type: CONSTRAINT; Schema: oordbms; Owner: oordbms; Tablespace: 
--

ALTER TABLE ONLY "$class"
    ADD CONSTRAINT class_def_pkey PRIMARY KEY (schema_name, class_name);


--
-- Name: class_def_regclass_key; Type: CONSTRAINT; Schema: oordbms; Owner: oordbms; Tablespace: 
--

ALTER TABLE ONLY "$class"
    ADD CONSTRAINT class_def_regclass_key UNIQUE (regclass);


--
-- Name: resource_pkey; Type: CONSTRAINT; Schema: oordbms; Owner: oordbms; Tablespace: 
--

ALTER TABLE ONLY "$atom"
    ADD CONSTRAINT resource_pkey PRIMARY KEY (id);


--
-- Name: resource_url_key; Type: CONSTRAINT; Schema: oordbms; Owner: oordbms; Tablespace: 
--

ALTER TABLE ONLY "$atom"
    ADD CONSTRAINT resource_url_key UNIQUE (iri);


--
-- Name: $atom_touch; Type: TRIGGER; Schema: oordbms; Owner: oordbms
--

CREATE TRIGGER "$atom_touch" BEFORE INSERT OR UPDATE ON "$atom" FOR EACH ROW EXECUTE PROCEDURE "$atom_touch"();


--
-- Name: _ISA $atom; Type: TRIGGER; Schema: oordbms; Owner: oordbms
--

CREATE TRIGGER "_ISA $atom" BEFORE INSERT OR UPDATE ON "$class" FOR EACH ROW EXECUTE PROCEDURE "$class_isa_$atom"();


--
-- Name: _ISA~resource; Type: TRIGGER; Schema: oordbms; Owner: oordbms
--

CREATE TRIGGER "_ISA~resource" AFTER DELETE ON "$class" FOR EACH ROW EXECUTE PROCEDURE "$class_isa_$atom"();


--
-- Name: db_functions_touch; Type: TRIGGER; Schema: oordbms; Owner: postgres
--

CREATE TRIGGER db_functions_touch INSTEAD OF INSERT OR DELETE OR UPDATE ON db_functions FOR EACH ROW EXECUTE PROCEDURE db_functions_trigger();


--
-- Name: oordbms_after_delete; Type: TRIGGER; Schema: oordbms; Owner: oordbms
--

CREATE TRIGGER oordbms_after_delete AFTER DELETE ON "$class" FOR EACH ROW EXECUTE PROCEDURE "$class_refresh"();


--
-- Name: oordbms_after_insert; Type: TRIGGER; Schema: oordbms; Owner: oordbms
--

CREATE TRIGGER oordbms_after_insert AFTER INSERT ON "$class" FOR EACH ROW EXECUTE PROCEDURE "$class_refresh"();


--
-- Name: oordbms_after_update; Type: TRIGGER; Schema: oordbms; Owner: oordbms
--

CREATE TRIGGER oordbms_after_update AFTER UPDATE ON "$class" FOR EACH ROW EXECUTE PROCEDURE "$class_refresh"();


--
-- Name: oordbms_before_insert; Type: TRIGGER; Schema: oordbms; Owner: oordbms
--

CREATE TRIGGER oordbms_before_insert BEFORE INSERT ON "$class" FOR EACH ROW EXECUTE PROCEDURE "$class_touch"();


--
-- Name: oordbms_before_update; Type: TRIGGER; Schema: oordbms; Owner: oordbms
--

CREATE TRIGGER oordbms_before_update BEFORE UPDATE ON "$class" FOR EACH ROW EXECUTE PROCEDURE "$class_touch"();


--
-- Name: ISA resource; Type: FK CONSTRAINT; Schema: oordbms; Owner: oordbms
--

ALTER TABLE ONLY "$class"
    ADD CONSTRAINT "ISA resource" FOREIGN KEY (id) REFERENCES "$atom"(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: oordbms; Type: ACL; Schema: -; Owner: oordbms
--

REVOKE ALL ON SCHEMA oordbms FROM PUBLIC;
REVOKE ALL ON SCHEMA oordbms FROM oordbms;
GRANT ALL ON SCHEMA oordbms TO oordbms;
GRANT USAGE ON SCHEMA oordbms TO PUBLIC;


--
-- Name: data_get_json_values(text, text, json); Type: ACL; Schema: oordbms; Owner: postgres
--

REVOKE ALL ON FUNCTION data_get_json_values(namespace text, name text, key json) FROM PUBLIC;
REVOKE ALL ON FUNCTION data_get_json_values(namespace text, name text, key json) FROM postgres;
GRANT ALL ON FUNCTION data_get_json_values(namespace text, name text, key json) TO postgres;
GRANT ALL ON FUNCTION data_get_json_values(namespace text, name text, key json) TO PUBLIC;
GRANT ALL ON FUNCTION data_get_json_values(namespace text, name text, key json) TO http;


--
-- Name: data_set_json_values(text, text, json, set_json_values_mode, json); Type: ACL; Schema: oordbms; Owner: postgres
--

REVOKE ALL ON FUNCTION data_set_json_values(namespace text, name text, key json, mode set_json_values_mode, data json) FROM PUBLIC;
REVOKE ALL ON FUNCTION data_set_json_values(namespace text, name text, key json, mode set_json_values_mode, data json) FROM postgres;
GRANT ALL ON FUNCTION data_set_json_values(namespace text, name text, key json, mode set_json_values_mode, data json) TO postgres;
GRANT ALL ON FUNCTION data_set_json_values(namespace text, name text, key json, mode set_json_values_mode, data json) TO PUBLIC;
GRANT ALL ON FUNCTION data_set_json_values(namespace text, name text, key json, mode set_json_values_mode, data json) TO http;


--
-- Name: get_proc_info(text, text); Type: ACL; Schema: oordbms; Owner: postgres
--

REVOKE ALL ON FUNCTION get_proc_info(namespace text, name text, OUT sysid oid, OUT sql_identifier text, OUT argnames text[], OUT argtypes text[], OUT comment text, OUT has_http_acl boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_proc_info(namespace text, name text, OUT sysid oid, OUT sql_identifier text, OUT argnames text[], OUT argtypes text[], OUT comment text, OUT has_http_acl boolean) FROM postgres;
GRANT ALL ON FUNCTION get_proc_info(namespace text, name text, OUT sysid oid, OUT sql_identifier text, OUT argnames text[], OUT argtypes text[], OUT comment text, OUT has_http_acl boolean) TO postgres;
GRANT ALL ON FUNCTION get_proc_info(namespace text, name text, OUT sysid oid, OUT sql_identifier text, OUT argnames text[], OUT argtypes text[], OUT comment text, OUT has_http_acl boolean) TO PUBLIC;
GRANT ALL ON FUNCTION get_proc_info(namespace text, name text, OUT sysid oid, OUT sql_identifier text, OUT argnames text[], OUT argtypes text[], OUT comment text, OUT has_http_acl boolean) TO http;


--
-- Name: list_namespaces(); Type: ACL; Schema: oordbms; Owner: postgres
--

REVOKE ALL ON FUNCTION list_namespaces() FROM PUBLIC;
REVOKE ALL ON FUNCTION list_namespaces() FROM postgres;
GRANT ALL ON FUNCTION list_namespaces() TO postgres;
GRANT ALL ON FUNCTION list_namespaces() TO PUBLIC;
GRANT ALL ON FUNCTION list_namespaces() TO http;


--
-- Name: pg_get_args(pg_proc); Type: ACL; Schema: oordbms; Owner: postgres
--

REVOKE ALL ON FUNCTION pg_get_args(p pg_proc, OUT argnames text[], OUT argtypes text[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION pg_get_args(p pg_proc, OUT argnames text[], OUT argtypes text[]) FROM postgres;
GRANT ALL ON FUNCTION pg_get_args(p pg_proc, OUT argnames text[], OUT argtypes text[]) TO postgres;
GRANT ALL ON FUNCTION pg_get_args(p pg_proc, OUT argnames text[], OUT argtypes text[]) TO PUBLIC;
GRANT ALL ON FUNCTION pg_get_args(p pg_proc, OUT argnames text[], OUT argtypes text[]) TO http;


--
-- Name: db_class; Type: ACL; Schema: oordbms; Owner: oordbms
--

REVOKE ALL ON TABLE db_class FROM PUBLIC;
REVOKE ALL ON TABLE db_class FROM oordbms;
GRANT ALL ON TABLE db_class TO oordbms;
GRANT SELECT ON TABLE db_class TO PUBLIC;


--
-- Name: db_class_details; Type: ACL; Schema: oordbms; Owner: oordbms
--

REVOKE ALL ON TABLE db_class_details FROM PUBLIC;
REVOKE ALL ON TABLE db_class_details FROM oordbms;
GRANT ALL ON TABLE db_class_details TO oordbms;
GRANT SELECT ON TABLE db_class_details TO PUBLIC;


--
-- Name: db_foreign_keys; Type: ACL; Schema: oordbms; Owner: postgres
--

REVOKE ALL ON TABLE db_foreign_keys FROM PUBLIC;
REVOKE ALL ON TABLE db_foreign_keys FROM postgres;
GRANT ALL ON TABLE db_foreign_keys TO postgres;
GRANT SELECT ON TABLE db_foreign_keys TO PUBLIC;


--
-- Name: db_functions; Type: ACL; Schema: oordbms; Owner: postgres
--

REVOKE ALL ON TABLE db_functions FROM PUBLIC;
REVOKE ALL ON TABLE db_functions FROM postgres;
GRANT ALL ON TABLE db_functions TO postgres;
GRANT SELECT,INSERT,UPDATE ON TABLE db_functions TO PUBLIC;


--
-- Name: db_schemas; Type: ACL; Schema: oordbms; Owner: postgres
--

REVOKE ALL ON TABLE db_schemas FROM PUBLIC;
REVOKE ALL ON TABLE db_schemas FROM postgres;
GRANT ALL ON TABLE db_schemas TO postgres;
GRANT SELECT ON TABLE db_schemas TO PUBLIC;


--
-- Name: db_unique_keys; Type: ACL; Schema: oordbms; Owner: postgres
--

REVOKE ALL ON TABLE db_unique_keys FROM PUBLIC;
REVOKE ALL ON TABLE db_unique_keys FROM postgres;
GRANT ALL ON TABLE db_unique_keys TO postgres;
GRANT SELECT ON TABLE db_unique_keys TO PUBLIC;


--
-- Name: pg_query; Type: ACL; Schema: oordbms; Owner: postgres
--

REVOKE ALL ON TABLE pg_query FROM PUBLIC;
REVOKE ALL ON TABLE pg_query FROM postgres;
GRANT ALL ON TABLE pg_query TO postgres;
GRANT SELECT ON TABLE pg_query TO oordbms;


--
-- Name: pg_query_class; Type: ACL; Schema: oordbms; Owner: postgres
--

REVOKE ALL ON TABLE pg_query_class FROM PUBLIC;
REVOKE ALL ON TABLE pg_query_class FROM postgres;
GRANT ALL ON TABLE pg_query_class TO postgres;
GRANT SELECT ON TABLE pg_query_class TO PUBLIC;


--
-- Name: pg_query_proc; Type: ACL; Schema: oordbms; Owner: postgres
--

REVOKE ALL ON TABLE pg_query_proc FROM PUBLIC;
REVOKE ALL ON TABLE pg_query_proc FROM postgres;
GRANT ALL ON TABLE pg_query_proc TO postgres;
GRANT SELECT ON TABLE pg_query_proc TO PUBLIC;
GRANT SELECT ON TABLE pg_query_proc TO oordbms;


--
-- PostgreSQL database dump complete
--

