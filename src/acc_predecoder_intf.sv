`include "acc_interface/assign.svh"

module acc_predecoder_intf #(
    parameter int NumInstr = 1,
    parameter acc_pkg::offload_instr_t OffloadInstr[NumInstr] = {0}
) (
    ACC_PRD_BUS prd
);

  acc_pkg::acc_prd_req_t prd_req;
  acc_pkg::acc_prd_rsp_t prd_rsp;

  `ACC_PRD_ASSIGN_TO_RESP(prd_rsp, prd)
  `ACC_PRD_ASSIGN_FROM_REQ(prd, prd_req)

  acc_predecoder #(
      .NumInstr     ( NumInstr     ),
      .OffloadInstr ( OffloadInstr )
  ) acc_predecoder_i (
      .prd_req_i ( prd_req ),
      .prd_rsp_o ( prd_rsp )
  );

endmodule
