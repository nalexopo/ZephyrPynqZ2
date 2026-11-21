# Connect to target and select CPU 0
connect
targets -set -nocase -filter {name =~ "ARM*#0"}

# Reset the system cleanly first
puts "Resetting system..."
rst -system
after 500

# Load and run the Xilinx FSBL to initialize DDR memory and clocks
puts "Loading FSBL..."
dow /home/nalexopo/ZephyrWorkspace/Scratch/boards/tul/pynqz2/support/fsbl.elf
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
