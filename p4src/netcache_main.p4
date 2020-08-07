#include "includes/headers.p4"
#include "includes/parsers.p4"
#include "includes/checksum.p4"

#include "cache.p4"
#include "value.p4"
#include "ipv4.p4"
#include "ethernet.p4"

// Define the constants using here
#define NC_PORT 8888
#define NUM_CACHE 128
#define READ_REQUEST     0
#define READ_REPLY       1
#define HOT_READ_REQUEST 2
#define WRITE_REQUEST    4
#define WRITE_REPLY      5
#define UPDATE_REQUEST   8
#define UPDATE_REPLY     9

// Packet enters the switch
control ingress {
   process_cache();
   process_value();

   // Apply routing logic here
   apply (ipv4_route);
}

// Define the header fields we are using
header_type nc_cache_md_t {
    fields {
        cache_exist: 1;
        cache_index: 14;
        cache_valid: 1;
    }
}
metadata nc_cache_md_t nc_cache_md;

// Check if Cache exists on the switch
control process_cache {
    apply (check_cache_exist);
    if (nc_cache_md.cache_exist == 1) {
        if (nc_hdr.operation == READ_REQUEST) {
            apply (check_cache_valid);
        }
        else if (nc_hdr.operation == UPDATE_REPLY) {
            apply (set_cache_valid);
        }
    }
}

// Match action table for cache exists
action check_cache_exist_act(index) {
    modify_field (nc_cache_md.cache_exist, 1);
    modify_field (nc_cache_md.cache_index, index);
}
table check_cache_exist {
    reads {
        nc_hdr.key: exact;
    }
    actions {
        check_cache_exist_act;
    }
    size: NUM_CACHE;
}

// Register variable for a valid cache
register cache_valid_reg {
    width: 1;
    instance_count: NUM_CACHE;
}

// Match action table for a valid cache
action check_cache_valid_act() {
    register_read(nc_cache_md.cache_valid, cache_valid_reg, nc_cache_md.cache_index);
}
table check_cache_valid {
    actions {
        check_cache_valid_act;
    }
}

// Match action table to update the cache as valid
action set_cache_valid_act() {
    register_write(cache_valid_reg, nc_cache_md.cache_index, 1);
}
table set_cache_valid {
    actions {
        set_cache_valid_act;
    }
}

// Finally, Egress the data packet
control egress {
    apply (ethernet_set_mac);
}
