--
-- CREATE_INDEX
-- Create ancillary data structures (i.e. indices)
--
set default_nulls_smallest = off;
--
-- BTREE
--
--DDL_STATEMENT_BEGIN--
CREATE INDEX onek_unique1 ON onek USING btree(unique1 int4_ops);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE INDEX IF NOT EXISTS onek_unique1 ON onek USING btree(unique1 int4_ops);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE INDEX IF NOT EXISTS ON onek USING btree(unique1 int4_ops);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE INDEX onek_unique2 ON onek USING btree(unique2 int4_ops);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE INDEX onek_hundred ON onek USING btree(hundred int4_ops);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE INDEX onek_stringu1 ON onek USING btree(stringu1 name_ops);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE INDEX tenk1_unique1 ON tenk1 USING btree(unique1 int4_ops);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE INDEX tenk1_unique2 ON tenk1 USING btree(unique2 int4_ops);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE INDEX tenk1_hundred ON tenk1 USING btree(hundred int4_ops);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE INDEX tenk1_thous_tenthous ON tenk1 (thousand, tenthous);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE INDEX tenk2_unique1 ON tenk2 USING btree(unique1 int4_ops);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE INDEX tenk2_unique2 ON tenk2 USING btree(unique2 int4_ops);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE INDEX tenk2_hundred ON tenk2 USING btree(hundred int4_ops);
--DDL_STATEMENT_END--

-- test comments
COMMENT ON INDEX six_wrong IS 'bad index';
COMMENT ON INDEX six IS 'good index';
COMMENT ON INDEX six IS NULL;

--
-- BTREE ascending/descending cases
--
-- we load int4/text from pure descending data (each key is a new
-- low key) and name/f8 from pure ascending data (each key is a new
-- high key).  we had a bug where new low keys would sometimes be
-- "lost".
--
--DDL_STATEMENT_BEGIN--
CREATE INDEX bt_i4_index ON bt_i4_heap USING btree (seqno int4_ops);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE INDEX bt_name_index ON bt_name_heap USING btree (seqno name_ops);
--DDL_STATEMENT_END--

-- CREATE INDEX bt_txt_index ON bt_txt_heap USING btree (seqno text_ops);

--DDL_STATEMENT_BEGIN--
CREATE INDEX bt_f8_index ON bt_f8_heap USING btree (seqno float8_ops);
--DDL_STATEMENT_END--

--
-- HASH
--
--DDL_STATEMENT_BEGIN--
CREATE INDEX hash_i4_index ON hash_i4_heap USING hash (random int4_ops);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE INDEX hash_name_index ON hash_name_heap USING hash (random name_ops);
--DDL_STATEMENT_END--

-- CREATE INDEX hash_txt_index ON hash_txt_heap USING hash (random text_ops);
--DDL_STATEMENT_BEGIN--
CREATE INDEX hash_f8_index ON hash_f8_heap USING hash (random float8_ops) WITH (fillfactor=60);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE UNLOGGED TABLE unlogged_hash_table (id int4);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE INDEX unlogged_hash_index ON unlogged_hash_table USING hash (id int4_ops);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
DROP TABLE unlogged_hash_table;
--DDL_STATEMENT_END--

-- CREATE INDEX hash_ovfl_index ON hash_ovfl_heap USING hash (x int4_ops);

-- Test hash index build tuplesorting.  Force hash tuplesort using low
-- maintenance_work_mem setting and fillfactor:
SET maintenance_work_mem = '1MB';
--DDL_STATEMENT_BEGIN--
CREATE INDEX hash_tuplesort_idx ON tenk1 USING hash (stringu1 name_ops) WITH (fillfactor = 10);
--DDL_STATEMENT_END--
EXPLAIN (COSTS OFF)
SELECT count(*) FROM tenk1 WHERE stringu1 = 'TVAAAA';
SELECT count(*) FROM tenk1 WHERE stringu1 = 'TVAAAA';
--DDL_STATEMENT_BEGIN--
DROP INDEX hash_tuplesort_idx;
--DDL_STATEMENT_END--
RESET maintenance_work_mem;

--
-- Test unique index with included columns
--
--DDL_STATEMENT_BEGIN--
CREATE TABLE covering_index_heap (f1 int, f2 int, f3 text);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE UNIQUE INDEX covering_index_index on covering_index_heap (f1,f2);
--DDL_STATEMENT_END--

INSERT INTO covering_index_heap VALUES(1,1,'AAA');
INSERT INTO covering_index_heap VALUES(1,2,'AAA');
-- this should fail because of unique index on f1,f2:
INSERT INTO covering_index_heap VALUES(1,2,'BBB');
-- and this shouldn't:
INSERT INTO covering_index_heap VALUES(1,4,'AAA');
-- Try to build index on table that already contains data
--DDL_STATEMENT_BEGIN--
CREATE UNIQUE INDEX covering_pkey on covering_index_heap (f1,f2);
--DDL_STATEMENT_END--
-- Try to use existing covering index as primary key
-- ALTER TABLE covering_index_heap ADD CONSTRAINT covering_pkey PRIMARY KEY USING INDEX covering_pkey;
--DDL_STATEMENT_BEGIN--
DROP TABLE covering_index_heap;
--DDL_STATEMENT_END--

