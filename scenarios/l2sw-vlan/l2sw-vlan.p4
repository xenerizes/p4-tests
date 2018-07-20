#include <ethernet.p4>
#include <dot1q.p4>
#include <typedefs.p4>
#include <v1model.p4>

#define MAC_LEARN_RCVR 1
#define BROADCAST_GRP 1

#define DOT1Q_ETHTYPE 0x8100
#define DOT1Q_ETHTYPE_QINQ 0x88A8
#define DOT1Q_NONE_VID 12w0


struct headers_t {
    ethernet_t ethernet;
    dot1q_t dot1q;
}

struct learn_digest_t {
    port_t port;
    ethaddr_t src_mac;
    vid_t vlan_id;
}

struct metadata {
    // This field, in fact, has an effect only when the packet comes from
    // access port (untagged). Unfortunately, v1model and switch emulator
    // do not allow to remove the tag from one packet, but keep on another.
    // See more in Deparser
    bool is_tagged;
}

parser ParserImpl (
    packet_in buffer,
    out headers_t parsed_hdr,
    inout metadata meta,
    inout standard_metadata_t ostd
    )
{
    state start {
        meta.is_tagged = true;
        transition parse_eth;
    }

    state parse_eth {
        buffer.extract(parsed_hdr.ethernet);
        transition select(parsed_hdr.ethernet.etherType) {
            DOT1Q_ETHTYPE: parse_dot1q;
            DOT1Q_ETHTYPE_QINQ: parse_dot1q;
            default: not_tagged;
        }
    }

    state not_tagged {
        meta.is_tagged = false;
        transition accept;
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
    /* Table access: set VLAN for access port */

    action set_vlan(vid_t vlan_id) {
        hdr.dot1q.etherType = hdr.ethernet.etherType;
        hdr.ethernet.etherType = DOT1Q_ETHTYPE;
        hdr.dot1q.vid = vlan_id;
    }

    table access {
        key = { ostd.ingress_port: exact; }
        actions = { set_vlan; }
        // Because of switch emulator restrictions we have to set NONE tag
        // to all untagged packets here; see explanations in Deparser
        default_action = set_vlan(DOT1Q_NONE_VID);
    }

    /* Table source MAC */

    action learn() {
        learn_digest_t msg;
        msg.src_mac = hdr.ethernet.srcAddr;
        msg.port = ostd.ingress_port;
        msg.vlan_id = hdr.dot1q.vid;
        digest(MAC_LEARN_RCVR, msg);
    }

    table src_mac {
        key = {
            hdr.ethernet.srcAddr: exact;
            hdr.dot1q.vid: exact;
        }
        actions = { learn; }
        default_action = learn;
        support_timeout = true;
    }

    /* Table destination MAC */

    // Broadcast sends packet to all ports (iff multicast group with id 1 which
    // contains all the ports was created on switch). Grouping by vlan can be
    // implemented only via multicast groups too, which is not the desired
    // behavior. In any case we can't exclude packet source port from the
    // multicast group without explicit creation of `broadcast` multicast group
    // for each (port, vlan) pair via switch CLI or P4Runtime (controller), i.e.
    // there is no built-in port grouping mechanism in P4 language.
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
        key = {
            hdr.ethernet.dstAddr: exact;
            // Ternary for multicast, where vlan should have no effect
            hdr.dot1q.vid: ternary;
        }
        actions = { broadcast; forward; multicast; }
        default_action = broadcast;
        support_timeout = true;
    }

    apply {
        ostd.drop = 0;
        if (!meta.is_tagged) {
            access.apply();
        }
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
    /* Table change vlan */

    action set_vlan(vid_t vlan_id) {
        // Simple switch throws on boolean assignment with complex conditions
        // if (hdr.dot1q.vid != vlan_id) {
            hdr.dot1q.vid = vlan_id;
            meta.is_tagged = true;
        // }
    }

    // This has no effect
    action remove_vlan() {
        meta.is_tagged = false;
    }

    table change_vlan {
        key = { ostd.egress_spec: exact; }
        actions = { set_vlan; remove_vlan; NoAction; }
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
        // No meta field in deparser in v1model. Conditional statements
        // are not supported in deparser of switch emulator
        // if (meta.is_tagged) {
            // Consequently, we can handle all packets, but output packets
            // should be all tagged or all untagged. The best solution I found
            // is to add fixed DOT1Q_NONE_VID tag to all untagged packets.
            buffer.emit(hdr.dot1q);
        // }
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
