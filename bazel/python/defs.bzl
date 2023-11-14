"""Macro to create an interactive Python shell for a py_library."""

_SCRIPT = """
import code
import readline
import rlcompleter


def main():
  vars = globals()
  vars.update(locals())
  readline.set_completer(rlcompleter.Completer(vars).complete)
  readline.parse_and_bind('tab: complete')
  console = code.InteractiveConsole(vars)
  console.interact()


if __name__ == '__main__':
  main()
"""

def _cli_impl(ctx):
  out = ctx.actions.declare_file('cli.py')
  ctx.actions.write(
    output = out,
    content = _SCRIPT,
  )
  return [DefaultInfo(files = depset([out]))]

_cli = rule(
    implementation = _cli_impl,
)

def py_interactive(name, deps, **kwargs):
  _cli(name="_cli")
  native.py_binary(
    name = name,
    srcs = [":_cli"],
    main = "cli.py",
    deps = deps,
    **kwargs,
  )
