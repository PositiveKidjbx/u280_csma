// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.1 (win64) Build 3865809 Sun May  7 15:05:29 MDT 2023
// Date        : Mon Oct 14 16:37:48 2024
// Host        : DESKTOP-DVFFB09 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               e:/vivado_ex/xdma_u280_official_ex/xdma_u280_official_ex.srcs/sources_1/ip/xdma_u280_official/xdma_u280_official_stub.v
// Design      : xdma_u280_official
// Purpose     : Stub declaration of top-level module interface
// Device      : xcu280-fsvh2892-2L-e-es1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "xdma_u280_official_core_top,Vivado 2023.1" *)
module xdma_u280_official(sys_clk, sys_clk_gt, sys_rst_n, user_lnk_up, 
  pci_exp_txp, pci_exp_txn, pci_exp_rxp, pci_exp_rxn, axi_aclk, axi_aresetn, usr_irq_req, 
  usr_irq_ack, msi_enable, msi_vector_width, s_axis_c2h_tdata_0, s_axis_c2h_tlast_0, 
  s_axis_c2h_tvalid_0, s_axis_c2h_tready_0, s_axis_c2h_tkeep_0, m_axis_h2c_tdata_0, 
  m_axis_h2c_tlast_0, m_axis_h2c_tvalid_0, m_axis_h2c_tready_0, m_axis_h2c_tkeep_0)
/* synthesis syn_black_box black_box_pad_pin="sys_clk_gt,sys_rst_n,user_lnk_up,pci_exp_txp[15:0],pci_exp_txn[15:0],pci_exp_rxp[15:0],pci_exp_rxn[15:0],axi_aresetn,usr_irq_req[0:0],usr_irq_ack[0:0],msi_enable,msi_vector_width[2:0],s_axis_c2h_tdata_0[511:0],s_axis_c2h_tlast_0,s_axis_c2h_tvalid_0,s_axis_c2h_tready_0,s_axis_c2h_tkeep_0[63:0],m_axis_h2c_tdata_0[511:0],m_axis_h2c_tlast_0,m_axis_h2c_tvalid_0,m_axis_h2c_tready_0,m_axis_h2c_tkeep_0[63:0]" */
/* synthesis syn_force_seq_prim="sys_clk" */
/* synthesis syn_force_seq_prim="axi_aclk" */;
  input sys_clk /* synthesis syn_isclock = 1 */;
  input sys_clk_gt;
  input sys_rst_n;
  output user_lnk_up;
  output [15:0]pci_exp_txp;
  output [15:0]pci_exp_txn;
  input [15:0]pci_exp_rxp;
  input [15:0]pci_exp_rxn;
  output axi_aclk /* synthesis syn_isclock = 1 */;
  output axi_aresetn;
  input [0:0]usr_irq_req;
  output [0:0]usr_irq_ack;
  output msi_enable;
  output [2:0]msi_vector_width;
  input [511:0]s_axis_c2h_tdata_0;
  input s_axis_c2h_tlast_0;
  input s_axis_c2h_tvalid_0;
  output s_axis_c2h_tready_0;
  input [63:0]s_axis_c2h_tkeep_0;
  output [511:0]m_axis_h2c_tdata_0;
  output m_axis_h2c_tlast_0;
  output m_axis_h2c_tvalid_0;
  input m_axis_h2c_tready_0;
  output [63:0]m_axis_h2c_tkeep_0;
endmodule
