
# Discussion

For extension units featuring offloaded memory access instructions (e.g. RVF/D: fld, fsw), a few additional questions are raised.

## Memory Consistency
The `RISC-V Weak Memory Ordering` memory consistency model specifies that code running in a single hart appears to execute in order from the perspective of other memory instructions in the _same_ hart.
From the perspective of another hart, the memory instructions from the first hart may appear to be executed in a different order.
For explicit synchronizeation between harts, the FENCE instruction is provided. [[1]](#1)


RISC-V extensions implemented via external functional units operate on the same hart as the issuing core.
Therefore, offloaded memory access instructions should occur in the issuing core program order.
However, in the current version of our design, there is currently no way to guarantee the order in which the operations are executed.
Memory access ordering is violated.

The following approaches could be consiedered to resolve the Issue:
### Explicit Synchronization via Specialized FENCE Instruction.
Similarly to how synchronization is achieved between harts, we could define a FENCE instruction to explicitly order memory access instructions offloaded to external functional units working on the same hart.
- *+* Simple hardware implementation (potentially)
- *+* Potentially higher performance through more flexible parallel execution
- *-* RISC-V memory consistency model is violated
- *-* Synchronization is responsibility of programmer.

### Enforce Memory Ordering
The memory ordering could be enforced by the offloading mechanism itself.
Memory operations should be identified early on in the accelerator adapter module, and allowed to be offloaded only if there is no conflicting memory operation in flight.
The adapter keeps track of outstanding memory access instructions.
This mandates a bit more predecoding of offload instructions, to identify such memory operations, a memory access table to keep track of in-flight operations and a mechanism to feed back succeeded memory transactions from the accelerators and the core alike.
The following rules must be enforced:
- A hart may not issue load operations while there is a store operation in  flight.
- A hart may not issue a store operation while there is a load operation in flight.
- A hart may not issue a store operation while there is a store operation in flight.

The following changes would be made to the architecture
- The accelerator predecoder units identify offloaded memory operations.
- The accelerator adapter keeps track of offloaded memory operations:
  - While any load operation is in flight, new store operations issued from the core are to be stalled. (both Core-internal and offloaded stores)
  - Only one store operation may be in flight at any given time.
    While a store operation is under way, no new memory operation may execute (load or store).
- The accelerator subsystem needs to inform the accelerator adapter of its memory operation status. Two solutions come to mind:
  - Each accelerator capable of performing memory operations maintains a dedicated line for loads and stores respectively, informing the adapter about outstanding operations.
    While this is a minimum-latency solution, as the information for completing a memory operation is transmitted in a dedicated line, it complicates the RTL architecture considerably by introducing a new communication protocol.
  - A new response format may be defined for memory operation responses and sent accross the existing C-interface.
    Memory operation responses would not be forwarded to the offloading core, but change the state of the memory ordering mechanism in the accelerator adapter.
- The offloading CPU core must include provisions to stall upon encountering an internal memory operation, if do instructed by the accelerator adapter.

This scheme seems to be very complicated to implement and come at a considerable overhead.
However, it has several advantages over explicit synchronization:
- *+* RISC-V memory consistency model is respected
- *+* Operation is transparent to programmer
- *-* Additional latency + potentially hardware overhead.

## Physical Memory Protection (PMP) / Physical Memory Attributes (PMA)
For all memory operations, PMP/PMA checks must be performed.
For offloaded memory operations, this poses a problem in the current implementation specification, as memory operations are not known to the adapter or the offloading core.
Two schemes to implement PMP/PMA checks are possible
- Expose PMP/PMA configurations from offloading core to all external units capable of performing offloaded memory operations.
  This possibility is easily integrated into the existing specification of the REI, as any responsibilty for PMP checks are offloaded to the accelerator subsystem.
  However, this scheme poses additional challenges:
    - How to handle PMP reconfigurations, with in-flight memory operations?
    - According to the risc-v privileged spec [[1]](#1), PMP violations are to be always trapped precisely and PMA access faults are strongly recommended to do so.
      Implementing precise exceptions upon fails detected in external accelerator units very hard to do.
e   - PMP is an expensive structure.
      Duplicating in each accelerator unit may not be practical.
- Perform PMP/PMA checks prior to instruction offloading.
  The accelerator adapter may perform some predecoding to identify load/store instructions, and provide the core with the memory address to perform PMP/PMA checks.
  The overhead for predecoding memory operations in the attached predecoders may already become neccessary to enforce memory ordering as detailed above.
  The complexity overhead on the adapter side could therefore be somewhat limited:
    - In addtition to identifying offloaded memory operations, provisions must be taken to avoid offloading instructions that fail the issuing core's PMP/PMA configuration.
  On the core side, the following requirements arise:
    - Check externally supplied memory addresses for PMP/PMA violations
    - Raise exception, if offloaded instructions are identified as memory operations by adapter and violate PMP/PMA config.

The overall area overhead of the second method quite probably is lower than the former, as expensive PMP structures do not have to be duplicated.


## Error Response
The interconnect response channel carries an error flag signal.
However, the action to be taken by an offloading core upon encounering an accelerator error condition (and what those error conditions might be) has not yet been defined.


## References
<a id="1">[1]</a>
[RISC-V Instruction Set Manual Volume I: UserLEvel ISA document version 20190608-Base-Ratified (June 8 2019)](https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMFDQC-and-Priv-v1.11/riscv-privileged-20190608.pdf)
