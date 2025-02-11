--
-- TRIGGERS
--

--DDL_STATEMENT_BEGIN--
create table pkeys (pkey1 int4 not null, pkey2 text not null);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table fkeys (fkey1 int4, fkey2 text, fkey3 int);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table fkeys2 (fkey21 int4, fkey22 text, pkey23 int not null);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create index fkeys_i on fkeys (fkey1, fkey2);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create index fkeys2_i on fkeys2 (fkey21, fkey22);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create index fkeys2p_i on fkeys2 (pkey23);
--DDL_STATEMENT_END--

insert into pkeys values (10, '1');
insert into pkeys values (20, '2');
insert into pkeys values (30, '3');
insert into pkeys values (40, '4');
insert into pkeys values (50, '5');
insert into pkeys values (60, '6');
--DDL_STATEMENT_BEGIN--
create unique index pkeys_i on pkeys (pkey1, pkey2);
--DDL_STATEMENT_END--

--
-- For fkeys:
-- 	(fkey1, fkey2)	--> pkeys (pkey1, pkey2)
-- 	(fkey3)		--> fkeys2 (pkey23)
--
--DDL_STATEMENT_BEGIN--
create trigger check_fkeys_pkey_exist
	before insert or update on fkeys
	for each row
	execute function
	check_primary_key ('fkey1', 'fkey2', 'pkeys', 'pkey1', 'pkey2');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger check_fkeys_pkey2_exist
	before insert or update on fkeys
	for each row
	execute function check_primary_key ('fkey3', 'fkeys2', 'pkey23');
--DDL_STATEMENT_END--

--
-- For fkeys2:
-- 	(fkey21, fkey22)	--> pkeys (pkey1, pkey2)
--
--DDL_STATEMENT_BEGIN--
create trigger check_fkeys2_pkey_exist
	before insert or update on fkeys2
	for each row
	execute procedure
	check_primary_key ('fkey21', 'fkey22', 'pkeys', 'pkey1', 'pkey2');
--DDL_STATEMENT_END--

-- Test comments
COMMENT ON TRIGGER check_fkeys2_pkey_bad ON fkeys2 IS 'wrong';
COMMENT ON TRIGGER check_fkeys2_pkey_exist ON fkeys2 IS 'right';
COMMENT ON TRIGGER check_fkeys2_pkey_exist ON fkeys2 IS NULL;

--
-- For pkeys:
-- 	ON DELETE/UPDATE (pkey1, pkey2) CASCADE:
-- 		fkeys (fkey1, fkey2) and fkeys2 (fkey21, fkey22)
--
--DDL_STATEMENT_BEGIN--
create trigger check_pkeys_fkey_cascade
	before delete or update on pkeys
	for each row
	execute procedure
	check_foreign_key (2, 'cascade', 'pkey1', 'pkey2',
	'fkeys', 'fkey1', 'fkey2', 'fkeys2', 'fkey21', 'fkey22');
--DDL_STATEMENT_END--

--
-- For fkeys2:
-- 	ON DELETE/UPDATE (pkey23) RESTRICT:
-- 		fkeys (fkey3)
--
--DDL_STATEMENT_BEGIN--
create trigger check_fkeys2_fkey_restrict
	before delete or update on fkeys2
	for each row
	execute procedure check_foreign_key (1, 'restrict', 'pkey23', 'fkeys', 'fkey3');
--DDL_STATEMENT_END--

insert into fkeys2 values (10, '1', 1);
insert into fkeys2 values (30, '3', 2);
insert into fkeys2 values (40, '4', 5);
insert into fkeys2 values (50, '5', 3);
-- no key in pkeys
insert into fkeys2 values (70, '5', 3);

insert into fkeys values (10, '1', 2);
insert into fkeys values (30, '3', 3);
insert into fkeys values (40, '4', 2);
insert into fkeys values (50, '5', 2);
-- no key in pkeys
insert into fkeys values (70, '5', 1);
-- no key in fkeys2
insert into fkeys values (60, '6', 4);

delete from pkeys where pkey1 = 30 and pkey2 = '3';
delete from pkeys where pkey1 = 40 and pkey2 = '4';
update pkeys set pkey1 = 7, pkey2 = '70' where pkey1 = 50 and pkey2 = '5';
update pkeys set pkey1 = 7, pkey2 = '70' where pkey1 = 10 and pkey2 = '1';

SELECT trigger_name, event_manipulation, event_object_schema, event_object_table,
       action_order, action_condition, action_orientation, action_timing,
       action_reference_old_table, action_reference_new_table
  FROM information_schema.triggers
  WHERE event_object_table in ('pkeys', 'fkeys', 'fkeys2')
  ORDER BY trigger_name COLLATE "C", 2;
  
--DDL_STATEMENT_BEGIN--
DROP TABLE pkeys;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
DROP TABLE fkeys;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
DROP TABLE fkeys2;
--DDL_STATEMENT_END--

-- Check behavior when trigger returns unmodified trigtuple
--DDL_STATEMENT_BEGIN--
create table trigtest (f1 int, f2 text);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger trigger_return_old
	before insert or delete or update on trigtest
	for each row execute procedure trigger_return_old();
--DDL_STATEMENT_END--

insert into trigtest values(1, 'foo');
select * from trigtest;
update trigtest set f2 = f2 || 'bar';
select * from trigtest;
delete from trigtest;
select * from trigtest;
--DDL_STATEMENT_BEGIN--
drop table trigtest;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create sequence ttdummy_seq increment 10 start 0 minvalue 0;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create table tttest (
	price_id	int4,
	price_val	int4,
	price_on	int4,
	price_off	int4 default 999999
);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger ttdummy
	before delete or update on tttest
	for each row
	execute procedure
	ttdummy (price_on, price_off);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger ttserial
	before insert or update on tttest
	for each row
	execute procedure
	autoinc (price_on, ttdummy_seq);
--DDL_STATEMENT_END--

insert into tttest values (1, 1, null);
insert into tttest values (2, 2, null);
insert into tttest values (3, 3, 0);

select * from tttest;
delete from tttest where price_id = 2;
select * from tttest;
-- what do we see ?

-- get current prices
select * from tttest where price_off = 999999;

-- change price for price_id == 3
update tttest set price_val = 30 where price_id = 3;
select * from tttest;

-- now we want to change pric_id in ALL tuples
-- this gets us not what we need
update tttest set price_id = 5 where price_id = 3;
select * from tttest;

-- restore data as before last update:
select set_ttdummy(0);
delete from tttest where price_id = 5;
update tttest set price_off = 999999 where price_val = 30;
select * from tttest;

-- and try change price_id now!
update tttest set price_id = 5 where price_id = 3;
select * from tttest;
-- isn't it what we need ?

select set_ttdummy(1);

-- we want to correct some "date"
update tttest set price_on = -1 where price_id = 1;
-- but this doesn't work

-- try in this way
select set_ttdummy(0);
update tttest set price_on = -1 where price_id = 1;
select * from tttest;
-- isn't it what we need ?

-- get price for price_id == 5 as it was @ "date" 35
select * from tttest where price_on <= 35 and price_off > 35 and price_id = 5;

--DDL_STATEMENT_BEGIN--
drop table tttest;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop sequence ttdummy_seq;
--DDL_STATEMENT_END--

--
-- tests for per-statement triggers
--

--DDL_STATEMENT_BEGIN--
CREATE TABLE log_table (tstamp timestamp default timeofday()::timestamp);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TABLE main_table (a int unique, b int);
--DDL_STATEMENT_END--

COPY main_table (a,b) FROM stdin;
5	10
20	20
30	10
50	35
80	15
\.

--DDL_STATEMENT_BEGIN--
CREATE FUNCTION trigger_func() RETURNS trigger LANGUAGE plpgsql AS '
BEGIN
	RAISE NOTICE ''trigger_func(%) called: action = %, when = %, level = %'', TG_ARGV[0], TG_OP, TG_WHEN, TG_LEVEL;
	RETURN NULL;
END;';
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER before_ins_stmt_trig BEFORE INSERT ON main_table
FOR EACH STATEMENT EXECUTE PROCEDURE trigger_func('before_ins_stmt');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER after_ins_stmt_trig AFTER INSERT ON main_table
FOR EACH STATEMENT EXECUTE PROCEDURE trigger_func('after_ins_stmt');
--DDL_STATEMENT_END--

--
-- if neither 'FOR EACH ROW' nor 'FOR EACH STATEMENT' was specified,
-- CREATE TRIGGER should default to 'FOR EACH STATEMENT'
--
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER after_upd_stmt_trig AFTER UPDATE ON main_table
EXECUTE PROCEDURE trigger_func('after_upd_stmt');
--DDL_STATEMENT_END--

-- Both insert and update statement level triggers (before and after) should
-- fire.  Doesn't fire UPDATE before trigger, but only because one isn't
-- defined.
INSERT INTO main_table (a, b) VALUES (5, 10) ON CONFLICT (a)
  DO UPDATE SET b = EXCLUDED.b;
  
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER after_upd_row_trig AFTER UPDATE ON main_table
FOR EACH ROW EXECUTE PROCEDURE trigger_func('after_upd_row');
--DDL_STATEMENT_END--

INSERT INTO main_table DEFAULT VALUES;

UPDATE main_table SET a = a + 1 WHERE b < 30;
-- UPDATE that effects zero rows should still call per-statement trigger
UPDATE main_table SET a = a + 2 WHERE b > 100;

-- constraint now unneeded
--DDL_STATEMENT_BEGIN--
ALTER TABLE main_table DROP CONSTRAINT main_table_a_key;
--DDL_STATEMENT_END--

-- COPY should fire per-row and per-statement INSERT triggers
COPY main_table (a, b) FROM stdin;
30	40
50	60
\.

SELECT * FROM main_table ORDER BY a, b;

--
-- test triggers with WHEN clause
--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER modified_a BEFORE UPDATE OF a ON main_table
FOR EACH ROW WHEN (OLD.a <> NEW.a) EXECUTE PROCEDURE trigger_func('modified_a');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER modified_any BEFORE UPDATE OF a ON main_table
FOR EACH ROW WHEN (OLD.* IS DISTINCT FROM NEW.*) EXECUTE PROCEDURE trigger_func('modified_any');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER insert_a AFTER INSERT ON main_table
FOR EACH ROW WHEN (NEW.a = 123) EXECUTE PROCEDURE trigger_func('insert_a');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER delete_a AFTER DELETE ON main_table
FOR EACH ROW WHEN (OLD.a = 123) EXECUTE PROCEDURE trigger_func('delete_a');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER insert_when BEFORE INSERT ON main_table
FOR EACH STATEMENT WHEN (true) EXECUTE PROCEDURE trigger_func('insert_when');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER delete_when AFTER DELETE ON main_table
FOR EACH STATEMENT WHEN (true) EXECUTE PROCEDURE trigger_func('delete_when');
--DDL_STATEMENT_END--
SELECT trigger_name, event_manipulation, event_object_schema, event_object_table,
       action_order, action_condition, action_orientation, action_timing,
       action_reference_old_table, action_reference_new_table
  FROM information_schema.triggers
  WHERE event_object_table IN ('main_table')
  ORDER BY trigger_name COLLATE "C", 2;
