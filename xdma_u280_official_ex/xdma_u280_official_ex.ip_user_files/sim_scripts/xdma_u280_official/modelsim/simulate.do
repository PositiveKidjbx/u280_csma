onbreak {quit -f}
onerror {quit -f}

vsim -voptargs="+acc"  -L xilinx_vip -L xpm -L gtwizard_ultrascale_v1_7_16 -L xil_defaultlib -L blk_mem_gen_v8_4_6 -L xdma_v4_1_23 -L xilinx_vip -L unisims_ver -L unimacro_ver -L secureip -lib xil_defaultlib xil_defaultlib.xdma_u280_official xil_defaultlib.glbl

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure
view signals

do {xdma_u280_official.udo}

run 1000ns

quit -force
