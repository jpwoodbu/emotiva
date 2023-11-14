import code
import readline
import rlcompleter


def general_main():
  vars = globals()
  vars.update(locals())
  readline.set_completer(rlcompleter.Completer(vars).complete)
  readline.parse_and_bind('tab: complete')
  console = code.InteractiveConsole(vars)
  console.interact()


def main():
  vars = globals()
  vars.update(locals())
  readline.set_completer(rlcompleter.Completer(vars).complete)
  readline.parse_and_bind('tab: complete')
  console = code.InteractiveConsole(vars)
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
  main()