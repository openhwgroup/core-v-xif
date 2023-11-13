Introduction
=============

The ``eXtension interface``, also called ``CORE-V-XIF``, is an interface aimed at extending a |processor| with (custom or standardized) instructions implemented in a |coprocessor|.

It can be used to implement standard RISC-V extensions as for example B (Bit Manipulation), M (Integer Multiplication and Division), F (Single-Precision Floating Point) and D (Double-Precision Floating Point). It can also be used to implement custom extensions.
Extensions implemented on the interface are unprivileged, i.e. implementing privileged extensions like H (Hypervisor) is not supported.

The goal of ``CORE-V-XIF`` is to enable the design and verification of instruction extensions in a |coprocessor| in a standardized manner without the need to modify the |processor| itself.

License
-------
Copyright 2021 OpenHW Group.

Copyright and related rights are licensed under the Solderpad Hardware
License, Version 0.51 (the “License”); you may not use this file except
in compliance with the License. You may obtain a copy of the License at
http://solderpad.org/licenses/SHL-0.51. Unless required by applicable
law or agreed to in writing, software, hardware and materials
distributed under this License is distributed on an “AS IS” BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

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
