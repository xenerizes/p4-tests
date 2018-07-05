from tools.switch_monitor import SwitchMonitor


def compare_pkt_list(expected, captured):
    """
    Compare two packet lists
    """
    for pkt in expected:
        if pkt not in captured:
            return False
        captured.remove(pkt)

    return len(captured) == 0


class ScenarioTestCase(object):
    """
    Run test case: send, receive packets and compare with expected
    """
    def __init__(self, port_map, packet_map, expected_map):
        self.port_map = port_map
        self.packet_map = packet_map
        self.expected_map = expected_map
        self.captured_map = None

    def run(self):
        monitor = SwitchMonitor(port_map=self.port_map, pkt_map=self.packet_map)
        self.captured_map = monitor.run().data
        eq = self.compare_pkt_maps()
        print("OK" if eq else "Failed")

    def summary(self):
        if self.captured_map is None:
            return
        # TODO
        print('Expected: ', self.expected_map)
        print('Captured: ', self.captured_map)

    def compare_pkt_maps(self):
        for port in self.expected_map:
            if not compare_pkt_list(self.captured_map[port],
                                    self.expected_map[port]):
                return False
        return True
