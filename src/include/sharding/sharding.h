/*-------------------------------------------------------------------------
 *
 * sharding.h
 *	  definitions of types, and declarations of functions, that are used in
 *	  table sharding functionality.
 *
 *
 * Copyright (c) 2019-2021 ZettaDB inc. All rights reserved.
 *
 * This source code is licensed under Apache 2.0 License,
 * combined with Common Clause Condition 1.0, as detailed in the NOTICE file.
 *
 * src/include/sharding/sharding.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef SHARDING_H
#define SHARDING_H

#include "catalog/pg_shard_node.h"
#include "catalog/pg_shard.h"
#include "utils/hsearch.h"
#include "utils/rel.h" // Relation


#define MAX_NODES_PER_SHARD 7

typedef uint32 Shard_node_id_t;
extern Shard_node_id_t Invalid_shard_node_id;
extern Shard_node_id_t First_shard_node_id;

typedef enum Storage_HA_Mode {
	HA_INVALID = -1,
	HA_NO_REP = 0,
	HA_MGR,
	HA_RBR
} Storage_HA_Mode;

/*
  All storage shards of a kunlun cluster share the same HA mode and
  they never change it after the cluster is created.
*/
extern Storage_HA_Mode storage_ha_mode(void);
extern Storage_HA_Mode metaserver_ha_mode(void);

/*
 * A shard has one master node and multiple slaves nodes. they contain
 * identical data, and each shard node is stored as a mysql db instance
 * on a computer server.
 * A slave node replicates binlogs from master node to keep data in sync.
 * A computing node mostly sent queries to master node to execute, but it
 * can also send read only queries to slave nodes to execute.
 * */
typedef struct Shard_node_t
{
  NameData user_name;

  uint32 shard_id; /* The owner shard, references pg_shard(id). BKI can't specify
				   foreign key though. */
  uint32 svr_node_id;
  uint16_t port;
  /*
   * When dispatching read only select stmts to a slave, choose the one with
   * max ro_weight of a shard.
   */
  int16_t ro_weight;
  Shard_node_id_t id;
  char *hostaddr;
  char *passwd;
} Shard_node_t;

// A cluster can have at most 2^16 shards, i.e. a table can be split to
// at most 2^16 tablets.
typedef uint16_t Nshards_t;

typedef uint32 Shard_id_t;
extern Shard_id_t Invalid_shard_id;
extern Shard_id_t First_shard_id;


/*
 * If one modifies this number, do modify ERRORDATA_STACK_SIZE to the
 * same value.
 * */
#define MAX_SHARDS 256

typedef struct ShardNodeConnId {
	Oid shardid, nodeid; // shardid=0 means metadata cluster.
	uint32_t connid;
} ShardNodeConnId;

typedef struct ShardConnKillReq {
	char type; // 1: conn; 2: query
#define METASHARD_REQ 0x1
#define STORAGE_SHARD_REQ 0x2
	char flags;
	uint16_t num_ents;
	// next request offset in request queue;
	// total request size in bytes for appended single request.
	uint32_t next_req_off;
	ShardNodeConnId entries[1];
} ShardConnKillReq;


/*
 * Find from hash table the cached shard, if not found, scan tables to load it,
 * and setup reference to its Shard_node_t objects.
 * */
extern bool ShardExists(Oid shardid);

/*
 * Find cached Shard_node_t objects. If not cached, scan table to cache it and
 * setup its owner's reference to it if the owner is also cached.
 * */
extern bool FindCachedShardNode(Oid shardid, Oid nodeid, Shard_node_t* out);

extern Oid FindBestShardForTable(int policy, Relation rel);
extern Oid GetShardMasterNodeId(Oid shardid);

extern Size ShardingTopoCheckSize(void);
extern void ShardingTopoCheckShmemInit(void);
extern bool RequestShardingTopoCheck(Oid shardid);
extern void ProcessShardingTopoReqs(void);

extern void ShardConnKillReqQShmemInit(void);
extern Size ShardConnKillReqQSize(void);
extern void reapShardConnKillReqs(void);
extern Size ShardConnKillReqSize(int nodes);
extern void appendShardConnKillReq(ShardConnKillReq*req);

extern ShardConnKillReq *makeMetaConnKillReq(char type, uint32_t connid);
extern ShardConnKillReq *makeShardConnKillReq(char type);
extern void inform_cluster_log_applier_main(void);

extern List *GetAllShardIds(void);

/* Get the pid of the topo service */
extern pid_t get_topo_service_pid(void);

/**
 * The main loop of the topology service, responsible for updating the
 * cluster topology, and handling requests to kill shard connection
 */
extern void TopoServiceMain(void);
#endif /* !SHARDING_H */