INSERT INTO main_table (a) VALUES (123), (456);
COPY main_table FROM stdin;
123	999
456	999
\.
DELETE FROM main_table WHERE a IN (123, 456);
UPDATE main_table SET a = 50, b = 60;
SELECT * FROM main_table ORDER BY a, b;
SELECT pg_get_triggerdef(oid, true) FROM pg_trigger WHERE tgrelid = 'main_table'::regclass AND tgname = 'modified_a';
SELECT pg_get_triggerdef(oid, false) FROM pg_trigger WHERE tgrelid = 'main_table'::regclass AND tgname = 'modified_a';
SELECT pg_get_triggerdef(oid, true) FROM pg_trigger WHERE tgrelid = 'main_table'::regclass AND tgname = 'modified_any';
--DDL_STATEMENT_BEGIN--
DROP TRIGGER modified_a ON main_table;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
DROP TRIGGER modified_any ON main_table;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
DROP TRIGGER insert_a ON main_table;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
DROP TRIGGER delete_a ON main_table;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
DROP TRIGGER insert_when ON main_table;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
DROP TRIGGER delete_when ON main_table;
--DDL_STATEMENT_END--

-- Test column-level triggers
--DDL_STATEMENT_BEGIN--
DROP TRIGGER after_upd_row_trig ON main_table;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER before_upd_a_row_trig BEFORE UPDATE OF a ON main_table
FOR EACH ROW EXECUTE PROCEDURE trigger_func('before_upd_a_row');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER after_upd_b_row_trig AFTER UPDATE OF b ON main_table
FOR EACH ROW EXECUTE PROCEDURE trigger_func('after_upd_b_row');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER after_upd_a_b_row_trig AFTER UPDATE OF a, b ON main_table
FOR EACH ROW EXECUTE PROCEDURE trigger_func('after_upd_a_b_row');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER before_upd_a_stmt_trig BEFORE UPDATE OF a ON main_table
FOR EACH STATEMENT EXECUTE PROCEDURE trigger_func('before_upd_a_stmt');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER after_upd_b_stmt_trig AFTER UPDATE OF b ON main_table
FOR EACH STATEMENT EXECUTE PROCEDURE trigger_func('after_upd_b_stmt');
--DDL_STATEMENT_END--

SELECT pg_get_triggerdef(oid) FROM pg_trigger WHERE tgrelid = 'main_table'::regclass AND tgname = 'after_upd_a_b_row_trig';

UPDATE main_table SET a = 50;
UPDATE main_table SET b = 10;

--
-- Test case for bug with BEFORE trigger followed by AFTER trigger with WHEN
--

--DDL_STATEMENT_BEGIN--
CREATE TABLE some_t (some_col boolean NOT NULL);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE FUNCTION dummy_update_func() RETURNS trigger AS $$
BEGIN
  RAISE NOTICE 'dummy_update_func(%) called: action = %, old = %, new = %',
    TG_ARGV[0], TG_OP, OLD, NEW;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER some_trig_before BEFORE UPDATE ON some_t FOR EACH ROW
  EXECUTE PROCEDURE dummy_update_func('before');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER some_trig_aftera AFTER UPDATE ON some_t FOR EACH ROW
  WHEN (NOT OLD.some_col AND NEW.some_col)
  EXECUTE PROCEDURE dummy_update_func('aftera');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER some_trig_afterb AFTER UPDATE ON some_t FOR EACH ROW
  WHEN (NOT NEW.some_col)
  EXECUTE PROCEDURE dummy_update_func('afterb');
--DDL_STATEMENT_END--
INSERT INTO some_t VALUES (TRUE);
UPDATE some_t SET some_col = TRUE;
UPDATE some_t SET some_col = FALSE;
UPDATE some_t SET some_col = TRUE;
--DDL_STATEMENT_BEGIN--
DROP TABLE some_t;
--DDL_STATEMENT_END--

-- bogus cases
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER error_upd_and_col BEFORE UPDATE OR UPDATE OF a ON main_table
FOR EACH ROW EXECUTE PROCEDURE trigger_func('error_upd_and_col');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER error_upd_a_a BEFORE UPDATE OF a, a ON main_table
FOR EACH ROW EXECUTE PROCEDURE trigger_func('error_upd_a_a');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER error_ins_a BEFORE INSERT OF a ON main_table
FOR EACH ROW EXECUTE PROCEDURE trigger_func('error_ins_a');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER error_ins_when BEFORE INSERT OR UPDATE ON main_table
FOR EACH ROW WHEN (OLD.a <> NEW.a)
EXECUTE PROCEDURE trigger_func('error_ins_old');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER error_del_when BEFORE DELETE OR UPDATE ON main_table
FOR EACH ROW WHEN (OLD.a <> NEW.a)
EXECUTE PROCEDURE trigger_func('error_del_new');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER error_del_when BEFORE INSERT OR UPDATE ON main_table
FOR EACH ROW WHEN (NEW.tableoid <> 0)
EXECUTE PROCEDURE trigger_func('error_when_sys_column');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER error_stmt_when BEFORE UPDATE OF a ON main_table
FOR EACH STATEMENT WHEN (OLD.* IS DISTINCT FROM NEW.*)
EXECUTE PROCEDURE trigger_func('error_stmt_when');
--DDL_STATEMENT_END--

-- check dependency restrictions
--DDL_STATEMENT_BEGIN--
ALTER TABLE main_table DROP COLUMN b;
--DDL_STATEMENT_END--
-- this should succeed, but we'll roll it back to keep the triggers around
begin;
--DDL_STATEMENT_BEGIN--
DROP TRIGGER after_upd_a_b_row_trig ON main_table;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
DROP TRIGGER after_upd_b_row_trig ON main_table;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
DROP TRIGGER after_upd_b_stmt_trig ON main_table;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
ALTER TABLE main_table DROP COLUMN b;
--DDL_STATEMENT_END--
rollback;

-- Test enable/disable triggers

--DDL_STATEMENT_BEGIN--
create table trigtest (i serial primary key);
--DDL_STATEMENT_END--
-- test that disabling RI triggers works
--DDL_STATEMENT_BEGIN--
create table trigtest2 (i int references trigtest(i) on delete cascade);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create function trigtest() returns trigger as $$
begin
	raise notice '% % % %', TG_RELNAME, TG_OP, TG_WHEN, TG_LEVEL;
	return new;
end;$$ language plpgsql;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger trigtest_b_row_tg before insert or update or delete on trigtest
for each row execute procedure trigtest();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trigtest_a_row_tg after insert or update or delete on trigtest
for each row execute procedure trigtest();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trigtest_b_stmt_tg before insert or update or delete on trigtest
for each statement execute procedure trigtest();
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger trigtest_a_stmt_tg after insert or update or delete on trigtest
for each statement execute procedure trigtest();
--DDL_STATEMENT_END--
insert into trigtest default values;
--DDL_STATEMENT_BEGIN--
alter table trigtest disable trigger trigtest_b_row_tg;
--DDL_STATEMENT_END--
insert into trigtest default values;
--DDL_STATEMENT_BEGIN--
alter table trigtest disable trigger user;
--DDL_STATEMENT_END--
insert into trigtest default values;
--DDL_STATEMENT_BEGIN--
alter table trigtest enable trigger trigtest_a_stmt_tg;
--DDL_STATEMENT_END--
insert into trigtest default values;
set session_replication_role = replica;
insert into trigtest default values;  -- does not trigger
--DDL_STATEMENT_BEGIN--
alter table trigtest enable always trigger trigtest_a_stmt_tg;
--DDL_STATEMENT_END--
insert into trigtest default values;  -- now it does
reset session_replication_role;
insert into trigtest2 values(1);
insert into trigtest2 values(2);
delete from trigtest where i=2;
select * from trigtest2;
--DDL_STATEMENT_BEGIN--
alter table trigtest disable trigger all;
--DDL_STATEMENT_END--
delete from trigtest where i=1;
select * from trigtest2;
-- ensure we still insert, even when all triggers are disabled
insert into trigtest default values;
select *  from trigtest;
--DDL_STATEMENT_BEGIN--
drop table trigtest2;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop table trigtest;
--DDL_STATEMENT_END--


-- dump trigger data
--DDL_STATEMENT_BEGIN--
CREATE TABLE trigger_test (
        i int,
        v varchar
);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE OR REPLACE FUNCTION trigger_data()  RETURNS trigger
LANGUAGE plpgsql AS $$

declare

	argstr text;
	relid text;

begin

	relid = TG_relid::regclass;

	-- plpgsql can't discover its trigger data in a hash like perl and python
	-- can, or by a sort of reflection like tcl can,
	-- so we have to hard code the names.
	raise NOTICE 'TG_NAME: %', TG_name;
	raise NOTICE 'TG_WHEN: %', TG_when;
	raise NOTICE 'TG_LEVEL: %', TG_level;
	raise NOTICE 'TG_OP: %', TG_op;
	raise NOTICE 'TG_RELID::regclass: %', relid;
	raise NOTICE 'TG_RELNAME: %', TG_relname;
	raise NOTICE 'TG_TABLE_NAME: %', TG_table_name;
	raise NOTICE 'TG_TABLE_SCHEMA: %', TG_table_schema;
	raise NOTICE 'TG_NARGS: %', TG_nargs;

	argstr = '[';
	for i in 0 .. TG_nargs - 1 loop
		if i > 0 then
			argstr = argstr || ', ';
		end if;
		argstr = argstr || TG_argv[i];
	end loop;
	argstr = argstr || ']';
	raise NOTICE 'TG_ARGV: %', argstr;

	if TG_OP != 'INSERT' then
		raise NOTICE 'OLD: %', OLD;
	end if;

	if TG_OP != 'DELETE' then
		raise NOTICE 'NEW: %', NEW;
	end if;

	if TG_OP = 'DELETE' then
		return OLD;
	else
		return NEW;
	end if;

end;
$$;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER show_trigger_data_trig
BEFORE INSERT OR UPDATE OR DELETE ON trigger_test
FOR EACH ROW EXECUTE PROCEDURE trigger_data(23,'skidoo');
--DDL_STATEMENT_END--

insert into trigger_test values(1,'insert');
update trigger_test set v = 'update' where i = 1;
delete from trigger_test;

--DDL_STATEMENT_BEGIN--
DROP TRIGGER show_trigger_data_trig on trigger_test;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
DROP FUNCTION trigger_data();
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
DROP TABLE trigger_test;
--DDL_STATEMENT_END--

--
-- Test use of row comparisons on OLD/NEW
--

--DDL_STATEMENT_BEGIN--
CREATE TABLE trigger_test (f1 int, f2 text, f3 text);
--DDL_STATEMENT_END--

-- this is the obvious (and wrong...) way to compare rows
--DDL_STATEMENT_BEGIN--
CREATE FUNCTION mytrigger() RETURNS trigger LANGUAGE plpgsql as $$
begin
	if row(old.*) = row(new.*) then
		raise notice 'row % not changed', new.f1;
	else
		raise notice 'row % changed', new.f1;
	end if;
	return new;
