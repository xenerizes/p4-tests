#include <ethernet.p4>
#include <typedefs.p4>
#include <v1model.p4>

#define TABLE_CAPACITY 1024
#define MAC_LEARN_RCVR 1
#define BROADCAST_GRP 1

#define BROADCAST_MAC 0xffffffffffff
#define MAX_FRAME_SIZE 16018


struct headers_t {
    ethernet_t ethernet;
}

struct learn_digest_t {
    port_t port;
    ethaddr_t src_mac;
}

struct metadata { }

error {
    BroadcastSrc,
    PacketTooLong
}

parser ParserImpl (
    packet_in buffer,
    out headers_t parsed_hdr,
    inout metadata meta,
    inout standard_metadata_t ostd
    )
{
    state start {
        // Reject too long frames. Compiler does not support that for v1model
        // bit<32> frame_len = buffer.length();
        // verify(frame_len > MAX_FRAME_SIZE, error.PacketTooLong);
        transition parse_eth;
    }

    state parse_eth {
        buffer.extract(parsed_hdr.ethernet);
        // Reject frames with broadcast src MAC. Switch emulator throws and terminates 
        // verify(parsed_hdr.ethernet.srcAddr == BROADCAST_MAC, error.BroadcastSrc);
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
        // already implemented by target
    }

    table src_mac {
        key = { hdr.ethernet.srcAddr: exact; }
        actions = { learn; update; }
        default_action = learn;
        support_timeout = true;
    }

    /* Table destination MAC */

    action broadcast() {
        ostd.mcast_grp = BROADCAST_GRP;
    }

    action multicast(mcast_group_t mcast_grp) {
        ostd.mcast_grp = mcast_grp;
    }

    action forward(port_t port) {
        ostd.egress_spec = port;
    }

    table dst_mac {
        key = { hdr.ethernet.dstAddr: exact; }
        actions = { broadcast; forward; multicast; }
        default_action = broadcast;

        size = TABLE_CAPACITY;
        support_timeout = true;
    }

    apply {
        ostd.drop = 0;
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
