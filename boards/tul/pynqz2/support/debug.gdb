# Command-line equivalent of the "Debug Zephyr on PYNQ-Z2" VS Code config.
#   openocd -f boards/tul/pynqz2/support/openocd.cfg      (terminal 1)
#   arm-none-eabi-gdb -x boards/tul/pynqz2/support/debug.gdb   (terminal 2, from the repo root)

file build/zephyr/zephyr.elf
target extended-remote :3333

# Reset, run the FSBL (PLLs, DDR, MIO), stop it in its JTAG idle loop.
monitor pynqz2_prepare boards/tul/pynqz2/support/qspifsbl.elf

# zephyr.elf is linked at 0x00100000 (VMA == LMA), so load it directly.
load
set $pc = 0x00100000

break main
continue
