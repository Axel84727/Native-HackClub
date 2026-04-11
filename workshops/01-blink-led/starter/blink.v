// =============================================================================
// blink.v — Workshop 01 Starter File
// =============================================================================
// Your mission: make the LED blink at 1 Hz.
//
// Rules:
//   - No cheating (no looking at the solution until you've tried)
//   - No sleep(), no busy-wait, no microcontroller tricks
//   - Only synchronous logic: counters and flip-flops
//
// When you're done, run: ./tools/sim.sh workshops/01-blink-led/starter
// Open the waveform. If 'led' looks like a square wave, you did it.
//
// =============================================================================

`timescale 1ns / 1ps

module blink (
    input  logic clk,    // 100 MHz system clock — ticks 100 million times per second
    input  logic rst_n,  // Active-low reset — when this is 0, reset is active
    output logic led     // Connect this to a physical LED (or just watch in simulation)
);

    // =========================================================================
    // Step 1: Define your constants
    // =========================================================================
    // How many clock cycles is half a blink period at 100 MHz / 1 Hz?
    // Remember: half period because the LED needs to toggle TWICE per full cycle.

    localparam CLK_FREQ    = 100_000_000; // 100 MHz — don't change this
    localparam BLINK_FREQ  = 1;           // 1 Hz blink rate — you can change this later
    localparam HALF_PERIOD = /* TODO: compute this */ 0; // Hint: CLK_FREQ / BLINK_FREQ / 2 - 1

    // =========================================================================
    // Step 2: Declare your registers
    // =========================================================================
    // You need:
    //   - A counter wide enough to hold values up to HALF_PERIOD
    //   - A register to hold the current LED state (on or off)
    //
    // TODO: declare them here
    // Hint: 26 bits can hold values up to 67,108,863 which is > 49,999,999


    // =========================================================================
    // Step 3: Implement the counter logic
    // =========================================================================
    // On every rising clock edge:
    //   - If reset is active (rst_n == 0): clear everything to zero
    //   - Else if counter has reached HALF_PERIOD: reset counter, toggle LED
    //   - Else: increment counter
    //
    // TODO: write the always_ff block here
    // Hint: always_ff @(posedge clk or negedge rst_n) begin ... end
    // Hint: use <= (non-blocking assignment) inside always_ff
    // Hint: ~led_state flips a single bit


    // =========================================================================
    // Step 4: Connect the output
    // =========================================================================
    // TODO: assign led = ...

endmodule