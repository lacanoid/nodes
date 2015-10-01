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
-- Name: http; Type: SCHEMA; Schema: -; Owner: http
--

CREATE SCHEMA http;


ALTER SCHEMA http OWNER TO http;

SET search_path = http, pg_catalog;

--
-- Name: request_info; Type: DOMAIN; Schema: http; Owner: postgres
--

CREATE DOMAIN request_info AS text;


ALTER DOMAIN request_info OWNER TO postgres;

--
-- Name: proc_info(text, text); Type: FUNCTION; Schema: http; Owner: http
--

CREATE FUNCTION proc_info(namespace text, name text, OUT arity integer, OUT proc_oid oid, OUT sql_identifier text, OUT argnames text[], OUT argtypes text[], OUT comment text, OUT has_http_acl boolean) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
declare 
 p  record;
 pa record;
 r  record;
begin

 begin
   proc_oid := regproc(coalesce(quote_ident(namespace)||'.','')||quote_ident(name))::oid;
   sql_identifier := regproc(proc_oid)::text;
 exception when others then
   return;
 end;
 
 select * 
   from pg_proc
  where pg_proc.oid = proc_oid	
   into p;
   
 select array_agg(p.proargnames[i]) as iproargnames
 from (
   select i, p.proargmodes[i] as mode
     from generate_series(1,array_length(p.proargmodes,1)) i
    where p.proargmodes[i] in ('i','b')
 ) as pam 
 into pa;
 argnames := pa.iproargnames;

 select array_agg(typ)
 from ( 
   select at::regtype::text as typ
     from unnest(p.proargtypes) as at
 ) as at1 
 into argtypes;
 arity = coalesce(array_length(argtypes,1),0);

 select exists (
   select a
    from unnest(p.proacl) as a
   where a::text like 'http=%X%/%'
 ) into has_http_acl;

 comment := obj_description(proc_oid);

 return next;
end
$$;


ALTER FUNCTION http.proc_info(namespace text, name text, OUT arity integer, OUT proc_oid oid, OUT sql_identifier text, OUT argnames text[], OUT argtypes text[], OUT comment text, OUT has_http_acl boolean) OWNER TO http;

--
-- Name: http; Type: ACL; Schema: -; Owner: http
--

REVOKE ALL ON SCHEMA http FROM PUBLIC;
REVOKE ALL ON SCHEMA http FROM http;
GRANT ALL ON SCHEMA http TO http;
GRANT USAGE ON SCHEMA http TO PUBLIC;


--
-- PostgreSQL database dump complete
--