--
-- Test ADD CONSTRAINT USING INDEX
--

--DDL_STATEMENT_BEGIN--
CREATE TABLE cwi_test( a int , b varchar(10), c char);
--DDL_STATEMENT_END--

-- add some data so that all tests have something to work with.

INSERT INTO cwi_test VALUES(1, 2), (3, 4), (5, 6);

--DDL_STATEMENT_BEGIN--
CREATE UNIQUE INDEX cwi_uniq_idx ON cwi_test(a , b);
--DDL_STATEMENT_END--
--ALTER TABLE cwi_test ADD primary key USING INDEX cwi_uniq_idx;

\d cwi_test
\d cwi_uniq_idx

--DDL_STATEMENT_BEGIN--
CREATE UNIQUE INDEX cwi_uniq2_idx ON cwi_test(b , a);
--DDL_STATEMENT_END--
--ALTER TABLE cwi_test DROP CONSTRAINT cwi_uniq_idx,
--	ADD CONSTRAINT cwi_replaced_pkey PRIMARY KEY
--		USING INDEX cwi_uniq2_idx;
--\d cwi_test
--\d cwi_replaced_pkey
--DROP INDEX cwi_replaced_pkey;	-- Should fail; a constraint depends on it

--DDL_STATEMENT_BEGIN--
DROP TABLE cwi_test;
--DDL_STATEMENT_END--

-- ADD CONSTRAINT USING INDEX is forbidden on partitioned tables
--DDL_STATEMENT_BEGIN--
CREATE TABLE cwi_test(a int) PARTITION BY hash (a);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create unique index on cwi_test (a);
--DDL_STATEMENT_END--
--alter table cwi_test add primary key using index cwi_test_a_idx ;
--DDL_STATEMENT_BEGIN--
DROP TABLE cwi_test;
--DDL_STATEMENT_END--

--
-- Tests for IS NULL/IS NOT NULL with b-tree indexes
--
--DDL_STATEMENT_BEGIN--
drop table if exists onek_with_null;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table onek_with_null (like onek);
--DDL_STATEMENT_END--
INSERT INTO onek_with_null (unique1,unique2) VALUES (NULL, -1), (NULL, NULL);
--DDL_STATEMENT_BEGIN--
CREATE UNIQUE INDEX onek_nulltest ON onek_with_null (unique2,unique1);
--DDL_STATEMENT_END--

SET enable_seqscan = OFF;
SET enable_indexscan = ON;
SET enable_bitmapscan = ON;

SELECT count(*) FROM onek_with_null WHERE unique1 IS NULL;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NULL AND unique2 IS NULL;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NOT NULL;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NULL AND unique2 IS NOT NULL;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NOT NULL AND unique1 > 500;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NULL AND unique1 > 500;

--DDL_STATEMENT_BEGIN--
DROP INDEX onek_nulltest;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE UNIQUE INDEX onek_nulltest ON onek_with_null (unique2 desc,unique1);
--DDL_STATEMENT_END--

SELECT count(*) FROM onek_with_null WHERE unique1 IS NULL;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NULL AND unique2 IS NULL;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NOT NULL;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NULL AND unique2 IS NOT NULL;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NOT NULL AND unique1 > 500;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NULL AND unique1 > 500;

--DDL_STATEMENT_BEGIN--
DROP INDEX onek_nulltest;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE UNIQUE INDEX onek_nulltest ON onek_with_null (unique2 desc nulls last,unique1);
--DDL_STATEMENT_END--

SELECT count(*) FROM onek_with_null WHERE unique1 IS NULL;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NULL AND unique2 IS NULL;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NOT NULL;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NULL AND unique2 IS NOT NULL;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NOT NULL AND unique1 > 500;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NULL AND unique1 > 500;

--DDL_STATEMENT_BEGIN--
DROP INDEX onek_nulltest;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE UNIQUE INDEX onek_nulltest ON onek_with_null (unique2  nulls first,unique1);
--DDL_STATEMENT_END--

SELECT count(*) FROM onek_with_null WHERE unique1 IS NULL;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NULL AND unique2 IS NULL;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NOT NULL;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NULL AND unique2 IS NOT NULL;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NOT NULL AND unique1 > 500;
SELECT count(*) FROM onek_with_null WHERE unique1 IS NULL AND unique1 > 500;
--DDL_STATEMENT_BEGIN--
DROP INDEX onek_nulltest;
--DDL_STATEMENT_END--
-- Check initial-positioning logic too

--DDL_STATEMENT_BEGIN--
CREATE UNIQUE INDEX onek_nulltest ON onek_with_null (unique2);
--DDL_STATEMENT_END--

SET enable_seqscan = OFF;
SET enable_indexscan = ON;
SET enable_bitmapscan = OFF;

SELECT unique1, unique2 FROM onek_with_null
  ORDER BY unique2 LIMIT 2;
