#!/usr/bin/env python3

from scapy.all import Ether, TCP, IP
from scapy.all import RandMAC, RandIP
from scapy.all import get_if_hwaddr
from tools.test_case import ScenarioTestCase
from tools.packets import make_pkt, add_vlan_tag
from random import randint
from re import search

SCENARIO = 'l2sw-vlan'

port_map = {
    0: 'veth0',
    1: 'veth2',
    2: 'veth4',
    3: 'veth6'
}

tests = [ "Access source port", "Trunk source port" ]

test_maps = [
    {
        1: [
            make_pkt('99:99', 'veth2', id=str(1)),
            make_pkt('01:01', 'veth2', mcast=True, id=str(2)),
            make_pkt('00:03', 'veth2', id=str(3))
        ]
    },
    {
        2: list(add_vlan_tag(make_pkt('00:03', 'veth5', id=str(4)), 321))
    }
]

expected_maps = [
    {
        # TODO: check 0 for right tags
        0: [
            test_maps[0][1][0].copy(),
            test_maps[0][1][1].copy()
        ],
        2: [
            add_vlan_tag(test_maps[0][1][0].copy(), 321),
            add_vlan_tag(test_maps[0][1][1].copy(), 321)
        ],
        3: [
            add_vlan_tag(test_maps[0][1][0].copy(), 123),
            add_vlan_tag(test_maps[0][1][2].copy(), 123)
        ]
    },
    {
        3: list(add_vlan_tag(make_pkt('00:03', 'veth5', id=str(4)), 123))
    }
]

for idx, test_name in enumerate(tests):
    test = ScenarioTestCase(scenario=SCENARIO, test=test_name,
                            port_map=port_map, packet_map=test_maps[idx],
                            expected_map=expected_maps[idx])
    test.run()
