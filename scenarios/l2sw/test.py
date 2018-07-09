#!/usr/bin/env python3

from scapy.all import Ether, TCP, IP
from scapy.all import RandMAC, RandIP
from scapy.all import get_if_hwaddr
from tools.test_case import ScenarioTestCase
from tools.packets import make_pkt
from random import randint
from re import search

SCENARIO = 'l2sw'

port_map = {
    0: 'veth0',
    1: 'veth2',
    2: 'veth4',
    3: 'veth6'
}

tests = [ "Broadcast", "Multicast", "Unicast"]#, "Mixed" ]

test_maps = [
    { 1: list(make_pkt('99:99', 'veth2', id=str(i)) for i in range(100)) },
    { 3: list(make_pkt('01:01', 'veth6', mcast=True, id=str(i))
              for i in range(100, 200)) },
    { 0: list(make_pkt('00:0{}'.format(randint(1, 3)), 'veth2', id=str(i))
              for i in range(200, 300)) }
]

expected_maps = [
    {
        0: test_maps[0][1].copy(),
        2: test_maps[0][1].copy(),
        3: test_maps[0][1].copy()
    },
    {
        0: list(),
        1: test_maps[1][3].copy(),
        2: test_maps[1][3].copy()
    },
    {
        1: [pkt for pkt in test_maps[2][0] if search('.*1', pkt.dst)],
        2: [pkt for pkt in test_maps[2][0] if search('.*2', pkt.dst)],
        3: [pkt for pkt in test_maps[2][0] if search('.*3', pkt.dst)]
    }
]

for idx, test_name in enumerate(tests):
    test = ScenarioTestCase(scenario=SCENARIO, test=test_name,
                            port_map=port_map, packet_map=test_maps[idx],
                            expected_map=expected_maps[idx])
    test.run()
