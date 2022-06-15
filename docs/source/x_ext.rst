.. _x_ext:

eXtension Interface
===================

The eXtension interface enables extending |processor| with (custom or standardized) instructions without the need to change the RTL
of |processor| itself. Extensions can be provided in separate modules external to |processor| and are integrated
at system level by connecting them to the eXtension interface.

The eXtension interface provides low latency (tightly integrated) read and write access to the |processor| register file.
All opcodes which are not used (i.e. considered to be invalid) by |processor| can be used for extensions. It is recommended
however that custom instructions do not use opcodes that are reserved/used by RISC-V International.

The eXtension interface enables extension of |processor| with:

* Custom ALU type instructions.
* Custom load/store type instructions.
* Custom CSRs and related instructions.

Control-Tranfer type instructions (e.g. branches and jumps) are not supported via the eXtension interface.

CORE-V-XIF
----------

The terminology ``eXtension interface`` and ``CORE-V-XIF`` are used interchangeably.

Parameters
----------

The CORE-V-XIF specification contains the following parameters:

+------------------------------+------------------------+---------------+--------------------------------------------------------------------+
| Name                         | Type/Range             | Default       | Description                                                        |
+==============================+========================+===============+====================================================================+
| ``X_NUM_RS``                 | int unsigned (2..3)    | 2             | Number of register file read ports that can be used by the         |
|                              |                        |               | eXtension interface.                                               |
+------------------------------+------------------------+---------------+--------------------------------------------------------------------+
| ``X_ID_WIDTH``               | int unsigned (3..32)   | 4             | Identification (``id``) width for the eXtension interface.         |
+------------------------------+------------------------+---------------+--------------------------------------------------------------------+
| ``X_MEM_WIDTH``              | int unsigned (32, 64,  | 32            | Memory access width for loads/stores via the eXtension interface.  |
|                              | 128, 256)              |               |                                                                    |
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
| ``X_MISA``                   | logic [31:0]           | 0x0000_0000   | MISA extensions implemented on the eXtension interface.            |
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

.. note::

   A |processor| shall clearly document which ``X_MISA`` values it can support and there is no requirement that a |processor| can support
   all possible ``X_MISA`` values. For example, if a |processor| only supports machine mode, then it is not reasonable to expect that the
   |processor| will additionally support user mode by just setting the ``X_MISA[20]`` (``U`` bit) to 1.

Major features
--------------

The major features of CORE-V-XIF are:

* Minimal requirements on extension instruction encoding.

  If an extension instruction relies on reading from or writing to the core's general purpose register file, then the standard
  RISC-V bitfield locations for rs1, rs2, rs3, rd as used for non-compressed instructions ([RISC-V-UNPRIV]_) must be used.
  Bitfields for unused read or write operands can be fully repurposed. Extension instructions can either use the compressed
  or uncompressed instruction format. For offloading compressed instructions the |coprocessor| must provide the core with
  the related non-compressed instructions.

