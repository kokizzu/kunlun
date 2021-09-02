/*-------------------------------------------------------------------------
 *
 * format_type_remote.c
 *	  Map to remote DBMS types.
 *
 *
 * Copyright (c) 2019-2021 ZettaDB inc. All rights reserved.
 *
 * This source code is licensed under Apache 2.0 License,
 * combined with Common Clause Condition 1.0, as detailed in the NOTICE file.
 *
 * IDENTIFICATION
 *	  src/backend/utils/adt/format_type_remote.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include <ctype.h>

#include "catalog/namespace.h"
#include "catalog/pg_enum.h"
#include "catalog/pg_type.h"
#include "utils/builtins.h"
#include "utils/lsyscache.h"
#include "utils/numeric.h"
#include "utils/syscache.h"
#include <stdlib.h>
#include "access/remote_meta.h" // find_root_base_type

/*
 * DZW: format type for backend mysql storage node.
 * */
struct Type_id_name
{
  unsigned int id;
  bool output_const_needs_quote;
  const char *name;
};

static int typeid_name_cmp(const void*t1, const void*t2)
{
	struct Type_id_name *p1 = (struct Type_id_name *)t1;
	struct Type_id_name *p2 = (struct Type_id_name *)t2;
	return p1->id - p2->id;
}

/*
  mysql requires text/blob key fields to have length suffix, and we
  map several pg types to such mysql types.
*/
bool needs_mysql_keypart_len(Oid typid, int typmod)
{
	static Oid txt_types [] = {
		TEXTOID,
		BYTEAOID,
		XMLOID
	};

	bool ret = false;
	for (int i = 0; i < sizeof(txt_types)/sizeof(Oid); i++)
		if (typid == txt_types[i] || (VARCHAROID == typid && typmod == -1))
			return true;
	/*
	static bool txt_types_sorted = false;
	const static size_t num = sizeof(txt_types) / sizeof(Oid);
	if (!txt_types_sorted)
	{
		qsort(txt_types, num, sizeof(Oid), oid_cmp);
		txt_types_sorted = true;
	}
	Oid*res = bsearch(&typid, txt_types, num, sizeof(Oid), oid_cmp);
	if (res)
	{
		int idx = res - txt_types;
		if (!(idx < 0 || idx >= num))
			ret = true;
	}*/

	return ret;
}

/*
 * All other pg types are not supported for now.
 * Specifically, mysql doens't support array, vector or range types.
 *
 * The set of type OIDs here must be equal to the type OID set in find_type_slot.
 * */
static struct Type_id_name typid_names[] = 
{
	/* basic types */
	{BOOLOID, false, "bool"},
	{CHAROID, true, "char"},
	{INT8OID, false, "bigint"},
	{INT2OID, false, "smallint"},
	{INT4OID, false, "int"},
	{TEXTOID, true, "longtext"},
	{FLOAT4OID, false, "float"},
	{FLOAT8OID, false, "double"},
	{BPCHAROID, true, "char"},  // Blank Padded char
	{VARCHAROID, true, "varchar"},
	{BITOID, true, "bit"},  // b'01011010'
	{VARBITOID, true, "bit"},
	{NUMERICOID, false, "numeric"},
	{CASHOID, false, "numeric"}, // provide modifier to make it decimal(65,8).
	{BYTEAOID, true, "longblob"}, // exchange with storage node in hex string.TODO

	{NAMEOID, true, "varchar(64)"},
	{OIDOID, false, "int unsigned"},
	{CSTRINGOID, true, "varchar"},
	{JSONOID, true, "json"},
	{JSONBOID, true, "json"},
	{XMLOID, true, "longtext"},

	/*
	 * PG's internal system types, easy to translate anyway.
	 * */
	{CIDOID, false, "smallint unsigned"}, // CommandId
	{TIDOID, false, "bigint unsigned"}, // ItemPointerData
	{XIDOID, false, "int unsigned"}, // xmin, xmax. TransactionId
	{LSNOID, false, "bigint unsigned"},

	{MACADDROID, true, "char(18) character set latin1"},
	{INETOID, true, "varchar(255) character set latin1"},
	{CIDROID, true, "varchar(255) character set latin1"},
	{MACADDR8OID, true, "char(24) character set latin1"},
	{UUIDOID, true, "char(40) character set latin1"},

	/*
	 * date time types
	{TINTERVALOID, ""},
	{INTERVALOID, ""}, */
	{DATEOID, true, "date"},
	{TIMEOID, true, "time"},
	{TIMESTAMPOID, true, "datetime"},
	{TIMESTAMPTZOID, true, "datetime"},
	{TIMETZOID, true, "time"},
};

