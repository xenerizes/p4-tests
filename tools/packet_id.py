from scapy.all import Raw, Dot1Q


def raw_id_extractor(pkt):
    return None if not pkt.haslayer(Raw) else pkt[Raw].load
