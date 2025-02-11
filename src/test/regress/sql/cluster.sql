--DDL_STATEMENT_BEGIN--
drop table if exists clstr_tst_s;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TABLE clstr_tst_s (rf_a SERIAL PRIMARY KEY,
	b INT);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
drop table if exists clstr_tst;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TABLE clstr_tst (a SERIAL PRIMARY KEY,
	b INT,
	c varchar(50),
	d text);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE INDEX clstr_tst_b ON clstr_tst (b);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE INDEX clstr_tst_c ON clstr_tst (c);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE INDEX clstr_tst_c_b ON clstr_tst (c,b);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE INDEX clstr_tst_b_c ON clstr_tst (b,c);
--DDL_STATEMENT_END--

INSERT INTO clstr_tst_s (b) VALUES (0);
INSERT INTO clstr_tst_s (b) SELECT b FROM clstr_tst_s;
INSERT INTO clstr_tst_s (b) SELECT b FROM clstr_tst_s;
INSERT INTO clstr_tst_s (b) SELECT b FROM clstr_tst_s;
INSERT INTO clstr_tst_s (b) SELECT b FROM clstr_tst_s;
INSERT INTO clstr_tst_s (b) SELECT b FROM clstr_tst_s;

--DDL_STATEMENT_BEGIN--
drop table if exists clstr_tst_inh;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TABLE clstr_tst_inh (like clstr_tst);
--DDL_STATEMENT_END--

INSERT INTO clstr_tst (b, c) VALUES (11, 'once');
INSERT INTO clstr_tst (b, c) VALUES (10, 'diez');
INSERT INTO clstr_tst (b, c) VALUES (31, 'treinta y uno');
INSERT INTO clstr_tst (b, c) VALUES (22, 'veintidos');
INSERT INTO clstr_tst (b, c) VALUES (3, 'tres');
INSERT INTO clstr_tst (b, c) VALUES (20, 'veinte');
INSERT INTO clstr_tst (b, c) VALUES (23, 'veintitres');
INSERT INTO clstr_tst (b, c) VALUES (21, 'veintiuno');
INSERT INTO clstr_tst (b, c) VALUES (4, 'cuatro');
INSERT INTO clstr_tst (b, c) VALUES (14, 'catorce');
INSERT INTO clstr_tst (b, c) VALUES (2, 'dos');
INSERT INTO clstr_tst (b, c) VALUES (18, 'dieciocho');
INSERT INTO clstr_tst (b, c) VALUES (27, 'veintisiete');
INSERT INTO clstr_tst (b, c) VALUES (25, 'veinticinco');
INSERT INTO clstr_tst (b, c) VALUES (13, 'trece');
INSERT INTO clstr_tst (b, c) VALUES (28, 'veintiocho');
INSERT INTO clstr_tst (b, c) VALUES (32, 'treinta y dos');
INSERT INTO clstr_tst (b, c) VALUES (5, 'cinco');
INSERT INTO clstr_tst (b, c) VALUES (29, 'veintinueve');
INSERT INTO clstr_tst (b, c) VALUES (1, 'uno');
INSERT INTO clstr_tst (b, c) VALUES (24, 'veinticuatro');
INSERT INTO clstr_tst (b, c) VALUES (30, 'treinta');
INSERT INTO clstr_tst (b, c) VALUES (12, 'doce');
INSERT INTO clstr_tst (b, c) VALUES (17, 'diecisiete');
INSERT INTO clstr_tst (b, c) VALUES (9, 'nueve');
INSERT INTO clstr_tst (b, c) VALUES (19, 'diecinueve');
INSERT INTO clstr_tst (b, c) VALUES (26, 'veintiseis');
INSERT INTO clstr_tst (b, c) VALUES (15, 'quince');
INSERT INTO clstr_tst (b, c) VALUES (7, 'siete');
INSERT INTO clstr_tst (b, c) VALUES (16, 'dieciseis');
INSERT INTO clstr_tst (b, c) VALUES (8, 'ocho');
-- This entry is needed to test that TOASTED values are copied correctly.
INSERT INTO clstr_tst (b, c, d) VALUES (6, 'seis', repeat('xyzzy', 100000));

