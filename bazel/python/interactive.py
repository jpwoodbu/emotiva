import code
import readline
import rlcompleter
import sys


def main(argv: list[str]) -> None:
  vars = globals()
  readline.set_completer(rlcompleter.Completer(vars).complete)
  readline.parse_and_bind('tab: complete')
  console = code.InteractiveConsole(vars)
  if len(argv) > 1:
    for a in argv[1:]:
      console.push(a)
  console.interact()


if __name__ == '__main__':
  main(sys.argv)
