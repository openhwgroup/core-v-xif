`include "acc_interface/assign.svh"
`include "acc_interface/typedef.svh"

module acc_adapter_intf (
    input clk_i,
    input rst_ni,

    input logic [acc_pkg::DataWidth-1:0] hart_id_i,

    ACC_X_BUS    acc_x_mst,
    ACC_C_BUS    acc_c_slv,
    ACC_XMEM_BUS acc_xmem_slv,
    ACC_CMEM_BUS acc_cmem_mst,
    ACC_PRD_BUS  acc_prd_mst[acc_pkg::NumRspTot]
);
  import acc_pkg::*;

  typedef logic [AddrWidth-1:0] addr_t;
  typedef logic [DataWidth-1:0] data_t;

  acc_prd_req_t [NumRspTot-1:0] acc_prd_req;
  acc_prd_rsp_t [NumRspTot-1:0] acc_prd_rsp;

  acc_x_req_t acc_x_req;
  acc_x_rsp_t acc_x_rsp;
  acc_c_req_t acc_c_req;
  acc_c_rsp_t acc_c_rsp;

  acc_xmem_req_t acc_xmem_req;
  acc_xmem_rsp_t acc_xmem_rsp;
  acc_cmem_req_t acc_cmem_req;
  acc_cmem_rsp_t acc_cmem_rsp;

  acc_adapter acc_adapter_i (
      .clk_i          ( clk_i        ),
      .rst_ni         ( rst_ni       ),
      .hart_id_i      ( hart_id_i    ),
      .acc_x_req_i    ( acc_x_req    ),
      .acc_x_rsp_o    ( acc_x_rsp    ),
      .acc_c_req_o    ( acc_c_req    ),
      .acc_c_rsp_i    ( acc_c_rsp    ),
      .acc_xmem_req_o ( acc_xmem_req ),
      .acc_xmem_rsp_i ( acc_xmem_rsp ),
      .acc_cmem_req_i ( acc_cmem_req ),
      .acc_cmem_rsp_o ( acc_cmem_rsp ),
      .acc_prd_req_o  ( acc_prd_req  ),
      .acc_prd_rsp_i  ( acc_prd_rsp  )
  );

  `ACC_C_ASSIGN_FROM_REQ(acc_c_slv, acc_c_req)
  `ACC_C_ASSIGN_TO_RESP(acc_c_rsp, acc_c_slv)

  `ACC_X_ASSIGN_TO_REQ(acc_x_req, acc_x_mst)
  `ACC_X_ASSIGN_FROM_RESP(acc_x_mst, acc_x_rsp)

  `ACC_CMEM_ASSIGN_TO_REQ(acc_cmem_req, acc_cmem_mst)
  `ACC_CMEM_ASSIGN_FROM_RESP(acc_cmem_mst, acc_cmem_rsp)

  `ACC_XMEM_ASSIGN_FROM_REQ(acc_xmem_slv, acc_xmem_req)
  `ACC_XMEM_ASSIGN_TO_RESP(acc_xmem_rsp, acc_xmem_slv)

  for (genvar i=0; i<NumRspTot; i++) begin : gen_acc_predecoder_intf_assign
    `ACC_PRD_ASSIGN_FROM_REQ(acc_prd_mst[i], acc_prd_req[i])
    `ACC_PRD_ASSIGN_TO_RESP(acc_prd_rsp[i], acc_prd_mst[i])
  end

endmodule
