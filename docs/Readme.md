# Build instructions

The documents in this directory are written in reStructuredText and compiled to HTML using Sphinx. For more information, check https://www.sphinx-doc.org/en/master/usage/restructuredtext/index.html.

## Prerequisites

To build the documents, certain prequisites need to be fulfilled. This section outlines the necessary steps on Linux.

Sphinx is based on Python and requires at least version 3.8. Additionally, `make` is required and can be installed through build-essential.

```bash
sudo apt update
sudo apt install python3
sudo apt install build-essential
```

Please verify your Python version using

```bash
python3 --version
```

The recommended way of installing Sphinx is via `pip` using

```bash
pip install -U sphinx
```

Sphinx requires certain packages to build these documents. These are summarized in `doc/requirements.txt`. They can automatically be installed using

```bash
cd doc
pip install -r requirements.txt
```

## Building the documents

To build the documents, switch to the `doc` folder if not already done. Build is invoked via the `make` command. Typically, an HTML should be build.

```bash
cd doc
make html
```

A secondary build target is pdf. To build the pdf, additional prerequisites need to be met. To install `pdflatex`, run

```bash
sudo apt-get install texlive-latex-base
```

A pdf document can be built using the command

```bash
cd doc
make latexpdf
```

Simply type only `make` to view other available targets.

## Building the documents with additional Sphinx options

Additional Sphinx options can be set during the build process to control the output.
Currently, the only option available is to include the memory interface in the output.
To do so, run e.g. for html generation

```bash
cd doc
make SPHINXOPTS="-t MemoryIf" html
```