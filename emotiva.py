from dataclasses import dataclass
from datetime import datetime
import ipaddress
import socket
import threading
import xml.etree.ElementTree


_PING_PORT = 7000
_LISTENING_PORT = 7001
_XML_HEADER = '<?xml version="1.0" encoding="utf-8"?>'


def _format_command(command: str) -> bytes:
  return (_XML_HEADER + command).encode(encoding='utf-8')


def ping():
  data = _format_command('<emotivaPing />')
  with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
    s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, True)
    s.sendto(data, ('<broadcast>', _PING_PORT))


@dataclass
class Device:
  model: str
  name: str
  control_version: str
  control_port: int
  notify_port: int
  info_port: int
  setup_port_tcp: int
  last_seen: datetime
  address: ipaddress.IPv4Address | None = None


def _text_from_element(tree: xml.etree.ElementTree.Element, xpath: str) -> str:
  e = tree.find(xpath)
  if e is None:
    raise ValueError('{} not found while parsing XML'.format(xpath))
  return e.text  # type: ignore


def _int_from_element(*args, **kwargs) -> int:
  return int(_text_from_element(*args, **kwargs))
  

def _parseTransponder(data: str) -> Device:
  root = xml.etree.ElementTree.fromstring(data)
  if root.tag != 'emotivaTransponder':
    raise ValueError(
      'Received improperly formatted emotivaTransponder response.')
  return Device(
    _text_from_element(root, 'model'),
    _text_from_element(root, 'name'),
    _text_from_element(root, './control/version'),
    _int_from_element(root, './control/controlPort'),
    _int_from_element(root, './control/notifyPort'),
    _int_from_element(root, './control/infoPort'),
    _int_from_element(root, './control/setupPortTCP'),
    last_seen=datetime.now())


class Devices(threading.Thread):

  devices: dict[str, Device]

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
      d.last_seen = datetime.now()
    else:
      self.devices[address] = device

  def run(self):
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
      s.bind(('', _LISTENING_PORT))
      while True:
        data, address = s.recvfrom(1024)
        device = _parseTransponder(data.decode('utf-8'))
        device.address = ipaddress.ip_address(address[0])  # type:ignore
        self._upsert_device(device)
        print(self.devices)


def main():
  devices = Devices()
  devices.start()
  ping()


if __name__ == '__main__':
  main()
