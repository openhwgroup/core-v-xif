.. _x_ext:

eXtension Interface
===================

The eXtension interface enables extending |processor| with custom instructions without the need to change the RTL
of |processor| itself. Custom extensions can be provided in separate modules external to |processor| and are integrated
at system level by connecting them to the eXtension interface.

The eXtension interface provides low latency (tightly integrated) read and write access to the |processor| register file.
All opcodes which are not used (i.e. considered to be invalid) by |processor| can be used for custom extensions. It is recommended
however that custom instructions do not use opcodes that are reserved/used by RISC-V International.

The eXtension interface enables extension of |processor| with:

* Custom ALU type instructions.
* Custom load/store type instructions.
* Custom CSRs and related instructions.

Control-Tranfer type instructions (e.g. branches and jumps) are not supported via the eXtension interface.

CORE-V-XIF
----------

The terminology ``eXtension interface`` and ``CORE-V-XIF`` are used interchangeably. The CORE-V-XIF specification contains the following parameters:

* ``X_REG_WIDTH`` is the width of an integer register in bits and needs to match the XLEN of the |processor|, e.g. ``X_REG_WIDTH`` = 32 for RV32 CPUs.
* ``X_FREG_WIDTH`` is the (maximum) width of a floating point register in bits and needs to match the FLEN of the |processor|.
* ``X_NUM_RS`` specifies the number of register file read ports that can be used by CORE-V-XIF. Legal values are 2 and 3.
* ``X_NUM_FRS`` specifies the number of floating-point register file read ports that can be used by CORE-V-XIF. Legal values are 2 and 3.
* ``X_ID_WIDTH`` specifies the width of each of the ID signals of the eXtension interface. Legal values are 1-32.
* ``X_MEM_WIDTH`` specifies the memory access width for loads/stores via the eXtension interface. (Legal values are TBD.)
* ``X_RFR_WIDTH`` specifies the register file read access width for the eXtension interface. If XLEN = 32, then the legal values are 32 and 64 (e.g. for RV32P). If XLEN = 64, then the legal value is (only) 64.
* ``X_RFW_WIDTH`` specifies the register file write access width for the eXtension interface. If XLEN = 32, then the legal values are 32 and 64 (e.g. for RV32D). If XLEN = 64, then the legal value is (only) 64.

Parameters
----------

+------------------------------+------------------------+---------------+--------------------------------------------------------------------+
| Name                         | Type/Range             | Default       | Description                                                        |
+==============================+========================+===============+====================================================================+
| ``X_REG_WIDTH``              | int (32, 64)           | 32            | Width of an integer register in bits. Must be equal to XLEN.       |
+------------------------------+------------------------+---------------+--------------------------------------------------------------------+
| ``X_FREG_WIDTH``             | int (32, 64, 128)      | 32            | Width of a floating point register in bits. Must be equal to FLEN. |
+------------------------------+------------------------+---------------+--------------------------------------------------------------------+
| ``X_NUM_RS``                 | int (2..3)             | 2             | Number of register file read ports that can be used by the         |
|                              |                        |               | eXtension interface.                                               |
+------------------------------+------------------------+---------------+--------------------------------------------------------------------+
| ``X_NUM_FRS``                | int (2..3)             | 2             | Number of floating-point register file read ports that can be used |
|                              |                        |               | by the eXtension interface. In case that the F extension is not    |
|                              |                        |               | supported by a |processor|, then the related signals               |
|                              |                        |               | (i.e. ``frs`` and ``frs_valid``) shall be tied to 0.               |
+------------------------------+------------------------+---------------+--------------------------------------------------------------------+
| ``X_ID_WIDTH``               | int (1..32)            | 4             | Identification width for the eXtension interface.                  |
+------------------------------+------------------------+---------------+--------------------------------------------------------------------+
| ``X_MEM_WIDTH``              | int (32, 64, 128, 256) | 32            | Memory access width for loads/stores via the eXtension interface.  |
+------------------------------+------------------------+---------------+--------------------------------------------------------------------+
| ``X_RFR_WIDTH``              | int (32, 64)           | 32            | Register file read access width for the eXtension interface.       |
+------------------------------+------------------------+---------------+--------------------------------------------------------------------+
| ``X_RFW_WIDTH``              | int (32, 64)           | 32            | Register file write access width for the eXtension interface.      |
|                              |                        |               | Must be at least FLEN.                                             |
+------------------------------+------------------------+---------------+--------------------------------------------------------------------+
| ``X_MISA``                   | logic [31:0]           | 0x0000_0000   | MISA extensions implemented on the eXtension interface.            |
+------------------------------+------------------------+---------------+--------------------------------------------------------------------+

