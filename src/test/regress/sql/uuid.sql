-- regression test for the uuid datatype
-- creating test tables
--DDL_STATEMENT_BEGIN--
drop table if exists guid1;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TABLE guid1
(
	guid_field UUID,
	text_field TEXT DEFAULT(now())
);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop table if exists guid2;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TABLE guid2
(
	guid_field UUID,
	text_field TEXT DEFAULT(now())
);
--DDL_STATEMENT_END--

-- inserting invalid data tests
-- too long
INSERT INTO guid1(guid_field) VALUES('11111111-1111-1111-1111-111111111111F');
-- too short
INSERT INTO guid1(guid_field) VALUES('{11111111-1111-1111-1111-11111111111}');
-- valid data but invalid format
INSERT INTO guid1(guid_field) VALUES('111-11111-1111-1111-1111-111111111111');
INSERT INTO guid1(guid_field) VALUES('{22222222-2222-2222-2222-222222222222 ');
-- invalid data
INSERT INTO guid1(guid_field) VALUES('11111111-1111-1111-G111-111111111111');
INSERT INTO guid1(guid_field) VALUES('11+11111-1111-1111-1111-111111111111');

--inserting three input formats
INSERT INTO guid1(guid_field) VALUES('11111111-1111-1111-1111-111111111111');
INSERT INTO guid1(guid_field) VALUES('{22222222-2222-2222-2222-222222222222}');
INSERT INTO guid1(guid_field) VALUES('3f3e3c3b3a3039383736353433a2313e');

-- retrieving the inserted data
SELECT guid_field FROM guid1;

-- ordering test
SELECT guid_field FROM guid1 ORDER BY guid_field ASC;
SELECT guid_field FROM guid1 ORDER BY guid_field DESC;

-- = operator test
SELECT COUNT(*) FROM guid1 WHERE guid_field = '3f3e3c3b-3a30-3938-3736-353433a2313e';

-- <> operator test
SELECT COUNT(*) FROM guid1 WHERE guid_field <> '11111111111111111111111111111111';

-- < operator test
SELECT COUNT(*) FROM guid1 WHERE guid_field < '22222222-2222-2222-2222-222222222222';

-- <= operator test
SELECT COUNT(*) FROM guid1 WHERE guid_field <= '22222222-2222-2222-2222-222222222222';

-- > operator test
SELECT COUNT(*) FROM guid1 WHERE guid_field > '22222222-2222-2222-2222-222222222222';

-- >= operator test
SELECT COUNT(*) FROM guid1 WHERE guid_field >= '22222222-2222-2222-2222-222222222222';

-- btree and hash index creation test
--DDL_STATEMENT_BEGIN--
CREATE INDEX guid1_btree ON guid1 USING BTREE (guid_field);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE INDEX guid1_hash  ON guid1 USING HASH  (guid_field);
--DDL_STATEMENT_END--

-- unique index test
--DDL_STATEMENT_BEGIN--
CREATE UNIQUE INDEX guid1_unique_BTREE ON guid1 USING BTREE (guid_field);
--DDL_STATEMENT_END--
-- should fail
INSERT INTO guid1(guid_field) VALUES('11111111-1111-1111-1111-111111111111');

-- check to see whether the new indexes are actually there
SELECT count(*) FROM pg_class WHERE relkind='i' AND relname LIKE 'guid%';

-- populating the test tables with additional records
INSERT INTO guid1(guid_field) VALUES('44444444-4444-4444-4444-444444444444');
INSERT INTO guid2(guid_field) VALUES('11111111-1111-1111-1111-111111111111');
INSERT INTO guid2(guid_field) VALUES('{22222222-2222-2222-2222-222222222222}');
INSERT INTO guid2(guid_field) VALUES('3f3e3c3b3a3039383736353433a2313e');

-- join test
SELECT COUNT(*) FROM guid1 g1 INNER JOIN guid2 g2 ON g1.guid_field = g2.guid_field;
SELECT COUNT(*) FROM guid1 g1 LEFT JOIN guid2 g2 ON g1.guid_field = g2.guid_field WHERE g2.guid_field IS NULL;

-- clean up
--DDL_STATEMENT_BEGIN--
DROP TABLE guid1;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
DROP TABLE guid2 CASCADE;
--DDL_STATEMENT_END--
