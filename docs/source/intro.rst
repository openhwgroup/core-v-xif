Introduction
=============

The ``eXtension interface``, also called ``CORE-V-XIF``, is an interface aimed at extending a |processor| with (custom or standardized) instructions implemented in a |coprocessor|.

It can be used to implement standard RISC-V extensions as for example B (Bit Manipulation), M (Integer Multiplication and Division), F (Single-Precision Floating Point) and D (Double-Precision Floating Point). It can also be used to implement custom extensions.
Extensions implemented on the interface are unprivileged, i.e. implementing privileged extensions like H (Hypervisor) is not supported.

The goal of ``CORE-V-XIF`` is to enable the design and verification of instruction extensions in a |coprocessor| in a standardized manner without the need to modify the |processor| itself.

License
-------
Copyright 2021-2023 OpenHW Group.

SPDX-License-Identifier: Apache-2.0 WITH SHL-0.51

Standards Compliance
--------------------

The ``eXtension interface`` specification depends on the following specifications:

.. [RISC-V-UNPRIV] RISC-V Instruction Set Manual, Volume I: User-Level ISA, Document Version 20191213 (December 13, 2019),
   https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMAFDQC/riscv-spec-20191213.pdf

Contents
--------

 * :ref:`x_ext` describes the custom eXtension interface.

History
-------

References
----------

Contributors
------------
