# --- Stage 1: Connect and Reset ---
target extended-remote :3333
monitor halt

# --- Stage 2: Run FSBL to Initialize Clocks & DDR3 ---
# Load FSBL symbols and binary into On-Chip Memory (OCM)
file fsbl.elf
load fsbl.elf

# Set a temporary hardware breakpoint at the JTAG idle exit function
thbreak FsblHandoffJtagExit
continue

# --- Stage 3: Load Your Application into DDR3 ---
# Clear FSBL symbols so they do not conflict with your app
symbol-file

# Load raw binary to DDR3 at 0x00100000
restore /home/nalexopo/ZephyrWorkspace/Scratch/build/zephyr/zephyr.bin binary 0x00100000

# Attach debug symbols from your ELF mapped to 0x00100000
add-symbol-file /home/nalexopo/ZephyrWorkspace/Scratch/build/zephyr/zephyr.elf 0x00100000

# Point Program Counter to your application start address
set $pc = 0x00100000

# --- Stage 4: Start Debugging ---
# Set a hardware breakpoint at main and run
hbreak main
continue