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

# The Xilinx standalone BSP (used by the FSBL) leaves the PL310 L2 cache on.
# Zephyr keeps it on too: the PL310 patch in patches/ (see patches/README.md)
# extends Zephyr's cache maintenance to the L2, which the GEM DMA needs.
# Set keep_l2 to 0 to switch the L2 off instead, e.g. with an unpatched Zephyr.
set keep_l2 1

# Clean+invalidate all 8 ways of the PL310 and wait for it to finish
proc l2_clean_inv_all {} {
    mwr 0xF8F027FC 0x000000FF
    set timeout 100
    while {[mrd -value 0xF8F027FC] != 0 && $timeout > 0} {
        after 10
        incr timeout -1
    }
    mwr 0xF8F02730 0x0
}

if {!$keep_l2} {
    puts "Disabling PL310 L2 cache..."
    l2_clean_inv_all
    mwr 0xF8F02100 0x0
}

# Load your compiled Zephyr binary into DDR memory
puts "Loading Zephyr OS..."
dow -data /home/nalexopo/ZephyrWorkspace/Scratch/build/zephyr/zephyr.bin 0x00100000

# Zephyr starts with its caches off (soc_reset_hook clears SCTLR.C) until the
# MMU is up, so its early accesses go straight to DDR. Make sure no part of
# the image just downloaded is still sitting dirty in the L2.
if {$keep_l2} {
    puts "Cleaning PL310 L2 cache (kept enabled)..."
    l2_clean_inv_all
}
puts "L2 control = [format 0x%08x [mrd -value 0xF8F02100]]"

rwr pc 0x00100000
# Start execution of Zephyr
puts "Booting Zephyr!"
con
