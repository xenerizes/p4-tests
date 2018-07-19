from scapy.all import Ether, TCP, IP, Dot1Q
from scapy.all import RandMAC, RandIP
from scapy.all import get_if_hwaddr
from random import randint

MAC_MCAST_PREFIX = "01:00:5e:00:"
MAC_STANDARD_PREFIX = "00:00:00:00:"


def make_pkt(dst, iface, mcast=False, id=None):
    prefix = MAC_MCAST_PREFIX if mcast else MAC_STANDARD_PREFIX
    pkt = Ether(src=get_if_hwaddr(iface), dst=(prefix + dst))
    pkt = pkt/IP(dst="192.168.200.24")
    pkt = pkt/TCP(dport=1234, sport=randint(49152,65535))
    if id is not None:
        pkt = pkt/(id)
    return pkt


def add_vlan_tag(pkt, vid):
    return pkt.clone_with(payload=Dot1Q(vlan=vid)/pkt.payload)
