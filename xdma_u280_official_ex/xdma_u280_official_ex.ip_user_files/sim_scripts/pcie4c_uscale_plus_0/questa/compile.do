vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xilinx_vip
vlib questa_lib/msim/xpm
vlib questa_lib/msim/gtwizard_ultrascale_v1_7_16
vlib questa_lib/msim/xil_defaultlib

vmap xilinx_vip questa_lib/msim/xilinx_vip
vmap xpm questa_lib/msim/xpm
vmap gtwizard_ultrascale_v1_7_16 questa_lib/msim/gtwizard_ultrascale_v1_7_16
vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xilinx_vip  -incr -mfcu  -sv -L xdma_v4_1_23 -L xilinx_vip "+incdir+E:/Xilinx/Vivado/2023.1/data/xilinx_vip/include" \
"E:/Xilinx/Vivado/2023.1/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"E:/Xilinx/Vivado/2023.1/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"E:/Xilinx/Vivado/2023.1/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"E:/Xilinx/Vivado/2023.1/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"E:/Xilinx/Vivado/2023.1/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"E:/Xilinx/Vivado/2023.1/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"E:/Xilinx/Vivado/2023.1/data/xilinx_vip/hdl/axi_vip_if.sv" \
"E:/Xilinx/Vivado/2023.1/data/xilinx_vip/hdl/clk_vip_if.sv" \
"E:/Xilinx/Vivado/2023.1/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work xpm  -incr -mfcu  -sv -L xdma_v4_1_23 -L xilinx_vip "+incdir+../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source" "+incdir+E:/Xilinx/Vivado/2023.1/data/xilinx_vip/include" \
"E:/Xilinx/Vivado/2023.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"E:/Xilinx/Vivado/2023.1/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv" \
"E:/Xilinx/Vivado/2023.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm  -93  \
"E:/Xilinx/Vivado/2023.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work gtwizard_ultrascale_v1_7_16  -incr -mfcu  "+incdir+../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source" "+incdir+E:/Xilinx/Vivado/2023.1/data/xilinx_vip/include" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_bit_sync.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gte4_drp_arb.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe4_delay_powergood.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtye4_delay_powergood.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe3_cpll_cal.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe3_cal_freqcnt.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe4_cpll_cal.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe4_cpll_cal_rx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe4_cpll_cal_tx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe4_cal_freqcnt.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtye4_cpll_cal.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtye4_cpll_cal_rx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtye4_cpll_cal_tx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtye4_cal_freqcnt.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_buffbypass_rx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_buffbypass_tx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_reset.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_userclk_rx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_userclk_tx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_userdata_rx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_userdata_tx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_reset_sync.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_reset_inv_sync.v" \

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source" "+incdir+E:/Xilinx/Vivado/2023.1/data/xilinx_vip/include" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/ip_0/sim/gtwizard_ultrascale_v1_7_gtye4_channel.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/ip_0/sim/pcie4c_uscale_plus_0_gt_gtye4_channel_wrapper.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/ip_0/sim/pcie4c_uscale_plus_0_gt_gtwizard_gtye4.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/ip_0/sim/pcie4c_uscale_plus_0_gt_gtwizard_top.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/ip_0/sim/pcie4c_uscale_plus_0_gt.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_cxs_remap.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_bram_16k_int.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_bram_16k.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_bram_32k.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_bram_4k_int.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_bram_msix.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_bram_rep_int.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_bram_rep.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_bram_tph.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_bram.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_gtwizard_top.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_phy_ff_chain.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_phy_pipeline.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_gt_gt_channel.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_gt_gt_common.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_gt_phy_clk.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_gt_phy_rst.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_gt_phy_rxeq.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_gt_phy_txeq.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_sync_cell.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_sync.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_gt_cdr_ctrl_on_eidle.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_gt_receiver_detect_rxterm.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_gt_phy_wrapper.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_phy_top.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_init_ctrl.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_pl_eq.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_vf_decode.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_vf_decode_attr.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_pipe.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_seqnum_fifo.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_sys_clk_gen_ps.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/source/pcie4c_uscale_plus_0_pcie4c_uscale_core_top.v" \
"../../../../xdma_u280_official_ex.gen/sources_1/ip/pcie4c_uscale_plus_0/sim/pcie4c_uscale_plus_0.v" \

vlog -work xil_defaultlib \
"glbl.v"

