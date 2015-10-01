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
-- Name: dbms; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA dbms;


ALTER SCHEMA dbms OWNER TO postgres;

--
-- Name: SCHEMA dbms; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA dbms IS 'Database administration utilities';


SET search_path = dbms, pg_catalog;

--
-- Name: sql_expression; Type: DOMAIN; Schema: dbms; Owner: postgres
--

CREATE DOMAIN sql_expression AS text;


ALTER DOMAIN sql_expression OWNER TO postgres;

--
-- Name: DOMAIN sql_expression; Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON DOMAIN sql_expression IS 'SQL expression';


--
-- Name: sql_identifier; Type: DOMAIN; Schema: dbms; Owner: postgres
--

CREATE DOMAIN sql_identifier AS character varying;


ALTER DOMAIN sql_identifier OWNER TO postgres;

--
-- Name: DOMAIN sql_identifier; Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON DOMAIN sql_identifier IS 'SQL object identifier';


--
-- Name: sql_statement; Type: DOMAIN; Schema: dbms; Owner: postgres
--

CREATE DOMAIN sql_statement AS text;


ALTER DOMAIN sql_statement OWNER TO postgres;

--
-- Name: DOMAIN sql_statement; Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON DOMAIN sql_statement IS 'SQL statement';


--
-- Name: alter_enum_add(name, name); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION alter_enum_add(enum_name name, enum_elem name) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO pg_enum(enumtypid, enumlabel) VALUES(
        (SELECT oid FROM pg_type WHERE typtype='e' AND typname=enum_name), 
        enum_elem
    );
END;
$$;


ALTER FUNCTION dbms.alter_enum_add(enum_name name, enum_elem name) OWNER TO postgres;

--
-- Name: FUNCTION alter_enum_add(enum_name name, enum_elem name); Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON FUNCTION alter_enum_add(enum_name name, enum_elem name) IS 'Inserts a new ENUM element wthout re-creating the whole type. (DEPRECATED)';


--
-- Name: alter_enum_drop(name, name); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION alter_enum_drop(enum_name name, enum_elem name) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    type_oid INTEGER;
    rec RECORD;
    sql VARCHAR;
    ret INTEGER;
BEGIN
    SELECT pg_type.oid
    FROM pg_type 
    WHERE typtype = 'e' AND typname = enum_name
    INTO type_oid;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cannot find a enum: %', enum_name; 
    END IF;
    
    FOR rec IN 
        SELECT *
        FROM 
            pg_attribute
            JOIN pg_class ON pg_class.oid = attrelid
            JOIN pg_namespace ON pg_namespace.oid = relnamespace
        WHERE 
            atttypid = type_oid
            AND relkind = 'r'
    LOOP
        sql := 
            'SELECT 1 FROM ' 
            || quote_ident(rec.nspname) || '.'
            || quote_ident(rec.relname) || ' '
            || ' WHERE ' 
            || quote_ident(rec.attname) || ' = '
            || quote_literal(enum_elem)
            || ' LIMIT 1';
        EXECUTE sql INTO ret;
        IF ret IS NOT NULL THEN
            RAISE EXCEPTION 
                'Cannot delete the ENUM element %.%: column %.%.% contains references',
                quote_ident(enum_name), quote_ident(enum_elem),
                quote_ident(rec.nspname), quote_ident(rec.relname),
                rec.attname;
        END IF;
        DELETE FROM pg_enum WHERE enumtypid = type_oid AND enumlabel = enum_elem;
    END LOOP;
END;
$$;


ALTER FUNCTION dbms.alter_enum_drop(enum_name name, enum_elem name) OWNER TO postgres;

--
-- Name: FUNCTION alter_enum_drop(enum_name name, enum_elem name); Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON FUNCTION alter_enum_drop(enum_name name, enum_elem name) IS 'Removes the ENUM element "on the fly". Check references to the ENUM element in database''s tables before the deletion and throws an exception if the element cannot be deleted. (DEPRECATED)';


--
-- Name: attribute_names(regclass, smallint[]); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION attribute_names(regclass, smallint[]) RETURNS name[]
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


ALTER FUNCTION dbms.attribute_names(regclass, smallint[]) OWNER TO postgres;

--
-- Name: attribute_types(regclass, smallint[]); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION attribute_types(regclass, smallint[]) RETURNS text[]
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


ALTER FUNCTION dbms.attribute_types(regclass, smallint[]) OWNER TO postgres;

--
-- Name: backend_id(); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION backend_id() RETURNS integer
    LANGUAGE plperlu
    AS $_$return $$;$_$;


ALTER FUNCTION dbms.backend_id() OWNER TO postgres;

--
-- Name: backup_table(sql_identifier); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION backup_table(sql_identifier) RETURNS bigint
    LANGUAGE plpgsql
    AS $_$
declare
 my_table alias for $1;
 my_ext text;
 my_ident text;
 my_sql text;
 my_rows bigint;
begin
 my_ext := to_char(now(),'YYYYMMDDHH24MI');
 my_ident := dbms.sql_identifier(
		dbms.namespace(regclass(my_table)),
		dbms.name(regclass(my_table)) || '.' || my_ext
	     );
 raise notice 'Backing up table %', my_table||' to '||my_ident;

 execute 'create table '||my_ident||
         ' ( like '||my_table||
         ' including defaults'||
         ' including constraints'||
         ' including indexes )';

 execute 'insert into '||my_ident||
         ' select * from '||my_table;

 get diagnostics my_rows = ROW_COUNT; 

 return my_rows;
end;
$_$;


ALTER FUNCTION dbms.backup_table(sql_identifier) OWNER TO postgres;

--
-- Name: FUNCTION backup_table(sql_identifier); Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON FUNCTION backup_table(sql_identifier) IS 'Create a backup copy of a table';


--
-- Name: call(sql_expression); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION call(sql_expression) RETURNS text
    LANGUAGE plpgsql
    AS $_$
declare
 r bigint;
begin
 raise notice 'CALL:%',$1;
 return dbms.eval($1);
end
$_$;


ALTER FUNCTION dbms.call(sql_expression) OWNER TO postgres;