inline static int find_type_slot(Oid typid)
{
	/*
	 * This array must contain identical set of type ids as in struct typid_names.
	 * */
	static Oid supported_typeids[] = {
		BOOLOID,
		CHAROID,
		INT8OID,
		INT2OID,
		INT4OID,
		TEXTOID,
		FLOAT4OID,
		FLOAT8OID,
		BPCHAROID,
		VARCHAROID,
		BITOID,
		VARBITOID,
		NUMERICOID,
		CASHOID,
		BYTEAOID,
		NAMEOID,
		OIDOID,
		CSTRINGOID,
		JSONOID,
		JSONBOID,
		XMLOID,
		MACADDROID,
		INETOID,
		CIDROID,
		MACADDR8OID,
		UUIDOID,
		DATEOID,
		TIMEOID,
		TIMESTAMPOID,
		TIMESTAMPTZOID,
		TIMETZOID,
		CIDOID,
		TIDOID,
		XIDOID,
		LSNOID
	};
	static bool has_sorted = false;
	const static size_t num = sizeof(supported_typeids) / sizeof(Oid);
	if (!has_sorted)
	{
		has_sorted = true;
		qsort(supported_typeids, num, sizeof(Oid), oid_cmp);
	}

	Oid*res = bsearch(&typid, supported_typeids, num, sizeof(Oid), oid_cmp);
	if (res)
	{
		int ret = res - supported_typeids;
		if (ret < 0 || ret >= num)
			ret = -1;
		return ret;
	}
	else
		return -1;
}

bool type_is_enum_lite(Oid typid)
{
	int idx = find_type_slot(typid);
	if (idx > -1)
		return false;
	return (type_is_enum(typid));
}


void InitRemoteTypeInfo()
{
	const size_t num = sizeof(typid_names) / sizeof(typid_names[0]);
	struct Type_id_name *parr = (struct Type_id_name *)typid_names;
	qsort(parr, num, sizeof(struct Type_id_name), typeid_name_cmp);
}

const char *format_type_remote(Oid type_oid)
{
	int idx = find_type_slot(type_oid);
	if (idx < 0)
	{
		if (type_is_enum(type_oid))
		{
			return get_enum_type_mysql(type_oid);
		}

		/*
		  See if it's a domain type, if so use its basic type, which
		  may(system intrinsic) or may not (user defined) be recognized.
		*/
		if ((type_oid = find_root_base_type(type_oid)) == InvalidOid)
			return NULL;
		if ((idx = find_type_slot(type_oid)) < 0)
			return NULL;
	}
	return typid_names[idx].name;
}

/* 
 * Whether a const value of type 'type_oid' needs to be quoted by single quote(').
 * @retval 1: needs quote; 0: don't need quote; -1:unknown type, not decided.
 * */
int const_output_needs_quote(Oid type_oid)
{
	int idx = find_type_slot(type_oid);
	if (idx < 0)
	{
		if (type_is_enum(type_oid))
		{
			return 1; // enum string labels need quotes.
		}
		return -1;
	}
	return typid_names[idx].output_const_needs_quote ? 1 : 0;
}

bool is_string_type(Oid typid)
{
	char cat;
	bool p;

	get_type_category_preferred(typid, &cat, &p);
	return (cat == TYPCATEGORY_STRING);
}

typedef struct mysql_cast {
	Oid from_typid;
	const char *to_mysql_cast_type;
} mysql_cast;

inline static int mysql_cast_cmp(const void *v1, const void *v2)
{
	mysql_cast *vv1 = (mysql_cast *)v1;
	mysql_cast *vv2 = (mysql_cast *)v2;
	return vv1->from_typid > vv2->from_typid ? 1 :
		(vv1->from_typid < vv2->from_typid ? -1 : 0);
}

const char* mysql_can_cast(Oid typid)
{
	static mysql_cast mysql_castable_types[] = {
		{ CHAROID, "CHAR" },
		{ INT8OID, "SIGNED" },
		{ INT2OID, "SIGNED" },
		{ INT4OID, "SIGNED" },
		{ FLOAT4OID, "FLOAT" },
		{ FLOAT8OID, "REAL" },
		{ BPCHAROID, "CHAR" },
		{ VARCHAROID, "CHAR" },
		{ NUMERICOID, "DECIMAL" },// add (65,20) if typmod not specified. },
		{ CASHOID, "DECIMAL(65,8)" },
		{ NAMEOID, "CHAR(64)" },
		{ OIDOID, "UNSIGNED" },
		{ CSTRINGOID, "CHAR" },
		{ DATEOID,	"DATE" },
		{ TIMEOID,	"TIME" },
		{ TIMESTAMPOID, "DATETIME" },
		{ TIMESTAMPTZOID, "DATETIME" },
		{ TIMETZOID, "TIME" }
	};
	static bool has_sorted = false;
	const static size_t num = sizeof(mysql_castable_types) / sizeof(mysql_cast);
	if (!has_sorted)
	{
		has_sorted = true;
		qsort(mysql_castable_types, num, sizeof(mysql_cast), mysql_cast_cmp);
	}
	mysql_cast cast;
	cast.from_typid = typid;
	mysql_cast *res = (mysql_cast *)bsearch(&cast, mysql_castable_types, num,
		sizeof(mysql_cast), mysql_cast_cmp);
	if (res)
	{
		return res->to_mysql_cast_type;
	}
	else
		return NULL;
}

