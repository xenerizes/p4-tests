#!/usr/bin/env python3

from scapy.all import Packet
from scapy.all import Ether, TCP, IP
from scapy.all import RandMAC, RandIP
from scapy.all import sendp, get_if_hwaddr, sniff
from random import randint
from threading import Thread
import sys

iface_in = 'veth2'
iface_local = 'veth0'
iface_out = 'veth4'


def make_pkt(dst='2'):
    pkt = Ether(src=get_if_hwaddr(iface_in), dst=("00:00:00:00:02:0"+dst))
    pkt = pkt/IP(dst="192.168.200.24")
    pkt = pkt/TCP(dport=1234, sport=randint(49152,65535))/("load"*1)
    return pkt


expected = make_pkt()


def sender():
    print('sender')
    expected.show2()
    sendp(expected, iface=iface_in)
    sys.stdout.flush()


def handle_pkt(pkt):
    print(Packet(pkt) == Packet(expected))
    pkt.show2()
    sys.stdout.flush()


def receiver():
    print('receiver')
    sniff(count=1, iface=iface_out, prn=handle_pkt)
    sys.stdout.flush()


sndr = Thread(target=sender)
rcvr = Thread(target=receiver)
rcvr.start()
sndr.start()
