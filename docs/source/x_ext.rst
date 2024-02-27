.. _x_ext:

eXtension Interface
===================

The eXtension interface enables extending |processor| with (custom or standardized) instructions without the need to change the  :term:`RTL`
of |processor| itself. Extensions can be provided in separate modules external to |processor| and are integrated
at system level by connecting them to the eXtension interface.

The eXtension interface provides low latency (tightly integrated) read and write access to the |processor| register file.
All opcodes which are not used (i.e. considered to be invalid) by |processor| can be used for extensions. It is recommended
however that custom instructions do not use opcodes that are reserved/used by RISC-V International.

The eXtension interface enables extension of |processor| with:

* Custom :term:`ALU` type instructions.
* Custom :term:`CSRs<CSR>` and related instructions.

.. only:: MemoryIf

  If the memory interface is supported the eXtension interface enables in addition:

  * Custom load/store type instructions.

Control-Transfer type instructions (e.g. branches and jumps) are not supported via the eXtension interface.

CV-X-IF
----------

The terminology ``eXtension interface`` and ``CV-X-IF`` are used interchangeably.

Parameters
----------

The CV-X-IF specification contains the following parameters:

.. table:: Interface parameters
  :name: Interface parameters
  :class: no-scrollbar-table
  :widths: 30 15 10 45

  +------------------------------+------------------------+---------------+--------------------------------------------------------------------+
  | Name                         | Type/Range             | Default       | Description                                                        |
  +==============================+========================+===============+====================================================================+
  | ``X_NUM_RS``                 | int unsigned (2..3)    | 2             | Number of register file read ports that can be used by the         |
  |                              |                        |               | eXtension interface.                                               |
  +------------------------------+------------------------+---------------+--------------------------------------------------------------------+
  | ``X_ID_WIDTH``               | int unsigned (3..32)   | 4             | Identification (``id``) width for the eXtension interface.         |
  +------------------------------+------------------------+---------------+--------------------------------------------------------------------+
  | ``X_RFR_WIDTH``              | int unsigned (32, 64)  | 32            | Register file read access width for the eXtension interface.       |
  |                              |                        |               | Must be at least XLEN. If XLEN = 32, then the legal values are 32  |
  |                              |                        |               | and 64 (e.g. for RV32P). If XLEN = 64, then the legal value is     |
  |                              |                        |               | (only) 64.                                                         |
  +------------------------------+------------------------+---------------+--------------------------------------------------------------------+
  | ``X_RFW_WIDTH``              | int unsigned (32, 64)  | 32            | Register file write access width for the eXtension interface.      |
  |                              |                        |               | Must be at least XLEN. If XLEN = 32, then the legal values are 32  |
  |                              |                        |               | and 64 (e.g. for RV32D). If XLEN = 64, then the legal value is     |
  |                              |                        |               | (only) 64.                                                         |
  +------------------------------+------------------------+---------------+--------------------------------------------------------------------+
  | ``X_NUM_HARTS``              | int unsigned           | 1             | Number of harts (hardware threads) associated with the interface.  |
  |                              | (1..2^MXLEN)           |               | The |processor| determines the legal values for this parameter.    |
  +------------------------------+------------------------+---------------+--------------------------------------------------------------------+
  | ``X_HARTID_WIDTH``           | int unsigned           | 1             | Width of ``hartid`` signals.                                       |
  |                              | (1..MXLEN)             |               | Must be at least 1. Limited by the RISC-V privileged specification |
  |                              |                        |               | to MXLEN.                                                          |
  |                              |                        |               | The |processor| determines the legal values for this parameter.    |
  +------------------------------+------------------------+---------------+--------------------------------------------------------------------+
  | ``X_MISA``                   | logic [25:0]           | 32'b0         | MISA extensions implemented on the eXtension interface.            |
  |                              |                        |               | The |processor| determines the legal values for this parameter.    |
  +------------------------------+------------------------+---------------+--------------------------------------------------------------------+
  | ``X_ECS_XS``                 | logic [1:0]            | 2'b0          | Initial value for ``mstatus.XS``.                                  |
  +------------------------------+------------------------+---------------+--------------------------------------------------------------------+
  | ``X_DUALREAD``               | int unsigned (0..3)    | 0             | Is dual read supported? 0: No, 1: Yes, for ``rs1``,                |
  |                              |                        |               | 2: Yes, for ``rs1`` - ``rs2``, 3: Yes, for ``rs1`` - ``rs3``.      |
  |                              |                        |               | Legal values are determined by the |processor|.                    |
  +------------------------------+------------------------+---------------+--------------------------------------------------------------------+
  | ``X_DUALWRITE``              | int unsigned (0..1)    | 0             | Is dual write supported? 0: No, 1: Yes.                            |
  |                              |                        |               | Legal values are determined by the |processor|.                    |
  +------------------------------+------------------------+---------------+--------------------------------------------------------------------+
  | ``X_ISSUE_REGISTER_SPLIT``   | int unsigned (0..1)    | 0             | Does the interface pipeline register interface? 0: No, 1: Yes.     |
  |                              |                        |               | Legal values are determined by the |processor|.                    |
  |                              |                        |               | If 1, registers are provided after the issue of the instruction.   |
  |                              |                        |               | If 0, registers are provided at the same time as issue.            |
  +------------------------------+------------------------+---------------+--------------------------------------------------------------------+

The |processor| shall set the ``misa.Extensions`` field to a value that is the result of an or operation of its own Extensions and the ``X_MISA`` parameter.
Not all bits of ``misa.Extensions`` will be legal for a coprocessor to set, e.g. if this extension is already implemented in the |processor| or if it is an extension not possible to implement as part of a coprocessor like privileged extensions.

.. only:: MemoryIf

  The memory interface contains the following parameters:

  .. table:: Memory Interface parameters
    :name: Memory Interface parameters
    :class: no-scrollbar-table
    :widths: 30 15 10 45

    +------------------------------+------------------------+---------------+--------------------------------------------------------------------+
    | Name                         | Type/Range             | Default       | Description                                                        |
    +==============================+========================+===============+====================================================================+
    | ``X_MEM_WIDTH``              | int unsigned (32, 64,  | 32            | Memory access width for loads/stores via the eXtension interface.  |
    |                              | 128, 256)              |               |                                                                    |
    +------------------------------+------------------------+---------------+--------------------------------------------------------------------+

.. note::

   A |processor| shall clearly document which ``X_MISA`` values it can support and there is no requirement that a |processor| can support
   all possible ``X_MISA`` values. For example, if a |processor| only supports machine mode, then it is not reasonable to expect that the
   |processor| will additionally support user mode by just setting the ``X_MISA[20]`` (``U`` bit) to 1.

Additionally, the following type definitions are defined to improve readability of the specification and ensure consistency between the interfaces:

