// Copyright 2024 OpenHW Group
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

// CORE-V-XIF Package
// Contributor: Moritz Imfeld <moimfeld@student.ethz.ch>
// Contributor: Davide Schiavone <davide@openhwgroup.org>

package core_v_xif_pkg;

  // cv-x-if parameters
  parameter int X_NUM_RS = 2;
  parameter int X_ID_WIDTH = 4;
  parameter int X_MEM_WIDTH = 32;
  parameter int X_RFR_WIDTH = 32;
  parameter int X_RFW_WIDTH = 32;
  parameter logic [31:0] X_MISA = '0;
  parameter logic [1:0] X_ECS_XS = '0;
  parameter int X_DUALREAD = 0;
  parameter int X_DUALWRITE = 0;
  parameter int X_ISSUE_REGISTER_SPLIT = 0;
  parameter int XLEN = 32;

  typedef logic [X_NUM_RS+X_DUALREAD-1:0] registerflags_t;
  typedef logic [X_NUM_RS-1:0][X_RFR_WIDTH-1:0] mode_t;
  typedef logic [X_ID_WIDTH-1:0] id_t;

  typedef struct packed {
    logic [15:0] instr;  // Offloaded compressed instruction
    id_t id;  // Identification number of the offloaded compressed instruction
  } x_compressed_req_t;

  typedef struct packed {
    logic [31:0] instr;  // Uncompressed instruction
    logic accept;  // Is the offloaded compressed instruction (id) accepted by the coprocessor?
  } x_compressed_resp_t;

  typedef struct packed {
    logic [31:0] instr;  // Offloaded instruction
    mode_t mode;  // Privilege level
    id_t id;  // Identification of the offloaded instruction
  } x_issue_req_t;

  typedef struct packed {
    logic accept;  // Is the offloaded instruction (id) accepted by the coprocessor?
    logic writeback;  // Will the coprocessor perform a writeback in the core to rd?
    logic dualwrite;  // Will the coprocessor perform a dual writeback in the core to rd and rd+1?
    registerflags_t register_read;   // Will the coprocessor perform require specific registers to be read?
    logic loadstore;  // Is the offloaded instruction a load/store instruction?
    logic ecswrite;  // Will the coprocessor perform a writeback in the core to mstatus.xs, mstatus.fs, mstatus.vs
  } x_issue_resp_t;


  typedef struct packed {
    id_t id;  // Identification of the offloaded instruction
    logic [X_RFR_WIDTH-1:0] rs[X_NUM_RS-1:0];  // Register file source operands for the offloaded instruction.
    registerflags_t rs_valid; // Validity of the register file source operand(s).
    logic [5:0] ecs; // Extension Context Status ({mstatus.xs, mstatus.fs, mstatus.vs})
    logic ecs_valid; // Validity of the Extension Context Status.
  } x_register_t;


  typedef struct packed {
    id_t id;  // Identification of the offloaded instruction
    logic commit_kill;  // Shall an offloaded instruction be killed?
  } x_commit_t;

  typedef struct packed {
    id_t id;  // Identification of the offloaded instruction
    logic [31:0] addr;  // Virtual address of the memory transaction
    mode_t mode;  // Privilege level
    logic we;  // Write enable of the memory transaction
    logic [2:0] size;  // Size of the memory transaction
    logic [X_MEM_WIDTH/8-1:0] be;  // Byte enables for memory transaction
    logic [1:0] attr;  // Memory transaction attributes
    logic [X_MEM_WIDTH  -1:0] wdata;  // Write data of a store memory transaction
    logic last;  // Is this the last memory transaction for the offloaded instruction?
    logic spec;  // Is the memory transaction speculative?
  } x_mem_req_t;

  typedef struct packed {
    logic exc;  // Did the memory request cause a synchronous exception?
    logic [5:0] exccode;  // Exception code
    logic dbg;  // Did the memory request cause a debug trigger match with ``mcontrol.timing`` = 0?
  } x_mem_resp_t;

  typedef struct packed {
    id_t id;  // Identification of the offloaded instruction
    logic [X_MEM_WIDTH-1:0] rdata;  // Read data of a read memory transaction
    logic err;  // Did the instruction cause a bus error?
    logic dbg;  // Did the read data cause a debug trigger match with ``mcontrol.timing`` = 0?
  } x_mem_result_t;

  typedef struct packed {
    id_t id;  // Identification of the offloaded instruction
    logic [X_RFW_WIDTH     -1:0] data;  // Register file write data value(s)
    logic [4:0] rd;  // Register file destination address(es)
    logic [X_RFW_WIDTH/XLEN-1:0] we;  // Register file write enable(s)
    logic [2:0] ecswe;  // Write enables for {mstatus.xs, mstatus.fs, mstatus.vs}
    logic [5:0] ecsdata;  // Write data value for {mstatus.xs, mstatus.fs, mstatus.vs}
    logic exc;  // Did the instruction cause a synchronous exception?
    logic [5:0] exccode;  // Exception code
    logic dbg;  // Did the instruction cause a debug trigger match with ``mcontrol.timing`` = 0?
    logic err;  // Did the instruction cause a bus error?
  } x_result_t;

endpackage
