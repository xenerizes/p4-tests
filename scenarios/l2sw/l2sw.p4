#include <ethernet.p4>
#include <typedefs.p4>
#include <v1model.p4>

#define TABLE_CAPACITY 1024

struct headers {
    ethernet_t ethernet;
}

struct learn_digest_t {
    port_t port;
    ethaddr_t src_mac;
}

struct metadata { }

parser ParserImpl (
    packet_in buffer,
    out headers parsed_hdr,
    inout metadata meta,
    inout standard_metadata_t ostd
    )
{
    state start {
        transition parse_eth;
    }

    state parse_eth {
        buffer.extract(parsed_hdr.ethernet);
        transition accept;
    }
}

control VerifyChecksumImpl (
    inout headers hdr,
    inout metadata meta
    )
{
    apply { }
}

control IngressImpl (
    inout headers hdr,
    inout metadata meta,
    inout standard_metadata_t ostd
    )
{
    action learn() {
        mark_to_drop();
        learn_digest_t msg;
        msg.src_mac = hdr.ethernet.srcAddr;
        msg.port = ostd.ingress_port;
        digest(1, msg);
    }

    action update() {
        // TODO
    }

    action broadcast(port_t port_id) {
        ostd.drop = 0;
        // TODO
    }

    action multicast(mcast_group_t group_id) {
        ostd.drop = 0;
        // TODO clone(I2E, )
    }

    action unicast(port_t port_id) {
        ostd.drop = 0;
        ostd.egress_spec = port_id;
    }

    table src_mac {
        key = { hdr.ethernet.srcAddr: exact; }
        actions = { learn; update; }
        default_action = learn;
        size = TABLE_CAPACITY;
    }

    table dst_mac {
        key = { hdr.ethernet.dstAddr: exact; }
        actions = { broadcast; multicast; unicast; }
        default_action = broadcast;
        size = TABLE_CAPACITY;
    }

    apply {
        if (hdr.ethernet.isValid()) {
            src_mac.apply();
            dst_mac.apply();
        }
    }
}

control EgressImpl (
    inout headers hdr,
    inout metadata meta,
    inout standard_metadata_t ostd
    )
{
    apply { }
}

control ComputeChecksumImpl (
    inout headers hdr,
    inout metadata meta)
{
    apply { }
}

control DeparserImpl (
    packet_out buffer,
    in headers hdr)
{
    apply {
        buffer.emit(hdr.ethernet);
    }
}

V1Switch(
    ParserImpl(),
    VerifyChecksumImpl(),
    IngressImpl(),
    EgressImpl(),
    ComputeChecksumImpl(),
    DeparserImpl()
) main;
