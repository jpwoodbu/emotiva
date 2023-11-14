"""Macro to create an interactive Python shell for a py_library."""

def py_interactive(name, deps, **kwargs):
  native.py_binary(
    name = name,
    srcs = ["//bazel/python:interactive.py"],
    main = "interactive.py",
    deps = deps,
    **kwargs,
  )
