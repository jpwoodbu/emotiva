import dataclasses
from datetime import datetime
import ipaddress
import socket
import threading
import xml.etree.ElementTree


_PING_PORT = 7000
_TRANSPONDER_PORT = 7001
_XML_HEADER = '<?xml version="1.0" encoding="utf-8"?>'


def _format_command(command: str) -> bytes:
  return (_XML_HEADER + command).encode(encoding='utf-8')


def ping():
  data = _format_command('<emotivaPing />')
  with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
    s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, True)
    s.sendto(data, ('<broadcast>', _PING_PORT))


def _fields_to_xml(fields: list[str]) -> str:
  return ''.join(['<{} />'.format(f) for f in fields])


@dataclasses.dataclass
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
  _threads: list = dataclasses.field(default_factory=list)
  _subscribed_fields: set = dataclasses.field(default_factory=set)

  def _send(self, data: bytes) -> None:
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
      s.sendto(data, (str(self.address), self.control_port))

  def _command(self, command: str, value: str = '0', ack: bool = False) -> None:
    data = _format_command(
        '<emotivaControl><{} value="{}" ack="{}" /></emotivaControl>'.format(
            command, value, 'yes' if ack else 'no'))
    self._send(data)

  def _subscribe(self, fields: list[str]) -> None:
    data = _format_command(
      '<emotivaSubscription>{}</emotivaSubscription>'.format(
        _fields_to_xml(fields)))
    print(data.decode('utf-8'))
    self._send(data)
    for f in fields:
      self._subscribed_fields.add(f)

  def _unsubscribe(self, fields: list[str]) -> None:
    data = _format_command(
        '<emotivaUnsubscribe>{}</emotivaUnsubscribe>'.format(
           _fields_to_xml(fields)))
    print(data.decode('utf-8'))
    self._send(data)
    for f in fields:
      self._subscribed_fields.remove(f)

  def _unsubscribe_all(self):
    self._unsubscribe(list(self._subscribed_fields))

  def _update(self, fields: list[str]) -> None:
    data = _format_command(
        '<emotivaUpdate>{}</emotivaUpdate>'.format(_fields_to_xml(fields)))
    print(data.decode('utf-8'))
    self._send(data)

  def start_control_listener(self):
    def listen():
      with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        s.bind(('', self.control_port))
        while True:
          data, _ = s.recvfrom(4096)
          print('control port: ', data.decode('utf-8'))
    t = threading.Thread(target=listen, name='control listener')
    self._threads.append(t)
    t.start()

  # It seems that some messages come back to the remove on the control port.
  # E.g. acks for control messages, like a subscription request.
  def start_notification_listener(self):
    def listen():
      with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        s.bind(('', self.notify_port))
        while True:
          data, _ = s.recvfrom(4096)
          print('notify port: ', data.decode('utf-8'))
    t = threading.Thread(target=listen, name='notify listener')
    self._threads.append(t)
    t.start()


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
      s.bind(('', _TRANSPONDER_PORT))
      while True:
        data, address = s.recvfrom(1024)
        device = _parseTransponder(data.decode('utf-8'))
        device.address = ipaddress.ip_address(address[0])  # type:ignore
        self._upsert_device(device)

  def single_device(self) -> Device:
    """Returns a Device object if only one was found on the network.

    It is most likely only a single Emotiva device is on the network. The
    protocol also makes it difficult for a remote to talk to more than one
    Emotiva device at a time.

    Raises:
      RuntimeError: No devices have been discovered.
      RuntimeError: More than one device has been discovered.
    """
    if not self.devices:
      raise RuntimeError('No devices have been discovered.')
    if len(self.devices) > 1:
      raise RuntimeError('More than one device found.')
    return next(iter(self.devices.values()))


def main():
  devices = Devices()
  devices.start()
  ping()


if __name__ == '__main__':
  main()