end$$;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER t
BEFORE UPDATE ON trigger_test
FOR EACH ROW EXECUTE PROCEDURE mytrigger();
--DDL_STATEMENT_END--

INSERT INTO trigger_test VALUES(1, 'foo', 'bar');
INSERT INTO trigger_test VALUES(2, 'baz', 'quux');

UPDATE trigger_test SET f3 = 'bar';
UPDATE trigger_test SET f3 = NULL;
-- this demonstrates that the above isn't really working as desired:
UPDATE trigger_test SET f3 = NULL;

-- the right way when considering nulls is
--DDL_STATEMENT_BEGIN--
CREATE OR REPLACE FUNCTION mytrigger() RETURNS trigger LANGUAGE plpgsql as $$
begin
	if row(old.*) is distinct from row(new.*) then
		raise notice 'row % changed', new.f1;
	else
		raise notice 'row % not changed', new.f1;
	end if;
	return new;
end$$;
--DDL_STATEMENT_END--

UPDATE trigger_test SET f3 = 'bar';
UPDATE trigger_test SET f3 = NULL;
UPDATE trigger_test SET f3 = NULL;

--DDL_STATEMENT_BEGIN--
DROP TABLE trigger_test;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
DROP FUNCTION mytrigger();
--DDL_STATEMENT_END--

-- Test snapshot management in serializable transactions involving triggers
-- per bug report in 6bc73d4c0910042358k3d1adff3qa36f8df75198ecea@mail.gmail.com
--DDL_STATEMENT_BEGIN--
CREATE FUNCTION serializable_update_trig() RETURNS trigger LANGUAGE plpgsql AS
$$
declare
	rec record;
begin
	new.description = 'updated in trigger';
	return new;
end;
$$;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TABLE serializable_update_tab (
	id int,
	filler  text,
	description text
);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER serializable_update_trig BEFORE UPDATE ON serializable_update_tab
	FOR EACH ROW EXECUTE PROCEDURE serializable_update_trig();
--DDL_STATEMENT_END--

INSERT INTO serializable_update_tab SELECT a, repeat('xyzxz', 100), 'new'
	FROM generate_series(1, 50) a;

BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
UPDATE serializable_update_tab SET description = 'no no', id = 1 WHERE id = 1;
COMMIT;
SELECT description FROM serializable_update_tab WHERE id = 1;
--DDL_STATEMENT_BEGIN--
DROP TABLE serializable_update_tab;
--DDL_STATEMENT_END--

-- minimal update trigger

--DDL_STATEMENT_BEGIN--
CREATE TABLE min_updates_test (
	f1	text,
	f2 int,
	f3 int);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TABLE min_updates_test_oids (
	f1	text,
	f2 int,
	f3 int) WITH OIDS;
--DDL_STATEMENT_END--

INSERT INTO min_updates_test VALUES ('a',1,2),('b','2',null);

INSERT INTO min_updates_test_oids VALUES ('a',1,2),('b','2',null);

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER z_min_update
BEFORE UPDATE ON min_updates_test
FOR EACH ROW EXECUTE PROCEDURE suppress_redundant_updates_trigger();
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER z_min_update
BEFORE UPDATE ON min_updates_test_oids
FOR EACH ROW EXECUTE PROCEDURE suppress_redundant_updates_trigger();
--DDL_STATEMENT_END--

\set QUIET false

UPDATE min_updates_test SET f1 = f1;

UPDATE min_updates_test SET f2 = f2 + 1;

UPDATE min_updates_test SET f3 = 2 WHERE f3 is null;

UPDATE min_updates_test_oids SET f1 = f1;

UPDATE min_updates_test_oids SET f2 = f2 + 1;

UPDATE min_updates_test_oids SET f3 = 2 WHERE f3 is null;

\set QUIET true

SELECT * FROM min_updates_test;

SELECT * FROM min_updates_test_oids;

--DDL_STATEMENT_BEGIN--
DROP TABLE min_updates_test;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
DROP TABLE min_updates_test_oids;
--DDL_STATEMENT_END--

--
-- Test triggers on views
--

--DDL_STATEMENT_BEGIN--
CREATE VIEW main_view AS SELECT a, b FROM main_table;
--DDL_STATEMENT_END--

-- VIEW trigger function
--DDL_STATEMENT_BEGIN--
CREATE OR REPLACE FUNCTION view_trigger() RETURNS trigger
LANGUAGE plpgsql AS $$
declare
    argstr text = '';
begin
    for i in 0 .. TG_nargs - 1 loop
        if i > 0 then
            argstr = argstr || ', ';
        end if;
        argstr = argstr || TG_argv[i];
    end loop;

    raise notice '% % % % (%)', TG_RELNAME, TG_WHEN, TG_OP, TG_LEVEL, argstr;

    if TG_LEVEL = 'ROW' then
        if TG_OP = 'INSERT' then
            raise NOTICE 'NEW: %', NEW;
            INSERT INTO main_table VALUES (NEW.a, NEW.b);
            RETURN NEW;
        end if;

        if TG_OP = 'UPDATE' then
            raise NOTICE 'OLD: %, NEW: %', OLD, NEW;
            UPDATE main_table SET a = NEW.a, b = NEW.b WHERE a = OLD.a AND b = OLD.b;
            if NOT FOUND then RETURN NULL; end if;
            RETURN NEW;
        end if;

        if TG_OP = 'DELETE' then
            raise NOTICE 'OLD: %', OLD;
            DELETE FROM main_table WHERE a = OLD.a AND b = OLD.b;
            if NOT FOUND then RETURN NULL; end if;
            RETURN OLD;
        end if;
    end if;

    RETURN NULL;
end;
$$;
--DDL_STATEMENT_END--

-- Before row triggers aren't allowed on views
--DDL_STATEMENT_BEGIN--
CREATE TRIGGER invalid_trig BEFORE INSERT ON main_view
FOR EACH ROW EXECUTE PROCEDURE trigger_func('before_ins_row');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER invalid_trig BEFORE UPDATE ON main_view
FOR EACH ROW EXECUTE PROCEDURE trigger_func('before_upd_row');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER invalid_trig BEFORE DELETE ON main_view
FOR EACH ROW EXECUTE PROCEDURE trigger_func('before_del_row');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
-- After row triggers aren't allowed on views
CREATE TRIGGER invalid_trig AFTER INSERT ON main_view
FOR EACH ROW EXECUTE PROCEDURE trigger_func('before_ins_row');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER invalid_trig AFTER UPDATE ON main_view
FOR EACH ROW EXECUTE PROCEDURE trigger_func('before_upd_row');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER invalid_trig AFTER DELETE ON main_view
FOR EACH ROW EXECUTE PROCEDURE trigger_func('before_del_row');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
-- Truncate triggers aren't allowed on views
CREATE TRIGGER invalid_trig BEFORE TRUNCATE ON main_view
EXECUTE PROCEDURE trigger_func('before_tru_row');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER invalid_trig AFTER TRUNCATE ON main_view
EXECUTE PROCEDURE trigger_func('before_tru_row');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
-- INSTEAD OF triggers aren't allowed on tables
CREATE TRIGGER invalid_trig INSTEAD OF INSERT ON main_table
FOR EACH ROW EXECUTE PROCEDURE view_trigger('instead_of_ins');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER invalid_trig INSTEAD OF UPDATE ON main_table
FOR EACH ROW EXECUTE PROCEDURE view_trigger('instead_of_upd');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER invalid_trig INSTEAD OF DELETE ON main_table
FOR EACH ROW EXECUTE PROCEDURE view_trigger('instead_of_del');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
-- Don't support WHEN clauses with INSTEAD OF triggers
CREATE TRIGGER invalid_trig INSTEAD OF UPDATE ON main_view
FOR EACH ROW WHEN (OLD.a <> NEW.a) EXECUTE PROCEDURE view_trigger('instead_of_upd');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
-- Don't support column-level INSTEAD OF triggers
CREATE TRIGGER invalid_trig INSTEAD OF UPDATE OF a ON main_view
FOR EACH ROW EXECUTE PROCEDURE view_trigger('instead_of_upd');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
-- Don't support statement-level INSTEAD OF triggers
CREATE TRIGGER invalid_trig INSTEAD OF UPDATE ON main_view
EXECUTE PROCEDURE view_trigger('instead_of_upd');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
-- Valid INSTEAD OF triggers
CREATE TRIGGER instead_of_insert_trig INSTEAD OF INSERT ON main_view
FOR EACH ROW EXECUTE PROCEDURE view_trigger('instead_of_ins');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER instead_of_update_trig INSTEAD OF UPDATE ON main_view
FOR EACH ROW EXECUTE PROCEDURE view_trigger('instead_of_upd');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER instead_of_delete_trig INSTEAD OF DELETE ON main_view
FOR EACH ROW EXECUTE PROCEDURE view_trigger('instead_of_del');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
-- Valid BEFORE statement VIEW triggers
CREATE TRIGGER before_ins_stmt_trig BEFORE INSERT ON main_view
FOR EACH STATEMENT EXECUTE PROCEDURE view_trigger('before_view_ins_stmt');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER before_upd_stmt_trig BEFORE UPDATE ON main_view
FOR EACH STATEMENT EXECUTE PROCEDURE view_trigger('before_view_upd_stmt');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER before_del_stmt_trig BEFORE DELETE ON main_view
FOR EACH STATEMENT EXECUTE PROCEDURE view_trigger('before_view_del_stmt');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
-- Valid AFTER statement VIEW triggers
CREATE TRIGGER after_ins_stmt_trig AFTER INSERT ON main_view
FOR EACH STATEMENT EXECUTE PROCEDURE view_trigger('after_view_ins_stmt');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER after_upd_stmt_trig AFTER UPDATE ON main_view
FOR EACH STATEMENT EXECUTE PROCEDURE view_trigger('after_view_upd_stmt');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER after_del_stmt_trig AFTER DELETE ON main_view
FOR EACH STATEMENT EXECUTE PROCEDURE view_trigger('after_view_del_stmt');
--DDL_STATEMENT_END--

\set QUIET false

-- Insert into view using trigger
INSERT INTO main_view VALUES (20, 30);
INSERT INTO main_view VALUES (21, 31) RETURNING a, b;

-- Table trigger will prevent updates
UPDATE main_view SET b = 31 WHERE a = 20;
UPDATE main_view SET b = 32 WHERE a = 21 AND b = 31 RETURNING a, b;

-- Remove table trigger to allow updates
--DDL_STATEMENT_BEGIN--
DROP TRIGGER before_upd_a_row_trig ON main_table;
--DDL_STATEMENT_END--
UPDATE main_view SET b = 31 WHERE a = 20;
UPDATE main_view SET b = 32 WHERE a = 21 AND b = 31 RETURNING a, b;

-- Before and after stmt triggers should fire even when no rows are affected
UPDATE main_view SET b = 0 WHERE false;

-- Delete from view using trigger
DELETE FROM main_view WHERE a IN (20,21);
DELETE FROM main_view WHERE a = 31 RETURNING a, b;

\set QUIET true

