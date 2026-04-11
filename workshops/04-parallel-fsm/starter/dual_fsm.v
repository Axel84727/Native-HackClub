// =============================================================================
// dual_fsm.v — Workshop 04 Starter: Two FSMs in Parallel
// =============================================================================
// Build two state machines that run simultaneously in the same module.
//
// FSM A: traffic light (Red → Green → Yellow → Red → ...)
// FSM B: morse code transmitter (dots and dashes spelling "SOS" on loop)
//
// The challenge: both FSMs share a clock but have completely independent
// state registers, counters, and transitions. Neither waits for the other.
// Neither knows the other exists.
//
// Read the README first. Then implement FSM A, test it, then add FSM B.
// =============================================================================

`timescale 1ns / 1ps

module dual_fsm (
    input  logic clk,
    input  logic rst_n,

    // Traffic light outputs
    output logic light_red,
    output logic light_yellow,
    output logic light_green,

    // Morse outputs
    output logic morse_out,
    output logic morse_busy
);

    // =========================================================================
    // Timing parameters
    // =========================================================================
    // These are in clock cycles. At 100MHz, 1 second = 100_000_000 cycles.
    // For simulation speed you might want to reduce them temporarily,
    // but make sure your logic works with the real values too.

    localparam CLK_FREQ      = 100_000_000;
    localparam RED_CYCLES    = CLK_FREQ * 2;     // 2 seconds
    localparam GREEN_CYCLES  = CLK_FREQ * 2;     // 2 seconds
    localparam YEL_CYCLES    = CLK_FREQ / 2;     // 0.5 seconds
    localparam UNIT_CYCLES   = CLK_FREQ / 5;     // 200ms morse unit

    // =========================================================================
    // FSM A: Traffic light
    // =========================================================================

    // TODO: define state type (typedef enum logic [1:0] { RED, GREEN, YELLOW } light_state_t)

    // TODO: declare state register and counter

    // TODO: implement always_ff for state transitions

    // TODO: implement always_comb for output decoding
    // (light_red, light_green, light_yellow based on current state)

    // =========================================================================
    // FSM B: Morse code transmitter
    // =========================================================================
    // Morse SOS sequence has 18 elements (see solution for the full table).
    // Encode each element as (duration_in_units, is_tone).
    //
    // SOS = "... --- ..."
    //   S: dot, gap, dot, gap, dot, letter-gap
    //   O: dash, gap, dash, gap, dash, letter-gap
    //   S: dot, gap, dot, gap, dot, word-gap

    // TODO: declare sequence index register and timer

    // TODO: implement always_comb lookup table for (duration, is_tone) by index

    // TODO: implement always_ff to advance through the sequence
    // Each element holds for (duration * UNIT_CYCLES) clock cycles,
    // then advances to the next index (wrapping at the end)

    // TODO: assign outputs
    // assign morse_out  = (current element is tone);
    // assign morse_busy = 1'b1; // always transmitting (it loops forever)

endmodule