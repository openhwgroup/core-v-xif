// Copyright 2020 ETH Zurich and University of Bologna.::
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Noam Gallmann <gnoam@live.com>

package acc_test;

  import acc_pkg::*;

  //////////////////////////////////////////////
  // Accelerator Interconnect Test Structures //
  //////////////////////////////////////////////

  class c_req_t #(
    parameter int AddrWidth = -1,
    parameter int DataWidth = -1,
    parameter int IdWidth   = -1
  );
    rand logic [AddrWidth-1:0] addr;
    rand logic [DataWidth-1:0] data_arga;
    rand logic [DataWidth-1:0] data_argb;
    rand logic [DataWidth-1:0] data_argc;
    rand logic [31:0]          data_op;
    rand logic [IdWidth-1:0]   id;

    constraint id_lsb_c {
      id[0] == 1'b0;
    };

    typedef c_req_t # (
      .AddrWidth ( AddrWidth ),
      .DataWidth ( DataWidth ),
      .IdWidth   ( IdWidth   )
    ) int_c_req_t;

    function do_compare (int_c_req_t req);
      return addr      == req.addr      &&
             data_arga == req.data_arga &&
             data_argb == req.data_argb &&
             data_argc == req.data_argc &&
             data_op   == req.data_op;
    endfunction

    task display;
      $display(
              "c_req.addr: %x\n",       addr,
              "c_req.data_op: %x\n",    data_op,
              "c_req.data_arga: %x\n",  data_arga,
              "c_req.data_argb: %x\n",  data_argb,
              "c_req.data_argc: %x\n",  data_argc,
              "c_req.id: %x\n",         id,
              "\n"
            );
    endtask
  endclass

  // Compare C requests of different parameterizations.
  // different parametrizations
  class compare_c_req #(
    parameter type mst_c_req_t = logic,
    parameter type slv_c_req_t = logic
  );
    static function do_compare(mst_c_req_t mst_req, slv_c_req_t slv_req);
      return mst_req.addr      == slv_req.addr      &&
             mst_req.data_arga == slv_req.data_arga &&
             mst_req.data_argb == slv_req.data_argb &&
             mst_req.data_argc == slv_req.data_argc &&
             mst_req.data_op   == slv_req.data_op;
    endfunction
  endclass


  class c_rsp_t #(
    parameter int DataWidth = -1,
    parameter int IdWidth   = -1
  );
    rand logic [DataWidth-1:0] data0;
    rand logic [DataWidth-1:0] data1;
    rand logic                 dual_writeback;
    rand logic                 error;
    logic [4:0]                rd; // not random!
    logic [IdWidth-1:0]        id;

    typedef c_rsp_t # (
      .DataWidth    ( DataWidth ),
      .IdWidth      ( IdWidth   )
    ) int_c_rsp_t;

    task display;
      $display(
              "c_rsp.data0: %x\n",          data0,
              "c_rsp.data1: %x\n",          data1,
              "c_rsp.dual_writeback: %x\n", dual_writeback,
              "c_rsp.error %x\n",           error,
              "c_rsp.rd: %x\n",             rd,
              "c_rsp.id: %x\n",             id,
              "\n"
            );
    endtask

    function do_compare (int_c_rsp_t rsp);
      return data0          == rsp.data0          &
             data1          == rsp.data1          &
             dual_writeback == rsp.dual_writeback &
             error          == rsp.error          &
             rd             == rsp.rd;
    endfunction
  endclass


  // Compare rsps of different parameterizations.
  class compare_c_rsp #(
    parameter type mst_c_rsp_t = logic,
    parameter type slv_c_rsp_t = logic
  );
    static function do_compare(mst_c_rsp_t mst_rsp, slv_c_rsp_t slv_rsp);
      return mst_rsp.data0          == slv_rsp.data0          &
             mst_rsp.data1          == slv_rsp.data1          &
             mst_rsp.dual_writeback == slv_rsp.dual_writeback &
             mst_rsp.error          == slv_rsp.error          &
             mst_rsp.rd             == slv_rsp.rd;
    endfunction
  endclass

  class acc_c_driver #(
    parameter int AddrWidth = -1,
    parameter int DataWidth = -1,
    parameter int IdWidth   = -1,
    parameter time TA       = 0, // stimuli application time
    parameter time TT       = 0  // stimuli test time
  );

    typedef c_req_t #(
      .DataWidth ( DataWidth ),
      .AddrWidth ( AddrWidth ),
      .IdWidth   ( IdWidth   )
    ) int_c_req_t;

    typedef c_rsp_t #(
      .DataWidth ( DataWidth ),
      .IdWidth   ( IdWidth   )
    ) int_c_rsp_t;

    virtual ACC_C_BUS_DV # (
      .DataWidth ( DataWidth ),
      .AddrWidth ( AddrWidth ),
      .IdWidth   ( IdWidth   )
    ) bus;

    function new(
      virtual ACC_C_BUS_DV #(
        .DataWidth ( DataWidth ),
        .AddrWidth ( AddrWidth ),
        .IdWidth   ( IdWidth   )
      ) bus
    );
      this.bus=bus;
    endfunction

    task reset_master;
      bus.q_addr      <= '0;
      bus.q_data_op   <= '0;
      bus.q_data_arga <= '0;
      bus.q_data_argb <= '0;
      bus.q_data_argc <= '0;
      bus.q_id        <= '0;
      bus.q_valid     <= '0;
      bus.p_ready     <= '0;
    endtask

    task reset_slave;
      bus.p_data0          <= '0;
      bus.p_data1          <= '0;
      bus.p_dual_writeback <= '0;
      bus.p_id             <= '0;
      bus.p_rd             <= '0;
      bus.p_error          <= '0;
      bus.p_valid          <= '0;
      bus.q_ready          <= '0;
    endtask

    task cycle_start;
      #TT;
    endtask

    task cycle_end;
      @(posedge bus.clk_i);
    endtask

    // Send a request.
    task send_req (input int_c_req_t req);
      bus.q_addr      <= #TA req.addr;
      bus.q_data_op   <= #TA req.data_op;
      bus.q_data_arga <= #TA req.data_arga;
      bus.q_data_argb <= #TA req.data_argb;
      bus.q_data_argc <= #TA req.data_argc;
      bus.q_id        <= #TA req.id;
      bus.q_valid     <= #TA 1;
      cycle_start();
      while (bus.q_ready != 1) begin cycle_end(); cycle_start(); end
      cycle_end();
      bus.q_addr      <= #TA '0;
      bus.q_data_op   <= #TA '0;
      bus.q_data_arga <= #TA '0;
      bus.q_data_argb <= #TA '0;
      bus.q_data_argc <= #TA '0;
      bus.q_id        <= #TA '0;
      bus.q_valid     <= #TA  0;
    endtask

    // Send a response.
    task send_rsp(input int_c_rsp_t rsp);
      bus.p_data0          <= #TA rsp.data0;
      bus.p_data1          <= #TA rsp.data1;
      bus.p_dual_writeback <= #TA rsp.dual_writeback;
      bus.p_id             <= #TA rsp.id;
      bus.p_rd             <= #TA rsp.rd;
      bus.p_error          <= #TA rsp.error;
      bus.p_valid          <= #TA 1;
      cycle_start();
      while (bus.p_ready != 1) begin cycle_end(); cycle_start(); end
      cycle_end();
      bus.p_data0          <= #TA '0;
      bus.p_data1          <= #TA '0;
      bus.p_dual_writeback <= #TA '0;
      bus.p_id             <= #TA '0;
      bus.p_rd             <= #TA '0;
      bus.p_error          <= #TA '0;
      bus.p_valid          <= #TA 0;
    endtask

    // Receive a request.
    task recv_req (output int_c_req_t req );
      bus.q_ready <= #TA 1;
      cycle_start();
      while (bus.q_valid != 1) begin cycle_end(); cycle_start(); end
      req = new;
      req.addr      = bus.q_addr;
      req.data_op   = bus.q_data_op;
      req.data_arga = bus.q_data_arga;
      req.data_argb = bus.q_data_argb;
      req.data_argc = bus.q_data_argc;
      req.id        = bus.q_id;
      cycle_end();
      bus.q_ready <= #TA 0;
    endtask

    // Receive a response.
    task recv_rsp (output int_c_rsp_t rsp);
      bus.p_ready <= #TA 1;
      cycle_start();
      while (bus.p_valid != 1) begin cycle_end(); cycle_start(); end
      rsp                = new;
      rsp.data0          = bus.p_data0;
      rsp.data1          = bus.p_data1;
      rsp.dual_writeback = bus.p_dual_writeback;
      rsp.error          = bus.p_error;
      rsp.id             = bus.p_id;
      rsp.rd             = bus.p_rd;
      cycle_end();
      bus.p_ready <= #TA 0;
    endtask

    // Monitor request
    task mon_req (output int_c_req_t req);
      cycle_start();
      while (!(bus.q_valid && bus.q_ready)) begin cycle_end(); cycle_start(); end
      req = new;
      req.addr      = bus.q_addr;
      req.data_op   = bus.q_data_op;
      req.data_arga = bus.q_data_arga;
      req.data_argb = bus.q_data_argb;
      req.data_argc = bus.q_data_argc;
      req.id        = bus.q_id;
      cycle_end();
    endtask

    // Monitor response.
    task mon_rsp (output int_c_rsp_t rsp);
      cycle_start();
      while (!(bus.p_valid &&bus.p_ready)) begin cycle_end(); cycle_start(); end
      rsp                = new;
      rsp.data0          = bus.p_data0;
      rsp.data1          = bus.p_data1;
      rsp.dual_writeback = bus.p_dual_writeback;
      rsp.error          = bus.p_error;
      rsp.id             = bus.p_id;
      rsp.rd             = bus.p_rd;
      cycle_end();
    endtask

  endclass

  // Super classes for random acc drivers
  virtual class rand_c #(
    // Acc interface parameters
    parameter int DataWidth    = -1,
    parameter int AddrWidth    = -1,
    parameter int IdWidth      = -1,

    // Stimuli application and test time
    parameter time TA = 0ps,
    parameter time TT = 0ps
  );

    typedef c_req_t #(
      .AddrWidth    ( AddrWidth    ),
      .DataWidth    ( DataWidth    ),
      .IdWidth      ( IdWidth      )
    ) int_c_req_t;

    typedef c_rsp_t #(
      .DataWidth    ( DataWidth  ),
      .IdWidth      ( IdWidth    )
    ) int_c_rsp_t;

    typedef acc_test::acc_c_driver #(
      // Acc interface parameters
      .AddrWidth    ( AddrWidth    ),
      .DataWidth    ( DataWidth    ),
      .IdWidth      ( IdWidth      ),
      // Stimuli application and test time
      .TA(TA),
      .TT(TT)
    ) acc_c_driver_t;

    acc_c_driver_t drv;

    function new(
      virtual ACC_C_BUS_DV #(
        .DataWidth    ( DataWidth    ),
        .AddrWidth    ( AddrWidth    ),
        .IdWidth      ( IdWidth      )
      ) bus );
      this.drv = new (bus);
    endfunction

    task automatic rand_wait(input int unsigned min, input int unsigned max);
      int unsigned rand_success, cycles;
      rand_success = std::randomize(cycles) with {
        cycles >= min;
        cycles <= max;
        // Weigh the distribution so that the minimum cycle time is the common
        // case.
        cycles dist {min := 10, [min+1:max] := 1};
      };
      assert (rand_success) else $error("Failed to randomize wait cycles!");
      repeat (cycles) @(posedge this.drv.bus.clk_i);
    endtask

  endclass

  // Generate random requests as a master device.
  class rand_c_master #(
    // Acc interface parameters
    parameter int DataWidth       = -1,
    parameter int AccAddrWidth    = -1,
    parameter int AddrWidth       = -1,
    parameter int IdWidth         = -1,
    parameter int NumHier         = -1,
    parameter int HierLevel       = -1,
    parameter int NumRsp[NumHier] = '{-1},
    // Stimuli application and test time
    parameter time         TA                  = 0ps,
    parameter time         TT                  = 0ps,
    parameter int unsigned REQ_MIN_WAIT_CYCLES = 1,
    parameter int unsigned REQ_MAX_WAIT_CYCLES = 20,
    parameter int unsigned RSP_MIN_WAIT_CYCLES = 1,
    parameter int unsigned RSP_MAX_WAIT_CYCLES = 20
  ) extends rand_c #(
      // Acc interface parameters
      .DataWidth ( DataWidth ),
      .AddrWidth ( AddrWidth ),
      .IdWidth   ( IdWidth   ),
      // Stimuli application and test time
      .TA ( TA ),
      .TT ( TT )
    );

    int unsigned cnt = 0;
    bit req_done     = 0;

    // Reset the driver.
    task reset();
      drv.reset_master();
    endtask

    // Constructor.
    function new (
      virtual ACC_C_BUS_DV #(
        .DataWidth ( DataWidth ),
        .AddrWidth ( AddrWidth ),
        .IdWidth   ( IdWidth   )
      ) bus );
      super.new(bus);
    endfunction

    task run(input int n);
      fork
        send_requests(n);
        recv_response();
      join
    endtask

    // Send random requests.
    task send_requests (input int n);
      automatic int_c_req_t req = new;

      repeat (n) begin
        this.cnt++;
        assert(req.randomize with
          {
            addr[AddrWidth-1:AccAddrWidth] inside {[HierLevel:NumHier-1]};
            addr[AccAddrWidth-1:0]         inside {[0:NumRsp[addr[AddrWidth-1:AccAddrWidth]]-1]};
          }
        );
        rand_wait(REQ_MIN_WAIT_CYCLES, REQ_MAX_WAIT_CYCLES);
        this.drv.send_req(req);
      end
      this.req_done = 1;
    endtask

    // Receive random responses.
    task recv_response;
      while (!this.req_done || this.cnt > 0) begin
        automatic int_c_rsp_t rsp;
        this.cnt--;
        rand_wait(RSP_MIN_WAIT_CYCLES, RSP_MAX_WAIT_CYCLES);
        this.drv.recv_rsp(rsp);
      end
    endtask
  endclass

  class rand_c_slave #(
    // Acc interface parameters
    parameter int AddrWidth    = -1,
    parameter int DataWidth    = -1,
    parameter int IdWidth      = -1,
    // Stimuli application and test time
    parameter time  TA = 0ps,
    parameter time  TT = 0ps,
    parameter int unsigned REQ_MIN_WAIT_CYCLES = 0,
    parameter int unsigned REQ_MAX_WAIT_CYCLES = 10,
    parameter int unsigned RSP_MIN_WAIT_CYCLES = 0,
    parameter int unsigned RSP_MAX_WAIT_CYCLES = 10
  ) extends rand_c #(
      // Acc interface parameters
      .AddrWidth ( AddrWidth ),
      .DataWidth ( DataWidth ),
      .IdWidth   ( IdWidth   ),
      // Stimuli application and test time
      .TA(TA),
      .TT(TT)
    );

    mailbox req_mbx[2**IdWidth];

    /// Reset the driver.
    task reset();
      drv.reset_slave();
    endtask

    task run();
      fork
        recv_requests();
        send_responses();
      join
    endtask

    /// Constructor.
    function new (
      virtual ACC_C_BUS_DV #(
        .DataWidth    ( DataWidth    ),
        .AddrWidth    ( AddrWidth    ),
        .IdWidth      ( IdWidth      )
      ) bus);
      super.new(bus);
      foreach(this.req_mbx[ii]) req_mbx[ii] = new();
    endfunction

    task recv_requests();
      forever begin
        automatic int_c_req_t req;
        rand_wait(REQ_MIN_WAIT_CYCLES, REQ_MAX_WAIT_CYCLES);
        this.drv.recv_req(req);
        req_mbx[req.id >> 1].put(req);
      end
    endtask

    task send_responses();
      forever begin
        automatic int_c_rsp_t rsp = new;
        automatic int_c_req_t req;
        // generate random sequence of requesters.
        automatic int req_id[2**IdWidth];
        automatic bit req_found = 1'b0;
        // randomly pick a request
        for (int i =0; i<2**IdWidth; i++) begin
          req_id[i] = i;
        end
        req_id.shuffle();
        for (int i=0; i<2**IdWidth; i++) begin
          automatic int r_id = req_id[i];
          if (req_mbx[r_id].num() != 0) begin
            req_mbx[r_id].get(req);
            req_found = 1'b1;
            break;
          end
        end
        if (req_found==1'b1) begin
          // generate and send random response.
          assert(rsp.randomize());
          // get Id + Rd from corresponding request.
          rsp.id = req.id;
          rsp.rd = req.data_op[11:7];
          // send response back to requester.
          @(posedge this.drv.bus.clk_i);
          rand_wait(RSP_MIN_WAIT_CYCLES, RSP_MAX_WAIT_CYCLES);
          this.drv.send_rsp(rsp);
        end else begin
          this.drv.cycle_end();
        end
      end
    endtask
  endclass

  class acc_c_slv_monitor #(
    // Acc interface parameters
    parameter int DataWidth    = -1,
    parameter int AddrWidth    = -1,
    parameter int IdWidth      = -1,
    // Stimuli application and test time
    parameter time  TA = 0ps,
    parameter time  TT = 0ps
  ) extends rand_c #(
        .DataWidth    ( DataWidth    ),
        .AddrWidth    ( AddrWidth    ),
        .IdWidth      ( IdWidth      ),
        .TA           ( TA           ),
        .TT           ( TT           )
  );

    mailbox req_mbx[IdWidth**2];
    mailbox rsp_mbx[IdWidth**2];

    // Constructor.
    function new (
      virtual ACC_C_BUS_DV #(
        .DataWidth    ( DataWidth    ),
        .AddrWidth    ( AddrWidth    ),
        .IdWidth      ( IdWidth      )
      ) bus);
      super.new(bus);
      foreach (this.req_mbx[ii]) req_mbx[ii] = new();
      foreach (this.rsp_mbx[ii]) rsp_mbx[ii] = new();

    endfunction

    // Slave Monitor.
    // For each master maintain a separate mailbox.
    task monitor;
      fork
        forever begin
          automatic int_c_req_t req;
          this.drv.mon_req(req);
          // put in req mbox corresponding to the requester
          req_mbx[req.id].put(req);
        end
        forever begin
          automatic int_c_rsp_t rsp;
          this.drv.mon_rsp(rsp);
          // put in req mbox corresponding to the requester
          rsp_mbx[rsp.id].put(rsp);
        end
      join
    endtask
  endclass

  class acc_c_mst_monitor #(
    // Acc interface parameters
    parameter int DataWidth    = -1,
    parameter int AddrWidth    = -1,
    parameter int AccAddrWidth = -1,
    parameter int IdWidth      = -1,
    parameter int HierLevel    = -1,
    // Stimuli application and test time
    parameter time  TA = 0ps,
    parameter time  TT = 0ps
  ) extends rand_c #(
        .DataWidth ( DataWidth ),
        .AddrWidth ( AddrWidth ),
        .IdWidth   ( IdWidth   ),
        .TA        ( TA        ),
        .TT        ( TT        )
    );

    mailbox req_mbx [AccAddrWidth**2];
    mailbox req_mbx_fwd = new;
    mailbox rsp_mbx = new;

    // Constructor.
    function new (
      virtual ACC_C_BUS_DV #(
        .DataWidth ( DataWidth ),
        .AddrWidth ( AddrWidth ),
        .IdWidth   ( IdWidth   )
      ) bus);
      super.new(bus);
      foreach (this.req_mbx[ii]) req_mbx[ii] = new;
    endfunction

    // Master Monitor.
    // For each slave maintain a separate mailbox.
    task monitor;
      fork
        forever begin
          automatic int_c_req_t req;
          this.drv.mon_req(req);
          //req.display();
          // Check if request addresses this level
          if (req.addr[AddrWidth-1:AccAddrWidth] == HierLevel) begin
            // put in req mbox corresponding to the responder
            req_mbx[req.addr[AccAddrWidth-1:0]].put(req);
          end else begin
            // put in fwd req mbx
            req_mbx_fwd.put(req);
          end
        end
        forever begin
          automatic int_c_rsp_t rsp;
          this.drv.mon_rsp(rsp);
          rsp_mbx.put(rsp);
        end
      join
    endtask
  endclass

  /////////////////////////////////////////
  // Accelerator Adapter Test Structures //
  /////////////////////////////////////////

  class x_req_t #(
    parameter int DataWidth = -1
  );
    // REQ Channel
    randc logic [31:0]         instr_data;
    rand logic [DataWidth-1:0] rs1;
    rand logic [DataWidth-1:0] rs2;
    rand logic [DataWidth-1:0] rs3;
    rand logic [2:0]           rs_valid;
    rand logic [2:0]           rd_clean;
    // ACK channel
    rand logic       accept;
    rand logic [1:0] writeback;

    // Helper for randomization
    logic [2:0] last_rs_valid;
    logic [2:0] last_rd_clean;
    function void post_randomize;
      last_rs_valid = rs_valid;
      last_rd_clean = rd_clean;
    endfunction

    task display;
      $display(
              "x_req.instr_data = %x\n",  instr_data,
              "x_req.rs1 = %x\n",         rs1,
              "x_req.rs2 = %x\n",         rs2,
              "x_req.rs3 = %x\n",         rs3,
              "x_req.rs_valid = %x\n",    rs_valid,
              "x_req.rd_clean = %x\n",    rd_clean,
              "x_req.accept = %x\n",      accept,
              "x_req.writeback = %x\n",   writeback,
              "\n"
            );
    endtask

  endclass


  class x_rsp_t #(
    parameter DataWidth = -1
  );
    // RSP Channel
    rand logic [DataWidth-1:0] data0;
    rand logic [DataWidth-1:0] data1;
    rand logic                 error;
    rand logic [4:0]           rd;
    rand logic                 dual_writeback;

    task display;
      $display(
              "x_rsp.data0 = %x\n",           data0,
              "x_rsp.data1 = %x\n",           data1,
              "x_rsp.error = %x\n",           error,
              "x_rsp.rd = %x\n",              rd,
              "x_rsp.dual_writeback = %x\n",  dual_writeback,
              "\n"
            );
    endtask

  endclass

  class acc_x_driver #(
    parameter int DataWidth = -1,
    parameter time TA       = 0, // stimuli application time
    parameter time TT       = 0  // stimuli test time
  );

    typedef x_req_t #(
      .DataWidth ( DataWidth )
    ) int_x_req_t;

    typedef x_rsp_t #(
      .DataWidth ( DataWidth )
    ) int_x_rsp_t;

    virtual ACC_X_BUS_DV #(
      .DataWidth ( DataWidth )
    ) bus;

    function new(
      virtual ACC_X_BUS_DV #(
        .DataWidth ( DataWidth )
      ) bus
    );
      this.bus=bus;
    endfunction

    task reset_master;
      bus.q_instr_data <= '0;
      bus.q_rs1        <= '0;
      bus.q_rs2        <= '0;
      bus.q_rs3        <= '0;
      bus.q_rs_valid   <= '0;
      bus.q_rd_clean   <= '0;
      bus.q_valid      <= '0;
      bus.p_ready      <= '0;
    endtask

    task reset_slave;
      bus.q_ready          <= '0;
      bus.k_accept         <= '0;
      bus.k_writeback      <= '0;
      bus.p_data0          <= '0;
      bus.p_data1          <= '0;
      bus.p_dual_writeback <= '0;
      bus.p_rd             <= '0;
      bus.p_error          <= '0;
      bus.p_valid          <= '0;
    endtask

    task cycle_start;
      #TT;
    endtask

    task cycle_end;
      @(posedge bus.clk_i);
    endtask

    // Send a request
    task send_req (inout int_x_req_t req);
      bus.q_instr_data <= #TA req.instr_data;
      bus.q_rs1        <= #TA req.rs1;
      bus.q_rs2        <= #TA req.rs2;
      bus.q_rs3        <= #TA req.rs3;
      bus.q_rs_valid   <= #TA req.rs_valid;
      bus.q_rd_clean   <= #TA req.rd_clean;
      bus.q_valid      <= #TA 1;
      cycle_start();
      while (bus.q_ready != 1) begin
        // update source regs and rs_valid
        // rsx may change if valid bit not set
        if (~req.rs_valid[0]) begin
          assert(req.randomize(rs1));
        end
        if (~req.rs_valid[1]) begin
          assert(req.randomize(rs2));
        end
        if (~req.rs_valid[2]) begin
          assert(req.randomize(rs3));
        end
        assert(
          req.randomize(rs_valid) with {
            // valid rs may not become invalid.
            foreach(rs_valid[i]) last_rs_valid[i] == 1 -> rs_valid[i] == 1;
          }
        );
        assert(
          req.randomize(rd_clean) with {
            // clean rd may not become dirty during transaction.
            foreach(rd_clean[i]) last_rd_clean[i] == 1 -> rd_clean[i] == 1;
          }
        );
        bus.q_rs_valid <= #TA req.rs_valid;
        bus.q_rd_clean <= #TA req.rd_clean;
        bus.q_rs1      <= #TA req.rs1;
        bus.q_rs2      <= #TA req.rs2;
        bus.q_rs3      <= #TA req.rs3;
        cycle_end();
        cycle_start();
      end
      cycle_end();
      bus.q_valid      <= #TA '0;
      req.writeback = bus.k_writeback;
      req.accept    = bus.k_accept;
    endtask

    // Send a response.
    task send_rsp(input int_x_rsp_t rsp);
      bus.p_data0          <= #TA rsp.data0;
      bus.p_data1          <= #TA rsp.data1;
      bus.p_dual_writeback <= #TA rsp.dual_writeback;
      bus.p_rd             <= #TA rsp.rd;
      bus.p_error          <= #TA rsp.error;
      bus.p_valid          <= #TA 1;
      cycle_start();
      while (bus.p_ready != 1) begin cycle_end(); cycle_start(); end
      cycle_end();
      bus.p_data0          <= #TA '0;
      bus.p_data1          <= #TA '0;
      bus.p_dual_writeback <= #TA '0;
      bus.p_rd             <= #TA '0;
      bus.p_error          <= #TA '0;
      bus.p_valid          <= #TA 0;
    endtask

    // Receive a request and send acknowlegment signals
    task recv_req(inout int_x_req_t req);
      bus.q_ready     <= #TA 1;
      bus.k_accept    <= #TA req.accept;
      bus.k_writeback <= #TA req.writeback;
      while (bus.q_valid != 1) begin cycle_end(); cycle_start(); end
      req            = new;
      req.instr_data = bus.q_instr_data;
      req.rs1        = bus.q_rs1;
      req.rs2        = bus.q_rs2;
      req.rs3        = bus.q_rs3;
      req.rs_valid   = bus.q_rs_valid;
      req.rd_clean   = bus.q_rd_clean;
      cycle_end();
      bus.q_ready     <= #TA 0;
      bus.k_accept    <= #TA '0;
      bus.k_writeback <= #TA '0;
    endtask

    // Receive a response.
    task recv_rsp (output int_x_rsp_t rsp);
      bus.p_ready <= #TA 1;
      cycle_start();
      while (bus.p_valid != 1) begin cycle_end(); cycle_start(); end
      rsp                = new;
      rsp.data0          = bus.p_data0;
      rsp.data1          = bus.p_data1;
      rsp.dual_writeback = bus.p_dual_writeback;
      rsp.error          = bus.p_error;
      rsp.rd             = bus.p_rd;
      cycle_end();
      bus.p_ready <= #TA 0;
    endtask

    // Monitor request
    task mon_req (output int_x_req_t req);
      cycle_start();
      while (!(bus.q_valid && bus.q_ready)) begin cycle_end(); cycle_start(); end
      req            = new;
      req.instr_data = bus.q_instr_data;
      req.rs1        = bus.q_rs1;
      req.rs2        = bus.q_rs2;
      req.rs3        = bus.q_rs3;
      req.rs_valid   = bus.q_rs_valid;
      req.rd_clean   = bus.q_rd_clean;
      req.accept     = bus.k_accept;
      req.writeback  = bus.k_writeback;
      cycle_end();
    endtask

    // Monitor response.
    task mon_rsp (output int_x_rsp_t rsp);
      cycle_start();
      while (!(bus.p_valid &&bus.p_ready)) begin cycle_end(); cycle_start(); end
      rsp                = new;
      rsp.data0          = bus.p_data0;
      rsp.data1          = bus.p_data1;
      rsp.dual_writeback = bus.p_dual_writeback;
      rsp.error          = bus.p_error;
      rsp.rd             = bus.p_rd;
      cycle_end();
    endtask

  endclass

  // Super Class for random x drivers
  virtual class rand_x #(
    // Acc Adapter interface parameters
    parameter int DataWidth = -1,
    // Stimuli application and test time
    parameter time TA = 0ps,
    parameter time TT = 0ps
  );

    typedef x_req_t #(
      .DataWidth ( DataWidth )
    ) int_x_req_t;

    typedef x_rsp_t #(
      .DataWidth ( DataWidth )
    ) int_x_rsp_t;

    typedef acc_test::acc_x_driver #(
      .DataWidth ( DataWidth ),
      .TA        ( TA        ),
      .TT(TT)
    ) acc_x_driver_t;

    acc_x_driver_t drv;

    function new(
      virtual ACC_X_BUS_DV #(
        .DataWidth ( DataWidth )
      ) bus
    );
      this.drv = new(bus);
    endfunction

    task automatic rand_wait(input int unsigned min, input int unsigned max);
      int unsigned rand_success, cycles;
      rand_success = std::randomize(cycles) with {
        cycles >= min;
        cycles <= max;
        // Weigh the distribution so that the minimum cycle time is the common
        // case.
        cycles dist {min := 10, [min+1:max] := 1};
      };
      assert (rand_success) else $error("Failed to randomize wait cycles!");
      repeat (cycles) @(posedge this.drv.bus.clk_i);
    endtask
  endclass

  class rand_x_master #(
    parameter int DataWidth                    = -1,
    parameter time         TA                  = 0ps,
    parameter time         TT                  = 0ps,
    parameter int unsigned REQ_MIN_WAIT_CYCLES = 1,
    parameter int unsigned REQ_MAX_WAIT_CYCLES = 20,
    parameter int unsigned RSP_MIN_WAIT_CYCLES = 1,
    parameter int unsigned RSP_MAX_WAIT_CYCLES = 20
  ) extends rand_x #(
    .DataWidth ( DataWidth ),
    .TA        ( TA        ),
    .TT        ( TT        )
  );

    int unsigned cnt = 0;
    bit req_done     = 0;

    // Reset Driver
    task reset();
      drv.reset_master();
    endtask

    // Consructor
    function new(
      virtual ACC_X_BUS_DV #(
        .DataWidth(DataWidth)
      ) bus );
      super.new(bus);
    endfunction

    task run (input int n);
      fork
        send_requests(n);
        recv_response();
      join
    endtask

    // Send random requests
    task send_requests(input int n);
      automatic int_x_req_t req = new;

      repeat (n) begin
        this.cnt++;
        assert(req.randomize());
        rand_wait(REQ_MIN_WAIT_CYCLES, REQ_MAX_WAIT_CYCLES);
        this.drv.send_req(req);
      end
      this.req_done = 1;
    endtask

    // Receive response
    task recv_response;
      while (!this.req_done || this.cnt > 0) begin
        automatic int_x_rsp_t rsp;
        this.cnt--;
        rand_wait(RSP_MIN_WAIT_CYCLES, RSP_MAX_WAIT_CYCLES);
        this.drv.recv_rsp(rsp);
      end
    endtask
  endclass

  class rand_x_slave #(
    parameter int DataWidth                    = -1,
    parameter time         TA                  = 0ps,
    parameter time         TT                  = 0ps,
    parameter int unsigned REQ_MIN_WAIT_CYCLES = 1,
    parameter int unsigned REQ_MAX_WAIT_CYCLES = 20,
    parameter int unsigned RSP_MIN_WAIT_CYCLES = 1,
    parameter int unsigned RSP_MAX_WAIT_CYCLES = 20
  ) extends rand_x #(
    .DataWidth(DataWidth),
    .TA(TA),
    .TT(TT)
  );

    mailbox req_mbx = new();

    task recv_requests ();
      forever begin
        automatic int_x_req_t req;
        rand_wait(REQ_MIN_WAIT_CYCLES, REQ_MAX_WAIT_CYCLES);
        this.drv.recv_req(req);
        if (req.k_writeback) begin
          // put in mailbox if writeback expected
          req_mbx.put(req);
        end
      end
    endtask

    task send_responses();
      forever begin
        automatic int_x_rsp_t rsp = new;
        automatic int_x_req_t req;
        req_mbx.get(req);
        rand_wait(RSP_MIN_WAIT_CYCLES, RSP_MAX_WAIT_CYCLES);
        this.drv.send_rsp(rsp);
      end
    endtask

  endclass

  class acc_x_monitor#(
    parameter int DataWidth = -1,
    parameter time TA       = 0ps,
    parameter time TT       = 0ps
  ) extends rand_x #(
    .DataWidth(DataWidth),
    .TA(TA),
    .TT(TT)
  );

    mailbox req_mbx          = new();
    mailbox rsp_mbx          = new();
    mailbox req_mbx_rejected = new();

    // Constructor
    function new(
      virtual ACC_X_BUS_DV #(
        .DataWidth( DataWidth )
      ) bus);
      super.new(bus);
    endfunction

    // Monitor
    task monitor;
      fork
        forever begin
          automatic int_x_req_t req;
          this.drv.mon_req(req);
          if (req.accept) begin
            req_mbx.put(req);
          end else begin
            req_mbx_rejected.put(req);
          end
        end
        forever begin
          int_x_rsp_t rsp;
          this.drv.mon_rsp(rsp);
          rsp_mbx.put(rsp);
        end
      join
    endtask

  endclass

  // compare C / X interface responses
  class compare_c_x_rsp #(
    parameter type c_rsp_t = logic,
    parameter type x_rsp_t = logic
  );
    static function do_compare(c_rsp_t c_rsp, x_rsp_t x_rsp);
      return c_rsp.data0          == x_rsp.data0 &&
             c_rsp.data1          == x_rsp.data1 &&
             c_rsp.error          == x_rsp.error &&
             c_rsp.rd             == x_rsp.rd    &&
             c_rsp.dual_writeback == x_rsp.dual_writeback;
    endfunction
  endclass

  ////////////////////////////////////////////
  // Accelerator Predecoder Test Structures //
  ////////////////////////////////////////////

  class prd_rsp_t;
    rand logic       accept;
    rand logic [1:0] writeback;
    rand logic [2:0] use_rs;

    constraint accept_c {
      accept == 1'b0 -> writeback == '0;
      accept == 1'b0 -> use_rs == '0;
    };

    task display;
      $display(
              "prd_rsp.accept: %0d\n",     accept,
              "prd_rsp.writeback: %0d\n",  writeback,
              "prd_rsp.use_rs: %0d\n",     use_rs,
              "\n"
              );
    endtask

  endclass

  class prd_req_t;
    rand logic [31:0] instr_data;
  endclass

  class acc_prd_driver #(
    parameter time TA = 0, // stimuli application time
    parameter time TT = 0  // stimuli test time
  );

    virtual ACC_PRD_BUS_DV bus;

    function new( virtual ACC_PRD_BUS_DV bus);
      this.bus=bus;
    endfunction

    task reset_master;
      bus.q_instr_data <= '0;
    endtask

    task reset_slave;
      bus.p_accept    <= '0;
      bus.p_writeback <= '0;
      bus.p_use_rs    <= '0;
    endtask

    task cycle_start;
      #TT;
    endtask

    task cycle_end;
      @(posedge bus.clk_i);
    endtask

    // Send a request
    task send_req (input prd_req_t req);
      bus.q_instr_data <= #TA req.instr_data;
    endtask

    // Send a response
    // Response is sent in the same cycle, a new request is detected
    task send_rsp (input prd_rsp_t rsp);
      // Predecoders respond entirely combinational
      bus.p_accept    <= #TA rsp.accept;
      bus.p_writeback <= #TA rsp.writeback;
      bus.p_use_rs    <= #TA rsp.use_rs;
      //cycle_end();
    endtask

    // This interface is passive; no recv task necessary

    // request and response are generated at the same time.

    task mon_reqrsp (output prd_req_t req, output prd_rsp_t rsp);
      // record request and response at each change of instr_data input.
      automatic logic [31:0] last_instr_data = bus.q_instr_data;
      cycle_start();
      while (bus.q_instr_data == last_instr_data) begin
        cycle_end(); cycle_start();
      end
      req = new;
      rsp = new;
      req.instr_data = bus.q_instr_data;
      rsp.accept     = bus.p_accept;
      rsp.writeback  = bus.p_writeback;
      rsp.use_rs     = bus.p_use_rs;
      cycle_end();
    endtask

  endclass

 class rand_prd #(
    parameter time TA = 0ps,
    parameter time TT = 0ps
  );

    typedef acc_test::acc_prd_driver #(
      .TT(TT),
      .TA(TA)
    ) acc_prd_driver_t;

    acc_prd_driver_t drv;

    virtual ACC_PRD_BUS_DV bus;

    function new (virtual ACC_PRD_BUS_DV bus);
      this.drv = new(bus);
    endfunction


  endclass

 // Collectively driving all predecoders. Easier to coordinate one-hot accept
 // signal for adapter testbench.
 class rand_prd_slave_collective #(
    parameter NumRspTot = -1,
    parameter time TA   = 0ps,
    parameter time TT   = 0ps
  );

    typedef acc_test::acc_prd_driver #(
      .TT(TT),
      .TA(TA)
    ) acc_prd_driver_t;

    acc_prd_driver_t drv[NumRspTot];

    virtual ACC_PRD_BUS_DV bus [NumRspTot];

    function new ( virtual ACC_PRD_BUS_DV bus [NumRspTot] );
      foreach(this.drv[ii]) this.drv[ii] = new(bus[ii]);
    endfunction

    rand logic [NumRspTot-1:0] accept_onehot;

    task reset();
      foreach(this.drv[ii]) drv[ii].reset_slave();
    endtask

    task wait_instr();
      @(drv[0].bus.q_instr_data);
    endtask

    task run();
      // We generate random responses, not caring about the exact request.
      automatic prd_rsp_t prd_rsp[NumRspTot];
      forever begin

        assert(std::randomize(accept_onehot) with {
            $countones(accept_onehot) <= 1;
          }
        );
        for (int i=0; i<NumRspTot; i++) begin

          prd_rsp[i] = new;
          assert(
            prd_rsp[i].randomize with {
              accept == accept_onehot[i];
            }
          );
        end

        for (int i=0; i<NumRspTot; i++) begin
          fork
            automatic int ii=i;
            //$display("Time: %0t, Fork: %0d", $time, ii);
            this.drv[ii].send_rsp(prd_rsp[ii]);
          join_none
        end
        @(drv[0].bus.q_instr_data);
      end
    endtask
  endclass

  class acc_prd_monitor #(
    parameter time TA = 0ps,
    parameter time TT = 0ps
  ) extends rand_prd #(
    .TA(TA),
    .TT(TT)
  );

    // Constructor.
    function new (virtual ACC_PRD_BUS_DV bus);
      super.new(bus);
    endfunction

    mailbox rsp_mbx = new;
    mailbox req_mbx = new;

    // Record req and rsp for accepted instructions
    task monitor;
      forever begin
        automatic prd_req_t req;
        automatic prd_rsp_t rsp;
        this.drv.mon_reqrsp(req, rsp);
        if (rsp.accept) begin
          req_mbx.put(req);
          rsp_mbx.put(rsp);
        end
      end
    endtask

  endclass

  class adp_check_req #(
    parameter type acc_c_req_t = logic,
    parameter type acc_x_req_t = logic,
    parameter type acc_prd_rsp_t = logic
  );

    // Check construction of interconnect request from predecoder response
    // + adapter request.
    static function do_check (acc_x_req_t x_req, acc_prd_rsp_t prd_rsp, acc_c_req_t c_req);

      // Check result (Address is checked externally.
      return (c_req.data_arga == (prd_rsp.use_rs[0] ? x_req.rs1 : '0)) &&
             (c_req.data_argb == (prd_rsp.use_rs[1] ? x_req.rs2 : '0)) &&
             (c_req.data_argc == (prd_rsp.use_rs[2] ? x_req.rs3 : '0)) &&
             (c_req.id        == 1'b0)                                 &&
             (c_req.data_op   == x_req.instr_data);

    endfunction
  endclass


endpackage
