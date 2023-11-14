"""Macro to create an interactive Python shell for a py_library."""

def _quote_args(args):
  """Wrap Pyhton statements in quotes.

  This prevents statements with whitespace from being broken up within sys.argv
  """
  return ['"{}"'.format(a) for a in args]

def py_interactive(name, deps, pushes, **kwargs):
  """Create a py_binary target to run an interactive Python shell.

  deps: list of labels, the target(s) which are made available (i.e.
    importable) within the Python shell.
  pushes: list of str, Python statements run on the interpreter at start time.
  """
  native.py_binary(
    name = name,
    srcs = ["//bazel/python:interactive.py"],
    main = "interactive.py",
    deps = deps,
    args = _quote_args(pushes),
    **kwargs,
  )
