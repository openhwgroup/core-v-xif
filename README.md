# OpenHW Group Specification: Core-V eXtension interface (CV-X-IF)

The Core-V eXtension interface (CV-X-IF) is a RISC-V eXtension interface that provides a generalized framework suitable to implement custom coprocessors and ISA extensions for existing RISC-V processors.

It features independent channels for accelerator-agnostic offloading of instructions and writeback of the result(s).

## Configuration

The project is configured using the [pyproject.toml](./pyproject.toml) file. Its values are input to [docs/source/conf.py](./docs/source/conf.py) for building the documentation.

When updating the project, it should be ensured that the configuration is up to date. In particular, copyright should be checked to be up to date.

The specification uses semantic versioning (see [https://semver.org/](https://semver.org/)).

The specifications versions are controlled through git tags. The version is not hardcoded in the repository contents. Rather, the version is extracted from the last git tag using setuptools_scm. If a version matches a tag exactly, this version is used. Otherwise, the version is guessed according to the rules of setuptools_scm. This includes appending a postfix -devX where X denotes the distance in commits from the last tagged version.

## Documentation

The CV-X-IF specification can be found in the _docs_ folder and it is
captured in reStructuredText, rendered to html using [Sphinx](https://docs.readthedocs.io/en/stable/intro/getting-started-with-sphinx.html).
These documents are viewable using readthedocs and can be viewed [here](https://docs.openhwgroup.org/projects/openhw-group-core-v-xif/).

## Changelog

A changelog is generated automatically in the documentation from the individual pull requests. Pull requests labeled with *ignore-for-release* are ignored for the changelog generation.
