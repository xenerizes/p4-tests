#include <ethernet.p4>
#include <dot1q.p4>
#include <typedefs.p4>
#include <v1model.p4>

#define MAC_LEARN_RCVR 1
#define BROADCAST_GRP 1


struct headers_t {
    ethernet_t ethernet;
    dot1q_t dot1q;
}

struct learn_digest_t {
    port_t port;
    ethaddr_t src_mac;
}

struct metadata { }

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
        transition select(parsed_hdr.ethernet.etherType) {
            0x8100: parse_dot1q;
            default: accept;
        }
    }

    state parse_dot1q {
        buffer.extract(parsed_hdr.dot1q);
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
    /* Table set VLAN */

    action access(vid_t vlan_id) {
        hdr.dot1q.vid = vlan_id;
    }

    table set_vlan {
        key = {
            ostd.ingress_port: exact;
            hdr.dot1q.vid: exact;
        }
        actions = { access; NoAction; }
        default_action = NoAction;
    }

    /* Table source MAC */

    action learn() {
        learn_digest_t msg;
        msg.src_mac = hdr.ethernet.srcAddr;
        msg.port = ostd.ingress_port;
        digest(MAC_LEARN_RCVR, msg);
    }

    table src_mac {
        key = { hdr.ethernet.srcAddr: exact; }
        actions = { learn; nop; }
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
        support_timeout = true;
    }

    apply {
        ostd.drop = 0;
        set_vlan.apply();
        src_mac.apply();
        dst_mac.apply();
        clone(CloneType.I2E, 32w0);
    }
}

control EgressImpl (
    inout headers_t hdr,
    inout metadata meta,
    inout standard_metadata_t ostd
    )
{
    /* Table change vlan */

    action set_vlan(vid_t vlan_id) {
        hdr.dot1q.vid = vlan_id;
    }

    table change_vlan {
        key = { ostd.egress_spec: exact; }
        actions = { set_vlan; NoAction; }
        default_action = NoAction;
    }

    apply {
        change_vlan.apply();
    }
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
        buffer.emit(hdr.dot1q);
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
