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
    parameter int NumRs     = -1
  );
    rand logic            [AddrWidth-1:0] addr;
    rand logic [NumRs-1:0][DataWidth-1:0] rs;
    rand logic            [         31:0] instr_data;
    rand logic            [DataWidth-1:0] hart_id;

    typedef c_req_t # (
      .AddrWidth ( AddrWidth ),
      .DataWidth ( DataWidth ),
      .NumRs     ( NumRs     )
    ) int_c_req_t;

    function do_compare (int_c_req_t req);
      return addr       == req.addr       &&
             rs         == req.rs         &&
             instr_data == req.instr_data &&
             hart_id    == req.hart_id;
    endfunction

    task display;
      $display(
              "c_req.addr: %x\n",        addr,
              "c_req.instr_data: %x\n",  instr_data,
              "c_req.rs: %x\n",          rs,
              "c_req.hart_id: %x\n",     hart_id,
              "\n"
            );
    endtask
  endclass

  class c_rsp_t #(
    parameter int DataWidth = -1,
    parameter int NumWb = -1
  );
    rand logic [NumWb-1:0][DataWidth-1:0] data;
    rand logic                            dualwb;
    rand logic                            error;
    logic                 [          4:0] rd;
    logic                 [DataWidth-1:0] hart_id;

    typedef c_rsp_t # (
      .DataWidth ( DataWidth ),
      .NumWb     ( NumWb     )
    ) int_c_rsp_t;

    task display;
      $display(
              "c_rsp.data: %x\n",     data,
              "c_rsp.dualwb: %x\n",   dualwb,
              "c_rsp.error %x\n",     error,
              "c_rsp.rd: %x\n",       rd,
              "c_rsp.hart_id: %x\n",  hart_id,
              "\n"
            );
    endtask

    function do_compare (int_c_rsp_t rsp);
      return data    == rsp.data   &&
             dualwb  == rsp.dualwb &&
             error   == rsp.error  &&
             rd      == rsp.rd     &&
             hart_id == rsp.hart_id;
    endfunction
  endclass

  class acc_c_driver #(
    parameter int AddrWidth     = -1,
    parameter int DataWidth     = -1,
    parameter bit DualWriteback = 0,
    parameter bit TernaryOps    = 0,
    parameter time TA           = 0, // stimuli application time
    parameter time TT           = 0  // stimuli test time
  );
    localparam int unsigned NumRs = TernaryOps ? 3 : 2;
    localparam int unsigned NumWb = DualWriteback ? 2 : 1;

    typedef c_req_t #(
      .DataWidth ( DataWidth ),
      .AddrWidth ( AddrWidth ),
      .NumRs     ( NumRs     )
    ) int_c_req_t;

    typedef c_rsp_t #(
      .DataWidth ( DataWidth ),
      .NumWb     ( NumWb     )
    ) int_c_rsp_t;

    virtual ACC_C_BUS_DV # (
      .DataWidth     ( DataWidth     ),
      .AddrWidth     ( AddrWidth     ),
      .DualWriteback ( DualWriteback ),
      .TernaryOps    ( TernaryOps    )
    ) bus;

    logic [DataWidth-1:0] hart_id;
    bit const_hart_id;

    // Initialiation variable hart_id:
    // hart_id == -1 -> variable request hart id
    // hart_id >=  0 -> hart id hardwired.
    function new(
      virtual ACC_C_BUS_DV #(
        .DualWriteback ( DualWriteback ),
        .TernaryOps    ( TernaryOps    ),
        .DataWidth     ( DataWidth     ),
        .AddrWidth     ( AddrWidth     )
      ) bus,
      int hart_id = -1
    );
      this.bus = bus;
      this.const_hart_id = ( hart_id >= 0 );
      this.hart_id = DataWidth'(unsigned'(hart_id));
    endfunction

    task reset_master;
      bus.q_addr       <= '0;
      bus.q_instr_data <= '0;
      bus.q_rs         <= '0;
      bus.q_hart_id    <= const_hart_id ? hart_id : '0;
      bus.q_valid      <= '0;
      bus.p_ready      <= '0;
    endtask

    task reset_slave;
      bus.p_data    <= '0;
      bus.p_dualwb  <= '0;
      bus.p_hart_id <= '0;
      bus.p_rd      <= '0;
      bus.p_error   <= '0;
      bus.p_valid   <= '0;
      bus.q_ready   <= '0;
    endtask

    task cycle_start;
      #TT;
    endtask

    task cycle_end;
      @(posedge bus.clk_i);
    endtask

    // Send a request.
    task send_req (input int_c_req_t req);
      if (const_hart_id) begin
        assert(req.hart_id == hart_id) else
          $error("req.hart_id = %0x, sender.hart_id = %0x", req.hart_id, hart_id);
      end
      bus.q_addr       <= #TA req.addr;
      bus.q_instr_data <= #TA req.instr_data;
      bus.q_rs         <= #TA req.rs;
      bus.q_hart_id    <= #TA req.hart_id;
      bus.q_valid      <= #TA 1;
      cycle_start();
      while (bus.q_ready != 1) begin cycle_end(); cycle_start(); end
      cycle_end();
      bus.q_addr       <= #TA '0;
      bus.q_instr_data <= #TA '0;
      bus.q_rs         <= #TA '0;
      bus.q_hart_id    <= #TA const_hart_id ? hart_id : '0;
      bus.q_valid      <= #TA  0;
    endtask

    // Send a response.
    task send_rsp(input int_c_rsp_t rsp);
      bus.p_data    <= #TA rsp.data;
      bus.p_dualwb  <= #TA rsp.dualwb;
      bus.p_hart_id <= #TA rsp.hart_id;
      bus.p_rd      <= #TA rsp.rd;
      bus.p_error   <= #TA rsp.error;
      bus.p_valid   <= #TA 1;
      cycle_start();
      while (bus.p_ready != 1) begin cycle_end(); cycle_start(); end
      cycle_end();
      bus.p_data    <= #TA '0;
      bus.p_dualwb  <= #TA '0;
      bus.p_hart_id <= #TA '0;
      bus.p_rd      <= #TA '0;
      bus.p_error   <= #TA '0;
      bus.p_valid   <= #TA 0;
    endtask

    // Receive a request.
    task recv_req (output int_c_req_t req );
      bus.q_ready <= #TA 1;
      cycle_start();
      while (bus.q_valid != 1) begin cycle_end(); cycle_start(); end
      req            = new;
      req.addr       = bus.q_addr;
      req.instr_data = bus.q_instr_data;
      req.rs         = bus.q_rs;
      req.hart_id    = bus.q_hart_id;
      cycle_end();
      bus.q_ready <= #TA 0;
    endtask

    // Receive a response.
    task recv_rsp (output int_c_rsp_t rsp);
      bus.p_ready <= #TA 1;
      cycle_start();
      while (bus.p_valid != 1) begin cycle_end(); cycle_start(); end
      rsp         = new;
      rsp.data    = bus.p_data;
      rsp.dualwb  = bus.p_dualwb;
      rsp.error   = bus.p_error;
      rsp.hart_id = bus.p_hart_id;
      rsp.rd      = bus.p_rd;
      cycle_end();
      bus.p_ready <= #TA 0;
    endtask

    // Monitor request
    task mon_req (output int_c_req_t req);
      cycle_start();
      while (!(bus.q_valid && bus.q_ready)) begin cycle_end(); cycle_start(); end
      req            = new;
      req.addr       = bus.q_addr;
      req.instr_data = bus.q_instr_data;
      req.rs         = bus.q_rs;
      req.hart_id    = bus.q_hart_id;
      cycle_end();
    endtask

    // Monitor response.
    task mon_rsp (output int_c_rsp_t rsp);
      cycle_start();
      while (!(bus.p_valid &&bus.p_ready)) begin cycle_end(); cycle_start(); end
      rsp         = new;
      rsp.data    = bus.p_data;
      rsp.dualwb  = bus.p_dualwb;
      rsp.error   = bus.p_error;
      rsp.hart_id = bus.p_hart_id;
      rsp.rd      = bus.p_rd;
      cycle_end();
    endtask

  endclass

  // Super classes for random acc drivers
  virtual class rand_c #(
    // Acc interface parameters
    parameter int DataWidth = -1,
    parameter int AddrWidth = -1,
    parameter bit DualWriteback = 0,
    parameter bit TernaryOps    = 0,
    // Stimuli application and test time
    parameter time TA = 0ps,
    parameter time TT = 0ps
  );

    localparam int unsigned NumRs = TernaryOps ? 3 : 2;
    localparam int unsigned NumWb = DualWriteback ? 2 : 1;

    typedef c_req_t #(
      .DataWidth ( DataWidth ),
      .AddrWidth ( AddrWidth ),
      .NumRs     ( NumRs     )
    ) int_c_req_t;

    typedef c_rsp_t #(
      .DataWidth ( DataWidth ),
      .NumWb     ( NumWb     )
    ) int_c_rsp_t;

    typedef acc_test::acc_c_driver #(
      .AddrWidth     ( AddrWidth     ),
      .DataWidth     ( DataWidth     ),
      .DualWriteback ( DualWriteback ),
      .TernaryOps    ( TernaryOps    ),
      .TA            ( TA            ),
      .TT            ( TT            )
    ) acc_c_driver_t;

    acc_c_driver_t drv;

    function new(
      virtual ACC_C_BUS_DV #(
        .DataWidth     ( DataWidth     ),
        .AddrWidth     ( AddrWidth     ),
        .DualWriteback ( DualWriteback ),
        .TernaryOps    ( TernaryOps    )
      ) bus,
      int hart_id = -1
    );
      this.drv = new (bus, hart_id);
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

  class rand_hart_id;
    rand int hart_id;
    constraint positive_hart_id_c {
      hart_id >= 0;
    }
  endclass

  // Generate random requests as a master device.
  class rand_c_master #(
    // Acc interface parameters
    parameter int DataWidth       = -1,
    parameter int AccAddrWidth    = -1,
    parameter int AddrWidth       = -1,
    parameter int NumHier         = -1,
    parameter int HierLevel       = -1,
    parameter int NumRsp[NumHier] = '{-1},
    parameter bit DualWriteback   = 0,
    parameter bit TernaryOps      = 0,
    // Stimuli application and test time
    parameter time         TA                  = 0ps,
    parameter time         TT                  = 0ps,
    parameter int unsigned REQ_MIN_WAIT_CYCLES = 1,
    parameter int unsigned REQ_MAX_WAIT_CYCLES = 20,
    parameter int unsigned RSP_MIN_WAIT_CYCLES = 1,
    parameter int unsigned RSP_MAX_WAIT_CYCLES = 20
  ) extends rand_c #(
      .DataWidth     ( DataWidth     ),
      .AddrWidth     ( AddrWidth     ),
      .DualWriteback ( DualWriteback ),
      .TernaryOps    ( TernaryOps    ),
      .TA            ( TA            ),
      .TT            ( TT            )
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
        .DataWidth     ( DataWidth     ),
        .AddrWidth     ( AddrWidth     ),
        .DualWriteback ( DualWriteback ),
        .TernaryOps    ( TernaryOps    )
      ) bus,
      int hart_id
    );
      super.new(bus, hart_id);
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
        if (drv.const_hart_id) req.hart_id = drv.hart_id;
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

  // The slave modules do not know the hart_ids connected to it.
  // Therefore we cannot directly index into the mailbox array.
  // know the exact hart ids connected to it.
  // This class facilitates automatic mapping of hart_ids to corresponding
  // mailboxes.
  class mailbox_container #(
    parameter int  NumMbx = -1,
    parameter type msg_t  = logic,
    parameter type idx_t  = logic
  );
    mailbox mbx[NumMbx];
    int unsigned mbx_pointer[idx_t];
    int unsigned idx_pointer[logic[cf_math_pkg::idx_width(NumMbx)-1:0]];
    int unsigned mbx_next = 0;

    // This event is triggered once a mailbox is assigned a hart_id.
    // `get` functions waiting for specific hart_id mailboxes must wait for
    // this assignement to happen.
    event e_mbx_assigned [logic[31:0]];

    function new;
      foreach (mbx[ii]) mbx[ii] = new;
    endfunction

    function automatic event new_event();
      event e;
      return e;
    endfunction

    task put(input msg_t msg, input idx_t idx);
      if (!mbx_pointer.exists(idx)) begin
        if(!e_mbx_assigned.exists(idx)) begin
          this.e_mbx_assigned[idx] = new_event();
        end
        assert(mbx_next <= NumMbx);
        mbx_pointer[idx] = mbx_next;
        idx_pointer[mbx_next] = idx;
        -> e_mbx_assigned[idx];
        mbx_next++;
      end
      mbx[mbx_pointer[idx]].put(msg);
    endtask

    function automatic int num(idx_t idx);
      if (!mbx_pointer.exists(idx)) begin
        return 0;
      end else begin
        return mbx[mbx_pointer[idx]].num();
      end
    endfunction

    function automatic int num_direct(int i);
      assert(i < NumMbx);
      return mbx[i].num();
    endfunction

    task get(output msg_t msg, input idx_t idx);
      if (!mbx_pointer.exists(idx)) begin
        if(!e_mbx_assigned.exists(idx)) begin
          this.e_mbx_assigned[idx] = new_event();
        end
        @(e_mbx_assigned[idx]);
        assert(mbx_pointer.exists(idx));
      end
      mbx[mbx_pointer[idx]].get(msg);
    endtask

    task get_direct(output msg_t msg, input int i);
      assert(i < NumMbx);
      mbx[i].get(msg);
    endtask

    task peek(output msg_t msg, input idx_t idx);
      if (!mbx_pointer.exists(idx)) begin
        @(e_mbx_assigned[idx]);
        assert(mbx_pointer.exists(idx));
      end
      msg=new;
      mbx[mbx_pointer[idx]].peek(msg);
    endtask

    task peek_direct(output msg_t msg, input int i);
      assert(i < NumMbx);
      mbx[i].peek(msg);
    endtask

    function try_get(output msg_t msg, input idx_t idx);
      if (!mbx_pointer.exists(idx)) begin
        return 0;
      end
      return mbx[mbx_pointer[idx]].try_get(msg);
    endfunction

    // try_get message from random mailbox, if any.
    function automatic bit try_get_random(output msg_t msg);
      automatic int mbx_id[NumMbx];
      automatic bit msg_found = 1'b0;
      for (int i = 0; i < NumMbx; i++) begin
        mbx_id[i] = i;
      end
      mbx_id.shuffle();
      for (int i = 0; i < NumMbx; i++) begin
        if(idx_pointer.exists(mbx_id[i])) begin
          msg_found |= try_get(msg, idx_pointer[mbx_id[i]]);
        end
        if (msg_found) break;
      end
      return msg_found;
    endfunction

    function automatic bit empty();
      automatic bit result = 1;
      for (int i = 0; i < NumMbx; i++) begin
        result &= (mbx[i].num() == 0);
      end
      return result;
    endfunction

  endclass

  class rand_c_slave #(
    // Acc interface parameters
    parameter int AddrWidth     = -1,
    parameter int DataWidth     = -1,
    parameter int NumReq        = -1,
    parameter bit DualWriteback = 0,
    parameter bit TernaryOps    = 0,
    // Stimuli application and test time
    parameter int unsigned REQ_MIN_WAIT_CYCLES = 0,
    parameter int unsigned REQ_MAX_WAIT_CYCLES = 10,
    parameter int unsigned RSP_MIN_WAIT_CYCLES = 0,
    parameter int unsigned RSP_MAX_WAIT_CYCLES = 10,
    parameter time TA = 0ps,
    parameter time TT = 0ps
  ) extends rand_c #(
      .AddrWidth     ( AddrWidth     ),
      .DataWidth     ( DataWidth     ),
      .DualWriteback ( DualWriteback ),
      .TernaryOps    ( TernaryOps    ),
      .TA            ( TA            ),
      .TT            ( TT            )
    );

    mailbox_container #(
        .NumMbx ( NumReq      ),
        .msg_t  ( int_c_req_t ),
        .idx_t  ( logic[31:0] )
      ) req_mbx_cnt;

    /// Constructor.
    function new (
      virtual ACC_C_BUS_DV #(
        .DataWidth     ( DataWidth     ),
        .AddrWidth     ( AddrWidth     ),
        .DualWriteback ( DualWriteback ),
        .TernaryOps    ( TernaryOps    )
      ) bus);
      super.new(bus);
      req_mbx_cnt = new;
    endfunction

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

    task recv_requests();
      forever begin
        automatic int_c_req_t req;
        rand_wait(REQ_MIN_WAIT_CYCLES, REQ_MAX_WAIT_CYCLES);
        this.drv.recv_req(req);
        req_mbx_cnt.put(req, req.hart_id);
      end
    endtask

    // Generate and send random response.
    // The order in which requests from different origins are served is randomized
    task send_responses();
      forever begin
        automatic int_c_rsp_t rsp = new;
        automatic int_c_req_t req;
        automatic bit req_found;
        // get request from random requester mailbox.
        req_found = req_mbx_cnt.try_get_random(req);
        if (req_found==1'b1) begin
          assert(rsp.randomize());
          rsp.hart_id = req.hart_id;
          rsp.rd = req.instr_data[11:7];
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
    parameter int DataWidth     = -1,
    parameter int AddrWidth     = -1,
    parameter int NumReq        = -1,
    parameter bit DualWriteback = 0,
    parameter bit TernaryOps    = 0,
    // Stimuli application and test time
    parameter time  TA = 0ps,
    parameter time  TT = 0ps
  ) extends rand_c #(
        .DataWidth     ( DataWidth     ),
        .AddrWidth     ( AddrWidth     ),
        .DualWriteback ( DualWriteback ),
        .TernaryOps    ( TernaryOps    ),
        .TA            ( TA            ),
        .TT            ( TT            )
  );

    mailbox_container #(
        .NumMbx ( NumReq      ),
        .msg_t  ( int_c_req_t ),
        .idx_t  ( logic[31:0] )
      ) req_mbx_cnt;

    mailbox_container #(
        .NumMbx ( NumReq      ),
        .msg_t  ( int_c_rsp_t ),
        .idx_t  ( logic[31:0] )
      ) rsp_mbx_cnt;

    // Constructor.
    function new (
      virtual ACC_C_BUS_DV #(
        .DataWidth     ( DataWidth     ),
        .AddrWidth     ( AddrWidth     ),
        .DualWriteback ( DualWriteback ),
        .TernaryOps    ( TernaryOps    )
      ) bus);
      super.new(bus);
      req_mbx_cnt = new;
      rsp_mbx_cnt = new;
    endfunction

    // Slave Monitor.
    task monitor;
      fork
        forever begin
          automatic int_c_req_t req;
          this.drv.mon_req(req);
          // put in req mbox corresponding to the requester
          req_mbx_cnt.put(req, req.hart_id);
        end
        forever begin
          automatic int_c_rsp_t rsp;
          this.drv.mon_rsp(rsp);
          // put in req mbox corresponding to the requester
          rsp_mbx_cnt.put(rsp, rsp.hart_id);
        end
      join
    endtask
  endclass

  class acc_c_mst_monitor #(
    // Acc interface parameters
    parameter int DataWidth     = -1,
    parameter int AddrWidth     = -1,
    parameter int AccAddrWidth  = -1,
    parameter int HierLevel     = -1,
    parameter bit DualWriteback = 0,
    parameter bit TernaryOps    = 0,
    // Stimuli application and test time
    parameter time  TA = 0ps,
    parameter time  TT = 0ps
  ) extends rand_c #(
      .DataWidth     ( DataWidth     ),
      .AddrWidth     ( AddrWidth     ),
      .DualWriteback ( DualWriteback ),
      .TernaryOps    ( TernaryOps    ),
      .TA            ( TA            ),
      .TT            ( TT            )
    );

    mailbox req_mbx[AccAddrWidth**2];
    mailbox req_mbx_fwd = new;
    mailbox rsp_mbx = new;

    // Constructor.
    function new (
      virtual ACC_C_BUS_DV #(
        .DataWidth     ( DataWidth     ),
        .AddrWidth     ( AddrWidth     ),
        .DualWriteback ( DualWriteback ),
        .TernaryOps    ( TernaryOps    )
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
    parameter int DataWidth = -1,
    parameter int NumRs     = -1,
    parameter int NumWb     = -1
  );
    // REQ Channel
    randc logic           [         31:0] instr_data;
    rand logic [NumRs-1:0][DataWidth-1:0] rs;
    rand logic            [    NumRs-1:0] rs_valid;
    rand logic            [    NumWb-1:0] rd_clean;
    // ACK channel
    rand logic                            accept;
    rand logic            [    NumWb-1:0] writeback;

    // Helper for randomization
    logic            [    NumRs-1:0] last_rs_valid;
    logic            [    NumWb-1:0] last_rd_clean;
    logic [NumRs-1:0][DataWidth-1:0] last_rs;

    function void post_randomize;
      last_rs_valid = rs_valid;
      last_rd_clean = rd_clean;
      last_rs       = rs;
    endfunction

    task display;
      $display(
              "x_req.instr_data = %x\n",  instr_data,
              "x_req.rs = %x\n",          rs,
              "x_req.rs_valid = %x\n",    rs_valid,
              "x_req.rd_clean = %x\n",    rd_clean,
              "x_req.accept = %x\n",      accept,
              "x_req.writeback = %x\n",   writeback,
              "\n"
            );
    endtask

  endclass


  class x_rsp_t #(
    parameter int DataWidth = -1,
    parameter int NumWb     = -1
  );
    // RSP Channel
    rand logic [NumWb-1:0][DataWidth-1:0] data;
    rand logic                            error;
    rand logic            [          4:0] rd;
    rand logic                            dualwb;

    task display;
      $display(
              "x_rsp.data = %x\n",    data,
              "x_rsp.error = %x\n",   error,
              "x_rsp.rd = %x\n",      rd,
              "x_rsp.dualwb = %x\n",  dualwb,
              "\n"
            );
    endtask

  endclass

  class acc_x_driver #(
    parameter int DataWidth     = -1,
    parameter bit DualWriteback = 0,
    parameter bit TernaryOps    = 0,
    parameter time TA           = 0, // stimuli application time
    parameter time TT           = 0  // stimuli test time
  );
    localparam int unsigned NumRs = TernaryOps ? 3 : 2;
    localparam int unsigned NumWb = DualWriteback ? 2 : 1;

    typedef x_req_t #(
      .DataWidth ( DataWidth ),
      .NumRs     ( NumRs     ),
      .NumWb     ( NumWb     )
    ) int_x_req_t;

    typedef x_rsp_t #(
      .DataWidth ( DataWidth ),
      .NumWb     ( NumWb     )
    ) int_x_rsp_t;

    virtual ACC_X_BUS_DV #(
      .DataWidth     ( DataWidth     ),
      .DualWriteback ( DualWriteback ),
      .TernaryOps    ( TernaryOps    )
    ) bus;

    function new(
      virtual ACC_X_BUS_DV #(
        .DataWidth     ( DataWidth     ),
        .DualWriteback ( DualWriteback ),
        .TernaryOps    ( TernaryOps    )
      ) bus
    );
      this.bus=bus;
    endfunction

    task reset_master;
      bus.q_instr_data <= '0;
      bus.q_rs         <= '0;
      bus.q_rs_valid   <= '0;
      bus.q_rd_clean   <= '0;
      bus.q_valid      <= '0;
      bus.p_ready      <= '0;
    endtask

    task reset_slave;
      bus.q_ready     <= '0;
      bus.k_accept    <= '0;
      bus.k_writeback <= '0;
      bus.p_data      <= '0;
      bus.p_dualwb    <= '0;
      bus.p_rd        <= '0;
      bus.p_error     <= '0;
      bus.p_valid     <= '0;
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
      bus.q_rs         <= #TA req.rs;
      bus.q_rs_valid   <= #TA req.rs_valid;
      bus.q_rd_clean   <= #TA req.rd_clean;
      bus.q_valid      <= #TA 1;
      cycle_start();
      while (bus.q_ready != 1) begin
        // update source regs, rs_valid, rd_clean
        assert(req.randomize(rs) with
          {
            // rsx may change if valid bit not set
            foreach(rs[i]) if(rs_valid[i] == 1'b1) rs[i] == last_rs[i];
          }
        );
        assert(
          req.randomize(rs_valid) with {
            // valid rs may not become invalid.
            foreach(rs_valid[i]) last_rs_valid[i] == 1'b1 -> rs_valid[i] == 1'b1;
          }
        );
        assert(
          req.randomize(rd_clean) with {
            // clean rd may not become dirty during transaction.
            foreach(rd_clean[i]) last_rd_clean[i] == 1'b1 -> rd_clean[i] == 1'b1;
          }
        );
        bus.q_rs_valid <= #TA req.rs_valid;
        bus.q_rd_clean <= #TA req.rd_clean;
        bus.q_rs       <= #TA req.rs;
        cycle_end();
        cycle_start();
      end
      cycle_end();
      bus.q_valid  <= #TA '0;
      req.writeback = bus.k_writeback;
      req.accept    = bus.k_accept;
    endtask

    // Send a response.
    task send_rsp(input int_x_rsp_t rsp);
      bus.p_data   <= #TA rsp.data;
      bus.p_dualwb <= #TA rsp.dualwb;
      bus.p_rd     <= #TA rsp.rd;
      bus.p_error  <= #TA rsp.error;
      bus.p_valid  <= #TA 1;
      cycle_start();
      while (bus.p_ready != 1) begin cycle_end(); cycle_start(); end
      cycle_end();
      bus.p_data   <= #TA '0;
      bus.p_dualwb <= #TA '0;
      bus.p_rd     <= #TA '0;
      bus.p_error  <= #TA '0;
      bus.p_valid  <= #TA 0;
    endtask

    // Receive a request and send acknowlegment signals
    task recv_req(inout int_x_req_t req);
      bus.q_ready     <= #TA 1;
      bus.k_accept    <= #TA req.accept;
      bus.k_writeback <= #TA req.writeback;
      while (bus.q_valid != 1) begin cycle_end(); cycle_start(); end
      req            = new;
      req.instr_data = bus.q_instr_data;
      req.rs         = bus.q_rs;
      req.rs_valid   = bus.q_rs_valid;
      req.rd_clean   = bus.q_rd_clean;
      cycle_end();
      bus.q_ready     <= #TA 0;
      bus.k_accept    <= #TA '0;
      bus.k_writeback <= #TA '0;
    endtask

    // Receive a response.
    task recv_rsp(output int_x_rsp_t rsp);
      bus.p_ready <= #TA 1;
      cycle_start();
      while (bus.p_valid != 1) begin cycle_end(); cycle_start(); end
      rsp        = new;
      rsp.data   = bus.p_data;
      rsp.dualwb = bus.p_dualwb;
      rsp.error  = bus.p_error;
      rsp.rd     = bus.p_rd;
      cycle_end();
      bus.p_ready <= #TA 0;
    endtask

    // Monitor request
    task mon_req (output int_x_req_t req);
      cycle_start();
      while (!(bus.q_valid && bus.q_ready)) begin cycle_end(); cycle_start(); end
      req            = new;
      req.instr_data = bus.q_instr_data;
      req.rs         = bus.q_rs;
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
      rsp        = new;
      rsp.data   = bus.p_data;
      rsp.dualwb = bus.p_dualwb;
      rsp.error  = bus.p_error;
      rsp.rd     = bus.p_rd;
      cycle_end();
    endtask

  endclass

  // Super Class for random x drivers
  virtual class rand_x #(
    // Acc Adapter interface parameters
    parameter int DataWidth     = -1,
    parameter bit DualWriteback = 0,
    parameter bit TernaryOps    = 0,
    // Stimuli application and test time
    parameter time TA = 0ps,
    parameter time TT = 0ps
  );
    localparam int unsigned NumRs = TernaryOps ? 3 : 2;
    localparam int unsigned NumWb = DualWriteback ? 2 : 1;

    typedef x_req_t #(
      .DataWidth ( DataWidth ),
      .NumRs     ( NumRs     ),
      .NumWb     ( NumWb     )
    ) int_x_req_t;

    typedef x_rsp_t #(
      .DataWidth ( DataWidth ),
      .NumWb     ( NumWb     )
    ) int_x_rsp_t;

    typedef acc_test::acc_x_driver #(
      .DataWidth     ( DataWidth     ),
      .DualWriteback ( DualWriteback ),
      .TernaryOps    ( TernaryOps    ),
      .TA            ( TA            ),
      .TT            ( TT            )
    ) acc_x_driver_t;

    acc_x_driver_t drv;

    function new(
      virtual ACC_X_BUS_DV #(
        .DataWidth   ( DataWidth     ),
      .DualWriteback ( DualWriteback ),
      .TernaryOps    ( TernaryOps    )
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
    parameter int          DataWidth           = -1,
    parameter bit          DualWriteback       = 0,
    parameter bit          TernaryOps          = 0,
    parameter time         TA                  = 0ps,
    parameter time         TT                  = 0ps,
    parameter int unsigned REQ_MIN_WAIT_CYCLES = 1,
    parameter int unsigned REQ_MAX_WAIT_CYCLES = 20,
    parameter int unsigned RSP_MIN_WAIT_CYCLES = 1,
    parameter int unsigned RSP_MAX_WAIT_CYCLES = 20
  ) extends rand_x #(
    .DataWidth     ( DataWidth     ),
    .DualWriteback ( DualWriteback ),
    .TernaryOps    ( TernaryOps    ),
    .TA            ( TA            ),
    .TT            ( TT            )
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
        .DataWidth     ( DataWidth     ),
        .DualWriteback ( DualWriteback ),
        .TernaryOps    ( TernaryOps    )
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
    parameter int          DataWidth           = -1,
    parameter bit          DualWriteback       = 0,
    parameter bit          TernaryOps          = 0,
    parameter time         TA                  = 0ps,
    parameter time         TT                  = 0ps,
    parameter int unsigned REQ_MIN_WAIT_CYCLES = 1,
    parameter int unsigned REQ_MAX_WAIT_CYCLES = 20,
    parameter int unsigned RSP_MIN_WAIT_CYCLES = 1,
    parameter int unsigned RSP_MAX_WAIT_CYCLES = 20
  ) extends rand_x #(
    .DualWriteback ( DualWriteback ),
    .TernaryOps    ( TernaryOps    ),
    .DataWidth     ( DataWidth     ),
    .TA            ( TA            ),
    .TT            ( TT            )
  );

    mailbox req_mbx = new();

    // Reset Driver
    task reset();
      drv.reset_slave();
    endtask

    // Consructor
    function new(
      virtual ACC_X_BUS_DV #(
        .DataWidth     ( DataWidth     ),
        .DualWriteback ( DualWriteback ),
        .TernaryOps    ( TernaryOps    )
      ) bus );
      super.new(bus);
    endfunction

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
    parameter int  DataWidth     = -1,
    parameter bit  DualWriteback = 0,
    parameter bit  TernaryOps    = 0,
    parameter time TA            = 0ps,
    parameter time TT            = 0ps
  ) extends rand_x #(
    .DataWidth     ( DataWidth     ),
    .DualWriteback ( DualWriteback ),
    .TernaryOps    ( TernaryOps    ),
    .TA            ( TA            ),
    .TT            ( TT            )
  );

    mailbox req_mbx          = new();
    mailbox rsp_mbx          = new();
    mailbox req_mbx_rejected = new();

    // Constructor
    function new(
      virtual ACC_X_BUS_DV #(
        .DataWidth     ( DataWidth     ),
        .DualWriteback ( DualWriteback ),
        .TernaryOps    ( TernaryOps    )
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
      // Hart ID irrelevant for X Response
      return c_rsp.data   == x_rsp.data &&
             c_rsp.error  == x_rsp.error &&
             c_rsp.rd     == x_rsp.rd    &&
             c_rsp.dualwb == x_rsp.dualwb;
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
    parameter int NumRspTot = -1,
    parameter time TA       = 0ps,
    parameter time TT       = 0ps
  );

    typedef acc_test::acc_prd_driver #(
      .TT(TT),
      .TA(TA)
    ) acc_prd_driver_t;

    acc_prd_driver_t drv[NumRspTot];

    virtual ACC_PRD_BUS_DV bus [NumRspTot];

    function new (virtual ACC_PRD_BUS_DV bus[NumRspTot]);
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
    parameter type acc_c_req_t   = logic,
    parameter type acc_x_req_t   = logic,
    parameter type acc_prd_rsp_t = logic,
    parameter int  NumRs         = -1
  );

    // Check construction of interconnect request from predecoder response
    // + adapter request.
    static function do_check (acc_x_req_t x_req, acc_prd_rsp_t prd_rsp, acc_c_req_t c_req);
      automatic bit result = 1;
      // Check result (Address is checked externally.
      for (int i = 0; i < NumRs; i++) begin
        result &=(c_req.rs[i] == (prd_rsp.use_rs[i] ? x_req.rs[i] : '0));
      end
      result &= (c_req.instr_data   == x_req.instr_data);
      return result;
    endfunction

  endclass


endpackage
