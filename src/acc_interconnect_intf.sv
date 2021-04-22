`include "acc_interface/assign.svh"
`include "acc_interface/typedef.svh"

module acc_interconnect_intf #(
    parameter int unsigned HierLevel     = 0,
    // The number of requesters
    parameter int          NumReq        = 0,
    // The number of rsponders.
    parameter int          NumRsp        = 0,
    // Insert Pipeline register into request path
    parameter bit          RegisterReq   = 0,
    // Insert Pipeline register into response path
    parameter bit          RegisterRsp   = 0
) (
    input clk_i,
    input rst_ni,

    ACC_C_BUS    acc_c_slv         [NumReq],
    ACC_C_BUS    acc_c_mst_next    [NumReq],
    ACC_C_BUS    acc_c_mst         [NumRsp],
    ACC_CMEM_BUS acc_cmem_mst      [NumReq],
    ACC_CMEM_BUS acc_cmem_slv_next [NumReq],
    ACC_CMEM_BUS acc_cmem_slv      [NumRsp]
);
  import acc_pkg::*;

  typedef logic [DataWidth-1:0]  data_t;
  typedef logic [AddrWidth-1:0]  addr_t;

  acc_c_req_t    [NumReq-1:0] acc_c_slv_req;
  acc_c_rsp_t    [NumReq-1:0] acc_c_slv_rsp;
  acc_cmem_req_t [NumReq-1:0] acc_cmem_mst_req;
  acc_cmem_rsp_t [NumReq-1:0] acc_cmem_mst_rsp;

  acc_c_req_t    [NumReq-1:0] acc_c_mst_next_req;
  acc_c_rsp_t    [NumReq-1:0] acc_c_mst_next_rsp;
  acc_cmem_req_t [NumReq-1:0] acc_cmem_slv_next_req;
  acc_cmem_rsp_t [NumReq-1:0] acc_cmem_slv_next_rsp;

  acc_c_req_t    [NumRsp-1:0] acc_c_mst_req;
  acc_c_rsp_t    [NumRsp-1:0] acc_c_mst_rsp;
  acc_cmem_req_t [NumRsp-1:0] acc_cmem_slv_req;
  acc_cmem_rsp_t [NumRsp-1:0] acc_cmem_slv_rsp;


  acc_interconnect #(
      .HierLevel           ( HierLevel           ),
      .NumReq              ( NumReq              ),
      .NumRsp              ( NumRsp              ),
      .RegisterReq         ( RegisterReq         ),
      .RegisterRsp         ( RegisterRsp         )
  ) acc_interconnect_i (
      .clk_i                   ( clk_i                 ),
      .rst_ni                  ( rst_ni                ),
      .acc_c_slv_req_i         ( acc_c_slv_req         ),
      .acc_c_slv_rsp_o         ( acc_c_slv_rsp         ),
      .acc_cmem_mst_req_o      ( acc_cmem_mst_req      ),
      .acc_cmem_mst_rsp_i      ( acc_cmem_mst_rsp      ),
      .acc_c_mst_next_req_o    ( acc_c_mst_next_req    ),
      .acc_c_mst_next_rsp_i    ( acc_c_mst_next_rsp    ),
      .acc_cmem_slv_next_req_i ( acc_cmem_slv_next_req ),
      .acc_cmem_slv_next_rsp_o ( acc_cmem_slv_next_rsp ),
      .acc_c_mst_req_o         ( acc_c_mst_req         ),
      .acc_c_mst_rsp_i         ( acc_c_mst_rsp         ),
      .acc_cmem_slv_req_i      ( acc_cmem_slv_req      ),
      .acc_cmem_slv_rsp_o      ( acc_cmem_slv_rsp      )
  );

  for (genvar i = 0; i < NumReq; i++) begin : gen_c_slv_interface_assignement
    `ACC_C_ASSIGN_TO_REQ(acc_c_slv_req[i], acc_c_slv[i])
    `ACC_C_ASSIGN_FROM_RESP(acc_c_slv[i], acc_c_slv_rsp[i])
  end
  for (genvar i = 0; i < NumRsp; i++) begin : gen_c_mst_interface_assignement
    `ACC_C_ASSIGN_FROM_REQ(acc_c_mst[i], acc_c_mst_req[i])
    `ACC_C_ASSIGN_TO_RESP(acc_c_mst_rsp[i], acc_c_mst[i])
  end
  for (genvar i = 0; i < NumReq; i++) begin : gen_c_mst_next_interface_assignement
    `ACC_C_ASSIGN_FROM_REQ(acc_c_mst_next[i], acc_c_mst_next_req[i])
    `ACC_C_ASSIGN_TO_RESP(acc_c_mst_next_rsp[i], acc_c_mst_next[i])
  end

  for (genvar i = 0; i < NumReq; i++) begin : gen_cmem_mst_interface_assignement
    `ACC_CMEM_ASSIGN_TO_RESP(acc_cmem_mst_rsp[i], acc_cmem_mst[i])
    `ACC_CMEM_ASSIGN_FROM_REQ(acc_cmem_mst[i], acc_cmem_mst_req[i])
  end
  for (genvar i = 0; i < NumRsp; i++) begin : gen_cmem_slv_interface_assignement
    `ACC_CMEM_ASSIGN_FROM_RESP(acc_cmem_slv[i], acc_cmem_slv_rsp[i])
    `ACC_CMEM_ASSIGN_TO_REQ(acc_cmem_slv_req[i], acc_cmem_slv[i])
  end
  for (genvar i = 0; i < NumReq; i++) begin : gen_cmem_slv_next_interface_assignement
    `ACC_CMEM_ASSIGN_FROM_RESP(acc_cmem_slv_next[i], acc_cmem_slv_next_rsp[i])
    `ACC_CMEM_ASSIGN_TO_REQ(acc_cmem_slv_next_req[i], acc_cmem_slv_next[i])
  end

endmodule