-- Describe view should list triggers
\d main_view

-- Test dropping view triggers
--DDL_STATEMENT_BEGIN--
DROP TRIGGER instead_of_insert_trig ON main_view;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
DROP TRIGGER instead_of_delete_trig ON main_view;
--DDL_STATEMENT_END--
\d+ main_view
--DDL_STATEMENT_BEGIN--
DROP VIEW main_view;
--DDL_STATEMENT_END--

--
-- Test triggers on a join view
--
--DDL_STATEMENT_BEGIN--
CREATE TABLE country_table (
    country_id        serial primary key,
    country_name    text unique not null,
    continent        text not null
);
--DDL_STATEMENT_END--

INSERT INTO country_table (country_name, continent)
    VALUES ('Japan', 'Asia'),
           ('UK', 'Europe'),
           ('USA', 'North America')
    RETURNING *;
	
--DDL_STATEMENT_BEGIN--
CREATE TABLE city_table (
    city_id        serial primary key,
    city_name    text not null,
    population    bigint,
    country_id    int references country_table
);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE VIEW city_view AS
    SELECT city_id, city_name, population, country_name, continent
    FROM city_table ci
    LEFT JOIN country_table co ON co.country_id = ci.country_id;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE FUNCTION city_insert() RETURNS trigger LANGUAGE plpgsql AS $$
declare
    ctry_id int;
begin
    if NEW.country_name IS NOT NULL then
        SELECT country_id, continent INTO ctry_id, NEW.continent
            FROM country_table WHERE country_name = NEW.country_name;
        if NOT FOUND then
            raise exception 'No such country: "%"', NEW.country_name;
        end if;
    else
        NEW.continent = NULL;
    end if;

    if NEW.city_id IS NOT NULL then
        INSERT INTO city_table
            VALUES(NEW.city_id, NEW.city_name, NEW.population, ctry_id);
    else
        INSERT INTO city_table(city_name, population, country_id)
            VALUES(NEW.city_name, NEW.population, ctry_id)
            RETURNING city_id INTO NEW.city_id;
    end if;

    RETURN NEW;
end;
$$;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER city_insert_trig INSTEAD OF INSERT ON city_view
FOR EACH ROW EXECUTE PROCEDURE city_insert();
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE FUNCTION city_delete() RETURNS trigger LANGUAGE plpgsql AS $$
begin
    DELETE FROM city_table WHERE city_id = OLD.city_id;
    if NOT FOUND then RETURN NULL; end if;
    RETURN OLD;
end;
$$;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER city_delete_trig INSTEAD OF DELETE ON city_view
FOR EACH ROW EXECUTE PROCEDURE city_delete();
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE FUNCTION city_update() RETURNS trigger LANGUAGE plpgsql AS $$
declare
    ctry_id int;
begin
    if NEW.country_name IS DISTINCT FROM OLD.country_name then
        SELECT country_id, continent INTO ctry_id, NEW.continent
            FROM country_table WHERE country_name = NEW.country_name;
        if NOT FOUND then
            raise exception 'No such country: "%"', NEW.country_name;
        end if;

        UPDATE city_table SET city_name = NEW.city_name,
                              population = NEW.population,
                              country_id = ctry_id
            WHERE city_id = OLD.city_id;
    else
        UPDATE city_table SET city_name = NEW.city_name,
                              population = NEW.population
            WHERE city_id = OLD.city_id;
        NEW.continent = OLD.continent;
    end if;

    if NOT FOUND then RETURN NULL; end if;
    RETURN NEW;
end;
$$;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER city_update_trig INSTEAD OF UPDATE ON city_view
FOR EACH ROW EXECUTE PROCEDURE city_update();
--DDL_STATEMENT_END--

\set QUIET false

-- INSERT .. RETURNING
INSERT INTO city_view(city_name) VALUES('Tokyo') RETURNING *;
INSERT INTO city_view(city_name, population) VALUES('London', 7556900) RETURNING *;
INSERT INTO city_view(city_name, country_name) VALUES('Washington DC', 'USA') RETURNING *;
INSERT INTO city_view(city_id, city_name) VALUES(123456, 'New York') RETURNING *;
INSERT INTO city_view VALUES(234567, 'Birmingham', 1016800, 'UK', 'EU') RETURNING *;

-- UPDATE .. RETURNING
UPDATE city_view SET country_name = 'Japon' WHERE city_name = 'Tokyo'; -- error
UPDATE city_view SET country_name = 'Japan' WHERE city_name = 'Takyo'; -- no match
UPDATE city_view SET country_name = 'Japan' WHERE city_name = 'Tokyo' RETURNING *; -- OK

UPDATE city_view SET population = 13010279 WHERE city_name = 'Tokyo' RETURNING *;
UPDATE city_view SET country_name = 'UK' WHERE city_name = 'New York' RETURNING *;
UPDATE city_view SET country_name = 'USA', population = 8391881 WHERE city_name = 'New York' RETURNING *;
UPDATE city_view SET continent = 'EU' WHERE continent = 'Europe' RETURNING *;
UPDATE city_view v1 SET country_name = v2.country_name FROM city_view v2
    WHERE v2.city_name = 'Birmingham' AND v1.city_name = 'London' RETURNING *;

-- DELETE .. RETURNING
DELETE FROM city_view WHERE city_name = 'Birmingham' RETURNING *;

\set QUIET true

-- read-only view with WHERE clause
--DDL_STATEMENT_BEGIN--
CREATE VIEW european_city_view AS
    SELECT * FROM city_view WHERE continent = 'Europe';
SELECT count(*) FROM european_city_view;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE FUNCTION no_op_trig_fn() RETURNS trigger LANGUAGE plpgsql
AS 'begin RETURN NULL; end';
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE TRIGGER no_op_trig INSTEAD OF INSERT OR UPDATE OR DELETE
ON european_city_view FOR EACH ROW EXECUTE PROCEDURE no_op_trig_fn();
--DDL_STATEMENT_END--

\set QUIET false

INSERT INTO european_city_view VALUES (0, 'x', 10000, 'y', 'z');
UPDATE european_city_view SET population = 10000;
DELETE FROM european_city_view;

\set QUIET true

-- rules bypassing no-op triggers
--DDL_STATEMENT_BEGIN--
CREATE RULE european_city_insert_rule AS ON INSERT TO european_city_view
DO INSTEAD INSERT INTO city_view
VALUES (NEW.city_id, NEW.city_name, NEW.population, NEW.country_name, NEW.continent)
RETURNING *;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE RULE european_city_update_rule AS ON UPDATE TO european_city_view
DO INSTEAD UPDATE city_view SET
    city_name = NEW.city_name,
    population = NEW.population,
    country_name = NEW.country_name
WHERE city_id = OLD.city_id
RETURNING NEW.*;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
CREATE RULE european_city_delete_rule AS ON DELETE TO european_city_view
DO INSTEAD DELETE FROM city_view WHERE city_id = OLD.city_id RETURNING *;
--DDL_STATEMENT_END--

\set QUIET false

-- INSERT not limited by view's WHERE clause, but UPDATE AND DELETE are
INSERT INTO european_city_view(city_name, country_name)
    VALUES ('Cambridge', 'USA') RETURNING *;
UPDATE european_city_view SET country_name = 'UK'
    WHERE city_name = 'Cambridge';
DELETE FROM european_city_view WHERE city_name = 'Cambridge';

-- UPDATE and DELETE via rule and trigger
UPDATE city_view SET country_name = 'UK'
    WHERE city_name = 'Cambridge' RETURNING *;
UPDATE european_city_view SET population = 122800
    WHERE city_name = 'Cambridge' RETURNING *;
DELETE FROM european_city_view WHERE city_name = 'Cambridge' RETURNING *;

-- join UPDATE test
UPDATE city_view v SET population = 599657
    FROM city_table ci, country_table co
    WHERE ci.city_name = 'Washington DC' and co.country_name = 'USA'
    AND v.city_id = ci.city_id AND v.country_name = co.country_name
    RETURNING co.country_id, v.country_name,
              v.city_id, v.city_name, v.population;

\set QUIET true

SELECT * FROM city_view;

--DDL_STATEMENT_BEGIN--
DROP TABLE city_table CASCADE;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
DROP TABLE country_table;
--DDL_STATEMENT_END--


-- Test pg_trigger_depth()

--DDL_STATEMENT_BEGIN--
create table depth_a (id int not null primary key);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table depth_b (id int not null primary key);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table depth_c (id int not null primary key);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create function depth_a_tf() returns trigger
  language plpgsql as $$
begin
  raise notice '%: depth = %', tg_name, pg_trigger_depth();
  insert into depth_b values (new.id);
  raise notice '%: depth = %', tg_name, pg_trigger_depth();
  return new;
end;
$$;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger depth_a_tr before insert on depth_a
  for each row execute procedure depth_a_tf();
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create function depth_b_tf() returns trigger
  language plpgsql as $$
begin
  raise notice '%: depth = %', tg_name, pg_trigger_depth();
  begin
    execute 'insert into depth_c values (' || new.id::text || ')';
  exception
    when sqlstate 'U9999' then
      raise notice 'SQLSTATE = U9999: depth = %', pg_trigger_depth();
  end;
  raise notice '%: depth = %', tg_name, pg_trigger_depth();
  if new.id = 1 then
    execute 'insert into depth_c values (' || new.id::text || ')';
  end if;
  return new;
end;
$$;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger depth_b_tr before insert on depth_b
  for each row execute procedure depth_b_tf();
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create function depth_c_tf() returns trigger
  language plpgsql as $$
begin
  raise notice '%: depth = %', tg_name, pg_trigger_depth();
  if new.id = 1 then
    raise exception sqlstate 'U9999';
  end if;
  raise notice '%: depth = %', tg_name, pg_trigger_depth();
  return new;
end;
$$;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger depth_c_tr before insert on depth_c
  for each row execute procedure depth_c_tf();
--DDL_STATEMENT_END--

select pg_trigger_depth();
insert into depth_a values (1);
select pg_trigger_depth();
insert into depth_a values (2);
select pg_trigger_depth();

--DDL_STATEMENT_BEGIN--
drop table depth_a, depth_b, depth_c;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop function depth_a_tf();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop function depth_b_tf();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop function depth_c_tf();
--DDL_STATEMENT_END--

