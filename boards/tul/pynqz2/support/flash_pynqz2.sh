#!/bin/bash
# Build BOOT.bin (FSBL + Zephyr) and write it to the PYNQ-Z2 QSPI flash.
#
# Usage: flash_pynqz2.sh [--no-flash] [zephyr.elf] [output dir]
#   defaults: <Scratch>/build/zephyr/zephyr.elf, <Scratch>/build/boot
#   --no-flash  only build BOOT.bin, don't program the flash
#
# Programming goes over JTAG: leave boot jumper JP1 on JTAG while flashing,
# then set it to QSPI and power-cycle to boot from flash.
#
# The FSBL loads the ELF's segments into DDR (0x00100000) and jumps to the
# ELF entry point. No bitstream is included: Zephyr uses nothing in the PL.
set -euo pipefail

VITIS_SETTINGS="${VITIS_SETTINGS:-$HOME/tools/Xilinx/Vitis/2024.1/settings64.sh}"

DO_FLASH=1
if [ "${1:-}" = "--no-flash" ]; then
    DO_FLASH=0
    shift
fi

SUPPORT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRATCH_DIR="$(cd "$SUPPORT_DIR/../../../.." && pwd)"

FSBL="$SUPPORT_DIR/qspifsbl.elf"
ZEPHYR_ELF="$(realpath "${1:-$SCRATCH_DIR/build/zephyr/zephyr.elf}")"
OUT_DIR="$(realpath -m "${2:-$SCRATCH_DIR/build/boot}")"

for f in "$FSBL" "$ZEPHYR_ELF"; do
    [ -f "$f" ] || { echo "missing: $f" >&2; exit 1; }
done

# Vitis provides bootgen and program_flash
if [ "$DO_FLASH" = 1 ] || ! command -v bootgen >/dev/null; then
    [ -f "$VITIS_SETTINGS" ] || { echo "missing: $VITIS_SETTINGS (set VITIS_SETTINGS)" >&2; exit 1; }
    set +u
    # shellcheck disable=SC1090
    source "$VITIS_SETTINGS"
    set -u
fi

echo "=== Building BOOT.bin ==="
mkdir -p "$OUT_DIR"
cat > "$OUT_DIR/boot.bif" <<EOF
the_ROM_image:
{
    [bootloader] $FSBL
    $ZEPHYR_ELF
}
EOF

bootgen -arch zynq -image "$OUT_DIR/boot.bif" -o "$OUT_DIR/BOOT.bin" -w on
echo "Created $OUT_DIR/BOOT.bin"

[ "$DO_FLASH" = 1 ] || exit 0

echo "=== Programming QSPI flash (JP1 must be on JTAG) ==="
program_flash -f "$OUT_DIR/BOOT.bin" -offset 0 \
    -flash_type qspi-x4-single \
    -fsbl "$FSBL"

echo "=== Done: set JP1 to QSPI and power-cycle the board to boot from flash ==="
