parser start {
    return parse_ethernet;
}

#define ETHER_TYPE_IPV4 0x0800
parser parse_ethernet {
    extract (ethernet);
    return select (latest.etherType) {
        ETHER_TYPE_IPV4: parse_ipv4;
        default: ingress;
    }
}

#define IPV4_PROTOCOL_TCP 6
#define IPV4_PROTOCOL_UDP 17
parser parse_ipv4 {
    extract(ipv4);
    return select (latest.protocol) {
        IPV4_PROTOCOL_TCP: parse_tcp;
        IPV4_PROTOCOL_UDP: parse_udp;
        default: ingress;
    }
}

parser parse_tcp {
    extract (tcp);
    return ingress;
}

parser parse_udp {
    extract (udp);
    return select (latest.dstPort) {
        NC_PORT: parse_nc_hdr;
        default: ingress;
    }
}
/*
    Netcache specific parser
*/
parser parse_nc_hdr {
    extract (nc_hdr);
    return select(latest.operation) {
        READ_REQUEST: ingress;
        READ_REPLY: parse_value;
        HOT_READ_REQUEST: parse_nc_load;
        UPDATE_REQUEST: ingress;
        UPDATE_REPLY: parse_value;
        default: ingress;
    }
}

parser parse_nc_load {
    extract (nc_load);
    return ingress;
}

parser parse_value {
    return parse_nc_value_1;
}