SELECT unique1, unique2 FROM onek_with_null WHERE unique2 >= -1
  ORDER BY unique2 LIMIT 2;
SELECT unique1, unique2 FROM onek_with_null WHERE unique2 >= 0
  ORDER BY unique2 LIMIT 2;

SELECT unique1, unique2 FROM onek_with_null
  ORDER BY unique2 DESC LIMIT 2;
SELECT unique1, unique2 FROM onek_with_null WHERE unique2 >= -1
  ORDER BY unique2 DESC LIMIT 2;
SELECT unique1, unique2 FROM onek_with_null WHERE unique2 < 999
  ORDER BY unique2 DESC LIMIT 2;

RESET enable_seqscan;
RESET enable_indexscan;
RESET enable_bitmapscan;

--DDL_STATEMENT_BEGIN--
DROP TABLE onek_with_null;
--DDL_STATEMENT_END--

--
-- Check bitmap index path planning
--

EXPLAIN (COSTS OFF)
SELECT * FROM tenk1
  WHERE thousand = 42 AND (tenthous = 1 OR tenthous = 3 OR tenthous = 42);
SELECT * FROM tenk1
  WHERE thousand = 42 AND (tenthous = 1 OR tenthous = 3 OR tenthous = 42);

EXPLAIN (COSTS OFF)
SELECT count(*) FROM tenk1
  WHERE hundred = 42 AND (thousand = 42 OR thousand = 99);
SELECT count(*) FROM tenk1
  WHERE hundred = 42 AND (thousand = 42 OR thousand = 99);


explain (costs off)
SELECT unique1 FROM tenk1
WHERE unique1 IN (1,42,7)
ORDER BY unique1;

SELECT unique1 FROM tenk1
WHERE unique1 IN (1,42,7)
ORDER BY unique1;

explain (costs off)
SELECT thousand, tenthous FROM tenk1
WHERE thousand < 2 AND tenthous IN (1001,3000)
ORDER BY thousand;

SELECT thousand, tenthous FROM tenk1
WHERE thousand < 2 AND tenthous IN (1001,3000)
ORDER BY thousand;

SET enable_indexonlyscan = OFF;

explain (costs off)
SELECT thousand, tenthous FROM tenk1
WHERE thousand < 2 AND tenthous IN (1001,3000)
ORDER BY thousand;

SELECT thousand, tenthous FROM tenk1
WHERE thousand < 2 AND tenthous IN (1001,3000)
ORDER BY thousand;

RESET enable_indexonlyscan;

--
-- Check elimination of constant-NULL subexpressions
--

explain (costs off)
  select * from tenk1 where (thousand, tenthous) in ((1,1001), (null,null));

--
-- Check matching of boolean index columns to WHERE conditions and sort keys
--
--DDL_STATEMENT_BEGIN--
create temp table boolindex (b bool, i int, unique(b, i), junk float);
--DDL_STATEMENT_END--

explain (costs off)
  select * from boolindex order by b, i limit 10;
explain (costs off)
  select * from boolindex where b order by i limit 10;
explain (costs off)
  select * from boolindex where b = true order by i desc limit 10;
explain (costs off)
  select * from boolindex where not b order by i limit 10;

--
-- Test for multilevel page deletion
--
--DDL_STATEMENT_BEGIN--
CREATE TABLE delete_test_table (a bigint, b bigint, c bigint, d bigint);
--DDL_STATEMENT_END--
INSERT INTO delete_test_table SELECT i, 1, 2, 3 FROM generate_series(1,80000) i;
--DDL_STATEMENT_BEGIN--
ALTER TABLE delete_test_table ADD PRIMARY KEY (a,b,c,d);
--DDL_STATEMENT_END--
DELETE FROM delete_test_table WHERE a > 40000;
DELETE FROM delete_test_table WHERE a > 10;

--DDL_STATEMENT_BEGIN--
DROP TABLE delete_test_table;
--DDL_STATEMENT_END--
-- index inside schema
--DDL_STATEMENT_BEGIN--
CREATE SCHEMA schema_to_reindex;
--DDL_STATEMENT_END--
SET search_path = 'schema_to_reindex';
--DDL_STATEMENT_BEGIN--
CREATE TABLE table1(col1 SERIAL PRIMARY KEY);
--DDL_STATEMENT_END--
INSERT INTO table1 SELECT generate_series(1,400);
--DDL_STATEMENT_BEGIN--
CREATE TABLE table2(col1 SERIAL PRIMARY KEY, col2 TEXT NOT NULL);
--DDL_STATEMENT_END--
INSERT INTO table2 SELECT generate_series(1,400), 'abc';
CREATE INDEX ON table2(col2);
CREATE MATERIALIZED VIEW matview AS SELECT col1 FROM table2;
CREATE INDEX ON matview(col1);
--DDL_STATEMENT_BEGIN--
CREATE VIEW view AS SELECT col2 FROM table2;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
DROP TABLE table1;
--DDL_STATEMENT_END--
--DROP TABLE table2 cascade;
--DDL_STATEMENT_BEGIN--
DROP SCHEMA schema_to_reindex CASCADE;
--DDL_STATEMENT_END--