The major features of CORE-V-XIF are:

* Minimal requirements on custom instruction encoding.

  If a custom instruction relies on reading from or writing to the core's general purpose register file, then the standard
  RISC-V bitfield locations for rs1, rs2, rs3, rd as used for non-compressed instructions ([RISC-V-UNPRIV]_) must be used.
  Bitfields for unused read or write operands can be fully repurposed. Custom instructions can either use the compressed
  or uncompressed instruction format. For offloading compressed instructions the |coprocessor| must provide the core with
  the related non-compressed instructions.

* Support for dual writeback instructions.

  CORE-V-XIF optionally supports implementation of custom ISA extensions mandating dual register file writebacks. Dual writeback
  is supported for even-odd register pairs (``Xn`` and ``Xn+1`` with ``n <> 0`` and ``Xn`` extracted from instruction bits ``[11:7]``.

  Dual register file writeback is only supported if XLEN = 32.

* Support for dual read instructions (per source operand).

  CORE-V-XIF optionally supports implementation of custom ISA extensions mandating dual register file reads. Dual read
  is supported for even-odd register pairs (``Xn`` and ``Xn+1`` and ``Xn`` extracted from instruction bits `[19:15]``,
  ``[24:20]`` and ``[31:27]`` (i.e. ``rs1``, ``rs2`` and ``rs3``). Dual read can therefore provide six 32-bit operands
  per instruction.

  Dual register file read is only supported if XLEN = 32.

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
    parameter int          X_REG_WIDTH     =  32, // Width of an integer register in bits. Must be equal to XLEN.
    parameter int          X_FREG_WIDTH    =  32, // Width of a floating point register in bits. Must be equal to FLEN.
    parameter int          X_NUM_RS        =  2,  // Number of register file read ports that can be used by the eXtension interface
    parameter int          X_NUM_FRS       =  2,  // Number of floating-point register file read ports that can be used by the eXtension interface
    parameter int          X_ID_WIDTH      =  4,  // Identification width for the eXtension interface
    parameter int          X_MEM_WIDTH     =  32, // Memory access width for loads/stores via the eXtension interface
    parameter int          X_RFR_WIDTH     =  32, // Register file read access width for the eXtension interface
    parameter int          X_RFW_WIDTH     =  32, // Register file write access width for the eXtension interface
    parameter logic [31:0] X_MISA          =  '0  // MISA extensions implemented on the eXtension interface
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

The ``id`` is a unique identification number for offloaded instructions. An ``id`` value can be reused after an earlier instruction related to the same ``id`` value
has fully completed (i.e. because it was not accepted for offload, because it was killed or because it retired). The same ``id`` value will be used for all transaction
packets on all interfaces that logically relate to the same instruction.

A compressed request transaction is defined as the combination of all ``compressed_req`` signals during which ``compressed_valid`` is 1 and the ``id`` remains unchanged. I.e. a new
transaction can be started by just changing the ``id`` signal and keeping the valid signal asserted (even if ``compressed_ready`` remained 0).

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

Typically an accepted transaction over the compressed interface will be followed by a corresponding transaction over the issue interface, but there is no requirement
on the |processor| to do so (as the instructions offloaded over the compressed interface and issue interface are allowed to be speculative).

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
  | ``frs[X_NUM_FRS-1:0]`` | logic [X_FREG_WIDTH-1:0] | Floating-point register file source operands for the offloaded instruction. Tied to 0 if no floating-point      |
  |                        |                          | register file is present.                                                                                       |
  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``frs_valid``          | logic [X_NUM_FRS-1:0]    | Validity of the floating-point register file source operand(s). Tied to 0 if no floating-point                  |
  |                        |                          | register file is present.                                                                                       |
  +------------------------+--------------------------+-----------------------------------------------------------------------------------------------------------------+

A issue request transaction is defined as the combination of all ``issue_req`` signals during which ``issue_valid`` is 1 and the ``id`` remains unchanged. I.e. a new
transaction can be started by just changing the ``id`` signal and keeping the valid signal asserted.

The ``instr``, ``mode``, ``id`` and ``rs_valid`` signals are valid when ``issue_valid`` is 1. The ``rs`` is only considered valid when ``issue_valid`` is 1 and the corresponding
bit in ``rs_valid`` is 1 as well.

The ``instr`` and ``mode`` signals remain stable during an issue request transaction. The ``rs_valid`` bits are not required to be stable during the transaction. Each bit
can transition from 0 to 1, but is not allowed to transition back to 0 during a transaction. The ``rs`` signals are only required to be stable during the part
of a transaction in which these signals are considered to be valid.

The ``rs[X_NUM_RS-1:0]`` signals provide the register file operand(s) to the |coprocessor|. In case that ``XLEN`` = ``X_RFR_WIDTH``, then the regular register file
operands corresponding to ``rs1``, ``rs2`` or ``rs3`` are provided. In case ``XLEN`` != ``X_RFR_WIDTH`` (i.e. ``XLEN`` = 32 and ``X_RFR_WIDTH`` = 64), then the
``rs[X_NUM_RS-1:0]`` signals provide two 32-bit register file operands per index (corresponding to even/odd register pairs) with the even register specified
in ``rs1``, ``rs2`` or ``rs3``. The register file operand for the even register file index is provided in the lower 32 bits; the register file operand for the
odd register file index is provided in the upper 32 bits.

:numref:`Issue response type` describes the ``x_issue_resp_t`` type.

.. table:: Issue response type
  :name: Issue response type

  +------------------------+----------------------+------------------------------------------------------------------------------------------------------------------+ 
  | **Signal**             | **Type**             | **Description**                                                                                                  | 
  +------------------------+----------------------+------------------------------------------------------------------------------------------------------------------+ 
  | ``accept``             | logic                | Is the offloaded instruction (``id``) accepted by the |coprocessor|?                                             | 
  +------------------------+----------------------+------------------------------------------------------------------------------------------------------------------+ 
  | ``writeback``          | logic                | Will the |coprocessor| perform a writeback in the core to ``rd``?                                                | 
  |                        |                      | A |coprocessor| must signal ``writeback`` as 0 for non-accepted instructions.                                    | 
  +------------------------+----------------------+------------------------------------------------------------------------------------------------------------------+ 
  | ``float``              | logic                | Qualifies whether a writeback is to the floating-point register file or to integer register file?                |
  |                        |                      | A |coprocessor| must signal ``float`` as 0 for non-accepted instructions.                                        | 
  +------------------------+----------------------+------------------------------------------------------------------------------------------------------------------+ 
  | ``dualwrite``          | logic                | Will the |coprocessor| perform a dual writeback in the core to ``rd`` and ``rd+1``?                              | 
  |                        |                      | A |coprocessor| must signal ``dualwrite`` as 0 for non-accepted instructions.                                    | 
  +------------------------+----------------------+------------------------------------------------------------------------------------------------------------------+ 
  | ``dualread``           | logic                | Will the |coprocessor| require dual reads from ``rs1\rs2\rs3`` and ``rs1+1\rs2+1\rs3+1``?                        | 
  |                        |                      | A |coprocessor| must signal ``dualread`` as 0 for non-accepted instructions.                                     | 
  +------------------------+----------------------+------------------------------------------------------------------------------------------------------------------+ 
  | ``loadstore``          | logic                | Is the offloaded instruction a load/store instruction?                                                           | 
  |                        |                      | A |coprocessor| must signal ``loadstore`` as 0 for non-accepted instructions. (Only) if an instruction is        | 
  |                        |                      | accepted with ``loadstore`` is 1 and the instruction is not killed, then the |coprocessor| must perform one or   | 
  |                        |                      | more transactions via the memory group interface.                                                                | 
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

   The |processor| shall perform a commit transaction for every issue transaction, independent of the ``accept`` value of the issue transaction.

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
instruction is allowed to be committed or is supposed to be killed. The ``id`` values of subsequent commit transactions will increment (and wrap around)

For each offloaded and accepted instruction the core is guaranteed to (eventually) signal that such an instruction is either no longer speculative and can be committed (``commit_valid`` is 1
and ``commit_kill`` is 0) or that the instruction must be killed (``commit_valid`` is 1 and ``commit_kill`` is 1). 

A |coprocessor| does not have to wait for ``commit_valid`` to
become asserted. It can speculate that an offloaded accepted instruction will not get killed, but in case this speculation turns out to be wrong because the instruction actually did get killed,
then the |coprocessor| must undo any of its internal architectural state changes that are due to the killed instruction. 

A |coprocessor| is allowed to perform speculative memory request transactions, but then must be aware that |processor| can signal a failure for speculative memory request transactions to
certain memory regions. A |coprocessor| shall never perform memory request transactions for instructions that have already been killed at least a ``clk`` cycle earlier.

A |coprocessor| is not allowed to perform speculative result transactions. A |coprocessor| shall never perform result  transactions for instructions that have already been killed at least a ``clk`` cycle earlier.

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
  | ``size``     | logic [1:0]                | Size of the memory transaction. 0: byte, 1: halfword, 2: word.                                                  |
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
* Misaligned load/store handling
* Write buffer usage

As for non-offloaded load or store instructions it is assumed that execute permission is never required for offloaded load or store instructions.
If desired a |coprocessor| can avoid performing speculative loads or stores (as indicated by ``spec`` is 1) as well
by waiting for the commit interface to signal that the offloaded instruction is no longer speculative before issuing the memory request.

A memory request transaction is defined as the combination of all ``mem_req`` signals during which ``mem_valid`` is 1 and the ``id`` remains unchanged. I.e. a new
transaction can be started by just changing the ``id`` signal and keeping the valid signal asserted.

The signals in ``mem_req`` are valid when ``mem_valid`` is 1.
These signals remain stable during a memory request transaction until the actual handshake is performed with both ``mem_valid`` and ``mem_ready`` being 1.
``wdata`` is only required to remain stable during memory request transactions in which ``we`` is 1.

A |coprocessor| is required to (only) perform a memory request transaction(s) for non-killed instructions that it earlier accepted via the issue interface as load/store
instructions (i.e. ``loadstore`` is 1).

:numref:`Memory request type` describes the ``x_mem_resp_t`` type.

.. table:: Memory response type
  :name: Memory response type

  +------------------------+------------------+-----------------------------------------------------------------------------------------------------------------+
  | **Signal**             | **Type**         | **Description**                                                                                                 |
  +------------------------+------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``exc``                | logic            | Did the memory request cause a synchronous exception?                                                           |
  +------------------------+------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``exccode``            | logic [5:0]      | Exception code.                                                                                                 |
  +------------------------+------------------+-----------------------------------------------------------------------------------------------------------------+

The ``exc`` is used to signal synchronous exceptions resulting from the memory request transaction defined in ``mem_req``. In case of a synchronous exception
no corresponding transaction will be performed over the memory result (``mem_result_valid``) interface.
A synchronous exception will lead to a trap in |processor| unless the corresponding instruction is killed. ``exccode`` provides the least significant bits of the exception
code bitfield of the ``mcause`` CSR.

The signals in ``mem_resp`` are valid when ``mem_valid`` and  ``mem_ready`` are both 1. There are no stability requirements.

In case the memory request transaction results in a misaligned load/store operation, it is up to |processor| how/whether misaligned load/store operations are supported.
The memory response and hence the request/response handshake may get delayed.
If the first access results in a synchronous exception, the handshake can be performed immediately.
Otherwise, the handshake is performed once its known whether the second access results in a synchronous exception or not.

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

The memory result interface is used to provide a result from |processor| to the |coprocessor| for every memory transaction (i.e. for both read and write transactions).
No memory result transaction is performed for instructions that led to a synchronous exception as signaled via the memory (request/response) interface. If a
memory (request/response) transaction was not killed, then the corresponding memory result transaction will not be killed either.
Memory result transactions are provided by the |processor| in the same order (with matching ``id``) as the memory (request/response) transactions are received. The ``err`` signal
signals whether a bus error occurred. If so, then an NMI is signaled, just like for bus errors caused by non-offloaded loads and stores. 

From a |processor|'s point of view each memory request transaction has an associated memory result transaction. The same is not true for a |coprocessor| as it can receive
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
have exactly one result group transaction (even if no data needs to be written back to the |processor|'s register file).

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
  | ``we``        | logic [X_RFW_WIDTH-XLEN:0]      | Register file write enable(s).                                                                                  |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``float``     | logic                           | Floating-point register file or integer register file?                                                          |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``exc``       | logic                           | Did the instruction cause a synchronous exception?                                                              |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+
  | ``exccode``   | logic [5:0]                     | Exception code.                                                                                                 |
  +---------------+---------------------------------+-----------------------------------------------------------------------------------------------------------------+

A result transaction is defined as the combination of all ``result`` signals during which ``result_valid`` is 1 and the ``id`` remains unchanged. I.e. a new
transaction can be started by just changing the ``id`` signal and keeping the valid signal asserted.

The ``exc`` is used to signal synchronous exceptions. 
A synchronous exception will lead to a trap in |processor| unless the corresponding instruction is killed. ``exccode`` provides the least significant bits of the exception
code bitfield of the ``mcause`` CSR. ``we`` shall be driven to 0 by the |coprocessor| for synchronous exceptions.

``we`` is 2 bits wide when `XLEN`` = 32 and ``X_RFR_WIDTH`` = 64, and 1 bit wide otherwise. If ``we`` is 2 bits wide, then ``we[1]`` is only allowed to be 1 if ``we[0]`` is 1 as well (i.e. for
dual writeback).

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
* A commit interface handshake cannot be initiated before the corresponding issue interface handshake is initiated.
* A memory (request/response) interface handshake cannot be initiated before the corresponding issue interface handshake is initiated.
* A memory result interface transactions cannot be initiated before the corresponding memory request interface handshake is completed. Note that a |coprocessor|
  shall be able to tolerate memory result transactions for which it did not perform the corresponding memory request handshake itself.
* A result interface handshake cannot be initiated before the corresponding issue interface handshake is initiated.
* A result interface handshake cannot be initiated before the corresponding commit interface handshake is initiated (and the instruction is allowed to commit).
* A memory (request/response) interface handshake cannot be initiated for instructions that were killed in an earlier cycle.
* A memory result interface handshake cannot be initiated for instructions that were killed in an earlier cycle.
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
* The valid signals are not allowed to be retracted by a |coprocessor| (e.g. once ``mem_valid`` is asserted it must remain asserted until the handshake with ``mem_ready`` has been performed).
* A new transaction can be started by changing the ``id`` signal and keeping the valid signal asserted (thereby possibly terminating a previous transaction before it completed).
* The ready signal is allowed to be 1 when the corresponding valid signal is not asserted.

Signal dependencies
-------------------

|processor| shall not have combinatorial paths from its eXtension interface input signals to its eXtension interface output signals, except for the following allowed paths:

* paths from ``result_valid``, ``result`` to ``rs``, ``rs_valid``, ``frs``, ``frs_valid``.

.. note::

   The above implies that the non-compressed instruction ``instr[31:0]`` received via the compressed interface is not allowed
   to combinatorially feed into the issue interface's ``instr[31:0]`` instruction.

A |coprocessor| is allowed (and expected) to have combinatorial paths from its eXtension interface input signals to its eXtension interface output signals. In order to prevent combinatorial loops the following combinatorial paths are not allowed in a |coprocessor|:

* paths from ``rs``, ``rs_valid``, ``frs``, ``frs_valid`` to ``result_valid``, ``result``.

.. note::

   The above implies that a |coprocessor| has a pipeline stage separating the register file operands from its result generating circuit (similar to
   the separation between decode stage and execute stage found in many CPUs).

CPU recommendations
-------------------

Coprocessor recommendations
---------------------------

A |coprocessor| is recommended (but not required) to follow the following suggestions to maximize its re-use potential:

* Avoid using opcodes that are reserved or already used by RISC-V International unless for supporting a standard RISC-V extension.
* Make it easy to change opcode assignments such that a |coprocessor| can easily be updated if it conflicts with another |coprocessor|.
* Clearly document the supported parameter values.
* Clearly document the usage of features which are optional |processor| (TBD, e.g. ``dualwrite``, ``dualread``).