* Support for dual writeback instructions (optional, based on ``X_DUALWRITE``).

  CORE-V-XIF optionally supports implementation of (custom or standardized) ISA extensions mandating dual register file writebacks. Dual writeback
  is supported for even-odd register pairs (``Xn`` and ``Xn+1`` with ``n`` being an even number extracted from instruction bits ``[11:7]``.

  Dual register file writeback is only supported for ``XLEN`` = 32.

* Support for dual read instructions (per source operand) (optional, based on ``X_DUALREAD``).

  CORE-V-XIF optionally supports implementation of (custom or standardized) ISA extensions mandating dual register file reads. Dual read
  is supported for even-odd register pairs (``Xn`` and ``Xn+1``, with ``n`` being an even number extracted from instruction bits `[19:15]``,
  ``[24:20]`` and ``[31:27]`` (i.e. ``rs1``, ``rs2`` and ``rs3``). Dual read can therefore provide up to six 32-bit operands
  per instruction.

  When a dual read is performed with ``n`` = 0, the entire operand is 0, i.e. ``X1`` shall not need to be accessed by the |processor|.

  Dual register file read is only supported for XLEN = 32.

* Support for ternary operations.

  CORE-V-XIF optionally supports ISA extensions implementing instructions which use three source operands.
  Ternary instructions must be encoded in the R4-type instruction format defined by [RISC-V-UNPRIV]_.

* Support for instruction speculation.

  CORE-V-XIF indicates whether offloaded instructions are allowed to be commited (or should be killed).

CORE-V-XIF consists of six interfaces:

* **Compressed interface**. Signaling of compressed instruction to be offloaded.
* **Issue (request/response) interface**. Signaling of the uncompressed instruction to be offloaded including its register file based operands.
* **Commit interface**. Signaling of control signals related to whether instructions can be committed or should be killed.
* **Memory (request/response) interface**. Signaling of load/store related signals (i.e. its transaction request signals). This interface is optional.
* **Memory result interface**. Signaling of load/store related signals (i.e. its transaction result signals). This interface is optional.
* **Result interface**. Signaling of the instruction result(s).

Operating principle
-------------------

|processor| will attempt to offload every (compressed or non-compressed) instruction that it does not recognize as a legal instruction itself. 
In case of a compressed instruction the |coprocessor| must first provide the core with a matching uncompressed (i.e. 32-bit) instruction using the compressed interface.
This non-compressed instruction is then attempted for offload via the issue interface.

Offloading of the (non-compressed, 32-bit) instructions happens via the issue interface. 
The external |coprocessor| can decide to accept or reject the instruction offload. In case of acceptation the |coprocessor|
will further handle the instruction. In case of rejection the core will raise an illegal instruction exception. 
As part of the issue interface transaction the core provides the instruction and required register file operand(s) to the |coprocessor|. If
an offloaded instruction uses any of the register file sources ``rs1``, ``rs2`` or ``rs3``, then these are always encoded in instruction bits ``[19:15]``,
``[24:20]`` and ``[31:27]`` respectively. The |coprocessor| only needs to wait for the register file operands that a specific instruction actually uses.
The |coprocessor| informs the core whether an accepted offloaded instruction is a load/store, to which register(s) in the register file it will writeback, and
whether the offloaded instruction can potentially cause a synchronous exception. |processor| uses this information to reserve the load/store unit, to track
data dependencies between instructions, and to properly deal with exceptions caused by offloaded instructions.

Offloaded instructions are speculative; |processor| has not necessarily committed to them yet and might decide to kill them (e.g.
because they are in the shadow of a taken branch or because they are flushed due to an exception in an earlier instruction). Via the commit interface the
core will inform the |coprocessor| about whether an offloaded instruction will either need to be killed or whether the core will guarantee that the instruction
is no longer speculative and is allowed to be commited.

In case an accepted offloaded instruction is a load or store, then the |coprocessor| will use the load/store unit(s) in |processor| to actually perform the load
or store. The |coprocessor| provides the memory request transaction details (e.g. virtual address, write data, etc.) via the memory request interface and |processor|
will use its PMP/PMA to check if the load or store is actually allowed, and if so, will use its bus interface(s) to perform the required memory transaction and
provide the result (e.g. load data and/or fault status) back to the |coprocessor| via the memory result interface.

The final result of an accepted offloaded instruction can be written back into the |coprocessor| itself or into the core's register file. Either way, the
result interface is used to signal to the core that the instruction has completed. Apart from a possible writeback into the register file, the result
interface transaction is for example used in the core to increment the ``minstret`` CSR, to implement the fence instructions and to judge if instructions
before a ``WFI`` instruction have fully completed (so that sleep mode can be entered if needed).

In short: From a functional perspective it should not matter whether an instruction is handled inside the core or inside a |coprocessor|. In both cases
the instructions need to obey the same instruction dependency rules, memory consistency rules, load/store address checks, fences, etc.

Interfaces
----------

This section describes the six interfaces of CORE-V-XIF. Port directions are described as seen from the perspective of the |processor|.
The |coprocessor| will have opposite pin directions.
Stated signals names are not mandatory, but it is highly recommended to at least include the stated names as part of actual signal names. It is for example allowed to add prefixes and/or postfixes (e.g. ``x_`` prefix or ``_i``, ``_o`` postfixes) or to use different capitalization. A name mapping should be provided if non obvious renaming is applied.

SystemVerilog example
~~~~~~~~~~~~~~~~~~~~~
The description in this specification is based on SystemVerilog interfaces. Of course the use of SystemVerilog (interfaces) is not mandatory.

A |processor| using the eXtension interface could have the following interface:

.. code-block:: verilog

  module cpu
  (
    // eXtension interface
    if_xif.cpu_compressed       xif_compressed_if,
    if_xif.cpu_issue            xif_issue_if,
    if_xif.cpu_commit           xif_commit_if,
    if_xif.cpu_mem              xif_mem_if,
    if_xif.cpu_mem_result       xif_mem_result_if,
    if_xif.cpu_result           xif_result_if,

    ... // Other ports omitted
  );

A full example of a |processor| with an eXtension interface is the **CV32E40X**, which can be found at https://github.com/openhwgroup/cv32e40x. 

A |coprocessor| using the eXtension interface could have the following interface:

.. code-block:: verilog

  module coproc
  (
    // eXtension interface
    if_xif.coproc_compressed    xif_compressed_if,
    if_xif.coproc_issue         xif_issue_if,
    if_xif.coproc_commit        xif_commit_if,
    if_xif.coproc_mem           xif_mem_if,
    if_xif.coproc_mem_result    xif_mem_result_if,
    if_xif.coproc_result        xif_result_if,

    ... // Other ports omitted
  );

A SystemVerilog interface implementation for CORE-V-XIF could look as follows:

.. code-block:: verilog

  interface if_xif
  #(
    parameter int          X_NUM_RS        =  2,  // Number of register file read ports that can be used by the eXtension interface
    parameter int          X_ID_WIDTH      =  4,  // Identification width for the eXtension interface
    parameter int          X_MEM_WIDTH     =  32, // Maximum memory access width for loads/stores via the eXtension interface
    parameter int          X_RFR_WIDTH     =  32, // Register file read access width for the eXtension interface
    parameter int          X_RFW_WIDTH     =  32, // Register file write access width for the eXtension interface
    parameter logic [31:0] X_MISA          =  '0, // MISA extensions implemented on the eXtension interface
    parameter logic [ 1:0] X_ECS_XS        =  '0, // Default value for ``mstatus.xs``
    parameter int          X_DUALREAD      =  0,  // Dual register file read
    parameter int          X_DUALWRITE     =  0   // Dual register file write
  );

    ... // typedefs omitted

    // Compressed interface
    logic               compressed_valid;
    logic               compressed_ready;
    x_compressed_req_t  compressed_req;
    x_compressed_resp_t compressed_resp;

    // Issue interface
    logic               issue_valid;
    logic               issue_ready;
    x_issue_req_t       issue_req;
    x_issue_resp_t      issue_resp;

    // Commit interface
    logic               commit_valid;
    x_commit_t          commit;

    // Memory (request/response) interface
    logic               mem_valid;
    logic               mem_ready;
    x_mem_req_t         mem_req;
    x_mem_resp_t        mem_resp;

    // Memory result interface
    logic               mem_result_valid;
    x_mem_result_t      mem_result;

    // Result interface
    logic               result_valid;
    logic               result_ready;
    x_result_t          result;

    // Modports
    modport cpu_issue (
      output            issue_valid,
      input             issue_ready,
      output            issue_req,
      input             issue_resp
    );

    modport coproc_issue (
      input             issue_valid,
      output            issue_ready,
      input             issue_req,
      output            issue_resp
    );

    ... // Further modports omitted

  endinterface : if_xif

A full reference implementation of the SystemVerilog interface can be found at https://github.com/openhwgroup/cv32e40x/blob/master/rtl/if_xif.sv.


Identification
~~~~~~~~~~~~~~

The six interfaces of CORE-V-XIF all use a signal called ``id``, which serves as a unique identification number for offloaded instructions.
The same ``id`` value shall be used for all transaction packets on all interfaces that logically relate to the same instruction.
An ``id`` value can be reused after an earlier instruction related to the same ``id`` value is no longer consider in-flight.
The ``id`` values for in-flight offloaded instructions are only required to be unique; they are for example not required to be incremental.

``id`` values can only be introduced by the compressed interface and/or the issue interface.

An ``id`` becomes in-flight via the compressed interface in the first cycle that ``compressed_valid`` is 1 for that ``id`` or
when in the first cycle that ``issue_valid`` is 1 for that ``id`` (only if the same ``id`` was not already in-flight via the
compressed interface).

An ``id`` ends being in-flight when one of the following scenarios apply:

* the corresponding compressed request transaction is retracted.
* the corresponding compressed request transaction is not accepted.
* the corresponding issue request transaction is retracted.
* the corresponding issue request transaction is not accepted and the corresponding commit handshake has been performed.
* the corresponding commit transaction killed the offloaded instruction and no corresponding memory request transaction and/or corresponding memory result transactions is in progress or still needs to be performed.
* the corresponding result transaction has been performed.

Compressed interface
~~~~~~~~~~~~~~~~~~~~
:numref:`Compressed interface signals` describes the compressed interface signals.

.. table:: Compressed interface signals
  :name: Compressed interface signals

  +---------------------------+---------------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | **Signal**                | **Type**            | **Direction**   | **Description**                                                                                                              |
  |                           |                     | (|processor|)   |                                                                                                                              |
  +---------------------------+---------------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
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

  +------------------------+-------------------------+-----------------------------------------------------------------------------------------------------------------+
  | **Signal**             | **Type**                | **Description**                                                                                                 |
  +------------------------+-------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``instr``              | logic [15:0]            | Offloaded compressed instruction.                                                                               |
  +------------------------+-------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``mode``               | logic [1:0]             | Privilege level (2'b00 = User, 2'b01 = Supervisor, 2'b10 = Reserved, 2'b11 = Machine).                          |
  +------------------------+-------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``id``                 | logic [X_ID_WIDTH-1:0]  | Identification number of the offloaded compressed instruction.                                                  |
  +------------------------+-------------------------+-----------------------------------------------------------------------------------------------------------------+

The ``instr[15:0]`` signal is used to signal compressed instructions that are considered illegal by |processor| itself. A |coprocessor| can provide an uncompressed instruction
in response to receiving this.

A compressed request transaction is defined as the combination of all ``compressed_req`` signals during which ``compressed_valid`` is 1 and the ``id`` remains unchanged.
A |processor| is allowed to retract its compressed request transaction before it is accepted with ``compressed_ready`` = 1 and it can do so in the following ways:

* Set ``compressed_valid`` = 0.
* Keep ``compressed_valid`` = 1, but change the ``id`` signal (and if desired change the other signals in ``compressed_req``).

The signals in ``compressed_req`` are valid when ``compressed_valid`` is 1. These signals remain stable during a compressed request transaction (if ``id`` changes while ``compressed_valid`` remains 1,
then a new compressed request transaction started).

:numref:`Compressed response type` describes the ``x_compressed_resp_t`` type.

.. table:: Compressed response type
  :name: Compressed response type

  +------------------------+----------------------+-----------------------------------------------------------------------------------------------------------------+ 
  | **Signal**             | **Type**             | **Description**                                                                                                 | 
  +------------------------+----------------------+-----------------------------------------------------------------------------------------------------------------+ 
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

The |coprocessor| shall not take the ``mstatus`` based extension context status into account when generating the ``accept`` signal on its *compressed* interface (but it shall take
it into account when generating the ``accept`` signal on its *issue* interface).

Issue interface
~~~~~~~~~~~~~~~
:numref:`Issue interface signals` describes the issue interface signals.

.. table:: Issue interface signals
  :name: Issue interface signals

  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | **Signal**                | **Type**        | **Direction**   | **Description**                                                                                                              |
  |                           |                 | (|processor|)   |                                                                                                                              |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
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

  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+
  | **Signal**             | **Type**                 | **Description**                                                                                                 |
  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``instr``              | logic [31:0]             | Offloaded instruction.                                                                                          |
  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``mode``               | logic [1:0]              | Privilege level (2'b00 = User, 2'b01 = Supervisor, 2'b10 = Reserved, 2'b11 = Machine).                          |
  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``id``                 | logic [X_ID_WIDTH-1:0]   | Identification of the offloaded instruction.                                                                    |
  |                        |                          |                                                                                                                 |
  |                        |                          |                                                                                                                 |
  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``rs[X_NUM_RS-1:0]``   | logic [X_RFR_WIDTH-1:0]  | Register file source operands for the offloaded instruction.                                                    |
  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``rs_valid``           | logic [X_NUM_RS-1:0]     | Validity of the register file source operand(s).                                                                |
  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``ecs``                | logic [5:0]              | Extension Context Status ({``mstatus.xs``,``mstatus.fs``,``mstatus.vs``}).                                      |
  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``ecs_valid``          | logic                    | Validity of the Extension Context Status.                                                                       |
  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+

An issue request transaction is defined as the combination of all ``issue_req`` signals during which ``issue_valid`` is 1 and the ``id`` remains unchanged.
A |processor| is allowed to retract its issue request transaction before it is accepted with ``issue_ready`` = 1 and it can do so in the following ways:

* Set ``issue_valid`` = 0.
* Keep ``issue_valid`` = 1, but change the ``id`` signal (and if desired change the other signals in ``issue_req``).

The ``instr``, ``mode``, ``id``,  ``ecs``, ``ecs_valid`` and ``rs_valid`` signals are valid when ``issue_valid`` is 1. 
The ``rs`` signal is only considered valid when ``issue_valid`` is 1 and the corresponding bit in ``rs_valid`` is 1 as well.
The ``ecs`` signal is only considered valid when ``issue_valid`` is 1 and ``ecs_valid`` is 1 as well.

The ``instr`` and ``mode`` signals remain stable during an issue request transaction. The ``rs_valid`` bits are not required to be stable during the transaction. Each bit
can transition from 0 to 1, but is not allowed to transition back to 0 during a transaction. The ``rs`` signals are only required to be stable during the part
of a transaction in which these signals are considered to be valid. The ``ecs_valid`` bit is not required to be stable during the transaction. It can transition from
0 to 1, but is not allowed to transition back to 0 during a transaction. The ``ecs`` signal is only required to be stable during the part of a transaction in which
this signals is considered to be valid.

The ``rs[X_NUM_RS-1:0]`` signals provide the register file operand(s) to the |coprocessor|. In case that ``XLEN`` = ``X_RFR_WIDTH``, then the regular register file
operands corresponding to ``rs1``, ``rs2`` or ``rs3`` are provided. In case ``XLEN`` != ``X_RFR_WIDTH`` (i.e. ``XLEN`` = 32 and ``X_RFR_WIDTH`` = 64), then the
``rs[X_NUM_RS-1:0]`` signals provide two 32-bit register file operands per index (corresponding to even/odd register pairs) with the even register specified
in ``rs1``, ``rs2`` or ``rs3``. The register file operand for the even register file index is provided in the lower 32 bits; the register file operand for the
odd register file index is provided in the upper 32 bits. When reading from the ``X0``, ``X1`` pair, then a value of 0 is returned for the entire operand.
The ``X_DUALREAD`` parameter defines whether dual read is supported and for which register file sources
it is supported.

The ``ecs`` signal provides the Extension Context Status from the ``mstatus`` CSR to the |coprocessor|.

:numref:`Issue response type` describes the ``x_issue_resp_t`` type.

.. table:: Issue response type
  :name: Issue response type

  +------------------------+----------------------+------------------------------------------------------------------------------------------------------------------+
  | **Signal**             | **Type**             | **Description**                                                                                                  |
  +------------------------+----------------------+------------------------------------------------------------------------------------------------------------------+
  | ``accept``             | logic                | Is the offloaded instruction (``id``) accepted by the |coprocessor|?                                             |
  +------------------------+----------------------+------------------------------------------------------------------------------------------------------------------+
  | ``writeback``          | logic                | Will the |coprocessor| perform a writeback in the core to ``rd``?                                                |
  |                        |                      | Writeback to ``X0`` is allowed by the |coprocessor|, but will be ignored by the |processor|.                     |
  |                        |                      | A |coprocessor| must signal ``writeback`` as 0 for non-accepted instructions.                                    |
  +------------------------+----------------------+------------------------------------------------------------------------------------------------------------------+
  | ``dualwrite``          | logic                | Will the |coprocessor| perform a dual writeback in the core to ``rd`` and ``rd+1``?                              |
  |                        |                      | Only allowed if ``X_DUALWRITE`` = 1 and instruction bits ``[11:7]`` are even.                                    |
  |                        |                      | Writeback to the ``X0``, ``X1`` pair is allowed by the |coprocessor|, but will be ignored by the |processor|.    |
  |                        |                      | A |coprocessor| must signal ``dualwrite`` as 0 for non-accepted instructions.                                    |
  +------------------------+----------------------+------------------------------------------------------------------------------------------------------------------+
  | ``dualread``           | logic [2:0]          | Will the |coprocessor| require dual reads from ``rs1\rs2\rs3`` and ``rs1+1\rs2+1\rs3+1``?                        |
  |                        |                      | ``dualread[0]`` = 1 signals that dual read is required from ``rs1`` and ``rs1+1`` (only allowed if               |
  |                        |                      | ``X_DUALREAD`` > 0 and instruction bits ``[19:15]`` are even).                                                   |
  |                        |                      | ``dualread[1]`` = 1 signals that dual read is required from ``rs2`` and ``rs2+1`` (only allowed if               |
  |                        |                      | ``X_DUALREAD`` > 1 and instruction bits ``[24:20]`` are even).                                                   |
  |                        |                      | ``dualread[2]`` = 1 signals that dual read is required from ``rs3`` and ``rs3+1`` (only allowed if               |
  |                        |                      | ``X_DUALREAD`` > 2 and instruction bits ``[31:27]`` are even).                                                   |
  |                        |                      | A |coprocessor| must signal ``dualread`` as 0 for non-accepted instructions.                                     |
  +------------------------+----------------------+------------------------------------------------------------------------------------------------------------------+
  | ``loadstore``          | logic                | Is the offloaded instruction a load/store instruction?                                                           |
  |                        |                      | A |coprocessor| must signal ``loadstore`` as 0 for non-accepted instructions. (Only) if an instruction is        |
  |                        |                      | accepted with ``loadstore`` is 1 and the instruction is not killed, then the |coprocessor| must perform one or   |
  |                        |                      | more transactions via the memory group interface.                                                                |
  +------------------------+----------------------+------------------------------------------------------------------------------------------------------------------+
  | ``ecswrite``           | logic                | Will the |coprocessor| perform a writeback in the core to ``mstatus.xs``, ``mstatus.fs``, ``mstatus.vs``?        |
  |                        |                      | A |coprocessor| must signal ``ecswrite`` as 0 for non-accepted instructions.                                     |
  +------------------------+----------------------+------------------------------------------------------------------------------------------------------------------+
  | ``exc``                | logic                | Can the offloaded instruction possibly cause a synchronous exception in the |coprocessor| itself?                |
  |                        |                      | A |coprocessor| must signal ``exc`` as 0 for non-accepted instructions.                                          |
  +------------------------+----------------------+------------------------------------------------------------------------------------------------------------------+

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
* The required source registers are marked valid by the offloading core  (``issue_valid`` is 1 and required bit(s) ``rs_valid`` are 1).

A transaction is considered offloaded/accepted on the positive edge of ``clk`` when ``issue_valid``, ``issue_ready`` are asserted and ``accept`` is 1.
A transaction is considered not offloaded/rejected on the positive edge of ``clk`` when ``issue_valid`` and ``issue_ready`` are asserted while ``accept`` is 0.

The signals in ``issue_resp`` are valid when ``issue_valid`` and ``issue_ready`` are both 1. There are no stability requirements.

Commit interface
~~~~~~~~~~~~~~~~
:numref:`Commit interface signals` describes the commit interface signals.

.. table:: Commit interface signals
  :name: Commit interface signals

  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | **Signal**                | **Type**        | **Direction**   | **Description**                                                                                                              |
  |                           |                 | (|processor|)   |                                                                                                                              |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``commit_valid``          | logic           | output          | Commit request valid. Indicates that |processor| has valid commit or kill information for an offloaded instruction.          |
  |                           |                 |                 | There is no corresponding ready signal (it is implicit and assumed 1). The |coprocessor| shall be ready                      |
  |                           |                 |                 | to observe the ``commit_valid`` and ``commit_kill`` signals at any time coincident or after an issue transaction             |
  |                           |                 |                 | initiation.                                                                                                                  |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``commit``                | x_commit_t      | output          | Commit packet.                                                                                                               |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+

.. note::

   The |processor| shall perform a commit transaction for every issue transaction, independent of the ``accept`` value of the issue transaction. A |coprocessor| shall ignore the
   ``commit_kill`` signal for instructions that it did not accept. A |processor| can signal either ``commit_kill`` = 0 or ``commit_kill`` = 1 for non-accepted instructions.

:numref:`Commit packet type` describes the ``x_commit_t`` type.

.. table:: Commit packet type
  :name: Commit packet type

  +--------------------+------------------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``id``             | logic [X_ID_WIDTH-1:0] | Identification of the offloaded instruction. Valid when ``commit_valid`` is 1.                                               |
  +--------------------+------------------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``commit_kill``    | logic                  | Shall an offloaded instruction be killed? If ``commit_valid`` is 1 and ``commit_kill`` is 0, then the core guarantees        |
  |                    |                        | that the offloaded instruction (``id``) is no longer speculative, will not get killed (e.g. due to misspeculation or an      |
  |                    |                        | exception in a preceding instruction), and is allowed to be committed. If ``commit_valid`` is 1 and ``commit_kill`` is       |
  |                    |                        | 1, then the offloaded instruction (``id``) shall be killed in the |coprocessor| and the |coprocessor| must guarantee that the|
  |                    |                        | related instruction does/did not change architectural state.                                                                 |
  +--------------------+------------------------+------------------------------------------------------------------------------------------------------------------------------+

The ``commit_valid`` signal will be 1 exactly one ``clk`` cycle for every offloaded instruction by the |coprocessor| (whether accepted or not). The ``id`` value indicates which offloaded
instruction is allowed to be committed or is supposed to be killed.

For each offloaded and accepted instruction the core is guaranteed to (eventually) signal that such an instruction is either no longer speculative and can be committed (``commit_valid`` is 1
and ``commit_kill`` is 0) or that the instruction must be killed (``commit_valid`` is 1 and ``commit_kill`` is 1). 

A |coprocessor| does not have to wait for ``commit_valid`` to
become asserted. It can speculate that an offloaded accepted instruction will not get killed, but in case this speculation turns out to be wrong because the instruction actually did get killed,
then the |coprocessor| must undo any of its internal architectural state changes that are due to the killed instruction. 

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
:numref:`Memory (request/response) interface signals` describes the memory (request/response) interface signals.

.. table:: Memory (request/response) interface signals
  :name: Memory (request/response) interface signals

  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | **Signal**                | **Type**        | **Direction**   | **Description**                                                                                                              |
  |                           |                 | (|processor|)   |                                                                                                                              |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``mem_valid``             | logic           | input           | Memory (request/response) valid. Indicates that the |coprocessor| wants to perform a memory transaction for an               |
  |                           |                 |                 | offloaded instruction.                                                                                                       |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``mem_ready``             | logic           | output          | Memory (request/response) ready. The memory (request/response) signaled via ``mem_req`` is accepted by |processor| when      |
  |                           |                 |                 | ``mem_valid`` and  ``mem_ready`` are both 1.                                                                                 |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``mem_req``               | x_mem_req_t     | input           | Memory request packet.                                                                                                       |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``mem_resp``              | x_mem_resp_t    | output          | Memory response packet. Response to memory request (e.g. PMA check response). Note that this is not the memory result.       |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+

:numref:`Memory request type` describes the ``x_mem_req_t`` type.

.. table:: Memory request type
  :name: Memory request type

  +--------------+----------------------------+-----------------------------------------------------------------------------------------------------------------+
  | **Signal**   | **Type**                   | **Description**                                                                                                 |
  +--------------+----------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``id``       | logic [X_ID_WIDTH-1:0]     | Identification of the offloaded instruction.                                                                    |
  +--------------+----------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``addr``     | logic [31:0]               | Virtual address of the memory transaction.                                                                      |
  +--------------+----------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``mode``     | logic [1:0]                | Privilege level (2'b00 = User, 2'b01 = Supervisor, 2'b10 = Reserved, 2'b11 = Machine).                          |
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

* PMA checks and attribution
* PMU usage
* MMU usage
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

* ``be`` = 4'b0110, ``size`` = 3'b010``, ``addr[1:0]`` = 2'b00.
* ``be`` = 4'b0110, ``size`` = 3'b010``, ``addr[1:0]`` = 2'b01.

Note that a word transfer is needed in this example because the two bytes transfered are not halfword aligned.

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
into multiple transactions on the memory request interface, each of them having both ``attr[0]`` = 1 and ``attr[0]`` = 1.
The |processor| shall check whether an unaligned transaction to the requested
address is allowed or not (and respond with an appropriate synchronous exception via the memory response interface if needed).

.. note::

   Even though the |coprocessor| is allowed, and sometimes even mandated, to split transacations, this does not mean that split transactions will not result in exceptions.
   Whether a split transaction is allowed (and makes it onto the external |processor| bus interface) or will lead to an exception, is determined by the |processor| (e.g. by its PMA).
   No matter if the |coprocessor| already split a transaction or not, further splitting might be required within the |processor| itself (depending on whether a transaction
   on the memory (request/response) interface can be handled as single transaction on the |processor|'s native bus interface or not. In general a |processor| is allowed to make any modification
   to a memory (request/response) interface transaction as long as it is in accordance with the modifiable physical memory attribute for the concerned address region.

A memory request transaction starts in the cycle that ``mem_valid`` = 1 and ends in the cycle that both ``mem_valid`` = 1 and ``mem_ready`` = 1. The signals in ``mem_req`` are
valid when ``mem_valid`` is 1. The signals in ``mem_req`` shall remain stable during a memory request transaction, except that ``wdata`` is only required to remain stable during
memory request transactions in which ``we`` is 1. 

A |coprocessor| may issue multiple memory request transactions for an offloaded accepted load/store instruction. The |coprocessor|
shall signal ``last`` = 0 if it intends to issue following memory request transaction with the same ``id`` and it shall signal
``last`` = 1 otherwise. Once a |coprocessor| signals ``last`` = 1 for a memory request transaction it shall not issue further memory
request transactions for the same ``id``.

Normally a sequence of memory request transactions ends with a
transaction that has ``last`` = 1. However, if a |coprocessor| receives ``exc`` = 1 or ``dbg`` = 1 via the memory response interface in response to a non-last memory request transaction,
then it shall issue no further memory request transactions for the same instruction (``id``). Similarly, after having received `commit_kill`` = 1 no further memory request transactions shall
be issued by a |coprocessor| for the same instruction (``id``).

A |coprocessor| shall never initiate a memory request transaction(s) for offloaded non-accepted instructions.
A |coprocessor| shall never initiate a memory request transaction(s) for offloaded non-load/store instructions (``loadstore`` = 0).
A |coprocessor| shall never initiate a non-speculative memory request transaction(s) unless in the same cycle or after the cycle of receiving a commit transaction with ``commit_kill`` = 0.
A |coprocessor| shall never initiate a speculative memory request transaction(s) on cycles after a cycle in which it receives ``commit_kill`` = 1 via the commit transaction.
A |coprocessor| shall initiate memory request transaction(s) for offloaded accepted load/store instructions that receive ``commit_kill`` = 0 via the commit transaction.

A |processor| shall always (eventually) complete any memory request transaction by signaling ``mem_ready`` = 1 (also for transactions that relate to killed instructions).

:numref:`Memory response type` describes the ``x_mem_resp_t`` type.

.. table:: Memory response type
  :name: Memory response type

  +------------------------+------------------+-----------------------------------------------------------------------------------------------------------------+
  | **Signal**             | **Type**         | **Description**                                                                                                 |
  +------------------------+------------------+-----------------------------------------------------------------------------------------------------------------+
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
code bitfield of the ``mcause`` CSR. Similarly a debug trigger match with *before* timing will lead to debug mode entry in |processor| unless the corresponding instruction is killed.

A |coprocessor| shall take care that an instruction that causes ``exc`` = 1 or ``dbg`` = 1 does not cause (|coprocessor| local) side effects that are prohibited in the context of synchronous
exceptions or debug trigger match with * before* timing. Furthermore, if a result interface handshake will occur for this same instruction, then the ``exc``, ``exccode``  and ``dbg`` information shall be passed onto that handshake as well. It is the responsibility of the |processor| to make sure that (precise) synchronous exception entry and debug entry with *before* timing
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
:numref:`Memory result interface signals` describes the memory result interface signals.

.. table:: Memory result interface signals
  :name: Memory result interface signals

  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | **Signal**                | **Type**        | **Direction**   | **Description**                                                                                                              |
  |                           |                 | (|processor|)   |                                                                                                                              |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``mem_result_valid``      | logic           | output          | Memory result valid. Indicates that |processor| has a valid memory result for the corresponding memory request.              |
  |                           |                 |                 | There is no corresponding ready signal (it is implicit and assumed 1). The |coprocessor| must be ready to accept             |
  |                           |                 |                 | ``mem_result`` whenever ``mem_result_valid`` is 1.                                                                           |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | ``mem_result``            | x_mem_result_t  | output          | Memory result packet.                                                                                                        |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+

:numref:`Memory result type` describes the ``x_mem_result_t`` type.

.. table:: Memory result type
  :name: Memory result type

  +---------------+---------------------------+-----------------------------------------------------------------------------------------------------------------+
  | **Signal**    |          **Type**         | **Description**                                                                                                 |
  +---------------+---------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``id``        | logic [X_ID_WIDTH-1:0]    | Identification of the offloaded instruction.                                                                    |
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

Memory result transactions are provided by the |processor| in the same order (with matching ``id``) as the memory (request/response) transactions are received. The ``err`` signal
signals whether a bus error occurred. The ``dbg`` signal
signals whether a debug trigger match with *before* timing occurred ``rdata`` (for a read transaction only).

A |coprocessor| shall take care that an instruction that causes ``dbg`` = 1 does not cause (|coprocessor| local) side effects that are prohibited in the context of
debug trigger match with * before* timing. A |coprocessor| is allowed to treat ``err`` = 1 as an imprecise exception (i.e. it is not mandatory to prevent (|coprocessor| local)
side effects based on the ``err`` signal).
Furthermore, if a result interface handshake will occur for this same instruction, then the ``err`` and ``dbg`` information shall be passed onto that handshake as well. It is the responsibility of the |processor| to make sure that (precise) debug entry with *before* timing is achieved (possibly by killing following instructions that either are already offloaded or are in its own pipeline). Upon receiving ``err`` = 1 via the result interface handshake the |processor| shall signal an (imprecise) NMI.
A |coprocessor| shall not itself use the ``err`` or ``dbg`` information to kill following instructions in its pipeline.

If ``mem_result`` relates to an instruction that has been killed, then the |processor| is allowed to signal any value in ``mem_result`` and the |coprocessor| shall ignore the value received via ``mem_result``.

From a |processor|'s point of view each memory request transaction has an associated memory result transaction (except if a synchronous exception or debug trigger match with *before* timing
is signaled via the memory (request/response) interface). The same is not true for a |coprocessor| as it can receive
memory result transactions for instructions that it did not accept and for which it did not issue a memory request transaction. Such memory result transactions shall
be ignored by a |coprocessor|. In case that a |coprocessor| did issue a memory request transaction, then it is guaranteed to receive a corresponding memory result
transaction (which it must be ready to accept).

.. note::

   The above asymmetry can only occur at system level when multiple coprocessors are connected to a processor via some interconnect network. ``CORE-V-XIF`` in itself
   is a point-to-point connection, but its definition is written with ``CORE-V-XIF`` interconnect network(s) in mind.

The signals in ``mem_result`` are valid when ``mem_result_valid`` is 1.

The memory result interface is optional. If it is included, then the memory (request/response) interface shall also be included.

Result interface
~~~~~~~~~~~~~~~~
:numref:`Result interface signals` describes the result interface signals.

.. table:: Result interface signals
  :name: Result interface signals

  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
  | **Signal**                | **Type**        | **Direction**   | **Description**                                                                                                              |
  |                           |                 | (|processor|)   |                                                                                                                              |
  +---------------------------+-----------------+-----------------+------------------------------------------------------------------------------------------------------------------------------+
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

  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | **Signal**    | **Type**                        | **Description**                                                                                                 |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``id``        | logic [X_ID_WIDTH-1:0]          | Identification of the offloaded instruction.                                                                    |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``data``      | logic [X_RFW_WIDTH-1:0]         | Register file write data value(s).                                                                              |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``rd``        | logic [4:0]                     | Register file destination address(es).                                                                          |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``we``        | logic [X_RFW_WIDTH/XLEN-1:0]    | Register file write enable(s).                                                                                  |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``ecswe``     | logic [2:0]                     | Write enables for ``mstatus.xs``, ``mstatus.fs``, ``mstatus.vs``.                                               |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``ecsdata``   | logic [5:0]                     | Write data value for {``mstatus.xs``, ``mstatus.fs``, ``mstatus.vs``}.                                          |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``exc``       | logic                           | Did the instruction cause a synchronous exception?                                                              |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``exccode``   | logic [5:0]                     | Exception code.                                                                                                 |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``dbg``       | logic                           | Did the instruction cause a debug trigger match with ``mcontrol.timing`` = 0?                                   |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``err``       | logic                           | Did the instruction cause a bus error?                                                                          |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+

A result transaction starts in the cycle that ``result_valid`` = 1 and ends in the cycle that both ``result_valid`` = 1 and ``result_ready`` = 1. The signals in ``result`` are
valid when ``result_valid`` is 1. The signals in ``result`` shall remain stable during a result transaction, except that ``data`` is only required to remain stable during
result transactions in which ``we`` is not 0.

The ``exc`` is used to signal synchronous exceptions. 
A synchronous exception shall lead to a trap in the |processor| (unless ``dbg`` = 1 at the same time). ``exccode`` provides the least significant bits of the exception
code bitfield of the ``mcause`` CSR. ``we`` shall be driven to 0 by the |coprocessor| for synchronous exceptions.
The |processor| shall kill potentially already offloaded instructions to guarantee precise exception behavior.

The ``err`` is used to signal a bus error.
A bus error shall lead to an (imprecise) NMI in the |processor|.

The ``dbg`` is used to signal a debug trigger match with ``mcontrol.timing`` = 0. This signal is only used to signal debug trigger matches received earlier via
a corresponding memory (request/response) transaction or memory request transaction.
The trigger match shall lead to a debug entry  in the |processor|.
The |processor| shall kill potentially already offloaded instructions to guarantee precise debug entry behavior.

``we`` is 2 bits wide when ``XLEN`` = 32 and ``X_RFW_WIDTH`` = 64, and 1 bit wide otherwise. If ``we`` is 2 bits wide, then ``we[1]`` is only allowed to be 1 if ``we[0]`` is 1 as well (i.e. for
dual writeback). The |processor| shall ignore writeback to ``X0``.  When a dual writeback is performed to the ``X0``, ``X1`` pair, the entire write shall be ignored, i.e. neither ``X0`` nor ``X1``
shall be written by the |processor|.

If `ecswe[2]`` is 1, then the value in ``ecsdata[5:4]`` is written to ``mstatus.xs``.
If `ecswe[1]`` is 1, then the value in ``ecsdata[3:2]`` is written to ``mstatus.fs``.
If `ecswe[0]`` is 1, then the value in ``ecsdata[1:0]`` is written to ``mstatus.vs``.
The writes to the stated ``mstatus`` bitfields will take into account any WARL rules that might exist for these bitfields in the |processor|.

The signals in ``result`` are valid when ``result_valid`` is 1. These signals remain stable during a result transaction.

Interface dependencies
----------------------

The following rules apply to the relative ordering of the interface handshakes:

* The compressed interface transactions are in program order (possibly a subset) and the |processor| will at least attempt to offload instructions that it does not consider to be valid itself.
* The issue interface transactions are in program order (possibly a subset) and the |processor| will at least attempt to offload instructions that it does not consider to be valid itself.
* Every issue interface transaction (whether accepted or not) has an associated commit interface transaction and both interfaces use a matching transaction ordering.
* If an offloaded instruction is accepted as a ``loadstore`` instruction and not killed, then for each such instruction one or more memory transaction must occur
  via the memory interface. The transaction ordering on the memory interface interface must correspond to the transaction ordering on the issue interface.
* If an offloaded instruction is accepted and allowed to commit, then for each such instruction one result transaction must occur via the result interface (even
  if no writeback needs to happen to the core's register file). The transaction ordering on the result interface does not have to correspond to the transaction ordering
  on the issue interface.
* A commit interface handshake cannot be initiated before the corresponding issue interface handshake is initiated. It is allowed to be initiated at the same time or later.
* A memory (request/response) interface handshake cannot be initiated before the corresponding issue interface handshake is initiated. It is allowed to be initiated at the same time or later.
* Memory result interface transactions cannot be initiated before the corresponding memory request interface handshake is completed. They are allowed to be initiated at the same time as
  or after completion of the memory request interface handshake. Note that a |coprocessor| shall be able to tolerate memory result transactions for which it did not perform the corresponding
  memory request handshake itself.
* A result interface handshake cannot be initiated before the corresponding issue interface handshake is initiated. It is allowed to be initiated at the same time or later.
* A result interface handshake cannot be initiated before the corresponding commit interface handshake is initiated (and the instruction is allowed to commit). It is allowed to be initiated at the same time or later.
* A memory (request/response) interface handshake cannot be initiated for instructions that were killed in an earlier cycle.
* A memory result interface handshake shall occur for every memory (request/response) interface handshake unless the response has ``exc`` = 1 or ``dbg`` = 1.
* A result interface handshake cannot be (or have been) initiated for killed instructions.

Handshake rules
---------------

The following handshake pairs exist on the eXtension interface:

* ``compressed_valid`` with ``compressed_ready``.
* ``issue_valid`` with ``issue_ready``.
* ``commit_valid`` with implicit always ready signal.
* ``mem_valid`` with ``mem_ready``.
* ``mem_result_valid`` with implicit always ready signal.
* ``result_valid`` with ``result_ready``.

The only rule related to valid and ready signals is that:

* A transaction is considered accepted on the positive ``clk`` edge when both valid and (implicit or explicit) ready are 1.

Specifically note the following:

* The valid signals are allowed to be retracted by a |processor| (e.g. in case that the related instruction is killed in the |processor|'s pipeline before the corresponding ready is signaled).
* A new transaction can be started by a |processor| by changing the ``id`` signal and keeping the valid signal asserted (thereby possibly terminating a previous transaction before it completed).
* The valid signals are not allowed to be retracted by a |coprocessor| (e.g. once ``mem_valid`` is asserted it must remain asserted until the handshake with ``mem_ready`` has been performed). A new transaction can therefore not be started by a |coprocessor| by just changing the ``id`` signal and keeping the valid signal asserted if no ready has been received yet for the original transaction. The cycle after receiving the ready signal, a next (back-to-back) transaction is allowed to be started by just keeping the valid signal high and changing the ``id`` to that of the next transaction.
* The ready signals is allowed to be 1 when the corresponding valid signal is not asserted.

Signal dependencies
-------------------

A |processor| shall not have combinatorial paths from its eXtension interface input signals to its eXtension interface output signals, except for the following allowed paths:

* paths from ``result_valid``, ``result`` to ``rs``, ``rs_valid``.
* paths from ``mem_valid``, ``mem_req`` to ``mem_ready``, ``mem_resp``.

.. note::

   The above implies that the non-compressed instruction ``instr[31:0]`` received via the compressed interface is not allowed
   to combinatorially feed into the issue interface's ``instr[31:0]`` instruction.

A |coprocessor| is allowed (and expected) to have combinatorial paths from its eXtension interface input signals to its eXtension interface output signals. In order to prevent combinatorial loops the following combinatorial paths are not allowed in a |coprocessor|:

* paths from ``rs``, ``rs_valid`` to ``result_valid``, ``result``.
* paths from ``mem_ready``, ``mem_resp`` to ``mem_valid``, ``mem_req``.

.. note::

   The above implies that a |coprocessor| has a pipeline stage separating the register file operands from its result generating circuit (similar to
   the separation between decode stage and execute stage found in many CPUs).

.. note::
   As a |processor| is allowed to retract transactions on its compressed and issue interfaces, the ``compressed_ready`` and ``issue_ready`` signals will have to
   depend on signals received from the |processor| in a combinatorial manner (otherwise these ready signals might be signaled for the wrong ``id``).

Handshake dependencies
----------------------

In order to avoid system level deadlock both the |processor| and the |coprocessor| shall obey the following rules:

* The ``valid`` signal of a transaction shall not be dependent on the corresponding ``ready`` signal.
* Transactions related to an earlier part of the instruction flow shall not depend on transactions with the same ``id`` related to a later part of the instruction flow. The instruction flow is defined from earlier to later as follows: Compressed transaction, issue transaction, commit transaction, memory (request/response) transaction, memory result transaction, result transaction.
* Transactions with an earlier issued ``id`` shall not depend on transactions with a later issued ``id`` (e.g. a |coprocessor| is not allowed to delay generating ``mem_valid`` = 1
because it first wants to see ``commit_valid`` = 1 or ``result_ready`` = 1 for a newer instruction).

.. note::
   The use of the words *depend* and *dependent* relate to logical relationships, which is broader than combinatorial relationships.

CPU recommendations
-------------------

Coprocessor recommendations
---------------------------

A |coprocessor| is recommended (but not required) to follow the following suggestions to maximize its re-use potential:

* Avoid using opcodes that are reserved or already used by RISC-V International unless for supporting a standard RISC-V extension.
* Make it easy to change opcode assignments such that a |coprocessor| can easily be updated if it conflicts with another |coprocessor|.
* Clearly document the supported and required parameter values.
* Clearly document the supported and required interfaces (the memory (request/response) interface and memory result interface are optional).

Timing recommendations
----------------------

The integration of the eXtension interface will vary from |processor| to |processor|, and thus require its own set of timing constraints.

`CV32E40X eXtension timing budget <https://cv32e40x-user-manual.readthedocs.io/en/latest/x_ext.html#timing>`_ shows the recommended timing budgets
for the coprocessor and (optional) interconnect for the case in which a coprocessor is paired with the CV32E40X (https://github.com/openhwgroup/cv32e40x) processor.
As is shown in that timing budget, the coprocessor only receives a small part of the timing budget on the paths through ``xif_issue_if.issue_req.rs*``.
This enables the coprocessor to source its operands directly from the CV32E40X register file bypass network, thereby preventing stall cycles in case an
offloaded instruction depends on the result of a preceding non-offloaded instruction. This implies that, if a coprocessor is intended for pairing with the CV32E40X,
it will be beneficial timing wise if the coprocessor does not directly operate on the ``rs*`` source inputs, but registers them instead. To maximize utilization of a coprocessor with various CPUs, such registers could be made optional via a parameter.