--
-- Test updates to rows during firing of BEFORE ROW triggers.
-- As of 9.2, such cases should be rejected (see bug #6123).
--

--DDL_STATEMENT_BEGIN--
create temp table parent (
    aid int not null primary key,
    val1 text,
    val2 text,
    val3 text,
    val4 text,
    bcnt int not null default 0);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create temp table child (
    bid int not null primary key,
    aid int not null,
    val1 text);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create function parent_upd_func()
  returns trigger language plpgsql as
$$
begin
  if old.val1 <> new.val1 then
    new.val2 = new.val1;
    delete from child where child.aid = new.aid and child.val1 = new.val1;
  end if;
  return new;
end;
$$;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger parent_upd_trig before update on parent
  for each row execute procedure parent_upd_func();
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create function parent_del_func()
  returns trigger language plpgsql as
$$
begin
  delete from child where aid = old.aid;
  return old;
end;
$$;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger parent_del_trig before delete on parent
  for each row execute procedure parent_del_func();
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create function child_ins_func()
  returns trigger language plpgsql as
$$
begin
  update parent set bcnt = bcnt + 1 where aid = new.aid;
  return new;
end;
$$;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger child_ins_trig after insert on child
  for each row execute procedure child_ins_func();
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create function child_del_func()
  returns trigger language plpgsql as
$$
begin
  update parent set bcnt = bcnt - 1 where aid = old.aid;
  return old;
end;
$$;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger child_del_trig after delete on child
  for each row execute procedure child_del_func();
--DDL_STATEMENT_END--

insert into parent values (1, 'a', 'a', 'a', 'a', 0);
insert into child values (10, 1, 'b');
select * from parent; select * from child;

update parent set val1 = 'b' where aid = 1; -- should fail
select * from parent; select * from child;

delete from parent where aid = 1; -- should fail
select * from parent; select * from child;

-- replace the trigger function with one that restarts the deletion after
-- having modified a child
--DDL_STATEMENT_BEGIN--
create or replace function parent_del_func()
  returns trigger language plpgsql as
$$
begin
  delete from child where aid = old.aid;
  if found then
    delete from parent where aid = old.aid;
    return null; -- cancel outer deletion
  end if;
  return old;
end;
$$;
--DDL_STATEMENT_END--

delete from parent where aid = 1;
select * from parent; select * from child;

--DDL_STATEMENT_BEGIN--
drop table parent, child;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
drop function parent_upd_func();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop function parent_del_func();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop function child_ins_func();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop function child_del_func();
--DDL_STATEMENT_END--

-- similar case, but with a self-referencing FK so that parent and child
-- rows can be affected by a single operation

--DDL_STATEMENT_BEGIN--
create temp table self_ref_trigger (
    id int primary key,
    parent int references self_ref_trigger,
    data text,
    nchildren int not null default 0
);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create function self_ref_trigger_ins_func()
  returns trigger language plpgsql as
$$
begin
  if new.parent is not null then
    update self_ref_trigger set nchildren = nchildren + 1
      where id = new.parent;
  end if;
  return new;
end;
$$;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger self_ref_trigger_ins_trig before insert on self_ref_trigger
  for each row execute procedure self_ref_trigger_ins_func();
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create function self_ref_trigger_del_func()
  returns trigger language plpgsql as
$$
begin
  if old.parent is not null then
    update self_ref_trigger set nchildren = nchildren - 1
      where id = old.parent;
  end if;
  return old;
end;
$$;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger self_ref_trigger_del_trig before delete on self_ref_trigger
  for each row execute procedure self_ref_trigger_del_func();
--DDL_STATEMENT_END--

insert into self_ref_trigger values (1, null, 'root');
insert into self_ref_trigger values (2, 1, 'root child A');
insert into self_ref_trigger values (3, 1, 'root child B');
insert into self_ref_trigger values (4, 2, 'grandchild 1');
insert into self_ref_trigger values (5, 3, 'grandchild 2');

update self_ref_trigger set data = 'root!' where id = 1;

select * from self_ref_trigger;

delete from self_ref_trigger;

select * from self_ref_trigger;

--DDL_STATEMENT_BEGIN--
drop table self_ref_trigger;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop function self_ref_trigger_ins_func();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop function self_ref_trigger_del_func();
--DDL_STATEMENT_END--

--
-- Check that statement triggers work correctly even with all children excluded
--

--DDL_STATEMENT_BEGIN--
create table stmt_trig_on_empty_upd (a int);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table stmt_trig_on_empty_upd1 () inherits (stmt_trig_on_empty_upd);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create function update_stmt_notice() returns trigger as $$
begin
	raise notice 'updating %', TG_TABLE_NAME;
	return null;
end;
$$ language plpgsql;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger before_stmt_trigger
	before update on stmt_trig_on_empty_upd
	execute procedure update_stmt_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger before_stmt_trigger
	before update on stmt_trig_on_empty_upd1
	execute procedure update_stmt_notice();
--DDL_STATEMENT_END--

-- inherited no-op update
update stmt_trig_on_empty_upd set a = a where false returning a+1 as aa;
-- simple no-op update
update stmt_trig_on_empty_upd1 set a = a where false returning a+1 as aa;

--DDL_STATEMENT_BEGIN--
drop table stmt_trig_on_empty_upd cascade;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop function update_stmt_notice();
--DDL_STATEMENT_END--

--
-- Check that index creation (or DDL in general) is prohibited in a trigger
--

--DDL_STATEMENT_BEGIN--
create table trigger_ddl_table (
   col1 integer,
   col2 integer
);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create function trigger_ddl_func() returns trigger as $$
begin
  alter table trigger_ddl_table add primary key (col1);
  return new;
end$$ language plpgsql;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger trigger_ddl_func before insert on trigger_ddl_table for each row
  execute procedure trigger_ddl_func();
--DDL_STATEMENT_END--

insert into trigger_ddl_table values (1, 42);  -- fail

--DDL_STATEMENT_BEGIN--
create or replace function trigger_ddl_func() returns trigger as $$
begin
  create index on trigger_ddl_table (col2);
  return new;
end$$ language plpgsql;
--DDL_STATEMENT_END--

insert into trigger_ddl_table values (1, 42);  -- fail

--DDL_STATEMENT_BEGIN--
drop table trigger_ddl_table;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop function trigger_ddl_func();
--DDL_STATEMENT_END--

--
-- Verify behavior of before and after triggers with INSERT...ON CONFLICT
-- DO UPDATE
--
--DDL_STATEMENT_BEGIN--
create table upsert (key int4 primary key, color text);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create function upsert_before_func()
  returns trigger language plpgsql as
$$
begin
  if (TG_OP = 'UPDATE') then
    raise warning 'before update (old): %', old.*::text;
    raise warning 'before update (new): %', new.*::text;
  elsif (TG_OP = 'INSERT') then
    raise warning 'before insert (new): %', new.*::text;
    if new.key % 2 = 0 then
      new.key = new.key + 1;
      new.color = new.color || ' trig modified';
      raise warning 'before insert (new, modified): %', new.*::text;
    end if;
  end if;
  return new;
end;
$$;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger upsert_before_trig before insert or update on upsert
  for each row execute procedure upsert_before_func();
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create function upsert_after_func()
  returns trigger language plpgsql as
$$
begin
  if (TG_OP = 'UPDATE') then
    raise warning 'after update (old): %', old.*::text;
    raise warning 'after update (new): %', new.*::text;
  elsif (TG_OP = 'INSERT') then
    raise warning 'after insert (new): %', new.*::text;
  end if;
  return null;
end;
$$;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger upsert_after_trig after insert or update on upsert
  for each row execute procedure upsert_after_func();
--DDL_STATEMENT_END--

insert into upsert values(1, 'black') on conflict (key) do update set color = 'updated ' || upsert.color;
insert into upsert values(2, 'red') on conflict (key) do update set color = 'updated ' || upsert.color;
insert into upsert values(3, 'orange') on conflict (key) do update set color = 'updated ' || upsert.color;
insert into upsert values(4, 'green') on conflict (key) do update set color = 'updated ' || upsert.color;
insert into upsert values(5, 'purple') on conflict (key) do update set color = 'updated ' || upsert.color;
insert into upsert values(6, 'white') on conflict (key) do update set color = 'updated ' || upsert.color;
insert into upsert values(7, 'pink') on conflict (key) do update set color = 'updated ' || upsert.color;
insert into upsert values(8, 'yellow') on conflict (key) do update set color = 'updated ' || upsert.color;

select * from upsert;

--DDL_STATEMENT_BEGIN--
drop table upsert;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop function upsert_before_func();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop function upsert_after_func();
--DDL_STATEMENT_END--

--
-- Verify that triggers with transition tables are not allowed on
-- views
--

--DDL_STATEMENT_BEGIN--
create table my_table (i int);
--DDL_STATEMENT_END--
--DDL_STATEMENT_END--
create view my_view as select * from my_table;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create function my_trigger_function() returns trigger as $$ begin end; $$ language plpgsql;
--DDL_STATEMENT_END--
--DDL_STATEMENT_END--
create trigger my_trigger after update on my_view referencing old table as old_table
   for each statement execute procedure my_trigger_function();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop function my_trigger_function();
--DDL_STATEMENT_END--
--DDL_STATEMENT_END--
drop view my_view;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop table my_table;
--DDL_STATEMENT_END--

--
-- Verify cases that are unsupported with partitioned tables
--
--DDL_STATEMENT_BEGIN--
create table parted_trig (a int) partition by list (a);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create function trigger_nothing() returns trigger
  language plpgsql as $$ begin end; $$;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger failed before insert or update or delete on parted_trig
  for each row execute procedure trigger_nothing();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger failed instead of update on parted_trig
  for each row execute procedure trigger_nothing();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger failed after update on parted_trig
  referencing old table as old_table
  for each row execute procedure trigger_nothing();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop table parted_trig;
--DDL_STATEMENT_END--

--
-- Verify trigger creation for partitioned tables, and drop behavior
--
--DDL_STATEMENT_BEGIN--
create table trigpart (a int, b int) partition by range (a);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table trigpart1 partition of trigpart for values from (0) to (1000);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trg1 after insert on trigpart for each row execute procedure trigger_nothing();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table trigpart2 partition of trigpart for values from (1000) to (2000);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table trigpart3 (like trigpart);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table trigpart attach partition trigpart3 for values from (2000) to (3000);
--DDL_STATEMENT_END--
select tgrelid::regclass, tgname, tgfoid::regproc from pg_trigger
  where tgrelid::regclass::text like 'trigpart%' order by tgrelid::regclass::text;
--DDL_STATEMENT_BEGIN--
drop trigger trg1 on trigpart1;	-- fail
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop trigger trg1 on trigpart2;	-- fail
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop trigger trg1 on trigpart3;	-- fail
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop table trigpart2;			-- ok, trigger should be gone in that partition
--DDL_STATEMENT_END--
select tgrelid::regclass, tgname, tgfoid::regproc from pg_trigger
  where tgrelid::regclass::text like 'trigpart%' order by tgrelid::regclass::text;
--DDL_STATEMENT_BEGIN--
drop trigger trg1 on trigpart;		-- ok, all gone
--DDL_STATEMENT_END--
select tgrelid::regclass, tgname, tgfoid::regproc from pg_trigger
  where tgrelid::regclass::text like 'trigpart%' order by tgrelid::regclass::text;

--DDL_STATEMENT_BEGIN--
drop table trigpart;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop function trigger_nothing();
--DDL_STATEMENT_END--

--
-- Verify that triggers are fired for partitioned tables
--
--DDL_STATEMENT_BEGIN--
create table parted_stmt_trig (a int) partition by list (a);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_stmt_trig1 partition of parted_stmt_trig for values in (1);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_stmt_trig2 partition of parted_stmt_trig for values in (2);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create table parted2_stmt_trig (a int) partition by list (a);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted2_stmt_trig1 partition of parted2_stmt_trig for values in (1);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted2_stmt_trig2 partition of parted2_stmt_trig for values in (2);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create or replace function trigger_notice() returns trigger as $$
  begin
    raise notice 'trigger % on % % % for %', TG_NAME, TG_TABLE_NAME, TG_WHEN, TG_OP, TG_LEVEL;
    if TG_LEVEL = 'ROW' then
       return NEW;
    end if;
    return null;
  end;
  $$ language plpgsql;
--DDL_STATEMENT_END--

-- insert/update/delete statement-level triggers on the parent
--DDL_STATEMENT_BEGIN--
create trigger trig_ins_before before insert on parted_stmt_trig
  for each statement execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_ins_after after insert on parted_stmt_trig
  for each statement execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_upd_before before update on parted_stmt_trig
  for each statement execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_upd_after after update on parted_stmt_trig
  for each statement execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_del_before before delete on parted_stmt_trig
  for each statement execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_del_after after delete on parted_stmt_trig
  for each statement execute procedure trigger_notice();
--DDL_STATEMENT_END--

-- insert/update/delete row-level triggers on the parent
--DDL_STATEMENT_BEGIN--
create trigger trig_ins_after_parent after insert on parted_stmt_trig
  for each row execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_upd_after_parent after update on parted_stmt_trig
  for each row execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_del_after_parent after delete on parted_stmt_trig
  for each row execute procedure trigger_notice();
--DDL_STATEMENT_END--

-- insert/update/delete row-level triggers on the first partition
--DDL_STATEMENT_BEGIN--
create trigger trig_ins_before_child before insert on parted_stmt_trig1
  for each row execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_ins_after_child after insert on parted_stmt_trig1
  for each row execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_upd_before_child before update on parted_stmt_trig1
  for each row execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_upd_after_child after update on parted_stmt_trig1
  for each row execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_del_before_child before delete on parted_stmt_trig1
  for each row execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_del_after_child after delete on parted_stmt_trig1
  for each row execute procedure trigger_notice();
--DDL_STATEMENT_END--
-- insert/update/delete statement-level triggers on the parent
--DDL_STATEMENT_BEGIN--
create trigger trig_ins_before_3 before insert on parted2_stmt_trig
  for each statement execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_ins_after_3 after insert on parted2_stmt_trig
  for each statement execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_upd_before_3 before update on parted2_stmt_trig
  for each statement execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_upd_after_3 after update on parted2_stmt_trig
  for each statement execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_del_before_3 before delete on parted2_stmt_trig
  for each statement execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_del_after_3 after delete on parted2_stmt_trig
  for each statement execute procedure trigger_notice();
--DDL_STATEMENT_END--
with ins (a) as (
  insert into parted2_stmt_trig values (1), (2) returning a
) insert into parted_stmt_trig select a from ins returning tableoid::regclass, a;

with upd as (
  update parted2_stmt_trig set a = a
) update parted_stmt_trig  set a = a;

delete from parted_stmt_trig;

-- insert via copy on the parent
copy parted_stmt_trig(a) from stdin;
1
2
\.

-- insert via copy on the first partition
copy parted_stmt_trig1(a) from stdin;
1
\.

-- Disabling a trigger in the parent table should disable children triggers too
--DDL_STATEMENT_BEGIN--
alter table parted_stmt_trig disable trigger trig_ins_after_parent;
--DDL_STATEMENT_END--
insert into parted_stmt_trig values (1);
--DDL_STATEMENT_BEGIN--
alter table parted_stmt_trig enable trigger trig_ins_after_parent;
--DDL_STATEMENT_END--
insert into parted_stmt_trig values (1);

--DDL_STATEMENT_BEGIN--
drop table parted_stmt_trig, parted2_stmt_trig;
--DDL_STATEMENT_END--

-- Verify that triggers fire in alphabetical order
--DDL_STATEMENT_BEGIN--
create table parted_trig (a int) partition by range (a);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trig_1 partition of parted_trig for values from (0) to (1000)
   partition by range (a);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trig_1_1 partition of parted_trig_1 for values from (0) to (100);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trig_2 partition of parted_trig for values from (1000) to (2000);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger zzz after insert on parted_trig for each row execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger mmm after insert on parted_trig_1_1 for each row execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger aaa after insert on parted_trig_1 for each row execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger bbb after insert on parted_trig for each row execute procedure trigger_notice();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger qqq after insert on parted_trig_1_1 for each row execute procedure trigger_notice();
--DDL_STATEMENT_END--
insert into parted_trig values (50), (1500);
--DDL_STATEMENT_BEGIN--
drop table parted_trig;
--DDL_STATEMENT_END--

-- Verify propagation of trigger arguments to partitions
--DDL_STATEMENT_BEGIN--
create table parted_trig (a int) partition by list (a);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trig1 partition of parted_trig for values in (1);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create or replace function trigger_notice() returns trigger as $$
  declare
    arg1 text = TG_ARGV[0];
    arg2 integer = TG_ARGV[1];
  begin
    raise notice 'trigger % on % % % for % args % %',
		TG_NAME, TG_TABLE_NAME, TG_WHEN, TG_OP, TG_LEVEL, arg1, arg2;
    return null;
  end;
  $$ language plpgsql;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger aaa after insert on parted_trig
   for each row execute procedure trigger_notice('quirky', 1);
--DDL_STATEMENT_END--

-- Verify propagation of trigger arguments to partitions attached after creating trigger
--DDL_STATEMENT_BEGIN--
create table parted_trig2 partition of parted_trig for values in (2);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trig3 (like parted_trig);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parted_trig attach partition parted_trig3 for values in (3);
--DDL_STATEMENT_END--
insert into parted_trig values (1), (2), (3);
--DDL_STATEMENT_BEGIN--
drop table parted_trig;
--DDL_STATEMENT_END--
-- test irregular partitions (i.e., different column definitions),
-- including that the WHEN clause works
--DDL_STATEMENT_BEGIN--
create function bark(text) returns bool language plpgsql immutable
  as $$ begin raise notice '% <- woof!', $1; return true; end; $$;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create or replace function trigger_notice_ab() returns trigger as $$
  begin
    raise notice 'trigger % on % % % for %: (a,b)=(%,%)',
		TG_NAME, TG_TABLE_NAME, TG_WHEN, TG_OP, TG_LEVEL,
		NEW.a, NEW.b;
    if TG_LEVEL = 'ROW' then
       return NEW;
    end if;
    return null;
  end;
  $$ language plpgsql;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_irreg_ancestor (fd text, b text, fd2 int, fd3 int, a int)
  partition by range (b);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parted_irreg_ancestor drop column fd,
  drop column fd2, drop column fd3;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_irreg (fd int, a int, fd2 int, b text)
  partition by range (b);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parted_irreg drop column fd, drop column fd2;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parted_irreg_ancestor attach partition parted_irreg
  for values from ('aaaa') to ('zzzz');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted1_irreg (b text, fd int, a int);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parted1_irreg drop column fd;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parted_irreg attach partition parted1_irreg
  for values from ('aaaa') to ('bbbb');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger parted_trig after insert on parted_irreg
  for each row execute procedure trigger_notice_ab();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger parted_trig_odd after insert on parted_irreg for each row
  when (bark(new.b) AND new.a % 2 = 1) execute procedure trigger_notice_ab();
--DDL_STATEMENT_END--
-- we should hear barking for every insert, but parted_trig_odd only emits
-- noise for odd values of a. parted_trig does it for all inserts.
insert into parted_irreg values (1, 'aardvark'), (2, 'aanimals');
insert into parted1_irreg values ('aardwolf', 2);
insert into parted_irreg_ancestor values ('aasvogel', 3);
--DDL_STATEMENT_BEGIN--
drop table parted_irreg_ancestor;
--DDL_STATEMENT_END--

--
-- Constraint triggers and partitioned tables
--DDL_STATEMENT_BEGIN--
create table parted_constr_ancestor (a int, b text)
  partition by range (b);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_constr (a int, b text)
  partition by range (b);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parted_constr_ancestor attach partition parted_constr
  for values from ('aaaa') to ('zzzz');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted1_constr (a int, b text);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parted_constr attach partition parted1_constr
  for values from ('aaaa') to ('bbbb');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create constraint trigger parted_trig after insert on parted_constr_ancestor
  deferrable
  for each row execute procedure trigger_notice_ab();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create constraint trigger parted_trig_two after insert on parted_constr
  deferrable initially deferred
  for each row when (bark(new.b) AND new.a % 2 = 1)
  execute procedure trigger_notice_ab();
--DDL_STATEMENT_END--

-- The immediate constraint is fired immediately; the WHEN clause of the
-- deferred constraint is also called immediately.  The deferred constraint
-- is fired at commit time.
begin;
insert into parted_constr values (1, 'aardvark');
insert into parted1_constr values (2, 'aardwolf');
insert into parted_constr_ancestor values (3, 'aasvogel');
commit;

-- The WHEN clause is immediate, and both constraint triggers are fired at
-- commit time.
begin;
set constraints parted_trig deferred;
insert into parted_constr values (1, 'aardvark');
insert into parted1_constr values (2, 'aardwolf'), (3, 'aasvogel');
commit;
--DDL_STATEMENT_BEGIN--
drop table parted_constr_ancestor;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop function bark(text);
--DDL_STATEMENT_END--

-- Test that the WHEN clause is set properly to partitions
--DDL_STATEMENT_BEGIN--
create table parted_trigger (a int, b text) partition by range (a);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trigger_1 partition of parted_trigger for values from (0) to (1000);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trigger_2 (drp int, a int, b text);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parted_trigger_2 drop column drp;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parted_trigger attach partition parted_trigger_2 for values from (1000) to (2000);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger parted_trigger after update on parted_trigger
  for each row when (new.a % 2 = 1 and length(old.b) >= 2) execute procedure trigger_notice_ab();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trigger_3 (b text, a int) partition by range (length(b));
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trigger_3_1 partition of parted_trigger_3 for values from (1) to (3);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trigger_3_2 partition of parted_trigger_3 for values from (3) to (5);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parted_trigger attach partition parted_trigger_3 for values from (2000) to (3000);
--DDL_STATEMENT_END--
insert into parted_trigger values
    (0, 'a'), (1, 'bbb'), (2, 'bcd'), (3, 'c'),
	(1000, 'c'), (1001, 'ddd'), (1002, 'efg'), (1003, 'f'),
	(2000, 'e'), (2001, 'fff'), (2002, 'ghi'), (2003, 'h');
update parted_trigger set a = a + 2; -- notice for odd 'a' values, long 'b' values
--DDL_STATEMENT_BEGIN--
drop table parted_trigger;
--DDL_STATEMENT_END--

-- try a constraint trigger, also
--DDL_STATEMENT_BEGIN--
create table parted_referenced (a int);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table unparted_trigger (a int, b text);	-- for comparison purposes
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trigger (a int, b text) partition by range (a);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trigger_1 partition of parted_trigger for values from (0) to (1000);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trigger_2 (drp int, a int, b text);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parted_trigger_2 drop column drp;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parted_trigger attach partition parted_trigger_2 for values from (1000) to (2000);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create constraint trigger parted_trigger after update on parted_trigger
  from parted_referenced
  for each row execute procedure trigger_notice_ab();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create constraint trigger parted_trigger after update on unparted_trigger
  from parted_referenced
  for each row execute procedure trigger_notice_ab();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trigger_3 (b text, a int) partition by range (length(b));
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trigger_3_1 partition of parted_trigger_3 for values from (1) to (3);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trigger_3_2 partition of parted_trigger_3 for values from (3) to (5);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parted_trigger attach partition parted_trigger_3 for values from (2000) to (3000);
--DDL_STATEMENT_END--
select tgname, conname, t.tgrelid::regclass, t.tgconstrrelid::regclass,
  c.conrelid::regclass, c.confrelid::regclass
  from pg_trigger t join pg_constraint c on (t.tgconstraint = c.oid)
  where tgname = 'parted_trigger'
  order by t.tgrelid::regclass::text;
--DDL_STATEMENT_BEGIN--
drop table parted_referenced, parted_trigger, unparted_trigger;
--DDL_STATEMENT_END--

-- verify that the "AFTER UPDATE OF columns" event is propagated correctly
--DDL_STATEMENT_BEGIN--
create table parted_trigger (a int, b text) partition by range (a);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trigger_1 partition of parted_trigger for values from (0) to (1000);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trigger_2 (drp int, a int, b text);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parted_trigger_2 drop column drp;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parted_trigger attach partition parted_trigger_2 for values from (1000) to (2000);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger parted_trigger after update of b on parted_trigger
  for each row execute procedure trigger_notice_ab();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trigger_3 (b text, a int) partition by range (length(b));
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trigger_3_1 partition of parted_trigger_3 for values from (1) to (4);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table parted_trigger_3_2 partition of parted_trigger_3 for values from (4) to (8);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parted_trigger attach partition parted_trigger_3 for values from (2000) to (3000);
--DDL_STATEMENT_END--
insert into parted_trigger values (0, 'a'), (1000, 'c'), (2000, 'e'), (2001, 'eeee');
update parted_trigger set a = a + 2;	-- no notices here
update parted_trigger set b = b || 'b';	-- all triggers should fire
--DDL_STATEMENT_BEGIN--
drop table parted_trigger;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
drop function trigger_notice_ab();
--DDL_STATEMENT_END--

-- Make sure we don't end up with unnecessary copies of triggers, when
-- cloning them.
--DDL_STATEMENT_BEGIN--
create table trg_clone (a int) partition by range (a);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table trg_clone1 partition of trg_clone for values from (0) to (1000);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table trg_clone add constraint uniq unique (a) deferrable;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table trg_clone2 partition of trg_clone for values from (1000) to (2000);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table trg_clone3 partition of trg_clone for values from (2000) to (3000)
  partition by range (a);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table trg_clone_3_3 partition of trg_clone3 for values from (2000) to (2100);
--DDL_STATEMENT_END--
select tgrelid::regclass, count(*) from pg_trigger
  where tgrelid::regclass in ('trg_clone', 'trg_clone1', 'trg_clone2',
	'trg_clone3', 'trg_clone_3_3')
  group by tgrelid::regclass order by tgrelid::regclass;
--DDL_STATEMENT_BEGIN--
drop table trg_clone;
--DDL_STATEMENT_END--

--
-- Test the interaction between transition tables and both kinds of
-- inheritance.  We'll dump the contents of the transition tables in a
-- format that shows the attribute order, so that we can distinguish
-- tuple formats (though not dropped attributes).
--

--DDL_STATEMENT_BEGIN--
create or replace function dump_insert() returns trigger language plpgsql as
$$
  begin
    raise notice 'trigger = %, new table = %',
                 TG_NAME,
                 (select string_agg(new_table::text, ', ' order by a) from new_table);
    return null;
  end;
$$;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create or replace function dump_update() returns trigger language plpgsql as
$$
  begin
    raise notice 'trigger = %, old table = %, new table = %',
                 TG_NAME,
                 (select string_agg(old_table::text, ', ' order by a) from old_table),
                 (select string_agg(new_table::text, ', ' order by a) from new_table);
    return null;
  end;
$$;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create or replace function dump_delete() returns trigger language plpgsql as
$$
  begin
    raise notice 'trigger = %, old table = %',
                 TG_NAME,
                 (select string_agg(old_table::text, ', ' order by a) from old_table);
    return null;
  end;
$$;
--DDL_STATEMENT_END--

--
-- Verify behavior of statement triggers on partition hierarchy with
-- transition tables.  Tuples should appear to each trigger in the
-- format of the relation the trigger is attached to.
--

--DDL_STATEMENT_BEGIN--
-- set up a partition hierarchy with some different TupleDescriptors
create table parent (a text, b int) partition by list (a);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
-- a child matching parent
create table child1 partition of parent for values in ('AAA');
--DDL_STATEMENT_END--

-- a child with a dropped column
--DDL_STATEMENT_BEGIN--
create table child2 (x int, a text, b int);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table child2 drop column x;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parent attach partition child2 for values in ('BBB');
--DDL_STATEMENT_END--

-- a child with a different column order
--DDL_STATEMENT_BEGIN--
create table child3 (b int, a text);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parent attach partition child3 for values in ('CCC');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger parent_insert_trig
  after insert on parent referencing new table as new_table
  for each statement execute procedure dump_insert();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger parent_update_trig
  after update on parent referencing old table as old_table new table as new_table
  for each statement execute procedure dump_update();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger parent_delete_trig
  after delete on parent referencing old table as old_table
  for each statement execute procedure dump_delete();
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger child1_insert_trig
  after insert on child1 referencing new table as new_table
  for each statement execute procedure dump_insert();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger child1_update_trig
  after update on child1 referencing old table as old_table new table as new_table
  for each statement execute procedure dump_update();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger child1_delete_trig
  after delete on child1 referencing old table as old_table
  for each statement execute procedure dump_delete();
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger child2_insert_trig
  after insert on child2 referencing new table as new_table
  for each statement execute procedure dump_insert();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger child2_update_trig
  after update on child2 referencing old table as old_table new table as new_table
  for each statement execute procedure dump_update();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger child2_delete_trig
  after delete on child2 referencing old table as old_table
  for each statement execute procedure dump_delete();
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger child3_insert_trig
  after insert on child3 referencing new table as new_table
  for each statement execute procedure dump_insert();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger child3_update_trig
  after update on child3 referencing old table as old_table new table as new_table
  for each statement execute procedure dump_update();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger child3_delete_trig
  after delete on child3 referencing old table as old_table
  for each statement execute procedure dump_delete();
--DDL_STATEMENT_END--

SELECT trigger_name, event_manipulation, event_object_schema, event_object_table,
       action_order, action_condition, action_orientation, action_timing,
       action_reference_old_table, action_reference_new_table
  FROM information_schema.triggers
  WHERE event_object_table IN ('parent', 'child1', 'child2', 'child3')
  ORDER BY trigger_name COLLATE "C", 2;

-- insert directly into children sees respective child-format tuples
insert into child1 values ('AAA', 42);
insert into child2 values ('BBB', 42);
insert into child3 values (42, 'CCC');

-- update via parent sees parent-format tuples
update parent set b = b + 1;

-- delete via parent sees parent-format tuples
delete from parent;

-- insert into parent sees parent-format tuples
insert into parent values ('AAA', 42);
insert into parent values ('BBB', 42);
insert into parent values ('CCC', 42);

-- delete from children sees respective child-format tuples
delete from child1;
delete from child2;
delete from child3;

-- copy into parent sees parent-format tuples
copy parent (a, b) from stdin;
AAA	42
BBB	42
CCC	42
\.

-- DML affecting parent sees tuples collected from children even if
-- there is no transition table trigger on the children
--DDL_STATEMENT_BEGIN--
drop trigger child1_insert_trig on child1;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop trigger child1_update_trig on child1;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop trigger child1_delete_trig on child1;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop trigger child2_insert_trig on child2;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop trigger child2_update_trig on child2;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop trigger child2_delete_trig on child2;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop trigger child3_insert_trig on child3;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop trigger child3_update_trig on child3;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop trigger child3_delete_trig on child3;
--DDL_STATEMENT_END--
delete from parent;

-- copy into parent sees tuples collected from children even if there
-- is no transition-table trigger on the children
copy parent (a, b) from stdin;
AAA	42
BBB	42
CCC	42
\.

-- insert into parent with a before trigger on a child tuple before
-- insertion, and we capture the newly modified row in parent format
--DDL_STATEMENT_BEGIN--
create or replace function intercept_insert() returns trigger language plpgsql as
$$
  begin
    new.b = new.b + 1000;
    return new;
  end;
$$;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger intercept_insert_child3
  before insert on child3
  for each row execute procedure intercept_insert();
--DDL_STATEMENT_END--


-- insert, parent trigger sees post-modification parent-format tuple
insert into parent values ('AAA', 42), ('BBB', 42), ('CCC', 66);

-- copy, parent trigger sees post-modification parent-format tuple
copy parent (a, b) from stdin;
AAA	42
BBB	42
CCC	234
\.

--DDL_STATEMENT_BEGIN--
drop table child1, child2, child3, parent;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop function intercept_insert();
--DDL_STATEMENT_END--

--
-- Verify prohibition of row triggers with transition triggers on
-- partitions
--
--DDL_STATEMENT_BEGIN--
create table parent (a text, b int) partition by list (a);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table child partition of parent for values in ('AAA');
--DDL_STATEMENT_END--

-- adding row trigger with transition table fails
--DDL_STATEMENT_BEGIN--
create trigger child_row_trig
  after insert on child referencing new table as new_table
  for each row execute procedure dump_insert();
--DDL_STATEMENT_END--

-- detaching it first works
--DDL_STATEMENT_BEGIN--
alter table parent detach partition child;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger child_row_trig
  after insert on child referencing new table as new_table
  for each row execute procedure dump_insert();
--DDL_STATEMENT_END--

-- but now we're not allowed to reattach it
--DDL_STATEMENT_BEGIN--
alter table parent attach partition child for values in ('AAA');
--DDL_STATEMENT_END--

-- drop the trigger, and now we're allowed to attach it again
--DDL_STATEMENT_BEGIN--
drop trigger child_row_trig on child;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table parent attach partition child for values in ('AAA');
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
drop table child, parent;
--DDL_STATEMENT_END--

--
-- Verify behavior of statement triggers on (non-partition)
-- inheritance hierarchy with transition tables; similar to the
-- partition case, except there is no rerouting on insertion and child
-- tables can have extra columns
--

-- set up inheritance hierarchy with different TupleDescriptors
--DDL_STATEMENT_BEGIN--
create table parent (a text, b int);
--DDL_STATEMENT_END--

-- a child matching parent
--DDL_STATEMENT_BEGIN--
create table child1 () inherits (parent);
--DDL_STATEMENT_END--

-- a child with a different column order
--DDL_STATEMENT_BEGIN--
create table child2 (b int, a text);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table child2 inherit parent;
--DDL_STATEMENT_END--

-- a child with an extra column
--DDL_STATEMENT_BEGIN--
create table child3 (c text) inherits (parent);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger parent_insert_trig
  after insert on parent referencing new table as new_table
  for each statement execute procedure dump_insert();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger parent_update_trig
  after update on parent referencing old table as old_table new table as new_table
  for each statement execute procedure dump_update();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger parent_delete_trig
  after delete on parent referencing old table as old_table
  for each statement execute procedure dump_delete();
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger child1_insert_trig
  after insert on child1 referencing new table as new_table
  for each statement execute procedure dump_insert();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger child1_update_trig
  after update on child1 referencing old table as old_table new table as new_table
  for each statement execute procedure dump_update();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger child1_delete_trig
  after delete on child1 referencing old table as old_table
  for each statement execute procedure dump_delete();
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger child2_insert_trig
  after insert on child2 referencing new table as new_table
  for each statement execute procedure dump_insert();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger child2_update_trig
  after update on child2 referencing old table as old_table new table as new_table
  for each statement execute procedure dump_update();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger child2_delete_trig
  after delete on child2 referencing old table as old_table
  for each statement execute procedure dump_delete();
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger child3_insert_trig
  after insert on child3 referencing new table as new_table
  for each statement execute procedure dump_insert();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger child3_update_trig
  after update on child3 referencing old table as old_table new table as new_table
  for each statement execute procedure dump_update();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger child3_delete_trig
  after delete on child3 referencing old table as old_table
  for each statement execute procedure dump_delete();
--DDL_STATEMENT_END--

-- insert directly into children sees respective child-format tuples
insert into child1 values ('AAA', 42);
insert into child2 values (42, 'BBB');
insert into child3 values ('CCC', 42, 'foo');

-- update via parent sees parent-format tuples
update parent set b = b + 1;

-- delete via parent sees parent-format tuples
delete from parent;

-- reinsert values into children for next test...
insert into child1 values ('AAA', 42);
insert into child2 values (42, 'BBB');
insert into child3 values ('CCC', 42, 'foo');

-- delete from children sees respective child-format tuples
delete from child1;
delete from child2;
delete from child3;

-- copy into parent sees parent-format tuples (no rerouting, so these
-- are really inserted into the parent)
copy parent (a, b) from stdin;
AAA	42
BBB	42
CCC	42
\.

-- same behavior for copy if there is an index (interesting because rows are
-- captured by a different code path in copy.c if there are indexes)
--DDL_STATEMENT_BEGIN--
create index on parent(b);
--DDL_STATEMENT_END--
copy parent (a, b) from stdin;
DDD	42
\.

-- DML affecting parent sees tuples collected from children even if
-- there is no transition table trigger on the children
--DDL_STATEMENT_BEGIN--
drop trigger child1_insert_trig on child1;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop trigger child1_update_trig on child1;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop trigger child1_delete_trig on child1;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop trigger child2_insert_trig on child2;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop trigger child2_update_trig on child2;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop trigger child2_delete_trig on child2;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop trigger child3_insert_trig on child3;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop trigger child3_update_trig on child3;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop trigger child3_delete_trig on child3;
--DDL_STATEMENT_END--
delete from parent;

--DDL_STATEMENT_BEGIN--
drop table child1, child2, child3, parent;
--DDL_STATEMENT_END--

--
-- Verify prohibition of row triggers with transition triggers on
-- inheritance children
--
--DDL_STATEMENT_BEGIN--
create table parent (a text, b int);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table child () inherits (parent);
--DDL_STATEMENT_END--

-- adding row trigger with transition table fails
--DDL_STATEMENT_BEGIN--
create trigger child_row_trig
  after insert on child referencing new table as new_table
  for each row execute procedure dump_insert();
--DDL_STATEMENT_END--

-- disinheriting it first works
--DDL_STATEMENT_BEGIN--
alter table child no inherit parent;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger child_row_trig
  after insert on child referencing new table as new_table
  for each row execute procedure dump_insert();
--DDL_STATEMENT_END--

-- but now we're not allowed to make it inherit anymore
--DDL_STATEMENT_BEGIN--
alter table child inherit parent;
--DDL_STATEMENT_END--

-- drop the trigger, and now we're allowed to make it inherit again
--DDL_STATEMENT_BEGIN--
drop trigger child_row_trig on child;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
alter table child inherit parent;
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
drop table child, parent;
--DDL_STATEMENT_END--

--
-- Verify behavior of queries with wCTEs, where multiple transition
-- tuplestores can be active at the same time because there are
-- multiple DML statements that might fire triggers with transition
-- tables
--
--DDL_STATEMENT_BEGIN--
create table table1 (a int);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table table2 (a text);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger table1_trig
  after insert on table1 referencing new table as new_table
  for each statement execute procedure dump_insert();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger table2_trig
  after insert on table2 referencing new table as new_table
  for each statement execute procedure dump_insert();
--DDL_STATEMENT_END--

with wcte as (insert into table1 values (42))
  insert into table2 values ('hello world');

with wcte as (insert into table1 values (43))
  insert into table1 values (44);

select * from table1;
select * from table2;

--DDL_STATEMENT_BEGIN--
drop table table1;
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop table table2;
--DDL_STATEMENT_END--

--
-- Verify behavior of INSERT ... ON CONFLICT DO UPDATE ... with
-- transition tables.
--

--DDL_STATEMENT_BEGIN--
create table my_table (a int primary key, b text);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger my_table_insert_trig
  after insert on my_table referencing new table as new_table
  for each statement execute procedure dump_insert();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger my_table_update_trig
  after update on my_table referencing old table as old_table new table as new_table
  for each statement execute procedure dump_update();
--DDL_STATEMENT_END--

-- inserts only
insert into my_table values (1, 'AAA'), (2, 'BBB')
  on conflict (a) do
  update set b = my_table.b || ':' || excluded.b;

-- mixture of inserts and updates
insert into my_table values (1, 'AAA'), (2, 'BBB'), (3, 'CCC'), (4, 'DDD')
  on conflict (a) do
  update set b = my_table.b || ':' || excluded.b;

-- updates only
insert into my_table values (3, 'CCC'), (4, 'DDD')
  on conflict (a) do
  update set b = my_table.b || ':' || excluded.b;

--
-- now using a partitioned table
--

--DDL_STATEMENT_BEGIN--
create table iocdu_tt_parted (a int primary key, b text) partition by list (a);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table iocdu_tt_parted1 partition of iocdu_tt_parted for values in (1);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table iocdu_tt_parted2 partition of iocdu_tt_parted for values in (2);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table iocdu_tt_parted3 partition of iocdu_tt_parted for values in (3);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table iocdu_tt_parted4 partition of iocdu_tt_parted for values in (4);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger iocdu_tt_parted_insert_trig
  after insert on iocdu_tt_parted referencing new table as new_table
  for each statement execute procedure dump_insert();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger iocdu_tt_parted_update_trig
  after update on iocdu_tt_parted referencing old table as old_table new table as new_table
  for each statement execute procedure dump_update();
--DDL_STATEMENT_END--

-- inserts only
insert into iocdu_tt_parted values (1, 'AAA'), (2, 'BBB')
  on conflict (a) do
  update set b = iocdu_tt_parted.b || ':' || excluded.b;

-- mixture of inserts and updates
insert into iocdu_tt_parted values (1, 'AAA'), (2, 'BBB'), (3, 'CCC'), (4, 'DDD')
  on conflict (a) do
  update set b = iocdu_tt_parted.b || ':' || excluded.b;

-- updates only
insert into iocdu_tt_parted values (3, 'CCC'), (4, 'DDD')
  on conflict (a) do
  update set b = iocdu_tt_parted.b || ':' || excluded.b;
  
--DDL_STATEMENT_BEGIN--
drop table iocdu_tt_parted;
--DDL_STATEMENT_END--

--
-- Verify that you can't create a trigger with transition tables for
-- more than one event.
--

--DDL_STATEMENT_BEGIN--
create trigger my_table_multievent_trig
  after insert or update on my_table referencing new table as new_table
  for each statement execute procedure dump_insert();
--DDL_STATEMENT_END--

--
-- Verify that you can't create a trigger with transition tables with
-- a column list.
--

--DDL_STATEMENT_BEGIN--
create trigger my_table_col_update_trig
  after update of b on my_table referencing new table as new_table
  for each statement execute procedure dump_insert();
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
drop table my_table;
--DDL_STATEMENT_END--

--
-- Test firing of triggers with transition tables by foreign key cascades
--

--DDL_STATEMENT_BEGIN--
create table refd_table (a int primary key, b text);
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create table trig_table (a int, b text,
  foreign key (a) references refd_table on update cascade on delete cascade
);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger trig_table_before_trig
  before insert or update or delete on trig_table
  for each statement execute procedure trigger_func('trig_table');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_table_insert_trig
  after insert on trig_table referencing new table as new_table
  for each statement execute procedure dump_insert();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_table_update_trig
  after update on trig_table referencing old table as old_table new table as new_table
  for each statement execute procedure dump_update();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger trig_table_delete_trig
  after delete on trig_table referencing old table as old_table
  for each statement execute procedure dump_delete();
--DDL_STATEMENT_END--

insert into refd_table values
  (1, 'one'),
  (2, 'two'),
  (3, 'three');
insert into trig_table values
  (1, 'one a'),
  (1, 'one b'),
  (2, 'two a'),
  (2, 'two b'),
  (3, 'three a'),
  (3, 'three b');

update refd_table set a = 11 where b = 'one';

select * from trig_table;

delete from refd_table where length(b) = 3;

select * from trig_table;
--DDL_STATEMENT_BEGIN--
drop table refd_table, trig_table;
--DDL_STATEMENT_END--

--
-- self-referential FKs are even more fun
--

--DDL_STATEMENT_BEGIN--
create table self_ref (a int primary key,
                       b int references self_ref(a) on delete cascade);
--DDL_STATEMENT_END--

--DDL_STATEMENT_BEGIN--
create trigger self_ref_before_trig
  before delete on self_ref
  for each statement execute procedure trigger_func('self_ref');
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger self_ref_r_trig
  after delete on self_ref referencing old table as old_table
  for each row execute procedure dump_delete();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
create trigger self_ref_s_trig
  after delete on self_ref referencing old table as old_table
  for each statement execute procedure dump_delete();
--DDL_STATEMENT_END--

insert into self_ref values (1, null), (2, 1), (3, 2);

delete from self_ref where a = 1;

-- without AR trigger, cascaded deletes all end up in one transition table
--DDL_STATEMENT_BEGIN--
drop trigger self_ref_r_trig on self_ref;
--DDL_STATEMENT_END--

insert into self_ref values (1, null), (2, 1), (3, 2), (4, 3);

delete from self_ref where a = 1;

--DDL_STATEMENT_BEGIN--
drop table self_ref;
--DDL_STATEMENT_END--

-- cleanup
--DDL_STATEMENT_BEGIN--
drop function dump_insert();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop function dump_update();
--DDL_STATEMENT_END--
--DDL_STATEMENT_BEGIN--
drop function dump_delete();
--DDL_STATEMENT_END--