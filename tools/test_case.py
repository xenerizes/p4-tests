from switch_monitor import SwitchMonitor


def get_pkt_fields(pkt):
    """
    Extract all fields from the packet.

    :type pkt: scapy non-built packet
    :rtype: list of scapy layers
    """
    def expand(pkt):
        yield pkt
        while pkt.payload:
            pkt = pkt.payload
            yield pkt

    return list(expand(pkt))


def compare_pkt(rhs, lhs):
    """
    Compare two packets layer by layer
    """
    rhs_fields, lhs_fields = (get_pkt_fields(x) for x in (rhs, lhs))
    for layer_rhs, layer_lhs in zip(rhs_fields, lhs_fields):
        if layer_lhs != layer_rhs:
            return False
    return True


def compare_pkt_list(rhs, lhs):
    """
    Compare two packet lists packet by packet, layer by layer
    """
    for pkt_rhs, pkt_lhs in zip(rhs, lhs):
        if not compare_pkt(pkt_rhs, pkt_lhs):
            return False
    return True


class ScenarioTestCase(object):
    """
    Run test case: send, receive packets and compare with expected
    """
    def __init__(self, port_map, packet_map, expected_map):
        self.port_map, self.packet_map, self.expected_map =
            port_map, packet_map, expected_map
        self.captured_map = None

    def run(self):
        monitor = SwitchMonitor(port_map=self.port_map, pkt_map=self.packet_map)
        self.captured_map = monitor.run().data
        return self.compare_pkt_maps()

    def summary(self):
        if self.captured_map is None:
            return
        # TODO
        print('Expected: ', self.expected_map)
        print('Captured: ', self.captured_map)

    def compare_pkt_maps(self):
        pass
