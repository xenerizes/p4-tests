#include <ethernet.p4>
#include <typedefs.p4>
#include <v1model.p4>

#define TABLE_CAPACITY 1024
#define MAC_LEARN_RCVR 1

/* Packet type identifiers */
#define UNICAST_ID = 0
#define BROADCAST_ID = 1
#define MULTICAST_ID = 2

/* Selector parameters */
#define SELECTOR_SIZE 32w1024
#define SELECTOR_OUT_SIZE 32w10
#define HASH_BASE 16w0
#define HASH_MAX 32w65536


struct headers_t {
    ethernet_t ethernet;
}

struct learn_digest_t {
    port_t port;
    ethaddr_t src_mac;
}

struct metadata {
    bit<16> group_key;
}

parser ParserImpl (
    packet_in buffer,
    out headers_t parsed_hdr,
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
    inout headers_t hdr,
    inout metadata meta
    )
{
    apply { }
}

control IngressImpl (
    inout headers_t hdr,
    inout metadata meta,
    inout standard_metadata_t ostd
    )
{
    /* Table source MAC */

    action learn() {
        learn_digest_t msg;
        msg.src_mac = hdr.ethernet.srcAddr;
        msg.port = ostd.ingress_port;
        digest(MAC_LEARN_RCVR, msg);
    }

    action update() {
        // TODO: not sure how timeouts are implemented
    }

    @name("src_mac") table src_mac {
        key = { hdr.ethernet.srcAddr: exact; }
        actions = { learn; update; }
        default_action = learn;
        support_timeout = true;

        const entries = {
            (0xffffffffffff): update();
        }
    }

    /* Table destination MAC */

    // TODO: exclude ingress_port
    @name("broadcast") action broadcast() {
        ostd.drop = 0;
        ostd.mcast_grp = 0;
    }

    @name("forward") action forward(port_t port) {
        ostd.drop = 0;
        ostd.egress_spec = port;
    }

    @name("dst_mac") table dst_mac {
        key = {
            hdr.ethernet.dstAddr: exact;
            meta.group_key: selector;
        }
        actions = { broadcast; forward; }
        default_action = broadcast;

        size = TABLE_CAPACITY;
        support_timeout = true;

        @name("selector") implementation = action_selector(
            HashAlgorithm.identity,
            SELECTOR_SIZE,
            SELECTOR_OUT_SIZE
        );
    }

    apply {
        hash(
            meta.group_key,
            HashAlgorithm.crc16,
            HASH_BASE, {
                hdr.ethernet.srcAddr,
                hdr.ethernet.dstAddr
            },
            HASH_MAX);

        src_mac.apply();
        dst_mac.apply();
    }
}

control EgressImpl (
    inout headers_t hdr,
    inout metadata meta,
    inout standard_metadata_t ostd
    )
{
    apply { }
}

control ComputeChecksumImpl (
    inout headers_t hdr,
    inout metadata meta)
{
    apply { }
}

control DeparserImpl (
    packet_out buffer,
    in headers_t hdr)
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
