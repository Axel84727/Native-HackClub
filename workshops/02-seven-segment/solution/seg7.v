// =============================================================================
// seg7.v — Workshop 02: 7-Segment Display Driver
// =============================================================================
// A 7-segment display has 7 individual LED segments (a–g) plus a decimal point.
// To show a digit, you turn specific segments on and off.
// This is pure combinational logic — no clock needed, no state, no memory.
// Given a 4-bit input (0–15), output the right 7-bit pattern. That's it.
//
// SEGMENT LAYOUT (standard):
//      _
//     |_|   ← segments a (top), f (top-left), b (top-right),
//     |_|      g (middle), e (bottom-left), c (bottom-right), d (bottom)
//
//   Bit assignments (active-LOW on Basys3 — 0 = segment ON):
//   seg[6]=a, seg[5]=b, seg[4]=c, seg[3]=d, seg[2]=e, seg[1]=f, seg[0]=g
//   (Yes, the order seems backwards. That's hardware for you.)
//
// WHY IS THIS USEFUL?
//   This teaches you to think about hardware as a truth table, not a program.
//   A case statement in Verilog synthesizes to a MUX — a single hardware block.
//   All 16 possible inputs are resolved simultaneously; the output is just
//   "which row of the truth table is currently selected."
//   There's no "running through the cases" — it all exists in hardware at once.
//
// =============================================================================

`timescale 1ns / 1ps

module seg7 (
    input  logic [3:0] digit,    // 4-bit input: 0–9 (decimal), A–F (hex)
    output logic [6:0] segments  // Active-LOW segment drives: {a,b,c,d,e,f,g}
                                 // 0 = segment ON, 1 = segment OFF
);

    // =========================================================================
    // 7-segment lookup table
    // =========================================================================
    // This combinational block is a truth table.
    // Input: 4-bit digit value
    // Output: 7-bit segment pattern (active-low)
    //
    // For each digit, we list which segments are ON:
    //
    //   Digit 0:  a,b,c,d,e,f on → g off  → 7'b1000000 (active-low: 0=on)
    //   Digit 1:  b,c on         → a,d,e,f,g off → 7'b1111001
    //   etc.
    //
    // Encoding: {a, b, c, d, e, f, g}
    // Remember: active-LOW means 0 = segment lit, 1 = segment off

    always_comb begin
        case (digit)
            //                      abcdefg
            4'h0: segments = 7'b1000000; // 0: all except middle
            4'h1: segments = 7'b1111001; // 1: right two segments
            4'h2: segments = 7'b0100100; // 2: top, top-right, middle, bottom-left, bottom
            4'h3: segments = 7'b0110000; // 3: top, top-right, middle, bottom-right, bottom
            4'h4: segments = 7'b0011001; // 4: top-left, top-right, middle, bottom-right
            4'h5: segments = 7'b0010010; // 5: top, top-left, middle, bottom-right, bottom
            4'h6: segments = 7'b0000010; // 6: top, top-left, middle, bottom-left, bottom-right, bottom
            4'h7: segments = 7'b1111000; // 7: top, top-right, bottom-right
            4'h8: segments = 7'b0000000; // 8: all segments on
            4'h9: segments = 7'b0010000; // 9: top, top-left, top-right, middle, bottom-right, bottom
            4'hA: segments = 7'b0001000; // A: top, top-left, top-right, middle, bottom-left, bottom-right
            4'hB: segments = 7'b0000011; // B: top-left, middle, bottom-left, bottom-right, bottom
            4'hC: segments = 7'b1000110; // C: top, top-left, bottom-left, bottom
            4'hD: segments = 7'b0100001; // D: top-right, middle, bottom-left, bottom-right, bottom
            4'hE: segments = 7'b0000110; // E: top, top-left, middle, bottom-left, bottom
            4'hF: segments = 7'b0001110; // F: top, top-left, middle, bottom-left
            default: segments = 7'b1111111; // All off — should never happen but always have a default!
        endcase
    end
    // This case statement synthesizes to a 4:7 lookup table (LUT).
    // On an FPGA, this is a single logic block — not 16 comparisons in sequence.
    // All 16 results exist simultaneously as wired-up logic.
    // The current input just selects which one "wins."

endmodule


// =============================================================================
// counter_display.v — Count and show the result on the display
// =============================================================================
// Top-level wrapper: a counter that increments every second,
// decoded to drive a 7-segment display.
// This connects the clock divider from workshop 01 to the seg7 decoder above.

module counter_display (
    input  logic       clk,        // 100 MHz
    input  logic       rst_n,      // Active-low reset
    output logic [6:0] segments,   // 7-segment segments (active-low)
    output logic [3:0] an          // Digit anodes (active-low; we use only digit 0)
);

    localparam CLK_FREQ    = 100_000_000;
    localparam COUNT_FREQ  = 1; // Count up once per second
    localparam HALF_PERIOD = CLK_FREQ / COUNT_FREQ / 2 - 1;

    logic [25:0] clk_counter;
    logic        clk_tick;      // One-cycle pulse every half-period
    logic [3:0]  digit_val;     // Current digit to display (0–9, then wraps)

    // ── Clock divider → generates 1Hz tick ──────────────────────────────────
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_counter <= '0;
            clk_tick    <= 1'b0;
        end else begin
            clk_tick <= 1'b0; // Default: no tick this cycle
            if (clk_counter == HALF_PERIOD[25:0]) begin
                clk_counter <= '0;
                clk_tick    <= 1'b1; // One-cycle pulse!
            end else begin
                clk_counter <= clk_counter + 1'b1;
            end
        end
    end

    // ── Digit counter: 0–9, then wraps ──────────────────────────────────────
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            digit_val <= 4'h0;
        end else if (clk_tick) begin
            // On each 1Hz tick, increment the digit
            if (digit_val == 4'd9)
                digit_val <= 4'h0; // Wrap at 9 (showing decimal 0-9)
            else
                digit_val <= digit_val + 1'b1;
        end
    end

    // ── 7-segment decoder instantiation ─────────────────────────────────────
    seg7 u_seg7 (
        .digit    (digit_val),
        .segments (segments)
    );

    // Enable only digit 0 (leftmost), disable others
    // Anodes are active-low: 0 = digit ON
    assign an = 4'b1110; // Only AN0 is active

endmodule