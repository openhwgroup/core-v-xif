Introduction
=============

The ``Core-V eXtension interface``, also called ``CV-X-IF``, is an interface aimed at extending a |processor| with (custom or standardized) instructions implemented in a |coprocessor|.

It can be used to implement standard RISC-V extensions as for example B (Bit Manipulation), M (Integer Multiplication and Division), F (Single-Precision Floating Point) and D (Double-Precision Floating Point). It can also be used to implement custom extensions.
Extensions implemented on the interface are unprivileged, i.e. implementing privileged extensions like H (Hypervisor) is not supported.

The goal of ``CV-X-IF`` is to enable the design and verification of instruction extensions in a |coprocessor| in a standardized manner without the need to modify the |processor| itself.
Having a common interface allows designers of RISC-V :term:`CPUs<CPU>` to reuse existing co-processor and vice versa.
Please note that the |processor| and |coprocessor| can have different license models. For example, the |coprocessor| could be closed source, connected to an open-source |processor|.

History
-------

The idea of an extension interface originated from the **PULP Project** at ETH Zurich and University of Bologna, where it was used to decouple the floating-point unit and the CPU design.
The first version of this interface was called ``apu interface``, and it was implemented in the **CV32E40P** to communicate with the **CVFPU** |coprocessor|.
However, this interface was tightly coupled with the |processor| pipeline, which meant that any other new |coprocessor| extension had to modify the |processor| pipeline and decoder.
Moreover, it was designed for a specific use-case. Later, the PULP team developed a more advanced interface for the **CVA6** project, which could handle more complex scenarios required by the **ARA** vector machine. This interface was further refined in the **Snitch** project, where it was made more modular and independent from the pipeline, requiring only minimal changes to the decoder of the |processor|. The aim of ``CV-X-IF`` within the OpenHW Group is to take this interface to the next level and eliminate all dependencies between the |processor| and the |coprocessor|.
The interface is not only agnostic from the decoder and pipeline perspective, but also from the license and codebase standpoint, with the goal of becoming the standard interface that will enable wide reuse of RISC-V IPs.
The first CPU implementing such interface is the **CV32E40X**, which can be found at https://github.com/openhwgroup/cv32e40x.
The interface was also added as an option to **CVA6**, which can be found at https://github.com/openhwgroup/cva6.

License
-------
Copyright © |copyright|.

SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may not use this file except in compliance with the License, or, at your option, the Apache License version 2.0.

You may obtain a copy of the License at

https://solderpad.org/licenses/SHL-2.1/

Unless required by applicable law or agreed to in writing, any work distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

See the License for the specific language governing permissions and limitations under the License.

Standards Compliance
--------------------

The ``CV-X-IF`` specification depends on the unprivileged [RISC-V-UNPRIV]_ and privileged [RISC-V-PRIV]_ RISC-V specification.

.. [RISC-V-UNPRIV] The RISC-V Instruction Set Manual, Volume I: User-Level ISA,
   Document Version 20191213, Editors Andrew Waterman and Krste Asanovíc, RISC-V Foundation, December 2019.
.. [RISC-V-PRIV] The RISC-V Instruction Set Manual, Volume II: Privileged Architecture,
   Document Version 20211203, Editors Andrew Waterman, Krste Asanovíc, and John Hauser, RISC-V International, December 2021.

Glossary
--------

.. glossary:: 
    
    clk
        Clock signal

    ISA
        Instruction set architecture

    CPU
        Central processing unit

    ALU
        Arithmetic logic unit

    CSR
        Control and status register

    GPR
        General purpose register

    PMP
        Physical memory protection

    PMA
        Physical memory attributes

    MMU
        Memory management unit

    NMI
        Non-maskable interrupt

    UVM
        Universal Verification Methodology

    RTL
        Register transfer language

    ECS
        Extension Context Status