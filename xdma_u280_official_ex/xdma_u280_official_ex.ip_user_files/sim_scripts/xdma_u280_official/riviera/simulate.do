transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+xdma_u280_official  -L xilinx_vip -L xpm -L gtwizard_ultrascale_v1_7_16 -L xil_defaultlib -L blk_mem_gen_v8_4_6 -L xdma_v4_1_23 -L xilinx_vip -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.xdma_u280_official xil_defaultlib.glbl

do {xdma_u280_official.udo}

run 1000ns

endsim

quit -force
