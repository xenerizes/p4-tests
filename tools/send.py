#!/usr/bin/env python3

from scapy.all import PacketList
from scapy.all import Ether, TCP, IP
from scapy.all import RandMAC, RandIP
from scapy.all import get_if_hwaddr
from random import randint
from switch_monitor import SwitchMonitor


def make_pkt(dst, iface):
    pkt = Ether(src=get_if_hwaddr(iface), dst=("00:00:00:00:02:0"+dst))
    return pkt

port_map = {
    0: 'veth0',
    1: 'veth2',
    #2: 'veth4',
    3: 'veth6'
}

local_port = 0
sender = 1

packet_map = {
    1: PacketList(make_pkt('3', 'veth2'))
}


sm = SwitchMonitor(port_map, senders=[1], pkt_map=packet_map)
res = sm.run()
print(res.data)
