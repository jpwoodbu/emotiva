import code
import dataclasses
import ipaddress
import socket
import threading
import xml.etree.ElementTree

from absl import app
from absl import logging


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
  power: str = ''
  source: str = ''
  mode: str = ''
  volume: float = 0.0
  _threads: list = dataclasses.field(default_factory=list)
  _subscribed_fields: set = dataclasses.field(default_factory=set)
  _write_lock: threading.Lock = dataclasses.field(
    default_factory=threading.Lock)

  # List of tracked fields. Used for *_all() convenience functions.
  _FIELDS = ('power', 'source', 'mode', 'volume')

  def _send(self, data: bytes) -> None:
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
      logging.debug('sending: %s', data.decode('utf-8'))
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
    self._send(data)
    for f in fields:
      self._subscribed_fields.add(f)

  def subscribe_all(self) -> None:
    self.subscribe(list(self._FIELDS))

  def unsubscribe(self, fields: list[str]) -> None:
    data = _format_command(
        '<emotivaUnsubscribe>{}</emotivaUnsubscribe>'.format(
           _fields_to_xml(fields)))
    self._send(data)
    for f in fields:
      try:
        self._subscribed_fields.remove(f)
      except KeyError:
        # We may be unsubscribing with a new instance, perhaps to clean up state
        # on the Emotiva device.
        pass

  def unsubscribe_all(self):
    self.unsubscribe(list(self._subscribed_fields))

  def update(self, fields: list[str]) -> None:
    data = _format_command(
        '<emotivaUpdate>{}</emotivaUpdate>'.format(_fields_to_xml(fields)))
    self._send(data)

  def update_all(self) -> None:
    """Requests an update for all fields this object can track."""
    self.update(list(self._FIELDS))

  def _parse_data(
      self, tree: xml.etree.ElementTree.Element) -> None:
    for child in tree:
      name = child.tag
      try:
        value = child.attrib['value']
      except KeyError:
        raise ValueError(
          'Could not parse update/notify/subscription data. '
          'No "value" attribute in {}'.format(child.attrib))

      with self._write_lock:
        if name == 'power':
          self.power = value
        elif name == 'source':
          self.source = value
        elif name == 'mode':
          self.mode = value
        elif name == 'volume':
          self.volume = float(value)
      
  def _dispatch_data(self, data: str) -> None:
    root = xml.etree.ElementTree.fromstring(data)
    # emotivaUpdate: A push notification related to a subscription.
    # emotivaNotify: A response to an update request.
    # emotivaSubscription: A response to a subscription request.
    if root.tag in ('emotivaNotify', 'emotivaUpdate', 'emotivaSubscription'):
      self._parse_data(root)
    # An acknowledgement of a control request.
    elif root.tag == 'emotivaAck':
      logging.info('received ack: %s', data)
    # An acknowledgement of an unsubscribe request().
    elif root.tag == 'emotivaUnsubscribe':
      logging.info('received unscubscribe ack: %s', data)

  def _start_listener(self, name: str, port: int):
    def listen():
      with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        s.bind(('', port))
        while True:
          data, address = s.recvfrom(4096)
          if address[0] != str(self.address):
            logging.warn(
              'Ignoring unexpected packets from %s to port %s.',
              address[0], port) 
            continue 
          decoded_data = data.decode('utf-8')
          logging.debug('received by %s:\n %s', name, decoded_data)
          self._dispatch_data(decoded_data)
    t = threading.Thread(target=listen, name=name, daemon=True)
    self._threads.append(t)
    t.start()

  def start_listeners(self):
    self._start_listener('control', self.control_port)
    # It seems that some messages come back to the remote on the control port.
    # E.g. acks for control messages, like a subscription request.
    self._start_listener('notify', self.notify_port)


def broadcast_ping():
  data = _format_command('<emotivaPing />')
  with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
    s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, True)
    logging.debug('broadcasting: %s', data.decode('utf-8'))
    s.sendto(data, ('<broadcast>', _PING_PORT))


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


def _listen_for_transponder(timeout: float) -> Device:
  with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
    s.bind(('', TRANSPONDER_PORT))
    s.settimeout(timeout)
    broadcast_ping()
    data, address = s.recvfrom(4096)
    logging.debug('transponder port: \n%s', data.decode('utf-8'))
    device = parseTransponder(data.decode('utf-8'))
    device.address = ipaddress.ip_address(address[0])  # type:ignore
    return device


def discovery(timeout_sec: float = 1.0) -> Device | None:
  """This provides a simpler interface for getting a device.
  
  This function should be avoided if there is more than one Emotiva device you
  wish to control on the network. See the multi_device module.
  """
  try:
    return _listen_for_transponder(timeout_sec)
  except socket.timeout:
    return None


def main(argv: list[str]) -> None:
  del argv  # unused
  console = code.InteractiveConsole()
  console.push('import emotiva')
  console.push('d = emotiva.discovery()')
  console.push('d.start_listeners()')
  console.push('d.update_all()')
  console.interact(
    banner=(
      'The emotiva module has been imported. '
      'An object named "d" has been created which represents a local Emotiva '
      'device.'))


if __name__ == '__main__':
  app.run(main)
