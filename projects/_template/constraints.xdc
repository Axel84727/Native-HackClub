## =============================================================================
## constraints.xdc — Pin Constraints Template
## =============================================================================
## This file tells Vivado which physical pins on the FPGA correspond to
## the ports in your top-level module.
##
## Board target: Basys3 (Artix-7 35T) — the most common beginner board.
## If you have an Arty A7 or other board, check its reference manual for pin names.
## Digilent publishes .xdc files for all their boards — download the right one.
##
## Syntax:
##   set_property PACKAGE_PIN <pin_name> [get_ports { <port_name> }]
##   set_property IOSTANDARD LVCMOS33 [get_ports { <port_name> }]
##
## Every port that connects to physical I/O needs BOTH a PACKAGE_PIN and IOSTANDARD.
## Forgetting IOSTANDARD is a very popular way to get a "DRC error" from Vivado.
## You have been warned.
##
## To use a pin assignment: remove the leading ## from both lines.
## Commented-out constraints are ignored by Vivado entirely.
##
## =============================================================================


## =============================================================================
## Clock — 100 MHz onboard oscillator
## =============================================================================
## This is the main system clock. It's always on pin W5 on the Basys3.
## The create_clock constraint tells the timing analyzer how fast it runs.
## Without this, timing analysis is meaningless.

## set_property PACKAGE_PIN W5 [get_ports { clk }]
## set_property IOSTANDARD LVCMOS33 [get_ports { clk }]
## create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }]
## # Period = 10ns → 100 MHz. Change if you're using a different frequency.


## =============================================================================
## Reset — Center button (BTNC) on Basys3
## =============================================================================
## Active-low reset: pressing the button brings rst_n LOW (reset active).
## The button is active-high on the Basys3, so you'll need to invert it
## in your top module: assign rst_n = ~btnc;

## set_property PACKAGE_PIN U18 [get_ports { rst_n }]
## set_property IOSTANDARD LVCMOS33 [get_ports { rst_n }]


## =============================================================================
## LEDs — LD0 through LD15
## =============================================================================
## The Basys3 has 16 LEDs. They're active-high (1 = on, 0 = off).

## set_property PACKAGE_PIN U16 [get_ports { led[0] }]
## set_property IOSTANDARD LVCMOS33 [get_ports { led[0] }]

## set_property PACKAGE_PIN E19 [get_ports { led[1] }]
## set_property IOSTANDARD LVCMOS33 [get_ports { led[1] }]

## set_property PACKAGE_PIN U19 [get_ports { led[2] }]
## set_property IOSTANDARD LVCMOS33 [get_ports { led[2] }]

## set_property PACKAGE_PIN V19 [get_ports { led[3] }]
## set_property IOSTANDARD LVCMOS33 [get_ports { led[3] }]

## set_property PACKAGE_PIN W18 [get_ports { led[4] }]
## set_property IOSTANDARD LVCMOS33 [get_ports { led[4] }]

## set_property PACKAGE_PIN U15 [get_ports { led[5] }]
## set_property IOSTANDARD LVCMOS33 [get_ports { led[5] }]

## set_property PACKAGE_PIN U14 [get_ports { led[6] }]
## set_property IOSTANDARD LVCMOS33 [get_ports { led[6] }]

## set_property PACKAGE_PIN V14 [get_ports { led[7] }]
## set_property IOSTANDARD LVCMOS33 [get_ports { led[7] }]

## # (Uncomment led[8] through led[15] from the Basys3 master XDC if you need them)
## # https://github.com/Digilent/digilent-xdc


## =============================================================================
## Switches — SW0 through SW15
## =============================================================================
## 16 DIP switches. Active-high (up = 1, down = 0).

## set_property PACKAGE_PIN V17 [get_ports { sw[0] }]
## set_property IOSTANDARD LVCMOS33 [get_ports { sw[0] }]

## set_property PACKAGE_PIN V16 [get_ports { sw[1] }]
## set_property IOSTANDARD LVCMOS33 [get_ports { sw[1] }]

## set_property PACKAGE_PIN W16 [get_ports { sw[2] }]
## set_property IOSTANDARD LVCMOS33 [get_ports { sw[2] }]

