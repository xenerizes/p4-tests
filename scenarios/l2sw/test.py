#!/usr/bin/env python3

from scapy.all import Ether, TCP, IP
from scapy.all import RandMAC, RandIP
from scapy.all import get_if_hwaddr
from tools.test_case import ScenarioTestCase
from tools.packets import make_pkt


port_map = {
    0: 'veth0',
    1: 'veth2',
    2: 'veth4',
    3: 'veth6'
}

packet_map = {
    1: list(make_pkt('3', 'veth2'))
}

expected_map = {
    3: packet_map[1].copy()
}


test1 = ScenarioTestCase(port_map=port_map,
                         packet_map=packet_map,
                         expected_map=expected_map)
test1.run()
