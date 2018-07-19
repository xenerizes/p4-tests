from tools.switch_monitor import SwitchMonitor
from scapy.all import Raw
from sys import stdout

def pkt_list_comparator(captured, expected, id_extractor):
    captured_ids = [id_extractor(x) for x in captured]
    expected_ids = [id_extractor(x) for x in expected]
    return captured_ids == expected_ids


class ScenarioTestCase(object):
    """
    Run test case: send, receive packets and compare with expected
    """
    def __init__(self, port_map, packet_map, expected_map, scenario, test,
                 extractor):
        self.port_map = port_map
        self.packet_map = packet_map
        self.expected_map = expected_map
        self.captured_map = None
        self.extractor = extractor
        self.name = "Test \"{}\" for scenario \"{}\"".format(test, scenario)
        self.delim = "... "

    def run(self):
        stdout.write(self.name)
        stdout.write(self.delim)
        stdout.flush()

        monitor = SwitchMonitor(port_map=self.port_map, pkt_map=self.packet_map,
                                exp_map=self.expected_map)
        self.captured_map = monitor.run().data
        eq = self.compare_pkt_maps()

        print("OK" if eq else "Failed")

    def summary(self):
        print('Expected: ', self.expected_map)
        print('Captured: ', self.captured_map)

    def compare_pkt_maps(self):
        for port in self.expected_map.keys():
            if not pkt_list_comparator(self.captured_map[port],
                                       self.expected_map[port],
                                       self.extractor):
                return False
        return True
