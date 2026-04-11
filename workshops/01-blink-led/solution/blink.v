// =============================================================================
// blink.v — Workshop 01: Blink an LED at 1 Hz
// =============================================================================
// The "Hello, World!" of hardware. Except instead of printing text,
// you're toggling a wire at exactly 1 Hz using nothing but logic gates.
//
// The key insight: there is no sleep(). There is no loop waiting around.
// There is only a counter, ticking forward on every clock edge,
// and a flip-flop that toggles when the counter reaches its target.
// Everything happens in hardware. The OS has no idea this exists.
//
// HOW IT WORKS:
//   - Clock runs at 100,000,000 Hz (100 MHz)
//   - We want to blink at 1 Hz → toggle every 50,000,000 cycles
//   - A 26-bit counter counts from 0 to 49,999,999
//   - When it reaches the top, it resets and toggles the LED state
//   - Result: LED changes state every 0.5 seconds → full blink period = 1 second
//
// =============================================================================

`timescale 1ns / 1ps

module blink #(
    parameter int unsigned CLK_FREQ   = 100_000_000,
    parameter int unsigned BLINK_FREQ = 1
) (
    input  logic clk,       // 100 MHz system clock
    input  logic rst_n,     // Active-low reset
    output logic led        // The LED. Yes, just one. We start humble.
);

    // =========================================================================
    // How many bits do we need?
    // =========================================================================
    // We need to count to 49,999,999.
    // 2^25 = 33,554,432 — not enough
    // 2^26 = 67,108,864 — enough!
    // So we need a 26-bit counter.
    //
    // You can also use $clog2 to compute this automatically:
    //   localparam COUNTER_BITS = $clog2(HALF_PERIOD);
    // But it's worth doing this manually once so you understand why.

    localparam HALF_PERIOD = CLK_FREQ / BLINK_FREQ / 2 - 1; // = 49,999,999

    logic [25:0] counter; // 26 bits, can hold values 0..67,108,863
    logic        led_state;

    // =========================================================================
    // Counter + toggle logic
    // =========================================================================
    // On every rising clock edge:
    //   - Increment the counter
    //   - When it hits HALF_PERIOD: reset counter, toggle LED
    //
    // This is synchronous reset (reset only takes effect on a clock edge).
    // Some designs use asynchronous reset. For beginners, synchronous is simpler.

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset: start from a known, clean state.
            // If you don't do this, the counter boots to a random value
            // and your LED blinks at an unpredictable phase. Annoying.
            counter   <= 26'h0;
            led_state <= 1'b0;
        end else begin
            if (counter == HALF_PERIOD[25:0]) begin
                // We've counted half a period — time to toggle
                counter   <= 26'h0;
                led_state <= ~led_state; // ~ is bitwise NOT — flips a single bit
            end else begin
                // Not there yet — keep counting
                counter <= counter + 1'b1;
                // Why 1'b1 and not just 1?
                // "1" in Verilog is a 32-bit value. Adding it to a 26-bit
                // counter causes a width mismatch warning. 1'b1 is explicitly
                // 1 bit wide. The synthesizer extends it as needed. Clean.
            end
        end
    end

    // =========================================================================
    // Output
    // =========================================================================
    assign led = led_state;

endmodule