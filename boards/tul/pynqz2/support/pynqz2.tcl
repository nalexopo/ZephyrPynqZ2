# Connect to target and select CPU 0
connect
targets -set -nocase -filter {name =~ "ARM*#0"}

# Reset the system cleanly first
puts "Resetting system..."
rst -system
after 500

#in order for qspifsbl.elf to work you need to add this in fsbl.h 
#   #ifndef XPAR_PS7_QSPI_LINEAR_0_S_AXI_BASEADDR
#   #define XPAR_PS7_QSPI_LINEAR_0_S_AXI_BASEADDR XPAR_PS7_QSPI_LINEAR_0_BASEADDRESS
#   #endif
puts "Loading FSBL..."
dow /home/nalexopo/ZephyrWorkspace/Scratch/boards/tul/pynqz2/support/qspifsbl.elf
con
after 3000
stop



# Load your compiled Zephyr binary into DDR memory
puts "Loading Zephyr OS..."
dow -data /home/nalexopo/ZephyrWorkspace/Scratch/build/zephyr/zephyr.bin 0x00100000

rwr pc 0x00100000
# Start execution of Zephyr
puts "Booting Zephyr!"
con