-- CLUSTER clstr_tst_c ON clstr_tst;
SELECT a,b,c,substring(d for 30), length(d) from clstr_tst;
SELECT a,b,c,substring(d for 30), length(d) from clstr_tst ORDER BY a;
SELECT a,b,c,substring(d for 30), length(d) from clstr_tst ORDER BY b;
SELECT a,b,c,substring(d for 30), length(d) from clstr_tst ORDER BY c;

-- Verify that inheritance link still works
INSERT INTO clstr_tst_inh VALUES (0, 100, 'in child table');
SELECT a,b,c,substring(d for 30), length(d) from clstr_tst;

-- Verify that foreign key link still works
INSERT INTO clstr_tst (b, c) VALUES (1111, 'this should fail');

SELECT conname FROM pg_constraint WHERE conrelid = 'clstr_tst'::regclass
ORDER BY 1;


SELECT relname, relkind,
    EXISTS(SELECT 1 FROM pg_class WHERE oid = c.reltoastrelid) AS hastoast
FROM pg_class c WHERE relname LIKE 'clstr_tst%' ORDER BY relname;

-- Verify that indisclustered is correctly set
SELECT pg_class.relname FROM pg_index, pg_class, pg_class AS pg_class_2
WHERE pg_class.oid=indexrelid
	AND indrelid=pg_class_2.oid
	AND pg_class_2.relname = 'clstr_tst'
	AND indisclustered;

-- Try changing indisclustered
-- ALTER TABLE clstr_tst CLUSTER ON clstr_tst_b_c;
SELECT pg_class.relname FROM pg_index, pg_class, pg_class AS pg_class_2
WHERE pg_class.oid=indexrelid
	AND indrelid=pg_class_2.oid
	AND pg_class_2.relname = 'clstr_tst'
	AND indisclustered;

-- Try turning off all clustering
-- ALTER TABLE clstr_tst SET WITHOUT CLUSTER;
SELECT pg_class.relname FROM pg_index, pg_class, pg_class AS pg_class_2
WHERE pg_class.oid=indexrelid
	AND indrelid=pg_class_2.oid
	AND pg_class_2.relname = 'clstr_tst'
	AND indisclustered;

-- Verify that clustering all tables does in fact cluster the right ones
--DDL_STATEMENT_BEGIN--
CREATE USER regress_clstr_user;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TABLE clstr_1 (a INT PRIMARY KEY);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TABLE clstr_2 (a INT PRIMARY KEY);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TABLE clstr_3 (a INT PRIMARY KEY);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
ALTER TABLE clstr_1 OWNER TO regress_clstr_user;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
ALTER TABLE clstr_3 OWNER TO regress_clstr_user;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
GRANT SELECT ON clstr_2 TO regress_clstr_user;
--DDL_STATEMENT_END--
INSERT INTO clstr_1 VALUES (2);
INSERT INTO clstr_1 VALUES (1);
INSERT INTO clstr_2 VALUES (2);
INSERT INTO clstr_2 VALUES (1);
INSERT INTO clstr_3 VALUES (2);
INSERT INTO clstr_3 VALUES (1);

-- "CLUSTER <tablename>" on a table that hasn't been clustered
-- CLUSTER clstr_2;

-- CLUSTER clstr_1_pkey ON clstr_1;
-- CLUSTER clstr_2 USING clstr_2_pkey;
SELECT * FROM clstr_1 UNION ALL
  SELECT * FROM clstr_2 UNION ALL
  SELECT * FROM clstr_3 order by 1;

-- revert to the original state
DELETE FROM clstr_1;
DELETE FROM clstr_2;
DELETE FROM clstr_3;
INSERT INTO clstr_1 VALUES (2);
INSERT INTO clstr_1 VALUES (1);
INSERT INTO clstr_2 VALUES (2);
INSERT INTO clstr_2 VALUES (1);
INSERT INTO clstr_3 VALUES (2);
INSERT INTO clstr_3 VALUES (1);

