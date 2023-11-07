"""Support for multiple Emotiva devices on the same network.

WARNING: This is incomplete if you want to handle responses back from the device.
Since the listening ports on the remote for control and notify packets are
likely the same for all Emotiva devices, additional logic would be needed to
associate packets from different source IP addresses to different Device
objects.
"""
import socket
import threading

import emotiva


class Devices(threading.Thread):

  devices: dict[str, emotiva.Device]

  def __init__(self, *args, **kwargs):
    super().__init__(*args, **kwargs)
    self.devices = dict()

  def _upsert_device(self, device) -> None:
    address = str(device.address)
    if address in self.devices:
      d = self.devices[address]
      d.model = device.model
      d.name = device.name
      d.control_version = device.control_version
      d.control_port = device.control_port
      d.notify_port = device.notify_port
      d.info_port = device.info_port
      d.setup_port_tcp = device.setup_port_tcp
    else:
      self.devices[address] = device

  def run(self):
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
      s.bind(('', emotiva.TRANSPONDER_PORT))
      while True:
        data, address = s.recvfrom(4096)
        device = emotiva.parseTransponder(data.decode('utf-8'))
        device.address = ipaddress.ip_address(address[0])  # type:ignore
        self._upsert_device(device)