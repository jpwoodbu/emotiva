import code
import dataclasses
import ipaddress
import socket
import threading
import xml.etree.ElementTree

from absl import app


TRANSPONDER_PORT = 7001
_PING_PORT = 7000
_XML_HEADER = '<?xml version="1.0" encoding="utf-8"?>'


def _format_command(command: str) -> bytes:
  return (_XML_HEADER + command).encode(encoding='utf-8')


def _fields_to_xml(fields: list[str]) -> str:
  return ''.join(['<{} />'.format(f) for f in fields])


def _text_from_element(tree: xml.etree.ElementTree.Element, xpath: str) -> str:
  e = tree.find(xpath)
  if e is None:
    raise ValueError('{} not found while parsing XML'.format(xpath))
  return e.text  # type: ignore


def _int_from_element(*args, **kwargs) -> int:
  return int(_text_from_element(*args, **kwargs))


@dataclasses.dataclass
class Device:
  model: str
  name: str
  control_version: str
  control_port: int
  notify_port: int
  info_port: int
  setup_port_tcp: int
  address: ipaddress.IPv4Address | None = None
  _threads: list = dataclasses.field(default_factory=list)
  _subscribed_fields: set = dataclasses.field(default_factory=set)
  power: bool = False
  source: str = ''
  mode: str = ''
  volume: int = 0


  def _send(self, data: bytes) -> None:
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
      s.sendto(data, (str(self.address), self.control_port))

  def command(self, command: str, value: str = '0', ack: bool = False) -> None:
    data = _format_command(
        '<emotivaControl><{} value="{}" ack="{}" /></emotivaControl>'.format(
            command, value, 'yes' if ack else 'no'))
    self._send(data)

  def subscribe(self, fields: list[str]) -> None:
    data = _format_command(
      '<emotivaSubscription>{}</emotivaSubscription>'.format(
        _fields_to_xml(fields)))
    print(data.decode('utf-8'))
    self._send(data)
    for f in fields:
      self._subscribed_fields.add(f)

  def unsubscribe(self, fields: list[str]) -> None:
    data = _format_command(
        '<emotivaUnsubscribe>{}</emotivaUnsubscribe>'.format(
           _fields_to_xml(fields)))
    print(data.decode('utf-8'))
    self._send(data)
    for f in fields:
      self._subscribed_fields.remove(f)

  def unsubscribe_all(self):
    self.unsubscribe(list(self._subscribed_fields))

  def update(self, fields: list[str]) -> None:
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
          print('control port:\n', data.decode('utf-8'))
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
          print('notify port:\n', data.decode('utf-8'))
    t = threading.Thread(target=listen, name='notify listener')
    self._threads.append(t)
    t.start()
  
  def start_listeners(self):
    self.start_control_listener()
    self.start_notification_listener()


def broadcast_ping():
  data = _format_command('<emotivaPing />')
  with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
    s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, True)
    s.sendto(data, ('<broadcast>', _PING_PORT))

def unicast_ping(ip_address: str):
  address = ipaddress.IPv4Address(ip_address)  # Validates IP address
  data = _format_command('<emotivaPing />')
  with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
    s.sendto(data, (str(address), _PING_PORT))


def parseTransponder(data: str) -> Device:
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
      _int_from_element(root, './control/setupPortTCP'))


def _listen_for_transponder(timeout: float, ip_address: str) -> Device:
  with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
    s.bind(('', TRANSPONDER_PORT))
    s.settimeout(timeout)
    if ip_address:
      unicast_ping(ip_address)
    else:
      broadcast_ping()
    data, address = s.recvfrom(4096)
    device = parseTransponder(data.decode('utf-8'))
    device.address = ipaddress.ip_address(address[0])  # type:ignore
    return device


def discovery(timeout_sec: float = 1.0, ip_address: str = '') -> Device | None:
  """This provides a simpler interface for getting a device.
  
  This function should be avoided if there is more than one Emotiva device you
  wish to control on the network. See the multi_device module.
  """
  try:
    return _listen_for_transponder(timeout_sec, ip_address)
  except socket.timeout:
    return None


def main(argv: list[str]) -> None:
  del argv  # unused
  console = code.InteractiveConsole()
  console.push('import emotiva')
  console.interact()


if __name__ == '__main__':
  app.run(main)
