from scapy.all import Raw, Dot1Q


def raw_id_extractor(pkt):
    return None if not pkt.haslayer(Raw) else pkt[Raw].load


def vlan_extractor(pkt):
    return None if not pkt.haslayer(Dot1Q) else pkt[Dot1Q].vlan


def raw_id_vlan_extractor(pkt):
    return vlan_extractor(pkt), raw_id_extractor(pkt)
