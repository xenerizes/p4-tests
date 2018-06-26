typedef bit<48> ethaddr_t;

header ethernet_t {
    ethaddr_t dstAddr;
    ethaddr_t srcAddr;
    bit<16> etherType;
}
