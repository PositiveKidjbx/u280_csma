transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+pcie4c_uscale_plus_0  -L xilinx_vip -L xpm -L gtwizard_ultrascale_v1_7_16 -L xil_defaultlib -L xilinx_vip -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.pcie4c_uscale_plus_0 xil_defaultlib.glbl

do {pcie4c_uscale_plus_0.udo}

run 1000ns

endsim

quit -force