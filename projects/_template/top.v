// =============================================================================
// top.v — Top-level module template
// =============================================================================
// Project  : [Your project name here]
// Author   : [Your name here]
// Date     : [YYYY-MM-DD]
// Board    : [Basys3 / Arty A7 / other]
// Clock    : 100 MHz (change this if your board is different)
//
// Description:
//   [Replace this with a one-paragraph description of what this module does.
//    Explain the hardware mechanism, not just "it does the thing."]
//
// =============================================================================

`timescale 1ns / 1ps
// `timescale sets the time unit and precision for simulation.
// 1ns / 1ps means: time unit = 1ns, simulation precision = 1ps.
// You'll probably never need to change this. But now you know what it means.

module top (
    // ── Clock & Reset ────────────────────────────────────────────────────────
    input  logic        clk,        // System clock (100 MHz on Basys3/Arty)
    input  logic        rst_n,      // Active-low reset (push button on most boards)
                                    // Active-low means: 0 = reset, 1 = normal operation
                                    // The _n suffix is the convention. Follow it.

    // ── Inputs ───────────────────────────────────────────────────────────────
    // Add your input ports here.
    // Examples:
    // input  logic        button,     // Push button input
    // input  logic [7:0]  sw,         // DIP switches
    // input  logic        uart_rx,    // UART receive

    // ── Outputs ──────────────────────────────────────────────────────────────
    // Add your output ports here.
    // Examples:
    // output logic [3:0]  led,        // LEDs
    // output logic        uart_tx,    // UART transmit
    // output logic [6:0]  seg,        // 7-segment segments (active-low on Basys3)
    // output logic [3:0]  an          // 7-segment digit anodes (active-low on Basys3)

    // ── Placeholder (remove when you add real ports) ─────────────────────────
    output logic        heartbeat    // Blinking signal so you know the clock works
                                     // Good for debugging. Delete when you're done.
);

    // =========================================================================
    // Parameters
    // =========================================================================
    // Put your constants here so they're easy to find and change.
    // Hardcoding numbers in your logic is how you spend 2 hours debugging
    // because you changed the clock frequency and forgot to update 47 places.

    localparam CLK_FREQ_HZ   = 100_000_000; // 100 MHz — change if your board differs
    localparam BLINK_HZ      = 1;           // Heartbeat frequency in Hz
    localparam BLINK_CYCLES  = CLK_FREQ_HZ / BLINK_HZ / 2 - 1; // Half-period in cycles
    localparam COUNTER_BITS  = $clog2(BLINK_CYCLES + 1); // Minimum bits needed
    // $clog2 computes ceiling(log2(n)) — the number of bits needed to represent n.
    // It's a synthesis-time function. Use it instead of guessing "I think I need 26 bits."

    // =========================================================================
    // Internal signals
    // =========================================================================
    // Declare all your internal wires and registers here.
    // Keep names descriptive — "cnt" is lazy, "blink_counter" is kind.

    logic [COUNTER_BITS-1:0] blink_counter;  // Counts up to BLINK_CYCLES
    logic                    blink_reg;       // The actual blink state (high/low)

    // =========================================================================
    // Heartbeat blink logic
    // =========================================================================
    // This is a simple clock divider. It counts to BLINK_CYCLES, then toggles
    // blink_reg. The result is a signal that changes at BLINK_HZ.
    //
    // At 100 MHz with BLINK_HZ=1, BLINK_CYCLES = 49,999,999.
    // That means we count to ~50 million, toggle, count again, toggle.
    // One full cycle = 100 million clocks = 1 second. Magic? No. Math.

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset: clear everything to a known state.
            // Always reset to something deterministic — "whatever it boots to"
            // is not a valid design choice.
            blink_counter <= '0;  // '0 is the shorthand for "all zeros, any width"
            blink_reg     <= 1'b0;
        end else begin
            if (blink_counter == BLINK_CYCLES[COUNTER_BITS-1:0]) begin
                blink_counter <= '0;      // Reset counter
                blink_reg     <= ~blink_reg; // Toggle the output
            end else begin
                blink_counter <= blink_counter + 1'b1;
            end
        end
    end

    // =========================================================================
    // Output assignments
    // =========================================================================
    // Connect internal signals to output ports.
    // Keeping these as explicit assignments (rather than writing directly to
    // output ports in always blocks) makes the signal flow easier to read.

    assign heartbeat = blink_reg;

    // =========================================================================
    // Your logic goes below here
    // =========================================================================
    // Delete the heartbeat section above once your real logic is working.
    // Or keep it — a blinking LED is always a useful "the clock is alive" signal.


    // =========================================================================
    // Submodule instantiations
    // =========================================================================
    // If your design has submodules, instantiate them here.
    // Use named port connections — positional connections are a maintenance nightmare.
    //
    // Example:
    // my_submodule u_submodule (
    //     .clk     (clk),
    //     .rst_n   (rst_n),
    //     .data_in (my_signal),
    //     .result  (output_signal)
    // );

endmodule