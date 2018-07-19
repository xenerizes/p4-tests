typedef bit<12> vid_t;

header dot1q_t {
    bit<3> pcp;
    bit dei;
    vid_t vid;
    bit<16> etherType;
}
