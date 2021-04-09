// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Noam Gallmann <gnoam@live.com>

`include "acc_interface/assign.svh"
`include "acc_interface/typedef.svh"

module acc_adapter_tb #(
  parameter int unsigned DataWidth       = 32,
  parameter int          NumHier         = 3,
  parameter int          NumRsp[NumHier] = '{4,2,2},
  parameter int          NumRspTot       = sumn(NumRsp, NumHier),
  parameter bit          DualWriteback   = 1'b1,
  parameter bit          TernaryOps      = 1'b1,
  // TB Params
  parameter int unsigned NrRandomTransactions = 1000
);

  import acc_pkg::*;
  localparam int unsigned MaxNumRsp     = maxn(NumRsp, NumHier);
  localparam int unsigned HierAddrWidth = cf_math_pkg::idx_width(NumHier);
  localparam int unsigned AccAddrWidth  = cf_math_pkg::idx_width(MaxNumRsp);
  localparam int unsigned AddrWidth     = HierAddrWidth + AccAddrWidth;
  localparam int unsigned NumRs         = TernaryOps ? 3 : 2;
  localparam int unsigned NumWb         = DualWriteback ? 2 : 1;

  // Timing params
  localparam time ClkPeriod = 10ns;
  localparam time ApplTime  = 2ns;
  localparam time TestTime  = 8ns;

  logic clk, rst_n;

  acc_test::rand_hart_id  hid = new;
  logic [DataWidth-1:0] hart_id = hid.hart_id;

  // ----------------
  // Clock generation
  // ----------------
  initial begin
    rst_n = 0;
    repeat (3) begin
      #(ClkPeriod / 2) clk = 0;
      #(ClkPeriod / 2) clk = 1;
    end
    rst_n = 1;
    forever begin
      #(ClkPeriod / 2) clk = 0;
      #(ClkPeriod / 2) clk = 1;
    end
  end

  typedef acc_test::c_req_t #(
    .AddrWidth ( AddrWidth ),
    .DataWidth ( DataWidth ),
    .NumRs     ( NumRs     )
  ) tb_c_req_t;

  typedef acc_test::c_rsp_t #(
    .DataWidth ( DataWidth ),
    .NumWb     ( NumWb     )
  ) tb_c_rsp_t;

  typedef acc_test::cmem_req_t #(
    .AddrWidth ( AddrWidth ),
    .DataWidth ( DataWidth )
  ) tb_cmem_req_t;

  typedef acc_test::cmem_rsp_t #(
    .AddrWidth ( AddrWidth ),
    .DataWidth ( DataWidth )
  ) tb_cmem_rsp_t;

  typedef acc_test::x_req_t #(
    .DataWidth ( DataWidth ),
    .NumRs     ( NumRs     ),
    .NumWb     ( NumWb     )
  ) tb_x_req_t;

  typedef acc_test::x_rsp_t #(
    .DataWidth ( DataWidth ),
    .NumWb     ( NumWb     )
  ) tb_x_rsp_t;

  typedef acc_test::xmem_req_t #(
    .DataWidth ( DataWidth )
  ) tb_xmem_req_t;

  typedef acc_test::xmem_rsp_t #(
    .DataWidth ( DataWidth )
  ) tb_xmem_rsp_t;

  typedef acc_test::prd_req_t tb_prd_req_t;
  typedef acc_test::prd_rsp_t tb_prd_rsp_t;

  // From / to core
  ACC_X_BUS #(
    .DataWidth     ( DataWidth     ),
    .DualWriteback ( DualWriteback ),
    .TernaryOps    ( TernaryOps    )
  ) x_master ();

  ACC_X_BUS_DV #(
    .DataWidth     ( DataWidth     ),
    .DualWriteback ( DualWriteback ),
    .TernaryOps    ( TernaryOps    )
  ) x_master_dv (
    clk
  );

  ACC_XMEM_BUS #(
    .DataWidth     ( DataWidth     )
  ) xmem_slave ();

  ACC_XMEM_BUS_DV #(
    .DataWidth     ( DataWidth     )
  ) xmem_slave_dv (
    clk
  );

  // From / to interconnect
  ACC_C_BUS #(
    .AddrWidth     ( AddrWidth     ),
    .DataWidth     ( DataWidth     ),
    .DualWriteback ( DualWriteback ),
    .TernaryOps    ( TernaryOps    )
  ) c_slave ();

  ACC_C_BUS_DV #(
    .AddrWidth     ( AddrWidth     ),
    .DataWidth     ( DataWidth     ),
    .DualWriteback ( DualWriteback ),
    .TernaryOps    ( TernaryOps    )
  ) c_slave_dv (
    clk
  );

  ACC_CMEM_BUS #(
    .AddrWidth     ( AddrWidth     ),
    .DataWidth     ( DataWidth     )
  ) cmem_master ();

  ACC_CMEM_BUS_DV #(
    .AddrWidth     ( AddrWidth     ),
    .DataWidth     ( DataWidth     )
  ) cmem_master_dv (
    clk
  );

  // From / to predecoders
  ACC_PRD_BUS prd_master[NumRspTot] ();

  ACC_PRD_BUS_DV prd_master_dv[NumRspTot] (clk);

  // Interface assignments
  `ACC_C_ASSIGN(c_slave_dv, c_slave)

  `ACC_X_ASSIGN(x_master, x_master_dv)

  `ACC_XMEM_ASSIGN(xmem_slave_dv, xmem_slave)

  `ACC_CMEM_ASSIGN(cmem_master, cmem_master_dv)

  for (genvar i = 0; i < NumRspTot; i++) begin : gen_predecoder_intf_assign
    `ACC_PRD_ASSIGN(prd_master_dv[i], prd_master[i])
  end

  // --------
  // Monitors
  // --------
  typedef acc_test::acc_c_slv_monitor #(
    .DataWidth     ( DataWidth     ),
    .AddrWidth     ( AddrWidth     ),
    .NumReq        ( 1             ),
    .DualWriteback ( DualWriteback ),
    .TernaryOps    ( TernaryOps    ),
    .TA            ( ApplTime      ),
    .TT            ( TestTime      )
  ) acc_c_slv_monitor_t;

  typedef acc_test::acc_cmem_mst_monitor #(
    .DataWidth     ( DataWidth     ),
    .AddrWidth     ( AddrWidth     ),
    .NumReq        ( 1             ),
    .TA            ( ApplTime      ),
    .TT            ( TestTime      )
  ) acc_cmem_mst_monitor_t;

  typedef acc_test::acc_x_monitor #(
    .DataWidth     ( DataWidth     ),
    .DualWriteback ( DualWriteback ),
    .TernaryOps    ( TernaryOps    ),
    .TA            ( ApplTime      ),
    .TT            ( TestTime      )
  ) acc_x_monitor_t;

  typedef acc_test::acc_xmem_slv_monitor #(
    .DataWidth     ( DataWidth     ),
    .TA            ( ApplTime      ),
    .TT            ( TestTime      )
  ) acc_xmem_slv_monitor_t;

  typedef acc_test::acc_prd_monitor #(
    .TA ( ApplTime ),
    .TT ( TestTime )
  ) acc_prd_monitor_t;


  acc_c_slv_monitor_t acc_c_slv_monitor = new(c_slave_dv);
  initial begin
    @(posedge rst_n);
    acc_c_slv_monitor.monitor();
  end

  acc_cmem_mst_monitor_t acc_cmem_mst_monitor = new(cmem_master_dv);
  initial begin
    @(posedge rst_n);
    acc_cmem_mst_monitor.monitor();
  end

  acc_x_monitor_t acc_x_mst_monitor = new(x_master_dv);
  initial begin
    @(posedge rst_n);
    acc_x_mst_monitor.monitor();
  end

  acc_xmem_slv_monitor_t acc_xmem_slv_monitor = new(xmem_slave_dv);
  initial begin
    @(posedge rst_n);
    acc_xmem_slv_monitor.monitor();
  end

  acc_prd_monitor_t acc_prd_monitor[NumRspTot];
  for (genvar i = 0; i < NumRspTot; i++) begin : gen_predecoder_monitor
    initial begin
      acc_prd_monitor[i] = new(prd_master_dv[i]);
      @(posedge rst_n);
      acc_prd_monitor[i].monitor();
    end
  end

  // -------
  // Drivers
  // -------

  typedef acc_test::rand_c_slave#(
    .AddrWidth     ( AddrWidth     ),
    .DataWidth     ( DataWidth     ),
    .NumReq        ( 1             ),
    .DualWriteback ( DualWriteback ),
    .TernaryOps    ( TernaryOps    ),
    .TA            ( ApplTime      ),
    .TT            ( TestTime      )
  ) rand_c_slave_t;

  typedef acc_test::rand_cmem_master #(
    .DataWidth     ( DataWidth     ),
    .AddrWidth     ( AddrWidth     ),
    .TA            ( ApplTime      ),
    .TT            ( TestTime      )
  ) rand_cmem_master_t;

  typedef acc_test::rand_x_master#(
    .DataWidth     ( DataWidth     ),
    .DualWriteback ( DualWriteback ),
    .TernaryOps    ( TernaryOps    ),
    .TA            ( ApplTime      ),
    .TT            ( TestTime      )
  ) rand_x_master_t;

  typedef acc_test::rand_xmem_slave #(
    .DataWidth     ( DataWidth     ),
    .TA            ( ApplTime      ),
    .TT            ( TestTime      )
  ) rand_xmem_slave_t;

  typedef acc_test::rand_prd_slave_collective #(
    .NumRspTot ( NumRspTot ),
    .TA        ( ApplTime  ),
    .TT        ( TestTime  )
  ) rand_prd_slv_coll_t;

  rand_x_master_t rand_x_master = new(x_master_dv);
  initial begin
    rand_x_master.reset();
    @(posedge rst_n);
    rand_x_master.run(NrRandomTransactions);
  end

  rand_xmem_slave_t rand_xmem_slave = new(xmem_slave_dv);
  initial begin
    rand_xmem_slave.reset();
    @(posedge rst_n);
    rand_xmem_slave.run();
  end

  rand_c_slave_t rand_c_slave = new(c_slave_dv);
  initial begin
    rand_c_slave.reset();
    @(posedge rst_n);
    rand_c_slave.run();
  end

  // cmem_master with random acc_address for each request.
  rand_cmem_master_t rand_cmem_master = new(cmem_master_dv, 0, 1);
  initial begin
    rand_cmem_master.reset();
    @(posedge rst_n);
    rand_cmem_master.run(NrRandomTransactions);
  end

  rand_prd_slv_coll_t rand_prd_slv_coll = new(prd_master_dv);
  initial begin
    rand_prd_slv_coll.reset();
    @(posedge rst_n);
    rand_prd_slv_coll.run();
  end

  // Request generation checker
  let check_req(x_req, prd_rsp, c_req) = acc_test::adp_check_req#(
    .acc_c_req_t   ( tb_c_req_t   ),
    .acc_x_req_t   ( tb_x_req_t   ),
    .acc_prd_rsp_t ( tb_prd_rsp_t ),
    .NumRs         ( NumRs        )
  )::do_check(
    x_req, prd_rsp, c_req
  );

  // Signal comparators
  // TODO: MARK0
  let compare_cx_rsp(c_rsp, x_rsp) = acc_test::compare_cx_rsp#(
      .c_rsp_t(tb_c_rsp_t),
      .x_rsp_t(tb_x_rsp_t)
  )::do_compare(
      c_rsp, x_rsp
  );

  let compare_cmemxmem_rsp(cmem_rsp, xmem_rsp) = acc_test::compare_cmemxmem_rsp#(
      .cmem_rsp_t(tb_cmem_rsp_t),
      .xmem_rsp_t(tb_xmem_rsp_t)
  )::do_compare(
      cmem_rsp, xmem_rsp
  );

  let compare_cmemxmem_req(cmem_req, xmem_req) = acc_test::compare_cmemxmem_req#(
      .cmem_req_t(tb_cmem_req_t),
      .xmem_req_t(tb_xmem_req_t)
  )::do_compare(
      cmem_req, xmem_req
  );
  ////////////////
  // Scoreboard //
  ////////////////

  // X/C Request Path
  // ----------------
  // For each C request entering the interconnect (acc_slave_monitor), check
  //  - Address corresponds to accepting predecoder
  //  - Operands exposed in X Request have been propperly forwarded using mux
  //    signals from predecoder
  //  - instr_data properly forwarded
  // For each rejected request, check that no predecoder has accepted it

  // X/C Response Path
  // -----------------
  // Responses are just randomly generated and forwarded from C-Slave to
  // X-Master.
  // Check that they reach their target and remain the same.

  // XMem/CMem Request and Response Path
  // -----------------------------------
  // For each CMem Response observed at the CMem response output, get the
  // corresponding XMem request + response and CMem Request.
  // - Check that each each XMem request signals observed at the adapter XMem
  //   request output corresponds to a request generated at the CMem
  //   request input.
  // - Check that each CMem response signals observed a the adapter CMem
  //   response output corresponse to a response generated at the adapter XMem
  //   request input.
  // - Check that the accelerator address of each CMem response corresponds
  //   to the accelerator address of the corresponding CMem request.
  initial begin
    automatic int nr_xc_requests           = 0;
    automatic int nr_x_requests_rejected   = 0;
    automatic int nr_xc_responses          = 0;
    automatic bit xc_done                  = 0;
    automatic int nr_xmemcmem_transactions = 0;
    automatic bit xmemcmem_done            = 0;
    @(posedge rst_n);
    fork
      // X/C Request Path
      // ----------------
      // Check accepted requests
      forever begin
        automatic tb_x_req_t x_req;
        automatic tb_c_req_t c_req;
        automatic tb_prd_rsp_t prd_rsp;
        automatic tb_prd_req_t prd_req;
        automatic int prd_id, i;
        // Wait for a request at the interconnect output
        acc_c_slv_monitor.req_mbx_cnt.get(c_req, hart_id);

        // get predecoder ID
        // level-specific address
        prd_id = c_req.addr[AccAddrWidth-1:0];
        i = 0;
        while (i != c_req.addr[AddrWidth-1:AccAddrWidth]) begin
          // for each level add number of attached Responders
          prd_id += NumRsp[i];
          i++;
        end
        // get accepting predecoder response and request structures and
        // corresponding adapter request.
        assert(acc_prd_monitor[prd_id].req_mbx.try_get(prd_req)) else
          $error("C slave request without corresponding predecoder request");
        assert(acc_prd_monitor[prd_id].rsp_mbx.try_get(prd_rsp)) else
          $error("C slave request without corresponding predecoder response");
        assert(acc_x_mst_monitor.req_mbx.try_get(x_req)) else
          $error("C slave request without corresponding X master request");
        assert((prd_req.instr_data == x_req.instr_data) && (x_req.instr_data == c_req.instr_data))
        else $error("C slave request does not match predecoder or X request");
        assert(check_req(x_req, prd_rsp, c_req)) else
          $error("C slave request construction fault");
        nr_xc_requests++;
      end

      // check rejected requests
      forever begin
        automatic tb_x_req_t x_req;
        // Wait for rejected request
        acc_x_mst_monitor.req_mbx_rejected.get(x_req);
        // Check if any predecoder wanted to accept this request.
        for (int i = 0; i < NumRspTot; i++) begin
          automatic tb_prd_req_t prd_req;
          if (acc_prd_monitor[i].req_mbx.try_peek(prd_req)) begin
            // Instruction data is `randc`
            // no repetitions in 2**32 samples
            assert (prd_req.instr_data != x_req.instr_data) else
              $error("Rejected X master request was accepted by predecoder");
          end
        end
        nr_x_requests_rejected++;
      end

      // X/C Response path
      // -----------------
      forever begin
        automatic tb_x_rsp_t x_rsp;
        //automatic acc_test::x_rsp_t #(32) x_rsp;
        // Seems to be necessary here to explicitly refer to the class from
        // acc_test.
        // TODO: Why doesn't it work with typedef?! Same problem: MARK0
        // questasim raises fatal error:
        // # ** Error: (vsim-7065) Illegal assignment to class work.acc_test::
        // x_rsp_t #(32) from  class work.acc_test::x_rsp_t #(32)
        automatic tb_c_rsp_t c_rsp;
        // Wait for response at X master interface
        acc_x_mst_monitor.rsp_mbx.get(x_rsp);
        // ASSERT: There X response == C response
        assert(acc_c_slv_monitor.rsp_mbx_cnt.try_get(c_rsp, hart_id)) else
          $error("X Master response without corresponding C slave response");
        assert(compare_cx_rsp(c_rsp, x_rsp)) else
          $error("X Master response does not match C slave response");

        nr_xc_responses++;
        if (nr_xc_responses == NrRandomTransactions - nr_x_requests_rejected) xc_done = 1;
      end

      // XMem/CMem Request and Response Path
      // -----------------------------------
      forever begin
        automatic tb_cmem_req_t cmem_req;
        automatic tb_cmem_rsp_t cmem_rsp;
        automatic tb_xmem_req_t xmem_req;
        automatic tb_xmem_rsp_t xmem_rsp;
        acc_cmem_mst_monitor.rsp_mbx.get(cmem_rsp);
        #1;
        assert(acc_cmem_mst_monitor.req_mbx_cnt.try_get_direct(cmem_req, 0)) else
          $error("CMem response without corresponding CMem request.");
        assert(acc_xmem_slv_monitor.req_mbx.try_get(xmem_req)) else
          $error("CMem response without corresponding XMem request.");
        assert(acc_xmem_slv_monitor.rsp_mbx.try_get(xmem_rsp)) else
          $error("CMem response without corresponding XMem response.");
        assert(compare_cmemxmem_req(cmem_req, xmem_req)) else begin
          $error("CMem to XMem request mismatch.");
          cmem_req.display();
          xmem_req.display();
        end
        assert(compare_cmemxmem_rsp(cmem_rsp, xmem_rsp)) else begin
          $error("CMem to XMem response mismatch.");
          cmem_rsp.display();
          xmem_rsp.display();
        end
        assert(cmem_req.addr == cmem_rsp.addr) else
          $error("CMem Request to response address mismatch.");
        nr_xmemcmem_transactions++;
        if (nr_xmemcmem_transactions == NrRandomTransactions) xmemcmem_done = 1;
      end

      // Simulation terminator
      forever begin
        @(posedge clk);
        if(xc_done && xmemcmem_done) $finish;
      end

    join_none
  end

  final begin
    // Request path:
    for (int i = 0; i < NumRspTot; i++) begin
      assert (acc_prd_monitor[i].req_mbx.num() == 0);
    end
    assert(acc_x_mst_monitor.req_mbx.num() == 0);
    assert(acc_x_mst_monitor.req_mbx_rejected.num() == 0);
    assert(acc_c_slv_monitor.req_mbx_cnt.empty());
    // Response path:
    assert(acc_c_slv_monitor.rsp_mbx_cnt.empty());
    assert(acc_x_mst_monitor.rsp_mbx.num() == 0);
    // Memory Intf:
    assert(acc_xmem_slv_monitor.req_mbx.num() == 0);
    assert(acc_xmem_slv_monitor.rsp_mbx.num() == 0);
    assert(acc_cmem_mst_monitor.req_mbx_cnt.empty());
    assert(acc_cmem_mst_monitor.rsp_mbx.num() == 0);
    $display("Checked for non-empty mailboxes");
  end

  // DUT instantiation
  acc_adapter_intf #(
    .DataWidth     ( DataWidth     ),
    .NumHier       ( NumHier       ),
    .NumRsp        ( NumRsp        ),
    .DualWriteback ( DualWriteback ),
    .TernaryOps    ( TernaryOps    )
  ) dut (
    .clk_i        ( clk         ),
    .rst_ni       ( rst_n       ),
    .hart_id_i    ( hart_id     ),
    .acc_x_mst    ( x_master    ),
    .acc_c_slv    ( c_slave     ),
    .acc_xmem_slv ( xmem_slave  ),
    .acc_cmem_mst ( cmem_master ),
    .acc_prd_mst  ( prd_master  )
  );

endmodule
