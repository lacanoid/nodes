all: backup-database

backup-database:
	pg_dump -s -n px > px.sql
	pg_dump -s -n os > os.sql
	pg_dump -s -n rdf > rdf.sql
	pg_dump -s -n dbms > dbms.sql
	pg_dump -s -n http > http.sql
	pg_dump -s -n wiki > wiki.sql
	pg_dump -s -n dbms_metadata > dbms_metadata.sql
	pg_dump -s -n oordbms > oordbms.sql
	pg_dump -s -n sparql > sparql.sql
	pg_dump -s -n datalink > datalink.sql
	pg_dump -s -n network > network.sql
