from threading import Thread, Lock
from scapy.all import sniff
from scapy.all import sendp


class SniffResults(object):
    """
    Stores sniffing results for switch ports
    """
    def __init__(self):
        self.lck = Lock()
        self.data = dict()

    def add(self, port, pkt_list):
        self.lck.acquire()
        self.data[port] = list(pkt_list)
        self.lck.release()


class PortMonitor(Thread):
    """
    Sniff on specified switch port
    """
    def __init__(self, port, iface, packets=1, results=None,
                 timeout=5, **kwargs):
        """
        :param port: port id
        :param iface: interface name
        :param packets: number of packets to sniff
        :param results: variable to store the result; just returns if None
        :param **kwargs: arguments to pass to underlying Thread object
        :type port: int
        :type iface: string
        :type packets: int
        :type results: SniffResults
        """
        Thread.__init__(self, name=port, **kwargs)
        self.port = port
        self.iface = iface
        self.packets = packets
        self.results = results
        self.timeout = timeout

    def run(self):
        res = sniff(count=self.packets, iface=self.iface, timeout=self.timeout)
        if self.results is not None:
            self.results.add(self.port, res)
        else:
            return res


class Sender(Thread):
    """
    Send packets to specified switch port
    """
    def __init__(self, port, iface, pkt_list, **kwargs):
        """
        :param port: port id
        :param iface: interface name
        :param pkt_list: list of the packets to be sent
        :param **kwargs: arguments to pass to underlying Thread object
        :type port: int
        :type iface: string
        :type pkt_list: iterable collection of scapy packets
        """
        Thread.__init__(self, name=port, **kwargs)
        self.iface = iface
        self.packets = pkt_list

    def run(self):
        sendp(self.packets, iface=self.iface, verbose=False)


class SwitchMonitor(object):
    """
    Send packets and monitor them on specified ports
    """
    def __init__(self, port_map, pkt_map=[]):
        """
        :param port_map: port-interface mapping ({port: "interface"})
        :param senders: ports to send the packets
        :param pkt_map: port-packet list mapping ({port: packet_list})
        :type port_map: dict {int: string}
        :type senders: list of int
        :type pkt_map: dict {int: list(int)}
        """
        self.port_map = port_map
        self.sniff_res = SniffResults()

        self.monitors = list(
            PortMonitor(port, iface, results=self.sniff_res)
            for port, iface in self.port_map.items() if port not in pkt_map
        )
        self.senders = list(
            Sender(port, iface, pkt_list=pkt_map[port])
            for port, iface in self.port_map.items()
            if port in pkt_map
        )

    def run(self):
        """
        :returns: object containing port-packet mapping
        :rtype: SniffResults
        """
        res = SniffResults()
        for m in self.monitors:
            m.start()
        for s in self.senders:
            s.start()
        for m in self.monitors:
            m.join()

        return self.sniff_res
