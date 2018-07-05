from scapy.all import Ether, TCP, IP
from scapy.all import RandMAC, RandIP
from scapy.all import get_if_hwaddr
from random import randint


def make_pkt(dst, iface):
    pkt = Ether(src=get_if_hwaddr(iface), dst=("00:00:00:00:03:0"+dst))
    pkt = pkt/IP(dst="192.168.200.24")
    pkt = pkt/TCP(dport=1234, sport=randint(49152,65535))
    pkt = pkt/("GET /path/resource?param1=value1&param2=value2 HTTP/1.1")
    return pktt
