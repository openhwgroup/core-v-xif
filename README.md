# OpenHW Group Specification: Core-V eXtension interface (CV-X-IF)

The Core-V eXtension interface (CV-X-IF) is a RISC-V eXtension interface that provides a generalized framework suitable to implement custom coprocessors and ISA extensions for existing RISC-V processors.

It features independent channels for accelerator-agnostic offloading of instructions and writeback of the result(s).

## Configuration

The project is configured using the [pyproject.toml](./pyproject.toml) file. Its values are input to [docs/source/conf.py](./docs/source/conf.py) for building the documentation.

When updating the project, it should be ensured that the configuration is up to date. In particular, version and copyright should be checked.

The specification uses semantic versioning (see [https://semver.org/](https://semver.org/)).

## Documentation

The CV-X-IF user manual can be found in the _docs_ folder and it is
captured in reStructuredText, rendered to html using [Sphinx](https://docs.readthedocs.io/en/stable/intro/getting-started-with-sphinx.html).
These documents are viewable using readthedocs and can be viewed [here](https://docs.openhwgroup.org/projects/openhw-group-core-v-xif/).

## Changelog

A changelog is generated automatically in the documentation from the individual pull requests. Pull requests labeled with *ignore-for-release* are ignored for the changelog generation.