## set_property PACKAGE_PIN W17 [get_ports { sw[3] }]
## set_property IOSTANDARD LVCMOS33 [get_ports { sw[3] }]


## =============================================================================
## Push Buttons
## =============================================================================
## 5 buttons: center (C), up (U), down (D), left (L), right (R).
## All active-high.

## set_property PACKAGE_PIN U18 [get_ports { btnc }]    # Center
## set_property IOSTANDARD LVCMOS33 [get_ports { btnc }]

## set_property PACKAGE_PIN T18 [get_ports { btnu }]    # Up
## set_property IOSTANDARD LVCMOS33 [get_ports { btnu }]

## set_property PACKAGE_PIN W19 [get_ports { btnd }]    # Down
## set_property IOSTANDARD LVCMOS33 [get_ports { btnd }]

## set_property PACKAGE_PIN T17 [get_ports { btnl }]    # Left
## set_property IOSTANDARD LVCMOS33 [get_ports { btnl }]

## set_property PACKAGE_PIN U17 [get_ports { btnr }]    # Right
## set_property IOSTANDARD LVCMOS33 [get_ports { btnr }]


## =============================================================================
## 7-Segment Display (4-digit)
## =============================================================================
## The Basys3 has a 4-digit 7-segment display.
## Segments are active-LOW on this board (0 = segment ON, 1 = segment OFF).
## Digit enables (anodes) are also active-LOW.
## Yes, this is confusing. No, it doesn't change. Invert in your RTL.

## # Segments: {CA, CB, CC, CD, CE, CF, CG, DP}
## set_property PACKAGE_PIN W7 [get_ports { seg[0] }]   # CA
## set_property IOSTANDARD LVCMOS33 [get_ports { seg[0] }]

## set_property PACKAGE_PIN W6 [get_ports { seg[1] }]   # CB
## set_property IOSTANDARD LVCMOS33 [get_ports { seg[1] }]

## set_property PACKAGE_PIN U8 [get_ports { seg[2] }]   # CC
## set_property IOSTANDARD LVCMOS33 [get_ports { seg[2] }]

## set_property PACKAGE_PIN V8 [get_ports { seg[3] }]   # CD
## set_property IOSTANDARD LVCMOS33 [get_ports { seg[3] }]

## set_property PACKAGE_PIN U5 [get_ports { seg[4] }]   # CE
## set_property IOSTANDARD LVCMOS33 [get_ports { seg[4] }]

## set_property PACKAGE_PIN V5 [get_ports { seg[5] }]   # CF
## set_property IOSTANDARD LVCMOS33 [get_ports { seg[5] }]

## set_property PACKAGE_PIN U7 [get_ports { seg[6] }]   # CG
## set_property IOSTANDARD LVCMOS33 [get_ports { seg[6] }]

## # Digit anodes (active-low: 0 = digit on)
## set_property PACKAGE_PIN U2 [get_ports { an[0] }]
## set_property IOSTANDARD LVCMOS33 [get_ports { an[0] }]
## set_property PACKAGE_PIN U4 [get_ports { an[1] }]
## set_property IOSTANDARD LVCMOS33 [get_ports { an[1] }]
## set_property PACKAGE_PIN V4 [get_ports { an[2] }]
## set_property IOSTANDARD LVCMOS33 [get_ports { an[2] }]
## set_property PACKAGE_PIN W4 [get_ports { an[3] }]
## set_property IOSTANDARD LVCMOS33 [get_ports { an[3] }]


## =============================================================================
## UART (via USB-UART bridge, JA PMOD connector pins)
## =============================================================================
## The Basys3 has a USB-UART bridge connected to specific pins.
## When you connect via a terminal (115200 baud, 8N1), these are the pins.

## set_property PACKAGE_PIN B18 [get_ports { uart_tx }]
## set_property IOSTANDARD LVCMOS33 [get_ports { uart_tx }]

## set_property PACKAGE_PIN A18 [get_ports { uart_rx }]
## set_property IOSTANDARD LVCMOS33 [get_ports { uart_rx }]


## =============================================================================
## Configuration — misc settings
## =============================================================================
## These are usually fine at their defaults. Leaving them here for reference.

## set_property CFGBVS VCCO [current_design]
## set_property CONFIG_VOLTAGE 3.3 [current_design]