.. table:: Interface type definitions
  :name: Interface type definitions
  :class: no-scrollbar-table
  :widths: 20 30 50

  +------------------------------------------+----------------------------------------+--------------------------------------------------------------------+
  | Name                                     | Definition                             | Description                                                        |
  +==========================================+========================================+====================================================================+
  | .. _readregflags:                        | logic [X_NUM_RS+X_DUALREAD-1:0]        | Vector with a flag per possible source register.                   |
  |                                          |                                        | This depends upon the number of                                    |
  | ``readregflags_t``                       |                                        | read ports and their ability to read register pairs.               |
  |                                          |                                        | The bit positions map to registers as follows:                     |
  |                                          |                                        | Low indices correspond to low operand numbers, and the even part   |
  |                                          |                                        | of the pair has the lower index than the odd one.                  |
  +------------------------------------------+----------------------------------------+--------------------------------------------------------------------+
  | .. _writeregflags:                       | logic [X_DUALWRITE:0]                  | Bit vector indicating destination registers for write back.        |
  |                                          |                                        | The width depends on the ability to perform dual write.            |
  | ``writeregflags_t``                      |                                        | If ``X_DUALWRITE`` = 0, this signal is a single bit.               |
  |                                          |                                        | Bit 1 may only be set when bit 0 is also set.                      |
  |                                          |                                        | In this case, the vector indicates that a register pair is used.   |
  +------------------------------------------+----------------------------------------+--------------------------------------------------------------------+
  | .. _mode:                                | logic [X_NUM_RS-1:0][X_RFR_WIDTH-1:0]  | Privilege level                                                    |
  |                                          |                                        | (2'b00 = User, 2'b01 = Supervisor, 2'b10 = Reserved,               |
  | ``mode_t``                               |                                        | 2'b11 = Machine).                                                  |
  +------------------------------------------+----------------------------------------+--------------------------------------------------------------------+
  | .. _id:                                  | logic [X_ID_WIDTH-1:0]                 | Identification of the offloaded instruction.                       |
  |                                          |                                        | See `Identification`_ for details on the identifiers               |
  | ``id_t``                                 |                                        |                                                                    |
  +------------------------------------------+----------------------------------------+--------------------------------------------------------------------+
  | .. _hartid:                              | logic [X_HARTID_WIDTH-1:0]             | Identification of the hart offloading the instruction.             |
  |                                          |                                        | Only relevant in multi-hart systems. Hart IDs are not required to  |
  | ``hartid_t``                             |                                        | to be numbered continuously.                                       |
  |                                          |                                        | The hart ID would usually correspond to ``mhartid``, but it is not |
  |                                          |                                        | required to do so.                                                 |
  +------------------------------------------+----------------------------------------+--------------------------------------------------------------------+

Major features
--------------

The major features of CV-X-IF are:

* Minimal requirements on extension instruction encoding.

  If an extension instruction relies on reading from or writing to the core's general purpose register file, then the standard
  RISC-V bitfield locations for rs1, rs2, rs3, rd as used for non-compressed instructions ([RISC-V-UNPRIV]_) must be used.
  Bitfields for unused read or write operands can be fully repurposed. Extension instructions can either use the compressed
  or uncompressed instruction format. For offloading compressed instructions the |coprocessor| must provide the core with
  the related non-compressed instructions.

* Support for dual writeback instructions (optional, based on ``X_DUALWRITE``).

  CV-X-IF optionally supports implementation of (custom or standardized) :term:`ISA` extensions mandating dual register file writebacks. Dual writeback
  is supported for even-odd register pairs (``Xn`` and ``Xn+1`` with ``n`` being an even number extracted from instruction bits ``[11:7]``).

  Dual register file writeback is only supported for ``XLEN`` = 32.

* Support for dual read instructions (per source operand) (optional, based on ``X_DUALREAD``).

  CV-X-IF optionally supports implementation of (custom or standardized) :term:`ISA` extensions mandating dual register file reads. Dual read
  is supported for even-odd register pairs (``Xn`` and ``Xn+1``, with ``n`` being an even number extracted from instruction bits ``[19:15]``),
  ``[24:20]`` and ``[31:27]`` (i.e. ``rs1``, ``rs2`` and ``rs3``). Dual read can therefore provide up to six 32-bit operands
  per instruction.

  When a dual read is performed with ``n`` = 0, the entire operand is 0, i.e. ``x1`` shall not need to be accessed by the |processor|.

  Dual register file read is only supported for XLEN = 32.

* Support for ternary operations.

  CV-X-IF optionally supports :term:`ISA` extensions implementing instructions which use three source operands.
  Ternary instructions must be encoded in the R4-type instruction format defined by [RISC-V-UNPRIV]_.

* Support for instruction speculation.

  CV-X-IF indicates whether offloaded instructions are allowed to be committed (or should be killed).

CV-X-IF consists of the following interfaces:

* **Compressed interface**. Signaling of compressed instruction to be offloaded.
* **Issue (request/response) interface**. Signaling of the uncompressed instruction to be offloaded.
* **Register interface**. Signaling of :term:`GPRs<GPR>` and :term:`CSRs<CSR>`.
* **Commit interface**. Signaling of control signals related to whether instructions can be committed or should be killed.
* **Result interface**. Signaling of the instruction result(s).

.. only:: MemoryIf

  In addition, the following interfaces are added to CV-X-IF if the memory interface is used:

  * **Memory (request/response) interface**. Signaling of load/store related signals (i.e. its transaction request signals). This interface is optional.
  * **Memory result interface**. Signaling of load/store related signals (i.e. its transaction result signals). This interface is optional.

Operating principle
-------------------

|processor| will attempt to offload every (compressed or non-compressed) instruction that it does not recognize as a legal instruction itself.
In case of a compressed instruction the |coprocessor| must first provide the core with a matching uncompressed (i.e. 32-bit) instruction using the compressed interface.
This non-compressed instruction is then attempted for offload via the issue interface.

Offloading of the (non-compressed, 32-bit) instructions happens via the issue interface.
The external |coprocessor| can decide to accept or reject the instruction offload. In case of acceptation the |coprocessor|
will further handle the instruction. In case of rejection the core will raise an illegal instruction exception.
The core provides the required register file operand(s) to the |coprocessor| via the register interface.
If an offloaded instruction uses any of the register file sources ``rs1``, ``rs2`` or ``rs3``, then these are always encoded in instruction bits ``[19:15]``,
``[24:20]`` and ``[31:27]`` respectively. The |coprocessor| only needs to wait for the register file operands that a specific instruction actually uses.
The |coprocessor| informs the core to which register(s) in the register file it will writeback.
The |processor| uses this information to track data dependencies between instructions.

.. only:: MemoryIf

  The |coprocessor| informs the core whether an accepted offloaded instruction is a load/store.
  |processor| uses this information to reserve the load/store unit for that instruction.

Offloaded instructions are speculative; |processor| has not necessarily committed to them yet and might decide to kill them (e.g.
because they are in the shadow of a taken branch or because they are flushed due to an exception in an earlier instruction). Via the commit interface the
core will inform the |coprocessor| about whether an offloaded instruction will either need to be killed or whether the core will guarantee that the instruction
is no longer speculative and is allowed to be committed.

.. only:: MemoryIf

  In case an accepted offloaded instruction is a load or store, then the |coprocessor| will use the load/store unit(s) in |processor| to actually perform the load
  or store. The |coprocessor| provides the memory request transaction details (e.g. virtual address, write data, etc.) via the memory request interface and |processor|
  will use its :term:`PMP`/:term:`PMA` to check if the load or store is actually allowed, and if so, will use its bus interface(s) to perform the required memory transaction and
  provide the result (e.g. load data and/or fault status) back to the |coprocessor| via the memory result interface.

The final result of an accepted offloaded instruction can be written back into the |coprocessor| itself or into the |processor|'s register file. Either way, the
result interface is used to signal to the |processor| that the instruction has completed. Apart from a possible writeback into the register file, the result
interface transaction is for example used in the core to increment the ``minstret`` :term:`CSR`, to implement the fence instructions and to judge if instructions
before a ``WFI`` instruction have fully completed (so that sleep mode can be entered if needed).

In short: From a functional perspective it should not matter whether an instruction is handled inside the |processor| or inside a |coprocessor|. In both cases
the instructions need to obey the same instruction dependency rules, memory consistency rules, load/store address checks, fences, etc.

Interfaces
----------

This section describes the interfaces of CV-X-IF. Port directions are described as seen from the perspective of the |processor|.
The |coprocessor| will have opposite pin directions.
Stated signals names are not mandatory, but it is highly recommended to at least include the stated names as part of actual signal names. It is for example allowed to add prefixes and/or postfixes (e.g. ``x_`` prefix or ``_i``, ``_o`` postfixes) or to use different capitalization. A name mapping should be provided if non obvious renaming is applied.

Identification
~~~~~~~~~~~~~~

Most interfaces of CV-X-IF all use a signal called ``id``, which serves as a unique identification number for offloaded instructions.
The same ``id`` value shall be used for all transaction packets on all interfaces that logically relate to the same instruction.
An ``id`` value can be reused after an earlier instruction related to the same ``id`` value is no longer consider in-flight.
The ``id`` values for in-flight offloaded instructions are required to be unique.
The ``id`` values are required to be incremental from one issue transaction to the next.
The increment may be greater than one.
If the next ``id`` would be greater than the maximum value (``2**X_ID_WIDTH - 1``), the value of ``id`` wraps.

``id`` values can only be introduced by the issue interface.

An ``id`` becomes in-flight in the first cycle that ``issue_valid`` is 1 for that ``id``.

An ``id`` ends being in-flight when one of the following scenarios apply:

* the corresponding issue request transaction is retracted.
* the corresponding issue request transaction is not accepted and the corresponding commit handshake has been performed.
* the corresponding result transaction has been performed.

.. only:: MemoryIf

  * the corresponding commit transaction killed the offloaded instruction and no corresponding memory request transaction and/or corresponding memory result transactions is in progress or still needs to be performed.

For the purpose of relative identification, an instruction is considered to be preceding another instruction, if it was accepted in an issue transaction at an earlier time.
The other instruction is thus succeeding the earlier one.

Multiple Harts
~~~~~~~~~~~~~~

The interface can be used in systems with multiple harts (hardware threads).
This includes scenarios with multiple |processors| and multi-threaded implementations of |processors|.
RISC-V distinguishes between harts using ``hartid``, which we also introduce to the interface.
It is required to identify the source of the offloaded instruction, as multiple harts might be able to offload via a shared interface.
No duplicates of the combination of ``hartid`` and ``id`` may be in flight at any time within one instance of the interface.
Any state within the |coprocessor| (e.g. custom :term:`CSRs<CSR>`) must be duplicated according to the number of harts (indicated by the ``X_NUM_HARTS`` parameter).
Execution units may be shared among threads of the |coprocessor|, and conflicts around such resources must be managed by the |coprocessor|.

.. note::
  The interface can be used in scenarios where the |processor| is superscalar, i.e. it can issue more than one instruction per cycle.
  In such scenarios, the |coprocessor| is usually required to also be able to accept more than one instruction per cycle.
  Our expectation is that implementers will duplicate the interface according to the issue width.

Compressed interface
~~~~~~~~~~~~~~~~~~~~
:numref:`Compressed interface signals` describes the compressed interface signals.

.. table:: Compressed interface signals
  :name: Compressed interface signals
  :class: no-scrollbar-table
  :widths: 20 20 10 50

  +---------------------------+---------------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | Signal                    | Type                | Direction       | Description                                                                                                                  |
  |                           |                     | (|processor|)   |                                                                                                                              |
  +===========================+=====================+=================+==============================================================================================================================+
  | ``compressed_valid``      | logic               | output          | Compressed request valid. Request to uncompress a compressed instruction.                                                    |
  +---------------------------+---------------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``compressed_ready``      | logic               | input           | Compressed request ready. The transactions signaled via ``compressed_req`` and ``compressed_resp`` are accepted when         |
  |                           |                     |                 | ``compressed_valid`` and  ``compressed_ready`` are both 1.                                                                   |
  +---------------------------+---------------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``compressed_req``        | x_compressed_req_t  | output          | Compressed request packet.                                                                                                   |
  +---------------------------+---------------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``compressed_resp``       | x_compressed_resp_t | input           | Compressed response packet.                                                                                                  |
  +---------------------------+---------------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+

:numref:`Compressed request type` describes the ``x_compressed_req_t`` type.

.. table:: Compressed request type
  :name: Compressed request type
  :class: no-scrollbar-table
  :widths: 20 20 60

  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+
  | Signal                 | Type                     | Description                                                                                                     |
  +========================+==========================+=================================================================================================================+
  | ``instr``              | logic [15:0]             | Offloaded compressed instruction.                                                                               |
  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``hartid``             | :ref:`hartid_t <hartid>` | Identification of the hart offloading the instruction.                                                          |
  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+

The ``instr[15:0]`` signal is used to signal compressed instructions that are considered illegal by |processor| itself. A |coprocessor| can provide an uncompressed instruction
in response to receiving this.

A compressed request transaction is defined as the combination of all ``compressed_req`` signals during which ``compressed_valid`` is 1 and the ``hartid`` remains unchanged.
A |processor| is allowed to retract its compressed request transaction before it is accepted with ``compressed_ready`` = 1 and it can do so in the following ways:

* Set ``compressed_valid`` = 0.
* Keep ``compressed_valid`` = 1, but change the ``hartid`` signal (and if desired change the other signals in ``compressed_req``).

The signals in ``compressed_req`` are valid when ``compressed_valid`` is 1. These signals remain stable during a compressed request transaction (if ``hartid`` changes while ``compressed_valid`` remains 1,
then a new compressed request transaction started).

:numref:`Compressed response type` describes the ``x_compressed_resp_t`` type.

.. table:: Compressed response type
  :name: Compressed response type
  :class: no-scrollbar-table
  :widths: 20 20 60

  +------------------------+----------------------+-----------------------------------------------------------------------------------------------------------------+
  | Signal                 | Type                 | Description                                                                                                     |
  +========================+======================+=================================================================================================================+
  | ``instr``              | logic [31:0]         | Uncompressed instruction.                                                                                       |
  +------------------------+----------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``accept``             | logic                | Is the offloaded compressed instruction (``id``) accepted by the |coprocessor|?                                 |
  +------------------------+----------------------+-----------------------------------------------------------------------------------------------------------------+

The signals in ``compressed_resp`` are valid when ``compressed_valid`` and ``compressed_ready`` are both 1. There are no stability requirements.

The |processor| will attempt to offload every compressed instruction that it does not recognize as a legal instruction itself. |processor| might also attempt to offload
compressed instructions that it does recognize as legal instructions itself.

The |processor| shall cause an illegal instruction fault when attempting to execute (commit) an instruction that:

* is considered to be valid by the |processor| and accepted by the |coprocessor| (``accept`` = 1).
* is considered neither to be valid by the |processor| nor accepted by the |coprocessor| (``accept`` = 0).

The ``accept`` signal of the *compressed* interface merely indicates that the |coprocessor| accepts the compressed instruction as an instruction that it implements and translates into
its uncompressed counterpart.
Typically an accepted transaction over the compressed interface will be followed by a corresponding transaction over the issue interface, but there is no requirement
on the |processor| to do so (as the instructions offloaded over the compressed interface and issue interface are allowed to be speculative). Only when an ``accept``
is signaled over the *issue* interface, then an instruction is considered *accepted for offload*.

Explicitly, the |coprocessor| shall not execute the instruction after receiving it via the compressed interface.

The |coprocessor| shall not take the ``mstatus`` based extension context status (see ([RISC-V-PRIV]_)) into account when generating the ``accept`` signal on its *compressed* interface (but it shall take
it into account when generating the ``accept`` signal on its *issue* interface).

Issue interface
~~~~~~~~~~~~~~~
:numref:`Issue interface signals` describes the issue interface signals.

.. table:: Issue interface signals
  :name: Issue interface signals
  :class: no-scrollbar-table
  :widths: 20 20 10 50

  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | Signal                    | Type            | Direction       | Description                                                                                                                  |
  |                           |                 | (|processor|)   |                                                                                                                              |
  +===========================+=================+=================+==============================================================================================================================+
  | ``issue_valid``           | logic           | output          | Issue request valid. Indicates that |processor| wants to offload an instruction.                                             |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``issue_ready``           | logic           | input           | Issue request ready. The transaction signaled via ``issue_req`` and ``issue_resp`` is accepted when                          |
  |                           |                 |                 | ``issue_valid`` and  ``issue_ready`` are both 1.                                                                             |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``issue_req``             | x_issue_req_t   | output          | Issue request packet.                                                                                                        |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``issue_resp``            | x_issue_resp_t  | input           | Issue response packet.                                                                                                       |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+

:numref:`Issue request type` describes the ``x_issue_req_t`` type.

.. table:: Issue request type
  :name: Issue request type
  :class: no-scrollbar-table
  :widths: 20 20 60

  +------------------------+----------------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | Signal                 | Type                                   | Description                                                                                                     |
  +========================+========================================+=================================================================================================================+
  | ``instr``              | logic [31:0]                           | Offloaded instruction.                                                                                          |
  +------------------------+----------------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``hartid``             | :ref:`hartid_t <hartid>`               | Identification of the hart offloading the instruction.                                                          |
  +------------------------+----------------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``id``                 | :ref:`id_t <id>`                       | Identification of the offloaded instruction.                                                                    |
  |                        |                                        |                                                                                                                 |
  |                        |                                        |                                                                                                                 |
  +------------------------+----------------------------------------+-----------------------------------------------------------------------------------------------------------------+

An issue request transaction is defined as the combination of all ``issue_req`` signals during which ``issue_valid`` is 1 and the ``hartid`` remains unchanged.
A |processor| is allowed to retract its issue request transaction before it is accepted with ``issue_ready`` = 1 and it can do so in the following ways:

* Set ``issue_valid`` = 0.
* Keep ``issue_valid`` = 1, but change the ``hartid`` signal (and if desired change the other signals in ``issue_req``).

The ``instr``, ``hartid``, and ``id`` signals are valid when ``issue_valid`` is 1.
The ``instr`` signal remains stable during an issue request transaction.

.. only:: MemoryIf

  .. table:: Issue request type extended for Memory Interface
    :name: Issue request type extended for Memory Interface
    :class: no-scrollbar-table
    :widths: 20 20 60

    +------------------------+----------------------------------------+-----------------------------------------------------------------------------------------------------------------+
    | Signal                 | Type                                   | Description                                                                                                     |
    +========================+========================================+=================================================================================================================+
    | ``mode``               | :ref:`mode_t <mode>`                   | Effective privilege level, as used for load and store instructions.                                             |
    +------------------------+----------------------------------------+-----------------------------------------------------------------------------------------------------------------+

  The ``mode`` signal remains stable during an issue request transaction.

  ``mode`` is the effective privilege level as defined in [RISC-V-UNPRIV]_. That means that this already accounts for settings of ``mstatus.MPRV`` = 1.
  As coprocessors must be unprivileged, the mode signal may only be used in memory transactions.

  The ``mode`` signal is valid when ``issue_valid`` is 1.

:numref:`Issue response type` describes the ``x_issue_resp_t`` type.

.. table:: Issue response type
  :name: Issue response type
  :class: no-scrollbar-table
  :widths: 20 20 60

  +------------------------+------------------------+------------------------------------------------------------------------------------------------------------------+
  | Signal                 | Type                   | Description                                                                                                      |
  +========================+========================+==================================================================================================================+
  | ``accept``             | logic                  | Is the offloaded instruction (``id``) accepted by the |coprocessor|?                                             |
  +------------------------+------------------------+------------------------------------------------------------------------------------------------------------------+
  | ``writeback``          | :ref:`writeregflags_t  | Will the |coprocessor| perform a writeback in the core to ``rd``?                                                |
  |                        | <writeregflags>`       | Writeback to ``x0`` or the ``x0``, ``x1`` pair is allowed by the |coprocessor|,                                  |
  |                        |                        | but will be ignored by the |processor|.                                                                          |
  |                        |                        | A |coprocessor| must signal ``writeback`` as 0 for non-accepted instructions.                                    |
  |                        |                        | Writeback to a register pair is only allowed if ``X_DUALWRITE`` = 1 and instruction bits ``[11:7]`` are even.    |
  +------------------------+------------------------+------------------------------------------------------------------------------------------------------------------+
  | ``register_read``      | :ref:`readregflags_t   | Will the |coprocessor| perform require specific registers to be read?                                            |
  |                        | <readregflags>`        | A |coprocessor| may only request an odd register of a pair, if it also requests the even register of a pair.     |
  |                        |                        | A |coprocessor| must signal ``register_read`` as 0 for non-accepted instructions.                                |
  +------------------------+------------------------+------------------------------------------------------------------------------------------------------------------+
  | ``ecswrite``           | logic                  | Will the |coprocessor| perform a writeback in the core to ``mstatus.xs``, ``mstatus.fs``, ``mstatus.vs``?        |
  |                        |                        | A |coprocessor| must signal ``ecswrite`` as 0 for non-accepted instructions.                                     |
  +------------------------+------------------------+------------------------------------------------------------------------------------------------------------------+

The core shall attempt to offload instructions via the issue interface for the following two main scenarios:

* The instruction is originally non-compressed and it is not recognized as a valid instruction by the |processor|'s non-compressed instruction decoder.
* The instruction is originally compressed and the |coprocessor| accepted the compressed instruction and provided a 32-bit uncompressed instruction.
  In this case the 32-bit uncompressed instruction will be attempted for offload even if it matches in the |processor|'s non-compressed instruction decoder.

Apart from the above two main scenarios a |processor| may also attempt to offload
(compressed/uncompressed) instructions that it does recognize as legal instructions itself. In case that both the |processor| and the |coprocessor| accept the same instruction as being valid,
the instruction will cause an illegal instruction fault upon execution.

The |processor| shall cause an illegal instruction fault when attempting to execute (commit) an instruction that:

* is considered to be valid by the |processor| and accepted by the |coprocessor| (``accept`` = 1).
* is considered neither to be valid by the |processor| nor accepted by the |coprocessor| (``accept`` = 0).

A |coprocessor| can (only) accept an offloaded instruction when:

* It can handle the instruction (based on decoding ``instr``).
* There are no structural hazards that would prevent execution.

A transaction is considered offloaded/accepted on the positive edge of ``clk`` when ``issue_valid``, ``issue_ready`` are asserted and ``accept`` is 1.
A transaction is considered not offloaded/rejected on the positive edge of ``clk`` when ``issue_valid`` and ``issue_ready`` are asserted while ``accept`` is 0.

The signals in ``issue_resp`` are valid when ``issue_valid`` and ``issue_ready`` are both 1. There are no stability requirements.

.. only:: MemoryIf

  .. table:: Issue response type extended for Memory Interface
    :name: Issue response type extended for Memory Interface
    :class: no-scrollbar-table
    :widths: 20 20 60

    +------------------------+------------------------+------------------------------------------------------------------------------------------------------------------+
    | Signal                 | Type                   | Description                                                                                                      |
    +========================+========================+==================================================================================================================+
    | ``loadstore``          | logic                  | Is the offloaded instruction a load/store instruction?                                                           |
    |                        |                        | A |coprocessor| must signal ``loadstore`` as 0 for non-accepted instructions. (Only) if an instruction is        |
    |                        |                        | accepted with ``loadstore`` is 1 and the instruction is not killed, then the |coprocessor| must perform one or   |
    |                        |                        | more transactions via the memory group interface.                                                                |
    +------------------------+------------------------+------------------------------------------------------------------------------------------------------------------+

  If the memory interface is present, the issue response is extended with the ``loadstore`` signal.

Register interface
~~~~~~~~~~~~~~~~~~
:numref:`Register interface signals` describes the register interface signals.

.. table:: Register interface signals
  :name: Register interface signals
  :class: no-scrollbar-table
  :widths: 20 20 10 50

  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | Signal                    | Type            | Direction       | Description                                                                                                                  |
  |                           |                 | (|processor|)   |                                                                                                                              |
  +===========================+=================+=================+==============================================================================================================================+
  | ``register_valid``        | logic           | output          | Register request valid. Indicates that |processor| provides register contents related to an instruction.                     |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``register_ready``        | logic           | input           | Register request ready. The transaction signaled via ``register_req`` is accepted when                                       |
  |                           |                 |                 | ``register_valid`` and  ``register_ready`` are both 1.                                                                       |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``register``              | x_register_t    | output          | Register packet.                                                                                                             |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+

:numref:`Register type` describes the ``x_register_t`` type.

.. table:: Register type
  :name: Register type
  :class: no-scrollbar-table
  :widths: 20 20 60

  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+
  | Signal                 | Type                     | Description                                                                                                     |
  +========================+==========================+=================================================================================================================+
  | ``hartid``             | :ref:`hartid_t <hartid>` | Identification of the hart offloading the instruction.                                                          |
  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``id``                 | :ref:`id_t <id>`         | Identification of the offloaded instruction.                                                                    |
  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``rs[X_NUM_RS-1:0]``   | logic [X_RFR_WIDTH-1:0]  | Register file source operands for the offloaded instruction.                                                    |
  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``rs_valid``           | :ref:`readregflags_t     | Validity of the register file source operand(s). If register pairs are supported, the validity is signaled for  |
  |                        | <readregflags>`          | each register within the pair individually.                                                                     |
  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``ecs``                | logic [5:0]              | Extension Context Status ({``mstatus.xs``, ``mstatus.fs``, ``mstatus.vs``}).                                    |
  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``ecs_valid``          | logic                    | Validity of the Extension Context Status.                                                                       |
  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+

There are two main scenarios, in how the register interface will be used. They are selected by ``X_ISSUE_REGISTER_SPLIT``:

1. ``X_ISSUE_REGISTER_SPLIT`` = 0: A register transaction can be started in the same clock cycle as the issue transaction (``issue_valid = register_valid``, ``issue_ready = register_ready``, ``issue_req.hartid = register.hartid`` and ``issue_req.id = register.id``).
   In this case, the |processor| will speculatively provide all possible source registers via ``register.rs`` when they become available (signalled via the respective ``rs_valid`` signals).
   The |coprocessor| will delay accepting the instruction until all necessary registers are provided, and only then assert ``issue_ready`` and ``register_ready``.
   The ``rs_valid`` bits are not required to be stable during the transaction.
   Each bit can transition from 0 to 1, but is not allowed to transition back to 0 during a transaction.
   A |coprocessor| is not expected to wait for all ``rs_valid`` bits to be 1, but only for those registers it intends to read.
   The ``rs`` signals are only required to be stable during the part of a transaction in which these signals are considered to be valid.
   The ``ecs_valid`` bit is not required to be stable during the transaction. It can transition from 0 to 1, but is not allowed to transition back to 0 during a transaction.
   The ``ecs`` signal is only required to be stable during the part of a transaction in which this signals is considered to be valid.

2. ``X_ISSUE_REGISTER_SPLIT`` = 1: For a |processor| which splits the issue and register interface into subsequent pipeline stages (e.g. because it has a dedicated read registers (RR) stage), the registers will be provided after the issue transaction completed.
   The |processor| initiates the register transaction once all registers are available.
   If the |coprocessor| is able to accept multiple issue transactions before receiving the registers, the register transaction can occur in a different order.
   This allows the |processor| to reorder instructions based on the availability of operands.
   The |coprocessor| is always expected to be ready to retrieve its operands via the register interface after accepting the issue of an instruction.
   Therefore, ``register_ready`` is tied to 1.
   The ``register_valid`` signal will be 1 for one cycle, and ``rs_valid`` is guaranteed to be equal to the corresponding ``issue_resp.register_read``.
   Thus, a |coprocessor| can ignore ``rs_valid`` in this case and a |processor| may chose to not implement the signal.
   The same applies to the ``ecs`` and ``ecs_valid`` signals.

In both scenarios, the following applies:
The ``hartid``, ``id``, ``ecs_valid`` and ``rs_valid`` signals are valid when ``register_valid`` is 1.
The ``rs`` signal is only considered valid when ``register_valid`` is 1 and the corresponding bit in ``rs_valid`` is 1 as well.
The ``ecs`` signal is only considered valid when ``register_valid`` is 1 and ``ecs_valid`` is 1 as well.

The ``rs[X_NUM_RS-1:0]`` signals provide the register file operand(s) to the |coprocessor|. In case that ``XLEN`` = ``X_RFR_WIDTH``, then the regular register file
operands corresponding to ``rs1``, ``rs2`` or ``rs3`` are provided. In case ``XLEN`` != ``X_RFR_WIDTH`` (i.e. ``XLEN`` = 32 and ``X_RFR_WIDTH`` = 64), then the
``rs[X_NUM_RS-1:0]`` signals provide two 32-bit register file operands per index (corresponding to even/odd register pairs) with the even register specified
in ``rs1``, ``rs2`` or ``rs3``. The register file operand for the even register file index is provided in the lower 32 bits; the register file operand for the
odd register file index is provided in the upper 32 bits. When reading from the ``x0``, ``x1`` pair, then a value of 0 is returned for the entire operand.
The ``X_DUALREAD`` parameter defines whether dual read is supported and for which register file sources it is supported.

The ``ecs`` signal provides the Extension Context Status from the ``mstatus`` :term:`CSR` to the |coprocessor|.

Commit interface
~~~~~~~~~~~~~~~~
:numref:`Commit interface signals` describes the commit interface signals.

.. table:: Commit interface signals
  :name: Commit interface signals
  :class: no-scrollbar-table
  :widths: 20 20 10 50

  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | Signal                    | Type            | Direction       | Description                                                                                                                  |
  |                           |                 | (|processor|)   |                                                                                                                              |
  +===========================+=================+=================+==============================================================================================================================+
  | ``commit_valid``          | logic           | output          | Commit request valid. Indicates that |processor| has valid commit or kill information for an offloaded instruction.          |
  |                           |                 |                 | There is no corresponding ready signal (it is implicit and assumed 1). The |coprocessor| shall be ready                      |
  |                           |                 |                 | to observe the ``commit_valid`` and ``commit_kill`` signals at any time coincident or after an issue transaction             |
  |                           |                 |                 | initiation.                                                                                                                  |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``commit``                | x_commit_t      | output          | Commit packet.                                                                                                               |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+

:numref:`Commit packet type` describes the ``x_commit_t`` type.

.. table:: Commit packet type
  :name: Commit packet type
  :class: no-scrollbar-table
  :widths: 20 20 60

  +--------------------+--------------------------+------------------------------------------------------------------------------------------------------------------------------+
  | Signal             | Type                     | Description                                                                                                                  |
  +====================+==========================+==============================================================================================================================+
  | ``hartid``         | :ref:`hartid_t <hartid>` | Identification of the hart offloading the instruction.                                                                       |
  +--------------------+--------------------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``id``             | :ref:`id_t <id>`         | Identification of the offloaded instruction. Valid when ``commit_valid`` is 1.                                               |
  +--------------------+--------------------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``commit_kill``    | logic                    | If ``commit_valid`` is 1 and ``commit_kill`` is 0,  then the core guarantees that the offloaded instruction (``id``) and any |
  |                    |                          | older (i.e. preceding) instructions are no longer speculative, will not get killed (e.g. due to misspeculation or an         |
  |                    |                          | exception in a preceding instruction), and are allowed to be committed.                                                      |
  |                    |                          | If ``commit_valid`` is 1 and ``commit_kill`` is 1, then the offloaded instruction (``id``) and any newer (i.e. succeeding)   |
  |                    |                          | instructions shall be killed in the |coprocessor| and the |coprocessor| must guarantee that the related instructions do/did  |
  |                    |                          | not change architectural state.                                                                                              |
  +--------------------+--------------------------+------------------------------------------------------------------------------------------------------------------------------+

The ``commit_valid`` signal will be 1 exactly one ``clk`` cycle.
It is not required that a commit transaction is performed for each offloaded instruction individually.
Instructions can be signalled to be non-speculative or to be killed in batch.
E.g. signalling the oldest instruction to be killed is equivalent to requesting a flush of the |coprocessor|.
The first instruction to be considered not-to-be-killed after a commit transaction with ``commit_kill`` as 1,
is at earliest an instruction with successful issue transaction starting at least one clock cycle later.

.. note::

  If an instruction is marked in the |coprocessor| as killed or committed, the |coprocessor| shall ignore any subsequent commit transaction related to that instruction.

.. note::

  A |coprocessor| must be tolerant to any possible ``commit.id``, whether this represents and in-flight instruction or not.
  In this case, the |coprocessor| may still need to process the request by considering the relevant instructions (either preceding or succeeding) as no longer speculative or to be killed.
  This behavior supports scenarios in which more than one |coprocessor| is connected to an issue interface.

A |processor| is required to mark every instruction that has completed the issue transaction as either killed or non-speculative.
This includes accepted (`issue_resp.accept` = 1) and rejected instructions (`issue_resp.accept` = 0).

A |coprocessor| does not have to wait for ``commit_valid`` to
become asserted. It can speculate that an offloaded accepted instruction will not get killed, but in case this speculation turns out to be wrong because the instruction actually did get killed,
then the |coprocessor| must undo any of its internal architectural state changes that are due to the killed instruction.

.. only:: MemoryIf

  A |coprocessor| is allowed to perform speculative memory request transactions, but then it must be aware that |processor| can signal a failure for speculative memory request transactions to
  certain memory regions. A |coprocessor| shall never *initiate* memory request transactions for instructions that have already been killed at least a ``clk`` cycle earlier. If a memory request
  transaction or memory result transaction is already in progress at the time that the |processor| signals ``commit_kill`` = 1, then these transaction(s) will complete as normal (although the
  information contained within the memory response and memory result shall be ignored by the |coprocessor|).

A |coprocessor| is not allowed to perform speculative result transactions and shall therefore never initiate a result transaction for instructions that have not yet received a commit transaction
with ``commit_kill`` = 0. The earliest point at which a |coprocessor| can initiate a result handshake for an instruction is therefore the cycle in which ``commit_valid`` = 1 and ``commit_kill`` = 0
for that instruction.

The signals in ``commit`` are valid when ``commit_valid`` is 1.

Memory (request/response) interface
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. only:: not MemoryIf

  The memory (request/response) interface is not included in this version of the specification

.. only:: MemoryIf

  :numref:`Memory (request/response) interface signals` describes the memory (request/response) interface signals.

  .. table:: Memory (request/response) interface signals
    :name: Memory (request/response) interface signals
    :class: no-scrollbar-table
    :widths: 20 20 10 50

    +---------------------------+-----------------+-----------------+--------------------------------------------------------------------------------------------------------------------------------+
    | Signal                    | Type            | Direction       | Description                                                                                                                    |
    |                           |                 | (|processor|)   |                                                                                                                                |
    +===========================+=================+=================+================================================================================================================================+
    | ``mem_valid``             | logic           | input           | Memory (request/response) valid. Indicates that the |coprocessor| wants to perform a memory transaction for an                 |
    |                           |                 |                 | offloaded instruction.                                                                                                         |
    +---------------------------+-----------------+-----------------+--------------------------------------------------------------------------------------------------------------------------------+
    | ``mem_ready``             | logic           | output          | Memory (request/response) ready. The memory (request/response) signaled via ``mem_req`` is accepted by |processor| when        |
    |                           |                 |                 | ``mem_valid`` and  ``mem_ready`` are both 1.                                                                                   |
    +---------------------------+-----------------+-----------------+--------------------------------------------------------------------------------------------------------------------------------+
    | ``mem_req``               | x_mem_req_t     | input           | Memory request packet.                                                                                                         |
    +---------------------------+-----------------+-----------------+--------------------------------------------------------------------------------------------------------------------------------+
    | ``mem_resp``              | x_mem_resp_t    | output          | Memory response packet. Response to memory request (e.g. :term:`PMA` check response). Note that this is not the memory result. |
    +---------------------------+-----------------+-----------------+--------------------------------------------------------------------------------------------------------------------------------+

  :numref:`Memory request type` describes the ``x_mem_req_t`` type.

  .. table:: Memory request type
    :name: Memory request type
    :class: no-scrollbar-table
    :widths: 20 20 60

    +--------------+----------------------------+-----------------------------------------------------------------------------------------------------------------+
    | Signal       | Type                       | Description                                                                                                     |
    +==============+============================+=================================================================================================================+
    | ``hartid``   | :ref:`hartid_t <hartid>`   | Identification of the hart offloading the instruction.                                                          |
    +--------------+----------------------------+-----------------------------------------------------------------------------------------------------------------+
    | ``id``       | :ref:`id_t <id>`           | Identification of the offloaded instruction.                                                                    |
    +--------------+----------------------------+-----------------------------------------------------------------------------------------------------------------+
    | ``addr``     | logic [31:0]               | Virtual address of the memory transaction.                                                                      |
    +--------------+----------------------------+-----------------------------------------------------------------------------------------------------------------+
    | ``mode``     | :ref:`mode_t <mode>`       | Effective privilege level                                                                                       |
    +--------------+----------------------------+-----------------------------------------------------------------------------------------------------------------+
    | ``we``       | logic                      | Write enable of the memory transaction.                                                                         |
    +--------------+----------------------------+-----------------------------------------------------------------------------------------------------------------+
    | ``size``     | logic [2:0]                | Size of the memory transaction. 0: byte, 1: 2 bytes (halfword), 2: 4 bytes (word), 3: 8 bytes (doubleword),     |
    |              |                            | 4: 16 bytes, 5: 32 bytes, 6: Reserved, 7: Reserved.                                                             |
    +--------------+----------------------------+-----------------------------------------------------------------------------------------------------------------+
    | ``be``       | logic [X_MEM_WIDTH/8-1:0]  | Byte enables for memory transaction.                                                                            |
    +--------------+----------------------------+-----------------------------------------------------------------------------------------------------------------+
    | ``attr``     | logic [1:0]                | Memory transaction attributes. attr[0] = modifiable (0 = not modifiable, 1 = modifiable).                       |
    |              |                            | attr[1] = unaligned (0 = aligned, 1 = unaligned).                                                               |
    +--------------+----------------------------+-----------------------------------------------------------------------------------------------------------------+
    | ``wdata``    | logic [X_MEM_WIDTH-1:0]    | Write data of a store memory transaction.                                                                       |
    +--------------+----------------------------+-----------------------------------------------------------------------------------------------------------------+
    | ``last``     | logic                      | Is this the last memory transaction for the offloaded instruction?                                              |
    +--------------+----------------------------+-----------------------------------------------------------------------------------------------------------------+
    | ``spec``     | logic                      | Is the memory transaction speculative?                                                                          |
    +--------------+----------------------------+-----------------------------------------------------------------------------------------------------------------+

  The memory request interface can be used by the |coprocessor| to initiate data side memory read or memory write transactions. All memory transactions, no matter if
  they are initiated by |processor| itself or by a |coprocessor| via the memory request interface, are treated equally. Specifically this equal treatment applies to:

  * :term:`PMA` checks and attribution
  * :term:`PMP` usage
  * :term:`MMU` usage
  * Misaligned load/store exception handling
  * Write buffer usage

  As for non-offloaded load or store instructions it is assumed that execute permission is never required for offloaded load or store instructions.
  If desired a |coprocessor| can always avoid performing speculative loads or stores (as indicated by ``spec`` = 1)
  by waiting for the commit interface to signal that the offloaded instruction is no longer speculative before issuing the memory request.

  Whether a load or store is treated as being speculative or not by the |processor| shall only depend on the ``spec`` signal. Specifically, the |processor| shall
  ignore whatever value it might have communicated via ``commit_kill`` with respect to whether it treats a memory request as speculative or not. A |coprocessor|
  is allowed to signal ``spec`` = 1 without taking the commit transaction into account (so for example even after ``commit_kill`` = 0 has already been signaled).

  The ``addr`` signal indicates the (byte) start address of the memory transaction. Transactions on the memory (request/response) interface cannot cross a ``X_MEM_WIDTH`` (bus width) boundary.
  The byte lanes of the data signals (``wdata`` and ``rdata`` of the memory result) (and hence also the bits of the ``be`` signal) are aligned to the width of the memory interface ``X_MEM_WIDTH``.
  The ``be`` signal indicates on what byte lanes to expect valid data for both read and write transactions. ``be[n]`` determines the validity of data bits ``8*N+7:8*N``.
  There are no limitations on the allowed ``be`` values.
  The ``size`` signal indicates the size of the memory transaction. ``size`` shall reflect a naturally aligned range of byte lanes to be used in a transaction.
  The size of a transaction shall not exceed the maximum memory access width (memory bus width) as determined by ``X_MEM_WIDTH``.
  The ``addr`` signal shall be consistent with the ``be`` signal, i.e. if the maximum memory access width (memory bus width) is 2^N bytes (N=2,3,4,5) and the lowest set bit in
  ``be`` is at index IDX, then ``addr[N-1:0]`` shall be at most IDX.

  When for example performing a transaction that uses the middle two bytes on a 32-bit wide memory interface, the following (equivalent) `be``, ``size``, ``addr[1:0]`` combinations can be used:

  * ``be`` = 4'b0110, ``size`` = 3'b010, ``addr[1:0]`` = 2'b00.
  * ``be`` = 4'b0110, ``size`` = 3'b010, ``addr[1:0]`` = 2'b01.

  Note that a word transfer is needed in this example because the two bytes transferred are not halfword aligned.

  Unaligned (i.e. non naturally aligned) transactions are supported over the memory (request/response) interface using the ``be`` signal. Not all unaligned memory operations
  can however be performed as single transactions on the memory (request/response) interface. Specifically if an unaligned memory operation crosses a X_MEM_WIDTH boundary, then it shall
  be broken into multiple transactions on the memory (request/response) interface by the |coprocessor|.

  The ``attr`` signal indicates the attributes of the memory transaction.

  ``attr[0]`` indicates whether the transaction is a modifiable transaction. This bit shall be set if the
  transaction results from modifications already done in the |coprocessor| (e.g. merging, splitting, or using a transaction size larger than strictly needed (without changing the active byte lanes)).
  The |processor| shall check whether a modifiable transaction to the requested
  address is allowed or not (and respond with an appropriate synchronous exception via the memory response interface if needed). An example of a modified transaction is
  performing a (merged) word transaction as opposed of doing four byte transactions (assuming the natively intended memory operations are byte operations).

  ``attr[1]`` indicates whether the natively intended memory operation(s) resulting in this transaction is naturally aligned or not (0: aligned, 1: unaligned).
  In case that an unaligned native memory operation requires multiple memory request interface transactions, then the |coprocessor| is responsible for splitting the unaligned native memory operation
  into multiple transactions on the memory request interface, each of them having both ``attr[0]`` = 1 and ``attr[1]`` = 1.
  The |processor| shall check whether an unaligned transaction to the requested
  address is allowed or not (and respond with an appropriate synchronous exception via the memory response interface if needed).

  .. note::

    Even though the |coprocessor| is allowed, and sometimes even mandated, to split transactions, this does not mean that split transactions will not result in exceptions.
    Whether a split transaction is allowed (and makes it onto the external |processor| bus interface) or will lead to an exception, is determined by the |processor| (e.g. by its :term:`PMA`).
    No matter if the |coprocessor| already split a transaction or not, further splitting might be required within the |processor| itself (depending on whether a transaction
    on the memory (request/response) interface can be handled as single transaction on the |processor|'s native bus interface or not). In general a |processor| is allowed to make any modification
    to a memory (request/response) interface transaction as long as it is in accordance with the modifiable physical memory attribute for the concerned address region.

  A memory request transaction starts in the cycle that ``mem_valid`` = 1 and ends in the cycle that both ``mem_valid`` = 1 and ``mem_ready`` = 1. The signals in ``mem_req`` are
  valid when ``mem_valid`` is 1. The signals in ``mem_req`` shall remain stable during a memory request transaction, except that ``wdata`` is only required to remain stable during
  memory request transactions in which ``we`` is 1.

  A |coprocessor| may issue multiple memory request transactions for an offloaded accepted load/store instruction. The |coprocessor|
  shall signal ``last`` = 0 if it intends to issue following memory request transaction with the same ``id`` and it shall signal
  ``last`` = 1 otherwise. Once a |coprocessor| signals ``last`` = 1 for a memory request transaction it shall not issue further memory
  request transactions for the same combination of ``id`` and ``hartid``.

  Normally a sequence of memory request transactions ends with a
  transaction that has ``last`` = 1. However, if a |coprocessor| receives ``exc`` = 1 or ``dbg`` = 1 via the memory response interface in response to a non-last memory request transaction,
  then it shall issue no further memory request transactions for the same instruction (``hartid`` + ``id``). Similarly, after having received ``commit_kill`` = 1 no further memory request transactions shall
  be issued by a |coprocessor| for the same instruction (``hartid`` + ``id``).

  A |coprocessor| shall never initiate a memory request transaction(s) for offloaded non-accepted instructions.
  A |coprocessor| shall never initiate a memory request transaction(s) for offloaded non-load/store instructions (``loadstore`` = 0).
  A |coprocessor| shall never initiate a non-speculative memory request transaction(s) unless in the same cycle or after the cycle of receiving a commit transaction with ``commit_kill`` = 0.
  A |coprocessor| shall never initiate a speculative memory request transaction(s) on cycles after a cycle in which it receives ``commit_kill`` = 1 via the commit transaction.
  A |coprocessor| shall initiate memory request transaction(s) for offloaded accepted load/store instructions that receive ``commit_kill`` = 0 via the commit transaction.

  A |processor| shall always (eventually) complete any memory request transaction by signaling ``mem_ready`` = 1 (also for transactions that relate to killed instructions).

  :numref:`Memory response type` describes the ``x_mem_resp_t`` type.

  .. table:: Memory response type
    :name: Memory response type
    :class: no-scrollbar-table
    :widths: 20 20 60

    +------------------------+------------------+-----------------------------------------------------------------------------------------------------------------+
    | Signal                 | Type             | Description                                                                                                     |
    +========================+==================+=================================================================================================================+
    | ``exc``                | logic            | Did the memory request cause a synchronous exception?                                                           |
    +------------------------+------------------+-----------------------------------------------------------------------------------------------------------------+
    | ``exccode``            | logic [5:0]      | Exception code.                                                                                                 |
    +------------------------+------------------+-----------------------------------------------------------------------------------------------------------------+
    | ``dbg``                | logic            | Did the memory request cause a debug trigger match with ``mcontrol.timing`` = 0?                                |
    +------------------------+------------------+-----------------------------------------------------------------------------------------------------------------+

  The ``exc`` is used to signal synchronous exceptions resulting from the memory request transaction defined in ``mem_req``.
  The ``dbg`` is used to signal a debug trigger match with ``mcontrol.timing`` = 0 resulting from the memory request transaction defined in ``mem_req``.
  In case of a synchronous exception or debug trigger match with *before* timing no corresponding transaction will be performed over the memory result (``mem_result_valid``) interface.
  A synchronous exception will lead to a trap in |processor| unless the corresponding instruction is killed. ``exccode`` provides the least significant bits of the exception
  code bitfield of the ``mcause`` :term:`CSR`. Similarly a debug trigger match with *before* timing will lead to debug mode entry in |processor| unless the corresponding instruction is killed.

  A |coprocessor| shall take care that an instruction that causes ``exc`` = 1 or ``dbg`` = 1 does not cause (|coprocessor| local) side effects that are prohibited in the context of synchronous
  exceptions or debug trigger match with *before* timing. Furthermore, if a result interface handshake will occur for this same instruction, then the ``exc``, ``exccode``  and ``dbg`` information shall be passed onto that handshake as well. It is the responsibility of the |processor| to make sure that (precise) synchronous exception entry and debug entry with *before* timing
  is achieved (possibly by killing following instructions that either are already offloaded or are in its own pipeline). A |coprocessor| shall not itself use the ``exc`` or ``dbg`` information to
  kill following instructions in its pipeline.

  The signals in ``mem_resp`` are valid when ``mem_valid`` and  ``mem_ready`` are both 1. There are no stability requirements.

  If ``mem_resp`` relates to an instruction that has been killed, then the |processor| is allowed to signal any value in ``mem_resp`` and the |coprocessor| shall ignore the value received via ``mem_resp``.

  The memory response and hence the memory request/response handshake may get delayed in case that the |processor| splits a memory (request/response) interface transaction
  into multiple transactions on its native bus interface.
  Once it is known that the first, or any following, access results in a synchronous exception, the handshake can be performed immediately.
  Otherwise, the handshake is performed only once it is known that none of the split transactions result in a synchronous exception.

  The memory (request/response) interface is optional. If it is included, then the memory result interface shall also be included.

Memory result interface
~~~~~~~~~~~~~~~~~~~~~~~

.. only:: not MemoryIf

  The memory (request/response) interface is not included in this version of the specification

.. only:: MemoryIf

  :numref:`Memory result interface signals` describes the memory result interface signals.

  .. table:: Memory result interface signals
    :name: Memory result interface signals
    :class: no-scrollbar-table
    :widths: 20 20 10 50

    +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
    | Signal                    | Type            | Direction       | Description                                                                                                                  |
    |                           |                 | (|processor|)   |                                                                                                                              |
    +===========================+=================+=================+==============================================================================================================================+
    | ``mem_result_valid``      | logic           | output          | Memory result valid. Indicates that |processor| has a valid memory result for the corresponding memory request.              |
    |                           |                 |                 | There is no corresponding ready signal (it is implicit and assumed 1). The |coprocessor| must be ready to accept             |
    |                           |                 |                 | ``mem_result`` whenever ``mem_result_valid`` is 1.                                                                           |
    +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
    | ``mem_result``            | x_mem_result_t  | output          | Memory result packet.                                                                                                        |
    +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+

  :numref:`Memory result type` describes the ``x_mem_result_t`` type.

  .. table:: Memory result type
    :name: Memory result type
    :class: no-scrollbar-table
    :widths: 20 20 60

    +---------------+---------------------------+-----------------------------------------------------------------------------------------------------------------+
    | Signal        | Type                      | Description                                                                                                     |
    +===============+===========================+=================================================================================================================+
    | ``hartid``    | :ref:`hartid_t <hartid>`  | Identification of the hart offloading the instruction.                                                          |
    +---------------+---------------------------+-----------------------------------------------------------------------------------------------------------------+
    | ``id``        | :ref:`id_t <id>`          | Identification of the offloaded instruction.                                                                    |
    +---------------+---------------------------+-----------------------------------------------------------------------------------------------------------------+
    | ``rdata``     | logic [X_MEM_WIDTH-1:0]   | Read data of a read memory transaction. Only used for reads.                                                    |
    +---------------+---------------------------+-----------------------------------------------------------------------------------------------------------------+
    | ``err``       | logic                     | Did the instruction cause a bus error?                                                                          |
    +---------------+---------------------------+-----------------------------------------------------------------------------------------------------------------+
    | ``dbg``       | logic                     | Did the read data cause a debug trigger match with ``mcontrol.timing`` = 0?                                     |
    +---------------+---------------------------+-----------------------------------------------------------------------------------------------------------------+

  The memory result interface is used to provide a result from |processor| to the |coprocessor| for *every* memory transaction (i.e. for both read and write transactions).
  No memory result transaction is performed for instructions that led to a synchronous exception or debug trigger match with *before* timing as signaled via the memory (request/response) interface.
  Otherwise, one memory result transaction is performed per memory (request/response) transaction (even for killed instructions).

  Memory result transactions are provided by the |processor| in the same order (with matching ``hartid`` and ``id``) as the memory (request/response) transactions are received. The ``err`` signal
  signals whether a bus error occurred. The ``dbg`` signal
  signals whether a debug trigger match with *before* timing occurred ``rdata`` (for a read transaction only).

  A |coprocessor| shall take care that an instruction that causes ``dbg`` = 1 does not cause (|coprocessor| local) side effects that are prohibited in the context of
  debug trigger match with * before* timing. A |coprocessor| is allowed to treat ``err`` = 1 as an imprecise exception (i.e. it is not mandatory to prevent (|coprocessor| local)
  side effects based on the ``err`` signal).
  Furthermore, if a result interface handshake will occur for this same instruction, then the ``err`` and ``dbg`` information shall be passed onto that handshake as well. It is the responsibility of the |processor| to make sure that (precise) debug entry with *before* timing is achieved (possibly by killing following instructions that either are already offloaded or are in its own pipeline).
  Upon receiving ``err`` = 1 via the result interface handshake the |processor| is expected to take action to handle the error.
  The error handling performed by the |processor| is implementation-defined and may include raising an (imprecise) :term:`NMI`.
  A |coprocessor| shall not itself use the ``err`` or ``dbg`` information to kill following instructions in its pipeline.

  If ``mem_result`` relates to an instruction that has been killed, then the |processor| is allowed to signal any value in ``mem_result`` and the |coprocessor| shall ignore the value received via ``mem_result``.

  From a |processor|'s point of view each memory request transaction has an associated memory result transaction (except if a synchronous exception or debug trigger match with *before* timing
  is signaled via the memory (request/response) interface). The same is not true for a |coprocessor| as it can receive
  memory result transactions for instructions that it did not accept and for which it did not issue a memory request transaction. Such memory result transactions shall
  be ignored by a |coprocessor|. In case that a |coprocessor| did issue a memory request transaction, then it is guaranteed to receive a corresponding memory result
  transaction (which it must be ready to accept).

  .. note::

    The above asymmetry can only occur at system level when multiple coprocessors are connected to a processor via some interconnect network. ``CV-X-IF`` in itself
    is a point-to-point connection, but its definition is written with ``CV-X-IF`` interconnect network(s) in mind.

  The signals in ``mem_result`` are valid when ``mem_result_valid`` is 1.

  The memory result interface is optional. If it is included, then the memory (request/response) interface shall also be included.

Result interface
~~~~~~~~~~~~~~~~
:numref:`Result interface signals` describes the result interface signals.

.. table:: Result interface signals
  :name: Result interface signals
  :class: no-scrollbar-table
  :widths: 20 20 10 50

  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | Signal                    | Type            | Direction       | Description                                                                                                                  |
  |                           |                 | (|processor|)   |                                                                                                                              |
  +===========================+=================+=================+==============================================================================================================================+
  | ``result_valid``          | logic           | input           | Result request valid. Indicates that the |coprocessor| has a valid result (write data or exception) for an offloaded         |
  |                           |                 |                 | instruction.                                                                                                                 |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``result_ready``          | logic           | output          | Result request ready. The result signaled via ``result`` is accepted by the core when                                        |
  |                           |                 |                 | ``result_valid`` and  ``result_ready`` are both 1.                                                                           |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``result``                | x_result_t      | input           | Result packet.                                                                                                               |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+

The |coprocessor| shall provide results to the core via the result interface. A |coprocessor| is allowed to provide results to the core in an out of order fashion. A |coprocessor| is only
allowed to provide a result for an instruction once the core has indicated (via the commit interface) that this instruction is allowed to be committed. Each accepted offloaded (committed and not killed) instruction shall
have exactly one result transaction (even if no data needs to be written back to the |processor|'s register file). No result transaction shall be performed for instructions which have not been accepted for offload or
for instructions that have been killed.

:numref:`Result packet type` describes the ``x_result_t`` type.

.. table:: Result packet type
  :name: Result packet type
  :class: no-scrollbar-table
  :widths: 20 20 60

  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | Signal        | Type                            | Description                                                                                                     |
  +===============+=================================+=================================================================================================================+
  | ``hartid``    | :ref:`hartid_t <hartid>`        | Identification of the hart offloading the instruction.                                                          |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``id``        | :ref:`id_t <id>`                | Identification of the offloaded instruction.                                                                    |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``data``      | logic [X_RFW_WIDTH-1:0]         | Register file write data value(s).                                                                              |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``rd``        | logic [4:0]                     | Register file destination address(es).                                                                          |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``we``        | :ref:`writeregflags_t           | Register file write enable(s).                                                                                  |
  |               | <writeregflags>`                |                                                                                                                 |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``ecswe``     | logic [2:0]                     | Write enables for ``mstatus.xs``, ``mstatus.fs``, ``mstatus.vs``.                                               |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``ecsdata``   | logic [5:0]                     | Write data value for {``mstatus.xs``, ``mstatus.fs``, ``mstatus.vs``}.                                          |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+

A result transaction starts in the cycle that ``result_valid`` = 1 and ends in the cycle that both ``result_valid`` = 1 and ``result_ready`` = 1. The signals in ``result`` are
valid when ``result_valid`` is 1. The signals in ``result`` shall remain stable during a result transaction.

.. only:: MemoryIf

  The result interface is extended by the following signals, if the memory interface is present:

  .. table:: Result packet type extended for Memory Interface
    :name: Result packet type extended for Memory Interface
    :class: no-scrollbar-table
    :widths: 20 20 60

    +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
    | Signal        | Type                            | Description                                                                                                     |
    +===============+=================================+=================================================================================================================+
    | ``exc``       | logic                           | Did the instruction cause a synchronous exception?                                                              |
    +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
    | ``exccode``   | logic [5:0]                     | Exception code.                                                                                                 |
    +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
    | ``dbg``       | logic                           | Did the instruction cause a debug trigger match with ``mcontrol.timing`` = 0?                                   |
    +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
    | ``err``       | logic                           | Did the instruction cause a bus error?                                                                          |
    +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+

  The ``exc`` is used to signal synchronous exceptions.
  An exception may only be signalled if a memory transaction resulted in ``mem_resp.exc`` asserted.
  The received ``exccode`` shall be passed unmodified.
  A synchronous exception shall lead to a trap in the |processor| (unless ``dbg`` = 1 at the same time). ``exccode`` provides the least significant bits of the exception
  code bitfield of the ``mcause`` :term:`CSR`. ``we`` shall be driven to 0 by the |coprocessor| for synchronous exceptions.
  The |processor| shall kill potentially already offloaded instructions to guarantee precise exception behavior.

  The ``err`` is used to signal a bus error.
  A bus error shall lead to an (imprecise) :term:`NMI` in the |processor|.

  The ``dbg`` is used to signal a debug trigger match with ``mcontrol.timing`` = 0. This signal is only used to signal debug trigger matches received earlier via
  a corresponding memory (request/response) transaction or memory request transaction.
  The trigger match shall lead to a debug entry  in the |processor|.
  The |processor| shall kill potentially already offloaded instructions to guarantee precise debug entry behavior.

``we`` is 2 bits wide when ``XLEN`` = 32 and ``X_RFW_WIDTH`` = 64, and 1 bit wide otherwise. The |processor| shall ignore writeback to ``x0``.
When a dual writeback is performed to the ``x0``, ``x1`` pair, the entire write shall be ignored, i.e. neither ``x0`` nor ``x1`` shall be written by the |processor|.
For an instruction instance, the ``we`` signal must be the same as ``issue_resp.writeback``.
The |processor| is not required to check that these signals match.

.. note::
  ``issue_resp.writeback`` and ``result.we`` carry the same information.
  Nevertheless, ``result.we`` is provided to simplify the |processor| logic.
  Without this signal, the |processor| would have to look this information up based on the instruction ``id``.

If ``ecswe[2]`` is 1, then the value in ``ecsdata[5:4]`` is written to ``mstatus.xs``.
If ``ecswe[1]`` is 1, then the value in ``ecsdata[3:2]`` is written to ``mstatus.fs``.
If ``ecswe[0]`` is 1, then the value in ``ecsdata[1:0]`` is written to ``mstatus.vs``.
The writes to the stated ``mstatus`` bitfields will take into account any WARL rules that might exist for these bitfields in the |processor|.

Interface dependencies
----------------------

The following rules apply to the relative ordering of the interface handshakes:

* The compressed interface transactions are in program order (possibly a subset) and the |processor| will at least attempt to offload instructions that it does not consider to be valid itself.
* The issue interface transactions are in program order (possibly a subset) and the |processor| will at least attempt to offload instructions that it does not consider to be valid itself.
* Every issue interface transaction has an associated register interface transaction. It is not required for register transactions to be in the same order as the issue transactions.
* Every issue interface transaction (whether accepted or not) has an associated commit interface transaction and both interfaces use a matching transaction ordering.
* If an offloaded instruction is accepted and allowed to commit, then for each such instruction one result transaction must occur via the result interface (even
  if no writeback needs to happen to the core's register file). The transaction ordering on the result interface does not have to correspond to the transaction ordering
  on the issue interface.
* A commit interface handshake cannot be initiated before the corresponding issue interface handshake is initiated. It is allowed to be initiated at the same time or later.

.. only:: MemoryIf

  * If an offloaded instruction is accepted as a ``loadstore`` instruction and not killed, then for each such instruction one or more memory transaction must occur
    via the memory interface. The transaction ordering on the memory interface interface must correspond to the transaction ordering on the issue interface.
  * A memory (request/response) interface handshake cannot be initiated before the corresponding issue interface handshake is initiated. It is allowed to be initiated at the same time or later.
  * Memory result interface transactions cannot be initiated before the corresponding memory request interface handshake is completed. They are allowed to be initiated at the same time as
    or after completion of the memory request interface handshake. Note that a |coprocessor| shall be able to tolerate memory result transactions for which it did not perform the corresponding
    memory request handshake itself.
  * A memory (request/response) interface handshake cannot be initiated for instructions that were killed in an earlier cycle.
  * A memory result interface handshake shall occur for every memory (request/response) interface handshake unless the response has ``exc`` = 1 or ``dbg`` = 1.

* A result interface handshake cannot be initiated before the corresponding issue interface handshake is initiated. It is allowed to be initiated at the same time or later.
* A result interface handshake cannot be initiated before the corresponding commit interface handshake is initiated (and the instruction is allowed to commit). It is allowed to be initiated at the same time or later.

* A result interface handshake cannot be (or have been) initiated for killed instructions.

Handshake rules
---------------

The following handshake pairs exist on the eXtension interface:

* ``compressed_valid`` with ``compressed_ready``.
* ``issue_valid`` with ``issue_ready``.
* ``register_valid`` with ``register_ready``.
* ``commit_valid`` with implicit always ready signal.

.. only:: MemoryIf

  * ``mem_valid`` with ``mem_ready``.
  * ``mem_result_valid`` with implicit always ready signal.

* ``result_valid`` with ``result_ready``.

The only rule related to valid and ready signals is that:

* A transaction is considered accepted on the positive ``clk`` edge when both valid and (implicit or explicit) ready are 1.

Specifically note the following:

* The valid signals are allowed to be retracted by a |processor| (e.g. in case that the related instruction is killed in the |processor|'s pipeline before the corresponding ready is signaled).
* A new transaction can be started by a |processor| by changing the ``id`` signal and keeping the valid signal asserted (thereby possibly terminating a previous transaction before it completed).
* The valid signals are not allowed to be retracted by a |coprocessor| (e.g. once ``result_valid`` is asserted it must remain asserted until the handshake with ``result_ready`` has been performed). A new transaction can therefore not be started by a |coprocessor| by just changing the ``id`` signal and keeping the valid signal asserted if no ready has been received yet for the original transaction. The cycle after receiving the ready signal, a next (back-to-back) transaction is allowed to be started by just keeping the valid signal high and changing the ``id`` to that of the next transaction.
* The ready signals is allowed to be 1 when the corresponding valid signal is not asserted.

Signal dependencies
-------------------

A |processor| shall not have combinatorial paths from its eXtension interface input signals to its eXtension interface output signals, except for the following allowed paths:

* paths from ``result_valid``, ``result`` to ``rs``, ``rs_valid``.

.. only:: MemoryIf

  * paths from ``mem_valid``, ``mem_req`` to ``mem_ready``, ``mem_resp``.

.. note::

   The above implies that the non-compressed instruction ``instr[31:0]`` received via the compressed interface is not allowed
   to combinatorially feed into the issue interface's ``instr[31:0]`` instruction.

A |coprocessor| is allowed (and expected) to have combinatorial paths from its eXtension interface input signals to its eXtension interface output signals. In order to prevent combinatorial loops the following combinatorial paths are not allowed in a |coprocessor|:

* paths from ``rs``, ``rs_valid`` to ``result_valid``, ``result``.

.. only:: MemoryIf

  * paths from ``mem_ready``, ``mem_resp`` to ``mem_valid``, ``mem_req``.

.. note::

   The above implies that a |coprocessor| has a pipeline stage separating the register file operands from its result generating circuit (similar to
   the separation between decode stage and execute stage found in many :term:`CPUs<CPU>`).

.. note::
   As a |processor| is allowed to retract transactions on its compressed and issue interfaces, the ``compressed_ready`` and ``issue_ready`` signals will have to
   depend on signals received from the |processor| in a combinatorial manner (otherwise these ready signals might be signaled for the wrong ``id``).

Handshake dependencies
----------------------

In order to avoid system level deadlock both the |processor| and the |coprocessor| shall obey the following rules:

* The ``valid`` signal of a transaction shall not be dependent on the corresponding ``ready`` signal.
* Transactions related to an earlier part of the instruction flow shall not depend on transactions with the same ``id`` related to a later part of the instruction flow. The instruction flow is defined from earlier to later as follows:

  * compressed transaction
  * issue transaction
  * register transaction
  * commit transaction

  .. only:: MemoryIf

    * memory (request/response) transaction
    * memory result transaction

  * result transaction.
* Transactions with an earlier issued ``id`` shall not depend on transactions with a later issued ``id`` (e.g. a |coprocessor| is not allowed to delay generating ``result_valid`` = 1
  because it first wants to see ``commit_valid`` = 1 for a newer instruction).

.. note::
   The use of the words *depend* and *dependent* relate to logical relationships, which is broader than combinatorial relationships.

Appendix
========

This appendix contains several useful, non-normative pieces of information that help implementing the eXtension Interface.

SystemVerilog example
---------------------
In the ``src`` folder of this project, the file https://github.com/openhwgroup/core-v-xif/blob/main/src/core_v_xif.sv contains a non-normative realization of this specification based on SystemVerilog interfaces.
Of course the use of SystemVerilog (interfaces) is not mandatory.

Coprocessor recommendations
---------------------------

A |coprocessor| is recommended (but not required) to follow the following suggestions to maximize its re-use potential:

* Avoid using opcodes that are reserved or already used by RISC-V International unless for supporting a standard RISC-V extension.
* Make it easy to change opcode assignments such that a |coprocessor| can easily be updated if it conflicts with another |coprocessor|.
* Clearly document the supported and required parameter values.

.. only:: MemoryIf

  * Clearly document the supported and required interfaces.

Timing recommendations
----------------------

The integration of the eXtension interface will vary from |processor| to |processor|, and thus require its own set of timing constraints.

`CV32E40X eXtension timing budget <https://cv32e40x-user-manual.readthedocs.io/en/stable/x_ext.html#timing>`_ shows the recommended timing budgets
for the coprocessor and (optional) interconnect for the case in which a coprocessor is paired with the CV32E40X (https://github.com/openhwgroup/cv32e40x) processor.
As is shown in that timing budget, the coprocessor only receives a small part of the timing budget on the paths through ``xif_issue_if.issue_req.rs*``.
This enables the coprocessor to source its operands directly from the CV32E40X register file bypass network, thereby preventing stall cycles in case an
offloaded instruction depends on the result of a preceding non-offloaded instruction. This implies that, if a coprocessor is intended for pairing with the CV32E40X,
it will be beneficial timing wise if the coprocessor does not directly operate on the ``rs*`` source inputs, but registers them instead. To maximize utilization of a coprocessor with various :term:`CPUs<CPU>`, such registers could be made optional via a parameter.

Verification
------------

A :term:`UVM` agent for the interface was developed for the verification of CVA6.
It can be accessed under `https://github.com/openhwgroup/core-v-verif/tree/master/lib/uvm_agents/uvma_cvxif <https://github.com/openhwgroup/core-v-verif/tree/99b260b036b3c220ab3d405d521f5c710e587e89/lib/uvm_agents/uvma_cvxif>`_.