--
-- Name: count_records(regclass); Type: FUNCTION; Schema: dbms; Owner: postgres
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


ALTER FUNCTION dbms.count_records(my_table regclass) OWNER TO postgres;

--
-- Name: FUNCTION count_records(my_table regclass); Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON FUNCTION count_records(my_table regclass) IS 'Fast count number of tuples in a relation';


--
-- Name: create_partition(regclass, text); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION create_partition(my_table regclass, my_partition text) RETURNS sql_statement
    LANGUAGE sql
    AS $_$
select dbms.create_partition($1,$2,null)::dbms.sql_statement
$_$;


ALTER FUNCTION dbms.create_partition(my_table regclass, my_partition text) OWNER TO postgres;

--
-- Name: FUNCTION create_partition(my_table regclass, my_partition text); Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON FUNCTION create_partition(my_table regclass, my_partition text) IS 'Create table partition without constraint';


--
-- Name: create_partition(regclass, text, sql_expression); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION create_partition(my_table regclass, my_partition text, my_constraint sql_expression) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $_$
declare
 my_ident text;
 my_sql text;
begin
 my_ident := dbms.sql_identifier(
              dbms.namespace(my_table),
	      dbms.name(my_table)||'_'||my_partition
	     );
	     
  my_sql :=
     'create table '||my_ident||
     ' (like '||text(my_table)||
     ' including defaults including constraints including indexes)'||E';\n'||
     'alter table '||my_ident||
     ' inherit '||text(my_table)||E';\n';

  if my_constraint is not null then
    my_sql := my_sql||
     'alter table '||my_ident||
     ' add constraint "$PARTITION" '||
     ' check ('||my_constraint||')'||E';\n'||
     'create rule '||quote_ident('$PARTITION_'||my_partition)||
     ' as on insert to '||text(my_table)||
     ' where ('||my_constraint||') '||
     ' do instead insert into '||my_ident||' values (new.*)'||E';\n'
     ;
  end if;

 if dbms.stereotype(my_ident) is null then
 -- partition does not exists; create
  execute my_sql;
 end if;
   
-- update triggers
 return my_sql;
end
$_$;


ALTER FUNCTION dbms.create_partition(my_table regclass, my_partition text, my_constraint sql_expression) OWNER TO postgres;

--
-- Name: FUNCTION create_partition(my_table regclass, my_partition text, my_constraint sql_expression); Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON FUNCTION create_partition(my_table regclass, my_partition text, my_constraint sql_expression) IS 'Create table partition with constraint';


--
-- Name: create_partition_monthly(regclass, text); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION create_partition_monthly(my_table regclass, my_column text) RETURNS sql_statement
    LANGUAGE plpgsql
    AS $$
declare
 my_date date;
 my_partition name;
 my_constraint text;
 my_sql dbms.sql_statement;
begin
 my_date := date_trunc('month',now())+interval'1 month';
 my_partition := to_char(my_date,'YYYY_MM');

 if my_column is not null then
   my_constraint :=
     quote_ident(my_column)||'>='||quote_literal(to_char(my_date,'YYYY-MM-DD'))||' AND '||
     quote_ident(my_column)||'<'||quote_literal(to_char(my_date+interval'1 month','YYYY-MM-DD'));
 end if;
 
 my_sql := dbms.create_partition(my_table,my_partition,my_constraint);
 return my_sql;
end
$$;


ALTER FUNCTION dbms.create_partition_monthly(my_table regclass, my_column text) OWNER TO postgres;

--
-- Name: dot_view_dependancies(name); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION dot_view_dependancies(my_schema name) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare
 def1 text;
 def2 text;
begin
 create temporary table dot_tmp as
 select dbms.stereotype(sql_identifier),
        sql_identifier,
        dbms.stereotype(sql_identifier) as ref_stereotype,
        ref_sql_identifier,
        sysid::bigint,
        ref_sysid::bigint
   from dbms.view_dependancies
  where namespace=my_schema or ref_namespace=my_schema;

 -- graph nodes
 select dbms.concat(
          'o'||sysid||
          ' [label="'||sql_identifier||
          E'"];\n'
        ) 
   from (  
 select distinct sysid,sql_identifier,stereotype
   from dot_tmp
  union 
 select distinct ref_sysid,ref_sql_identifier,ref_stereotype
   from dot_tmp
  order by sql_identifier
      ) as a
   into def1;

 -- graph edges
 select dbms.concat(
          'o'||sysid||
          ' -> o'||ref_sysid||
          E';\n'
        ) 
   from dot_tmp
   into def2;

   drop table dot_tmp;
   
 return 'digraph '||my_schema||E' {\n'||
         E'rankdir=LR; node[shape="box"];\n'||
         def1||E'\n'||def2||E'}\n';
end
$$;


ALTER FUNCTION dbms.dot_view_dependancies(my_schema name) OWNER TO postgres;

--
-- Name: eval(sql_expression); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION eval(sql_expression) RETURNS text
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


ALTER FUNCTION dbms.eval(sql_expression) OWNER TO postgres;

--
-- Name: FUNCTION eval(sql_expression); Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON FUNCTION eval(sql_expression) IS 'Evaluate SQL expression';


--
-- Name: execute(sql_statement); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION execute(sql_statement) RETURNS integer
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


ALTER FUNCTION dbms.execute(sql_statement) OWNER TO postgres;

--
-- Name: FUNCTION execute(sql_statement); Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON FUNCTION execute(sql_statement) IS 'Execute SQL statement';


--
-- Name: has_oids(regclass); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION has_oids(regclass) RETURNS boolean
    LANGUAGE sql
    AS $_$select relhasoids from pg_catalog.pg_class where oid=$1$_$;


ALTER FUNCTION dbms.has_oids(regclass) OWNER TO postgres;

--
-- Name: is_superuser(text); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION is_superuser(username text) RETURNS boolean
    LANGUAGE sql
    AS $_$ 
 select usesuper from pg_user where usename = $1
$_$;


ALTER FUNCTION dbms.is_superuser(username text) OWNER TO postgres;

