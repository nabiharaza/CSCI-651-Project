#include "includes/headers.p4"
#include "includes/parsers.p4"
#include "includes/checksum.p4"

#include "cache.p4"
#include "heavy_hitter.p4"
#include "value.p4"
#include "ipv4.p4"
#include "ethernet.p4"

#define NC_PORT 8888
#define NUM_CACHE 128
#define NC_READ_REQUEST     0
#define NC_READ_REPLY       1
#define NC_HOT_READ_REQUEST 2
#define NC_WRITE_REQUEST    4
#define NC_WRITE_REPLY      5
#define NC_UPDATE_REQUEST   8
#define NC_UPDATE_REPLY     9

control ingress {
    process_cache();
    process_value();
    
    apply (ipv4_route);
}

//
header_type nc_cache_md_t {
    fields {
        cache_exist: 1;
        cache_index: 14;
        cache_valid: 1;
    }
}
metadata nc_cache_md_t nc_cache_md;
//
control process_cache {
    apply (check_cache_exist);
    if (nc_cache_md.cache_exist == 1) {
        if (nc_hdr.op == NC_READ_REQUEST) {
            apply (check_cache_valid);
        }
        else if (nc_hdr.op == NC_UPDATE_REPLY) {
            apply (set_cache_valid);
        }
    }
}

//
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
//
register cache_valid_reg {
    width: 1;
    instance_count: NUM_CACHE;
}

//
action check_cache_valid_act() {
    register_read(nc_cache_md.cache_valid, cache_valid_reg, nc_cache_md.cache_index);
}
table check_cache_valid {
    actions {
        check_cache_valid_act;
    }
    //default_action: check_cache_valid_act;
}
//
action set_cache_valid_act() {
    register_write(cache_valid_reg, nc_cache_md.cache_index, 1);
}
table set_cache_valid {
    actions {
        set_cache_valid_act;
    }
    //default_action: set_cache_valid_act;
}








control egress {
    //if (nc_hdr.op == NC_READ_REQUEST and nc_cache_md.cache_exist != 1) {
    //    heavy_hitter();
    //}
    apply (ethernet_set_mac);
}
