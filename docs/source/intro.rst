Introduction
=============

The ``eXtension interface``, also called ``CORE-V-XIF``, is an interface aimed at extending a |processor| with (custom or standardized) instructions implemented in a |coprocessor|.

It can be used to implement standard RISC-V extensions as for example B (Bit Manipulation), M (Integer Multiplication and Division), F (Single-Precision Floating Point) and D (Double-Precision Floating Point). It can also be used to implement custom extensions.
Extensions implemented on the interface are unprivileged, i.e. implementing privileged extensions like H (Hypervisor) is not supported.

The goal of ``CORE-V-XIF`` is to enable the design and verification of instruction extensions in a |coprocessor| in a standardized manner without the need to modify the |processor| itself.
Having a common interface allows designers of RISC-V CPUs to reuse existing co-processor and viceversa.
Please note that the |processor| and |coprocessor| can have different license models. Example, the |coprocessor| could be closed source, connected to an open-source |processor|.

History
-------

The idea of an ``eXtension interface`` originated from the **PULP Project** at ETH Zurich and University of Bologna, where it was used to decouple the floating-point unit and the CPU design.
The first version of this interface was called ``apu interface``, and it was implemented in the **CV32E40P** to communicate with the **CVFPU** |coprocessor|.
However, this interface was tightly coupled with the |processor| pipeline, which meant that any other new |coprocessor| extension had to modify the |processor| pipeline and decoder.
Moreover, it was designed for a specific use-case. Later, the PULP team developed a more advanced interface for the **CVA6** project, which could handle more complex scenarios required by the **ARA** vector machine. This interface was further refined in the **Snitch** project, where it was made more modular and independent from the pipeline, requiring only minimal changes to the decoder of the |processor|. The aim of ``CORE-V-XIF`` within the OpenHW Group is to take this interface to the next level and eliminate all dependencies between the |processor| and the |coprocessor|.
The interface is not only agnostic from the decoder and pipeline perspective, but also from the license and codebase standpoint, with the goal of becoming the standard interface that will enable wide reuse of RISC-V IPs.
The first CPU implementeing such interface is the **CV32E40X**, which can be found at https://github.com/openhwgroup/cv32e40x.

License
-------
Copyright 2021-2024 OpenHW Group.

SPDX-License-Identifier: Apache-2.0 WITH SHL-0.51

Standards Compliance
--------------------

The ``eXtension interface`` specification depends on the following specifications:

.. [RISC-V-UNPRIV] The RISC-V Instruction Set Manual, Volume I: User-Level ISA,
   Document Version 20191213”, Editors Andrew Waterman and Krste Asanovi´c, RISC-V Foundation, December 2019.
.. [RISC-V-PRIV] The RISC-V Instruction Set Manual, Volume II: Privileged Architecture,
   Document Version 20211203”, Editors Andrew Waterman, Krste Asanovi´c, and John Hauser, RISC-V International, December 2021.