--
-- Name: is_system_schema(text); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION is_system_schema(text) RETURNS boolean
    LANGUAGE sql
    AS $_$
SELECT $1 LIKE 'pg_%' OR $1 LIKE 'xpg_%' OR $1 = 'information_schema';
$_$;


ALTER FUNCTION dbms.is_system_schema(text) OWNER TO postgres;

--
-- Name: json_insert(regclass, text, boolean); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION json_insert(my_regclass regclass, my_json text, extend boolean) RETURNS bigint
    LANGUAGE plperlu
    AS $_$
use strict;
use JSON;
use Data::Dumper;
my ($regclass,$json,$extend)=@_;

my $obj=JSON->new->allow_nonref->decode($json);

if(!defined($obj)) { elog(ERROR,'Empty JSON'); return undef; } 
if(ref($obj) ne 'ARRAY') { 
   if(ref($obj) ne 'HASH') {
	elog(ERROR,'JSON neither ARRAY nor HASH'); return undef; 
   } else { $obj = [$obj]; }
}

my $n=0;
my %nid;
my %q=(
 'columns'        => spi_prepare('select * from dbms.pg_get_columns($1)','regclass'),
);

my %cols;
if($extend eq 't') {
 my $cols = spi_exec_prepared($q{'columns'},$regclass)->{rows};
 for my $i (@{$cols}) { 
  $cols{$i->{'name'}}=$i; 
  # elog(NOTICE,Dumper($i)); 
 }
}

