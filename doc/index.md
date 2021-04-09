# RISC-V Extension Interface

**Draft Specification Version 0.1**

The RISC-V Extension Interface (REI) defines a unified framework for RISC-V CPU cores to implement ISA extensions in external functional units and to share accelerator- and co-processor structures among multiple cores.

## Background
The different RISC-V cores originally designed and used at IIS (CV32E40P, CVA6, Ibex, Snitch) all feature various, and configurable extensions over the baseline RV32I/RV64I ISA.
Examples include support for the custom Xpulp ISA extensions, standard extensions like B (Bitmanip), M (Integer Multiplication and Division), F (Single-Precision Floating Point) and D (Double-Precision Floating Point).
The integration of these various instructions into the pipeline varies between different implementations.
Some ISA extensions (Xpulp, B, M) are deeply integrated into the core pipeline which complicates verification, debugging, and reduces portability to other designs.
In contrast, some designs implement the F and D extensions outside of the core pipeline (CV32E40P, Snitch) and use a variety of interfaces and interconnects.

The goal of the REI is to reduce the overall divergence between the different cores and provide a generalized infrastructure suitable to implement custom co-processors and ISA extensions.

## Overview
A top-level specification of the operating principle is given [here](operating-principle.md).

The REI aims to provide an entirely accelerator-agnostic instruction offloading mechanism.
The core concept of the REI is to move as much logic required to implement an ISA extension outside of the CPU cores implementing a base instruction set.
No extension-specific changes should be necessary to a CPU core architecture supporting the REI in order to implement new custom extensions.


The REI comprises the following core components
- The [accelerator interconnect module](accelerator-interconnect.md) implements the signal accelerator adapter to accelerator units.
- The [accelerator adapter module](accelerator-adapter.md) implements limited predecoding and book-keeping for offloaded instrucions. It operates in conjunction with the accelerator predecoders.
- The [accelerator predecoder module](accelerator-predecoder.md) is instantiated for each implemented extension and implements decoding of instruction-specific metadata.

The REI defines the following interfaces:
- The [X-Interface](x-interface.md) implements communication between the offloading processor core and the accelerator adapter.
- The [C-interface](c-interface.md) implements communication between the accelerator adapter and connected accelerator units.

## Properties

### Accelerator-Agnostic Instruction Offloading
The REI enables decoupled development of accelerators and CPU cores through a mechanism facilitating accelerator-agnostic instruction offloading.

### Dual-Writeback Instructions
The REI optionally supports implementation of custom ISA extensions mandating dual register writebacks.
In order to accomodate that need we provision the possibility to reserve multiple destination registers for a single offloaded instruction.
For even destination registers other than `X0`,  `Xn` and `Xn+1` are reserved for writeback upon offloading a dual-writeback instruction, where `Xn` denotes the destination register addresss extracted from `instr_data[11:7]`.

### Ternary Operations
The REI optionally supports ISA extensions implementing instructions which use three source operands.
Ternary instructions must be encoded in the R4-type instruction format defined by the RISC-V specification.

### Hierarchical Interconnect
The accelerator interface is designed to enable a number of flexible topologies.
The simplest topology is the direct attachment of one or multiple accelerators to a single CPU core.
The interconnect also supports sharing of accelerators accross multiple cores in a cluster-like topology.
The sharing granularity of accelerators is flexible.
Any number of cores in a cluster can be connected to share a selection of accelerators resulting in a hierarchical interconnect.

### Transaction Ordering
The accelerator interconnect itself does not guarantee any response transaction ordering.
The order in which offload requests are issued is determined by validity of source- and destination registers of the instruction to be offloaded.
The offloading core may provide internal structures to facilitate multiple instructions to be issued independently, resulting in a pseudo multi-issue pipeline.

### Memory Operations
The REI defines two distinct modes of memory access for external accelerator units.
- The internal mode for accessing memories for extension accelerators is through the offloading core's load/store unit.
  For executing offloaded memory operations, control over the offloading core's load/store unit is handed to the accelerator unit.
  Offloaded load and store operations happen directly through the core's memory interface.
- Certain accelerators may implement their own dedicated memory interfaces in order to increase the available memory bandwidth or to enable more independent operation.
  For this purpose, external mode memory operations are defined.

## Interface Subset Naming Convention
The naming scheme to describe the subset of optional features included in a hardware implementation of the REI implementation comprises the following components.

| Component | Description                                   |
| --------- | -----------                                   |
| REIv[X]   | REI Version [X] of the specification draft    |
| XLEN      | Base ISA bit width                            |
| T         | Support for ternary operations                |
| D         | Support for dual-writeback instructions       |
| M         | Support for 'internal mode' memory operations |
| E         | Support for 'external mode' memory operations |

The specification version indicator is separated from the rest of the description string by an underscore (`_`).
For example, a hardware implementation of the spec version 0.1 (this version) based on a 32 bit core supporting ternary operations and internal mode memory operations would be described with `REIv0.1_32TM`.

