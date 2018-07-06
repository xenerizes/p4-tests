#!/usr/bin/env python3

from scapy.all import Ether, TCP, IP
from scapy.all import RandMAC, RandIP
from scapy.all import get_if_hwaddr
from tools.test_case import ScenarioTestCase
from tools.packets import make_pkt

SCENARIO = 'l2sw'

port_map = {
    0: 'veth0',
    1: 'veth2',
    2: 'veth4',
    3: 'veth6'
}

tests = [ "Broadcast", "Multicast"]#, "Unicast", "Mixed" ]

test_maps = [
    { 1: list(make_pkt('99:99', 'veth2', id=str(i)) for i in range(3)) },
    { 3: list(make_pkt('11:11', 'veth6', mcast=True, id=str(i))
              for i in range(3, 5)) }
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
        2: test_maps[1][3].copy(),
        3: list()
    }
]

for idx, test_name in enumerate(tests):
    test = ScenarioTestCase(scenario=SCENARIO, test=test_name,
                            port_map=port_map, packet_map=test_maps[idx],
                            expected_map=expected_maps[idx])
    test.run()
