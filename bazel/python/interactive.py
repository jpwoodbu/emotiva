import code
import readline
import rlcompleter


def main():
  vars = globals()
  readline.set_completer(rlcompleter.Completer(vars).complete)
  readline.parse_and_bind('tab: complete')
  console = code.InteractiveConsole(vars)
  console.interact()


if __name__ == '__main__':
  main()
