onbreak {quit -f}
onerror {quit -f}

vsim  -lib xil_defaultlib xdma_u280_official_opt

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure
view signals

do {xdma_u280_official.udo}

run 1000ns

quit -force
