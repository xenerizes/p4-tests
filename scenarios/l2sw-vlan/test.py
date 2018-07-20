#!/usr/bin/env python3

from scapy.all import Ether, TCP, IP
from scapy.all import RandMAC, RandIP
from scapy.all import get_if_hwaddr
from tools.test_case import ScenarioTestCase
from tools.packets import make_pkt, change_vlan_tag
from tools.packet_id import raw_id_extractor
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
            make_pkt('99:99', port_map[1], id=str(1), tag=0),
            make_pkt('01:01', port_map[1], mcast=True, id=str(2), tag=0),
            make_pkt('00:10', port_map[1], id=str(3), tag=0)
        ]
    },
    {
        2: list(make_pkt('00:03', port_map[2], id=str(4), tag=321))
    }
]

expected_maps = [
    {
        0: [
            test_maps[0][1][0].copy(),
            test_maps[0][1][1].copy(),
            test_maps[0][1][2].copy()
        ],
        2: [
            change_vlan_tag(test_maps[0][1][0].copy(), 321),
            change_vlan_tag(test_maps[0][1][1].copy(), 321)
        ],
        3: [
            change_vlan_tag(test_maps[0][1][0].copy(), 123)
        ]
    },
    {
        3: list(change_vlan_tag(test_maps[1][2][0].copy(), 123))
    }
]

for idx, test_name in enumerate(tests):
    test = ScenarioTestCase(scenario=SCENARIO, test=test_name,
                            port_map=port_map, packet_map=test_maps[idx],
                            expected_map=expected_maps[idx],
                            extractor=raw_id_extractor)
    test.run()
