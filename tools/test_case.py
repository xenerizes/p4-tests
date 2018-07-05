from tools.switch_monitor import SwitchMonitor
from sys import stdout


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
    def __init__(self, port_map, packet_map, expected_map, scenario, test):
        self.port_map = port_map
        self.packet_map = packet_map
        self.expected_map = expected_map
        self.captured_map = None
        self.name = "Test \"{}\" for scenario \"{}\"".format(test, scenario)
        self.delim = "... "

    def run(self):
        stdout.write(self.name)
        stdout.write(self.delim)
        stdout.flush()

        monitor = SwitchMonitor(port_map=self.port_map, pkt_map=self.packet_map)
        self.captured_map = monitor.run().data
        eq = self.compare_pkt_maps()

        print("OK" if eq else "Failed")

    def summary(self):
        print('Expected: ', self.expected_map)
        print('Captured: ', self.captured_map)

    def compare_pkt_maps(self):
        for port in self.expected_map:
            if not compare_pkt_list(self.captured_map[port],
                                    self.expected_map[port]):
                return False
        return True