-- this user can only cluster clstr_1 and clstr_3, but the latter
-- has not been clustered
SET SESSION AUTHORIZATION regress_clstr_user;
SELECT * FROM clstr_1 UNION ALL
  SELECT * FROM clstr_2 UNION ALL
  SELECT * FROM clstr_3 order by 1;

-- cluster a single table using the indisclustered bit previously set
DELETE FROM clstr_1;
INSERT INTO clstr_1 VALUES (2);
INSERT INTO clstr_1 VALUES (1);
SELECT * FROM clstr_1 order by 1;

-- Test MVCC-safety of cluster. There isn't much we can do to verify the
-- results with a single backend...

--DDL_STATEMENT_BEGIN--
CREATE TABLE clustertest (key1 int PRIMARY KEY);
--DDL_STATEMENT_END--

INSERT INTO clustertest VALUES (10);
INSERT INTO clustertest VALUES (20);
INSERT INTO clustertest VALUES (30);
INSERT INTO clustertest VALUES (40);
INSERT INTO clustertest VALUES (50);

BEGIN;

-- Test update where the old row version is found first in the scan
UPDATE clustertest SET key1 = 100 WHERE key1 = 10;

-- Test update where the new row version is found first in the scan
UPDATE clustertest SET key1 = 35 WHERE key1 = 40;

-- Test longer update chain
UPDATE clustertest SET key1 = 60 WHERE key1 = 50;
UPDATE clustertest SET key1 = 70 WHERE key1 = 60;
UPDATE clustertest SET key1 = 80 WHERE key1 = 70;

SELECT * FROM clustertest order by key1;
-- CLUSTER clustertest_pkey ON clustertest;
SELECT * FROM clustertest order by key1;

COMMIT;

SELECT * FROM clustertest order by key1;

-- check that temp tables can be clustered
--DDL_STATEMENT_BEGIN--
create temp table clstr_temp (col1 int primary key, col2 text);
--DDL_STATEMENT_END--
insert into clstr_temp values (2, 'two'), (1, 'one');
-- cluster clstr_temp using clstr_temp_pkey;
select * from clstr_temp;
--DDL_STATEMENT_BEGIN--
drop table clstr_temp;
--DDL_STATEMENT_END--

RESET SESSION AUTHORIZATION;

-- Check that partitioned tables cannot be clustered
--DDL_STATEMENT_BEGIN--
CREATE TABLE clstrpart (a int) PARTITION BY RANGE (a);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE INDEX clstrpart_idx ON clstrpart (a);
--DDL_STATEMENT_END--
-- ALTER TABLE clstrpart CLUSTER ON clstrpart_idx;
-- CLUSTER clstrpart USING clstrpart_idx;
--DDL_STATEMENT_BEGIN--
DROP TABLE clstrpart;
--DDL_STATEMENT_END--


--DDL_STATEMENT_BEGIN--
create table clstr_4 (like tenk1);
--DDL_STATEMENT_END--
insert into clstr_4 select * from tenk1;
--DDL_STATEMENT_BEGIN--
create index cluster_sort on clstr_4 (hundred, thousand, tenthous);
--DDL_STATEMENT_END--
set enable_indexscan = off;

-- Use external sort:
set maintenance_work_mem = '1MB';
select * from
(select unique1, hundred, lag(hundred) over () as lhundred,
        thousand, lag(thousand) over () as lthousand,
        tenthous, lag(tenthous) over () as ltenthous from clstr_4) ss
where row(hundred, thousand, tenthous) <= row(lhundred, lthousand, ltenthous);

reset enable_indexscan;
reset maintenance_work_mem;

-- clean up
--DDL_STATEMENT_BEGIN--
DROP TABLE clustertest;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
DROP TABLE clstr_1;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
DROP TABLE clstr_2;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
DROP TABLE clstr_3;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
DROP TABLE clstr_4;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
DROP USER regress_clstr_user;
--DDL_STATEMENT_END--
