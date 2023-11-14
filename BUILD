load("@rules_python//python:defs.bzl", "py_binary", "py_library")
load("@rules_python//python:pip.bzl", "compile_pip_requirements")
load("@requirements//:requirements.bzl", "requirement")
load(":py_interactive.bzl", "py_interactive")

compile_pip_requirements(
    name = "requirements",
    requirements_in = "requirements.in",
    requirements_txt = "requirements_lock.txt",
)

py_library(
    name = "emotiva",
    srcs = ["emotiva.py"],
    deps = [
        requirement("absl-py"),
    ],
)

py_library(
    name = "multi_device",
    srcs = ["multi_device.py"],
    deps = [
        ":emotiva",
    ],
)


py_interactive(
    name = "cli",
    deps = [":emotiva"],
)