my $sqlq = sub { my $a=shift; $a=~s/'/''/g; $a="'".$a."'"; return $a; };
my $sqlqi = sub { my $a=shift; $a=~s/"/""/g; $a='"'.$a.'"'; return $a; };

for my $i (@{$obj}) {
  my @keys;
  my @vals;
  # check if pkey for record is defined
  # make update statement
  for my $j (keys(%{$i})) {
    if($extend eq 't' && !defined($cols{$j})) {
       $cols{$j}={};
       my $ddl="ALTER TABLE $regclass ADD ".($sqlqi->($j))." text";
       elog(NOTICE,$ddl);
       spi_exec_query($ddl);
    }
    push @keys,$sqlqi->($j);
    push @vals,$sqlq->($i->{$j});
  }
  if(@vals) {
    my $keys = join(', ',@keys);
    my $vals = join(', ',@vals);
    my $sql="INSERT INTO $regclass ($keys) VALUES ($vals)";
    elog(NOTICE,$sql);
    my $rv=spi_exec_query($sql);
    $n++;
  }
#  elog(NOTICE,Dumper($i));
}

return $n;

$_$;


ALTER FUNCTION dbms.json_insert(my_regclass regclass, my_json text, extend boolean) OWNER TO postgres;

--
-- Name: json_save(regclass, text, boolean); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION json_save(my_regclass regclass, my_json text, extend boolean) RETURNS bigint
    LANGUAGE plperlu
    AS $_$
use strict;
use JSON;
use Data::Dumper;
my ($regclass,$json,$extend)=@_;

my $obj=JSON->new->allow_nonref->decode($json);

if(!defined($obj)) { elog(ERROR,'Empty JSON'); return undef; } 
if(ref($obj) ne 'ARRAY') { 
   if(ref($obj) ne 'HASH') {
	elog(ERROR,'JSON neither ARRAY no HASH'); return undef; 
   } else { $obj = [$obj]; }
}

my $n=0;
my %nid;
my %q=(
 'primary key'    => spi_prepare('select * from unnest(dbms.primary_key($1)) as name','regclass'),
 'columns'        => spi_prepare('select * from dbms.pg_get_columns($1)','regclass'),
);

my %cols;
if($extend eq 't') {
 my $cols = spi_exec_prepared($q{'columns'},$regclass)->{rows};
 for my $i (@{$cols}) { 
  $cols{$i->{'name'}}=$i; 
  # elog(NOTICE,Dumper($i)); 
 }
}
my @pkey;
my $pkey = spi_exec_prepared($q{'primary key'},$regclass)->{rows};
for my $i (@{$pkey}) {
  push @pkey,$i->{'name'};
}
unless(@pkey) {
  elog(ERROR,'no primary key');
}

my $sqlq = sub { my $a=shift; $a=~s/'/''/g; $a="'".$a."'"; return $a; };
my $sqlqi = sub { my $a=shift; $a=~s/"/""/g; $a='"'.$a.'"'; return $a; };

for my $i (@{$obj}) {
  my @cond;
  my @keys;
  my @vals;
  # check if pkey for record is defined
  for my $j (@pkey) {
    if(!defined($i->{$j})) {
      elog(WARNING,"No primary key in JSON! Skiping record.");
      last;
    } else {
      push @cond,$sqlqi->($j).'='.$sqlq->($i->{$j});
    }
  }
  # make update statement
  for my $j (keys(%{$i})) {
    if($extend eq 't' && !defined($cols{$j})) {
       $cols{$j}={};
       my $ddl="ALTER TABLE $regclass ADD ".($sqlqi->($j))." text";
       elog(NOTICE,$ddl);
       spi_exec_query($ddl);
    }
    push @keys,$sqlqi->($j);
    push @vals,$sqlq->($i->{$j});
  }
  if(@cond && @vals) {
    my $keys = join(', ',@keys);
    my $vals = join(', ',@vals);
    my $sql="UPDATE $regclass SET ($keys) = ($vals) WHERE ".join(' AND ',@cond);
    elog(NOTICE,$sql);
    my $rv=spi_exec_query($sql);
    $n+=$rv->{processed};
    if($rv->{processed}==0) {
      my $sql2="INSERT INTO $regclass ($keys) VALUES ($vals)";
      elog(NOTICE,$sql2);
      my $rv=spi_exec_query($sql2);
      $n++;
    }
  }
#  elog(NOTICE,Dumper($i));
}

#    $subject_id = spi_exec_prepared($q{resource},$si,$model_id)->{rows}->[0]->{nid}; 

return $n;

$_$;


ALTER FUNCTION dbms.json_save(my_regclass regclass, my_json text, extend boolean) OWNER TO postgres;

--
-- Name: FUNCTION json_save(my_regclass regclass, my_json text, extend boolean); Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON FUNCTION json_save(my_regclass regclass, my_json text, extend boolean) IS 'Save json array to table records, optionally adding columns if needed';


--
-- Name: json_save2(regclass, text, boolean); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION json_save2(my_regclass regclass, my_json text, extend boolean) RETURNS bigint
    LANGUAGE plperlu
    AS $_$
use strict;
use JSON;
use Data::Dumper;
my ($regclass,$json,$extend)=@_;

my $obj=JSON->new->allow_nonref->decode($json);

if(!defined($obj)) { elog(ERROR,'Empty JSON'); return undef; } 
if(ref($obj) ne 'ARRAY') { 
   if(ref($obj) ne 'HASH') {
	elog(ERROR,'JSON neither ARRAY no HASH'); return undef; 
   } else { $obj = [$obj]; }
}

my $n=0;
my %nid;
my %q=(
 'primary key'    => spi_prepare('select * from unnest(dbms.primary_key($1)) as name','regclass'),
 'unique keys'    => spi_prepare('select * from dbms.unique_keys where sysid=$1','regclass'),
 'columns'        => spi_prepare('select * from dbms.pg_get_columns($1)','regclass'),
);

my %cols;
if($extend eq 't') {
 my $cols = spi_exec_prepared($q{'columns'},$regclass)->{rows};
 for my $i (@{$cols}) { 
  $cols{$i->{'name'}}=$i; 
  # elog(NOTICE,Dumper($i)); 
 }
}
my $pkey;
my @ukey;
my $ukeys = spi_exec_prepared($q{'unique keys'},$regclass)->{rows};
for my $i (@{$ukeys}) {
  if($i->{'constraint_type'} eq 'PRIMARY KEY') { $pkey = [@{$i->{'attribute_names'}}]; } 
  else { push @ukey, [@{$i->{'attribute_names'}}]; }
}
unshift @ukey,$pkey;
unless(@ukey) {
  elog(ERROR,'no primary or unique key');
}

my $sqlq = sub { my $a=shift; $a=~s/'/''/g; $a="'".$a."'"; return $a; };
my $sqlqi = sub { my $a=shift; $a=~s/"/""/g; $a='"'.$a.'"'; return $a; };

for my $i (@{$obj}) {
  my @cond;
  my @keys;
  my @vals;
  # check if pkey for record is defined
  for my $conf (@ukey) {
    for my $a (@{$conf}) {
      if(!defined($i->{$a})) {
        undef(@cond); last;
      } else {
        push @cond,$sqlqi->($a).'='.$sqlq->($i->{$a});
      }
    }
    if(@cond) { last; }
  }
  if(!@cond) {
    elog(WARNING,"No unique key in JSON! Skiping record.");
  }
  # make update statement
  for my $j (keys(%{$i})) {
    if($extend eq 't' && !defined($cols{$j})) {
      # add new columns in needed
       $cols{$j}={};
       my $ddl="ALTER TABLE $regclass ADD ".($sqlqi->($j))." text";
       elog(NOTICE,$ddl);
       spi_exec_query($ddl);
    }
    push @keys,$sqlqi->($j);
    push @vals,$sqlq->($i->{$j});
  }
  if(@cond && @vals) {
    my $keys = join(', ',@keys);
    my $vals = join(', ',@vals);
    my $sql="UPDATE $regclass SET ($keys) = ($vals) WHERE ".join(' AND ',@cond);
    elog(NOTICE,$sql);
    my $rv=spi_exec_query($sql);
    $n+=$rv->{processed};
    if($rv->{processed}==0) {
      my $sql2="INSERT INTO $regclass ($keys) VALUES ($vals)";
      elog(NOTICE,$sql2);
      my $rv=spi_exec_query($sql2);
      $n++;
    }
  }
#  elog(NOTICE,Dumper($i));
}

#    $subject_id = spi_exec_prepared($q{resource},$si,$model_id)->{rows}->[0]->{nid}; 

return $n;

$_$;


ALTER FUNCTION dbms.json_save2(my_regclass regclass, my_json text, extend boolean) OWNER TO postgres;

--
-- Name: FUNCTION json_save2(my_regclass regclass, my_json text, extend boolean); Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON FUNCTION json_save2(my_regclass regclass, my_json text, extend boolean) IS 'Handles any unique, not just pk';


--
-- Name: name(regclass); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION name(regclass) RETURNS name
    LANGUAGE sql
    AS $_$select c.relname from pg_class c where c.oid=$1$_$;


ALTER FUNCTION dbms.name(regclass) OWNER TO postgres;

--
-- Name: FUNCTION name(regclass); Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON FUNCTION name(regclass) IS 'Return class name';


--
-- Name: namespace(regclass); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION namespace(regclass) RETURNS name
    LANGUAGE sql
    AS $_$select n.nspname from pg_namespace n join pg_class c on c.relnamespace=n.oid where c.oid=$1$_$;


ALTER FUNCTION dbms.namespace(regclass) OWNER TO postgres;

--
-- Name: FUNCTION namespace(regclass); Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON FUNCTION namespace(regclass) IS 'Return class namespace';


--
-- Name: nid(); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION nid() RETURNS bigint
    LANGUAGE sql
    AS $$select nextval('dbms.nid_seq')$$;


ALTER FUNCTION dbms.nid() OWNER TO postgres;

--
-- Name: FUNCTION nid(); Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON FUNCTION nid() IS 'Numeric ID generator';


--
-- Name: pg_acl_http(aclitem[]); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION pg_acl_http(aclitem[]) RETURNS boolean
    LANGUAGE sql
    AS $_$
select true
 where exists (
 select a
   from unnest($1) as a
  where a::text like 'http=%X%/%'
 )
$_$;


ALTER FUNCTION dbms.pg_acl_http(aclitem[]) OWNER TO postgres;

--
-- Name: FUNCTION pg_acl_http(aclitem[]); Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON FUNCTION pg_acl_http(aclitem[]) IS 'Check if aclitem has execute privilege for role http';


--
-- Name: pg_dump(name, name, text); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION pg_dump(name, name, text) RETURNS text
    LANGUAGE sql
    AS $_$  SELECT
    os.system('PGUSER='||current_user||
           ' pg_dump --attribute-inserts --no-owner --no-reconnect ' ||
           ' --schema '|| px.esc_sh($1) ||
           ' --table '|| px.esc_sh($2) ||
           ' '|| coalesce($3,'') ||' '|| current_database());
$_$;


ALTER FUNCTION dbms.pg_dump(name, name, text) OWNER TO postgres;

--
-- Name: pg_get_columns(regclass); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION pg_get_columns(regclass, OUT namespace name, OUT class_name name, OUT name name, OUT ord smallint, OUT type text, OUT size integer, OUT not_null boolean, OUT "default" text, OUT comment text, OUT primary_key name, OUT ndims integer, OUT is_local boolean, OUT storage text, OUT sql_identifier sql_identifier, OUT nuls boolean, OUT regclass oid, OUT definition text) RETURNS SETOF record
    LANGUAGE sql
    AS $_$
 SELECT s.nspname AS namespace, 
        c.relname AS class_name, 
        a.attname AS name, 
        a.attnum AS ord, 
        format_type(t.oid, NULL::integer) AS type, 
        CASE
            WHEN (a.atttypmod - 4) > 0 THEN a.atttypmod - 4
            ELSE NULL::integer
        END AS size, a.attnotnull AS not_null, def.adsrc AS "default", col_description(c.oid, a.attnum::integer) AS comment, 
        con.conname AS primary_key, 
        a.attndims as ndims,
        a.attislocal AS is_local, 
        a.attstorage::text as storage, 
        ((c.oid::regclass)::text || '.' || quote_ident(a.attname))::dbms.sql_identifier AS sql_identifier,
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
/*
        END ||
        CASE
            WHEN def.adsrc IS NOT NULL THEN ' DEFAULT '||def.adsrc
            ELSE ''
*/
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


ALTER FUNCTION dbms.pg_get_columns(regclass, OUT namespace name, OUT class_name name, OUT name name, OUT ord smallint, OUT type text, OUT size integer, OUT not_null boolean, OUT "default" text, OUT comment text, OUT primary_key name, OUT ndims integer, OUT is_local boolean, OUT storage text, OUT sql_identifier sql_identifier, OUT nuls boolean, OUT regclass oid, OUT definition text) OWNER TO postgres;

--
-- Name: FUNCTION pg_get_columns(regclass, OUT namespace name, OUT class_name name, OUT name name, OUT ord smallint, OUT type text, OUT size integer, OUT not_null boolean, OUT "default" text, OUT comment text, OUT primary_key name, OUT ndims integer, OUT is_local boolean, OUT storage text, OUT sql_identifier sql_identifier, OUT nuls boolean, OUT regclass oid, OUT definition text); Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON FUNCTION pg_get_columns(regclass, OUT namespace name, OUT class_name name, OUT name name, OUT ord smallint, OUT type text, OUT size integer, OUT not_null boolean, OUT "default" text, OUT comment text, OUT primary_key name, OUT ndims integer, OUT is_local boolean, OUT storage text, OUT sql_identifier sql_identifier, OUT nuls boolean, OUT regclass oid, OUT definition text) IS 'Table columns';


--
-- Name: primary_key(regclass); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION primary_key(my_class regclass) RETURNS name[]
    LANGUAGE sql
    AS $_$
select attribute_names 
  from dbms.unique_keys
 where sysid=$1
   and constraint_type='PRIMARY KEY'
 $_$;


ALTER FUNCTION dbms.primary_key(my_class regclass) OWNER TO postgres;

--
-- Name: primary_key(name, name); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION primary_key(my_schema name, my_table name) RETURNS name[]
    LANGUAGE sql
    AS $_$
select attribute_names 
  from dbms.unique_keys
 where table_schema=$1
   and table_name=$2
   and constraint_type='PRIMARY KEY'
 $_$;


ALTER FUNCTION dbms.primary_key(my_schema name, my_table name) OWNER TO postgres;

--
-- Name: proc_info(text, text); Type: FUNCTION; Schema: dbms; Owner: postgres
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


ALTER FUNCTION dbms.proc_info(namespace text, name text, OUT arity integer, OUT proc_oid oid, OUT sql_identifier text, OUT argnames text[], OUT argtypes text[], OUT comment text, OUT has_http_acl boolean) OWNER TO postgres;

--
-- Name: sql_full_identifier(name, name); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION sql_full_identifier(namespace name, name name) RETURNS sql_identifier
    LANGUAGE sql STABLE STRICT
    AS $_$
select cast(quote_ident($1)||'.'||quote_ident($2) as dbms.sql_identifier)
$_$;


ALTER FUNCTION dbms.sql_full_identifier(namespace name, name name) OWNER TO postgres;

--
-- Name: FUNCTION sql_full_identifier(namespace name, name name); Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON FUNCTION sql_full_identifier(namespace name, name name) IS 'Return properly quoted full SQL identifier (with schema)';


--
-- Name: sql_identifier(name, name); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION sql_identifier(namespace name, name name) RETURNS sql_identifier
    LANGUAGE sql STABLE STRICT
    AS $_$
select cast(quote_ident($1)||'.'||quote_ident($2) as dbms.sql_identifier)
$_$;


ALTER FUNCTION dbms.sql_identifier(namespace name, name name) OWNER TO postgres;

--
-- Name: FUNCTION sql_identifier(namespace name, name name); Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON FUNCTION sql_identifier(namespace name, name name) IS 'Return properly quoted SQL identifier';


--
-- Name: stereotype(sql_identifier); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION stereotype(sql_identifier) RETURNS text
    LANGUAGE plpgsql
    AS $_$declare
 my_oid oid;
 my_stereotype text;
begin
 begin
   my_oid := regclass($1)::oid;
   select 
       cast( 
         case c.relkind::text
         when 'r' then 'table'
         when 'v' then 'view'
         when 'i' then 'index'
         when 'c' then 'type'
         when 'S' then 'sequence'
       end as text) 
     from pg_class c
    where oid = my_oid
     into my_stereotype;
 exception
   when others then null;
 end;
 return my_stereotype;
end
$_$;


ALTER FUNCTION dbms.stereotype(sql_identifier) OWNER TO postgres;

--
-- Name: syslog(integer); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION syslog(lines integer) RETURNS text
    LANGUAGE sql SECURITY DEFINER
    AS $_$ select os.system('tail -'||$1||' /var/log/postgresql/postgresql-8.4-main.log') $_$;


ALTER FUNCTION dbms.syslog(lines integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: pid_size; Type: TABLE; Schema: dbms; Owner: postgres; Tablespace: 
--

CREATE TABLE pid_size (
    pid integer,
    size bigint
);


ALTER TABLE pid_size OWNER TO postgres;

--
-- Name: temp_space_usage(); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION temp_space_usage() RETURNS SETOF pid_size
    LANGUAGE plperlu
    AS $_$

my $rv=spi_exec_query("select setting from pg_settings where name='data_directory'",1);
my $tmpdir=$rv->{rows}[0]->{setting};
unless($tmpdir) {
	elog(ERROR,"Can't determine data_directory!");
}
$tmpdir.="/base/pgsql_tmp";

my %pid;

if(opendir(DH,$tmpdir)) {
  while(my $i=readdir(DH)) {
    if($i=~m/pgsql_tmp([0-9]+)/) {
	my $pid=$1;
	my $size=(stat($tmpdir."/".$i))[7];
	$pid{$pid}+=$size;
     }
  }
  closedir(DH);
}

for my $k (keys(%pid)) {
  return_next({pid=>$k,size=>$pid{$k}});
}

return undef;
$_$;


ALTER FUNCTION dbms.temp_space_usage() OWNER TO postgres;

--
-- Name: update_stat_daily_catalog_usage(); Type: FUNCTION; Schema: dbms; Owner: postgres
--

CREATE FUNCTION update_stat_daily_catalog_usage() RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
 my_day date;
begin
 my_day:=date(now());
 delete from dbms.stat_daily_catalog_usage
  where day=my_day;
 insert into dbms.stat_daily_catalog_usage
 select my_day,*
   from dbms.catalog_usage;
 return 'ok';
end
$$;


ALTER FUNCTION dbms.update_stat_daily_catalog_usage() OWNER TO postgres;

--
-- Name: FUNCTION update_stat_daily_catalog_usage(); Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON FUNCTION update_stat_daily_catalog_usage() IS 'Take a snapshot of table sizes into stat_daily_catalog_usage';


--
-- Name: array_agg(anyelement); Type: AGGREGATE; Schema: dbms; Owner: postgres
--

CREATE AGGREGATE array_agg(anyelement) (
    SFUNC = array_append,
    STYPE = anyarray,
    INITCOND = '{}'
);


ALTER AGGREGATE dbms.array_agg(anyelement) OWNER TO postgres;

--
-- Name: concat(text); Type: AGGREGATE; Schema: dbms; Owner: postgres
--

CREATE AGGREGATE concat(text) (
    SFUNC = textcat,
    STYPE = text
);


ALTER AGGREGATE dbms.concat(text) OWNER TO postgres;

--
-- Name: AGGREGATE concat(text); Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON AGGREGATE concat(text) IS 'String concatenation aggregate';


--
-- Name: catalog_usage; Type: VIEW; Schema: dbms; Owner: postgres
--

CREATE VIEW catalog_usage AS
 SELECT tab.sql_identifier,
    pg_relation_size((tab.sql_identifier)::regclass) AS pg_relation_size,
    pg_total_relation_size((tab.sql_identifier)::regclass) AS pg_total_relation_size,
    pg_size_pretty(pg_total_relation_size((tab.sql_identifier)::regclass)) AS pg_size_pretty,
    (c.reltuples)::bigint AS tuples,
    pg_stat_get_live_tuples(((tab.sql_identifier)::regclass)::oid) AS live,
    pg_stat_get_dead_tuples(((tab.sql_identifier)::regclass)::oid) AS dead
   FROM (( SELECT ((quote_ident((tables.table_schema)::text) || '.'::text) || quote_ident((tables.table_name)::text)) AS sql_identifier
           FROM information_schema.tables
          WHERE (((tables.table_type)::text = 'BASE TABLE'::text) AND ((tables.table_schema)::text !~~ 'pg_catalog'::text))) tab
     JOIN pg_class c ON ((c.oid = ((tab.sql_identifier)::regclass)::oid)))
  ORDER BY pg_total_relation_size((tab.sql_identifier)::regclass) DESC;


ALTER TABLE catalog_usage OWNER TO postgres;

--
-- Name: VIEW catalog_usage; Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON VIEW catalog_usage IS 'Current DBMS disk space usage per table';


--
-- Name: classes; Type: VIEW; Schema: dbms; Owner: postgres
--

CREATE VIEW classes AS
 SELECT c.oid AS sysid,
    n.nspname AS namespace,
    c.relname AS name,
    (
        CASE
            WHEN (c.relkind = 'r'::"char") THEN 'table'::text
            WHEN (c.relkind = 'v'::"char") THEN 'view'::text
            WHEN (c.relkind = 'i'::"char") THEN 'index'::text
            WHEN (c.relkind = 'S'::"char") THEN 'sequence'::text
            WHEN (c.relkind = 's'::"char") THEN 'special'::text
            ELSE NULL::text
        END)::name AS stereotype,
    u.usename AS owner,
    obj_description(c.oid) AS comment,
    (c.oid)::regclass AS regclass,
    sql_identifier(n.nspname, c.relname) AS sql_identifier,
    c.relhasoids AS has_oids,
        CASE
            WHEN (c.relkind = 'r'::"char") THEN true
            ELSE false
        END AS has_tableoid,
    (( SELECT count(*) AS count
           FROM pg_inherits
          WHERE (pg_inherits.inhrelid = c.oid)) = 0) AS is_root,
    (( SELECT count(*) AS count
           FROM pg_inherits
          WHERE (pg_inherits.inhparent = c.oid)) = 0) AS is_leaf
   FROM ((pg_class c
     LEFT JOIN pg_user u ON ((c.relowner = u.usesysid)))
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE (((((c.relkind = 'r'::"char") OR (c.relkind = 'v'::"char")) OR (c.relkind = ''::"char")) AND has_table_privilege(c.oid, 'select'::text)) AND has_schema_privilege(n.oid, 'usage'::text))
  ORDER BY n.nspname, c.relname;


ALTER TABLE classes OWNER TO postgres;

--
-- Name: VIEW classes; Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON VIEW classes IS 'Classes (tables and views)';


--
-- Name: foreign_keys; Type: VIEW; Schema: dbms; Owner: postgres
--

CREATE VIEW foreign_keys AS
 SELECT c.conname AS constraint_name,
    s1.nspname AS constraint_schema,
    c1.relname AS constraint_table,
    s2.nspname AS ref_table_schema,
    c2.relname AS ref_table_name,
    array_upper(c.conkey, 1) AS size,
    c.conkey,
    c.confkey,
    c1.oid AS sysid,
    c2.oid AS ref_sysid,
    c.oid AS constraint_sysid
   FROM ((((pg_constraint c
     JOIN pg_class c1 ON ((c1.oid = c.conrelid)))
     JOIN pg_namespace s1 ON ((s1.oid = c1.relnamespace)))
     JOIN pg_class c2 ON ((c2.oid = c.confrelid)))
     JOIN pg_namespace s2 ON ((s2.oid = c2.relnamespace)))
  WHERE (((((c1.relkind = 'r'::"char") OR (c1.relkind = 'v'::"char")) OR (c1.relkind = ''::"char")) AND (c.contype = 'f'::"char")) AND (c1.relname !~~ 'pg%_'::text));


ALTER TABLE foreign_keys OWNER TO postgres;

--
-- Name: VIEW foreign_keys; Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON VIEW foreign_keys IS 'Database foreign keys';


--
-- Name: functions; Type: VIEW; Schema: dbms; Owner: postgres
--

CREATE VIEW functions AS
 SELECT p.oid AS sysid,
    s.nspname AS namespace,
    p.proname AS name,
    pg_description.description AS comment,
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


ALTER TABLE functions OWNER TO postgres;

--
-- Name: indexes; Type: VIEW; Schema: dbms; Owner: postgres
--

CREATE VIEW indexes AS
 SELECT DISTINCT c.oid AS sysid,
    n.nspname AS namespace,
    c.relname AS class,
    i.relname AS name,
    NULL::text AS tablespace,
        CASE d.refclassid
            WHEN 'pg_constraint'::regclass THEN ((((((('ALTER TABLE '::text || quote_ident((n.nspname)::text)) || '.'::text) || quote_ident((c.relname)::text)) || ' ADD CONSTRAINT '::text) || quote_ident((cc.conname)::text)) || ' '::text) || pg_get_constraintdef(cc.oid))
            ELSE pg_get_indexdef(i.oid)
        END AS indexdef,
    cc.conname AS constraint_name
   FROM (((((pg_index x
     JOIN pg_class c ON ((c.oid = x.indrelid)))
     JOIN pg_class i ON ((i.oid = x.indexrelid)))
     JOIN pg_depend d ON ((d.objid = x.indexrelid)))
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
     LEFT JOIN pg_constraint cc ON ((cc.oid = d.refobjid)))
  WHERE ((c.relkind = 'r'::"char") AND (i.relkind = 'i'::"char"))
  ORDER BY c.oid, n.nspname, c.relname, i.relname, NULL::text,
        CASE d.refclassid
            WHEN 'pg_constraint'::regclass THEN ((((((('ALTER TABLE '::text || quote_ident((n.nspname)::text)) || '.'::text) || quote_ident((c.relname)::text)) || ' ADD CONSTRAINT '::text) || quote_ident((cc.conname)::text)) || ' '::text) || pg_get_constraintdef(cc.oid))
            ELSE pg_get_indexdef(i.oid)
        END, cc.conname;


ALTER TABLE indexes OWNER TO postgres;

--
-- Name: nid_seq; Type: SEQUENCE; Schema: dbms; Owner: postgres
--

CREATE SEQUENCE nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE nid_seq OWNER TO postgres;

--
-- Name: sql_advice_functions; Type: VIEW; Schema: dbms; Owner: postgres
--

CREATE VIEW sql_advice_functions AS
 SELECT f.owner,
    f.security,
    f.language,
    f.sql_identifier,
    f.namespace,
    f.name,
    f.sysid,
    ((('REVOKE ALL ON FUNCTION '::text || (f.sql_identifier)::text) || ' FROM PUBLIC'::text))::sql_statement AS sql_advice,
    f.comment
   FROM ((functions f
     JOIN pg_language l ON ((l.lanname = f.language)))
     JOIN pg_user u ON ((u.usename = f.owner)))
  WHERE (((NOT l.lanpltrusted) AND l.lanispl) AND (NOT u.usesuper));


ALTER TABLE sql_advice_functions OWNER TO postgres;

--
-- Name: VIEW sql_advice_functions; Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON VIEW sql_advice_functions IS 'Advices about functions';


--
-- Name: sql_advice_owner; Type: VIEW; Schema: dbms; Owner: postgres
--

CREATE VIEW sql_advice_owner AS
 SELECT (((((('ALTER '::text || upper((c.stereotype)::text)) || ' '::text) || (c.sql_identifier)::text) || ' OWNER TO '::text) || quote_ident((u.usename)::text)) || ';'::text) AS sql_advice,
    c.sysid,
    c.stereotype AS object_type,
    c.namespace,
    c.name,
    c.sql_identifier,
    c.owner,
    c.comment
   FROM ((classes c
     JOIN pg_namespace n ON ((n.nspname = c.namespace)))
     JOIN pg_user u ON ((u.usesysid = n.nspowner)))
  WHERE ((((c.owner <> c.namespace) AND (c.owner <> u.usename)) AND (NOT is_system_schema((c.namespace)::text))) AND (c.owner <> 'postgres'::name));


ALTER TABLE sql_advice_owner OWNER TO postgres;

--
-- Name: VIEW sql_advice_owner; Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON VIEW sql_advice_owner IS 'Tables and views where owner is different from schema';


--
-- Name: sql_advice; Type: VIEW; Schema: dbms; Owner: postgres
--

CREATE VIEW sql_advice AS
 SELECT 'OWNER'::text AS advice_class,
    a1.namespace,
    a1.name,
    a1.owner,
    a1.sql_identifier,
    a1.sysid,
    a1.comment,
    a1.sql_advice
   FROM sql_advice_owner a1
UNION
 SELECT 'UNSECURE'::text AS advice_class,
    a2.namespace,
    a2.name,
    a2.owner,
    a2.sql_identifier,
    a2.sysid,
    a2.comment,
    a2.sql_advice
   FROM sql_advice_functions a2
  ORDER BY 2, 3;


ALTER TABLE sql_advice OWNER TO postgres;

--
-- Name: VIEW sql_advice; Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON VIEW sql_advice IS 'All SQL advices';


--
-- Name: stat_daily_catalog_usage; Type: TABLE; Schema: dbms; Owner: postgres; Tablespace: 
--

CREATE TABLE stat_daily_catalog_usage (
    day date NOT NULL,
    sql_identifier text NOT NULL,
    pg_relation_size bigint,
    pg_total_relation_size bigint,
    pg_size_pretty text,
    live bigint,
    dead bigint
);


ALTER TABLE stat_daily_catalog_usage OWNER TO postgres;

--
-- Name: tables_changed; Type: VIEW; Schema: dbms; Owner: postgres
--

CREATE VIEW tables_changed AS
 SELECT ((pg_stat_all_tables.relid)::regclass)::text AS sql_identifier,
    pg_stat_all_tables.n_tup_ins,
    pg_stat_all_tables.n_tup_upd,
    pg_stat_all_tables.n_tup_hot_upd,
    pg_stat_all_tables.n_tup_del
   FROM pg_stat_all_tables
  WHERE ((((pg_stat_all_tables.n_tup_ins + pg_stat_all_tables.n_tup_upd) + pg_stat_all_tables.n_tup_del) > 1) AND (pg_stat_all_tables.schemaname !~~ 'pg_%'::text))
  ORDER BY ((pg_stat_all_tables.n_tup_ins + pg_stat_all_tables.n_tup_upd) + pg_stat_all_tables.n_tup_del);


ALTER TABLE tables_changed OWNER TO postgres;

--
-- Name: VIEW tables_changed; Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON VIEW tables_changed IS 'Tables with changes since last pg_stat_reset()';


--
-- Name: temp_space_usage; Type: VIEW; Schema: dbms; Owner: postgres
--

CREATE VIEW temp_space_usage AS
 SELECT temp_space_usage.pid,
    temp_space_usage.size
   FROM temp_space_usage() temp_space_usage(pid, size);


ALTER TABLE temp_space_usage OWNER TO postgres;

--
-- Name: unique_keys; Type: VIEW; Schema: dbms; Owner: postgres
--

CREATE VIEW unique_keys AS
 SELECT s.nspname AS table_schema,
    c.relname AS table_name,
    c2.conname AS constraint_name,
        CASE c2.contype
            WHEN 'p'::"char" THEN 'PRIMARY KEY'::text
            WHEN 'u'::"char" THEN 'UNIQUE'::text
            ELSE NULL::text
        END AS constraint_type,
    attribute_names((c.oid)::regclass, c2.conkey) AS attribute_names,
    attribute_types((c.oid)::regclass, c2.conkey) AS attribute_types,
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


ALTER TABLE unique_keys OWNER TO postgres;

--
-- Name: view_dependancies; Type: VIEW; Schema: dbms; Owner: postgres
--

CREATE VIEW view_dependancies AS
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


ALTER TABLE view_dependancies OWNER TO postgres;

--
-- Name: VIEW view_dependancies; Type: COMMENT; Schema: dbms; Owner: postgres
--

COMMENT ON VIEW view_dependancies IS 'Shows class dependancies';


--
-- Name: stat_daily_catalog_usage_pkey; Type: CONSTRAINT; Schema: dbms; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY stat_daily_catalog_usage
    ADD CONSTRAINT stat_daily_catalog_usage_pkey PRIMARY KEY (day, sql_identifier);


--
-- Name: dbms; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA dbms FROM PUBLIC;
REVOKE ALL ON SCHEMA dbms FROM postgres;
GRANT ALL ON SCHEMA dbms TO postgres;
GRANT USAGE ON SCHEMA dbms TO PUBLIC;


--
-- Name: classes; Type: ACL; Schema: dbms; Owner: postgres
--

REVOKE ALL ON TABLE classes FROM PUBLIC;
REVOKE ALL ON TABLE classes FROM postgres;
GRANT ALL ON TABLE classes TO postgres;
GRANT SELECT ON TABLE classes TO PUBLIC;


--
-- Name: tables_changed; Type: ACL; Schema: dbms; Owner: postgres
--

REVOKE ALL ON TABLE tables_changed FROM PUBLIC;
REVOKE ALL ON TABLE tables_changed FROM postgres;
GRANT ALL ON TABLE tables_changed TO postgres;
GRANT SELECT ON TABLE tables_changed TO PUBLIC;


--
-- Name: unique_keys; Type: ACL; Schema: dbms; Owner: postgres
--

REVOKE ALL ON TABLE unique_keys FROM PUBLIC;
REVOKE ALL ON TABLE unique_keys FROM postgres;
GRANT ALL ON TABLE unique_keys TO postgres;
GRANT SELECT ON TABLE unique_keys TO PUBLIC;


--
-- Name: view_dependancies; Type: ACL; Schema: dbms; Owner: postgres
--

REVOKE ALL ON TABLE view_dependancies FROM PUBLIC;
REVOKE ALL ON TABLE view_dependancies FROM postgres;
GRANT ALL ON TABLE view_dependancies TO postgres;
GRANT SELECT ON TABLE view_dependancies TO PUBLIC;


--
-- PostgreSQL database dump complete
--

