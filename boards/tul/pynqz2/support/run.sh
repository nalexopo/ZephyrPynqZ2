#!/bin/bash

echo "=== Starting XSCT Execution ==="
source ~/tools/Xilinx/Vitis/2024.1/settings64.sh
# Launch XSCT and pipe commands into it; outputs stream straight to terminal
xsct << 'EOF'
puts "--- Inside XSCT Environment ---"
source /home/nalexopo/ZephyrWorkspace/Scratch/boards/tul/pynqz2/support/pynqz2.tcl
puts "--- Tcl Script Finished ---"
exit
EOF

echo "=== XSCT execution finished ==="