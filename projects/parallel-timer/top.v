// =============================================================================
// top.v — Parallel Timer: Multiple independent hardware timers
// =============================================================================
// Project  : Parallel Timer
// Board    : Basys3 (Artix-7)
// Clock    : 100 MHz
//
// PROBLEM:
//   Software timers on a general-purpose OS are unreliable for precision work.
//   A 1ms timer on Linux can fire anywhere from 1ms to 15ms late depending on
//   scheduler load. Even on a bare microcontroller, timer ISRs share interrupt
//   priority and can be delayed by higher-priority peripherals.
//
// WHY NOT SOFTWARE:
//   A CPU has one program counter. Even if you use hardware timer peripherals,
//   the ISRs still execute sequentially on one core. Under load, the OS will
//   delay the ISR. The timer callback fires late. You can't fix this without
//   a real-time OS and careful priority assignment — and even then, jitter
//   remains in the microsecond range.
//
//   Hardware counters on an FPGA have zero jitter. Each counter is independent
//   silicon — it cannot be preempted, delayed, or interrupted. Four timers
//   counting at four frequencies use four sets of flip-flops. They all update
//   on the same clock edge, every cycle, without exception.
//
// HOW IT WORKS:
//   Four independent down-counters, each loaded with a different period.
//   When a counter reaches zero, it fires a one-cycle pulse on its output
//   and reloads itself. All four run simultaneously, forever.
//
//   Counter 0: fires every 1ms   (100,000 cycles at 100MHz)
//   Counter 1: fires every 3ms   (300,000 cycles)
//   Counter 2: fires every 7ms   (700,000 cycles)  ← prime! chosen intentionally
//   Counter 3: fires every 10ms  (1,000,000 cycles)
//
//   The 3ms and 7ms periods are coprime — their firing patterns don't align
//   for a very long time. This makes the combined output interesting to observe
//   and proves the timers are truly independent (not harmonically related).
//
// =============================================================================

`timescale 1ns / 1ps

module top (
    input  logic       clk,      // 100 MHz
    input  logic       rst_n,    // Active-low reset (center button on Basys3)
    output logic [3:0] led,      // Each LED lights up when its timer fires
    output logic [3:0] tick_out  // One-cycle pulse outputs (useful for measurement)
);

    // =========================================================================
    // Timer periods (in clock cycles at 100 MHz)
    // =========================================================================
    // 1 clock cycle = 10ns at 100MHz
    // 1ms = 1,000,000ns / 10ns = 100,000 cycles

    localparam [19:0] PERIOD_0 = 20'd100_000 - 1; // 1ms
    localparam [19:0] PERIOD_1 = 20'd300_000 - 1; // 3ms
    localparam [19:0] PERIOD_2 = 20'd700_000 - 1; // 7ms  (needs 20 bits: 2^20 = 1,048,576 > 700,000)
    localparam [19:0] PERIOD_3 = 20'd999_999;     // 10ms (1,000,000 - 1)
    // We subtract 1 because we compare against 0 (the counter fires when it reaches 0,
    // then reloads to PERIOD. So the period is PERIOD+1 cycles. Hence PERIOD = target-1.)

    // =========================================================================
    // Timer 0 — 1ms
    // =========================================================================
    logic [19:0] cnt0;
    logic        tick0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt0  <= PERIOD_0;
            tick0 <= 1'b0;
        end else begin
            tick0 <= 1'b0;          // Default: no tick this cycle
            if (cnt0 == 20'h0) begin
                cnt0  <= PERIOD_0;  // Reload
                tick0 <= 1'b1;      // Fire! One-cycle pulse.
            end else begin
                cnt0 <= cnt0 - 1'b1;
            end
        end
    end

    // =========================================================================
    // Timer 1 — 3ms
    // =========================================================================
    logic [19:0] cnt1;
    logic        tick1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt1  <= PERIOD_1;
            tick1 <= 1'b0;
        end else begin
            tick1 <= 1'b0;
            if (cnt1 == 20'h0) begin
                cnt1  <= PERIOD_1;
                tick1 <= 1'b1;
            end else begin
                cnt1 <= cnt1 - 1'b1;
            end
        end
    end

    // =========================================================================
    // Timer 2 — 7ms
    // =========================================================================
    logic [19:0] cnt2;
    logic        tick2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt2  <= PERIOD_2;
            tick2 <= 1'b0;
        end else begin
            tick2 <= 1'b0;
            if (cnt2 == 20'h0) begin
                cnt2  <= PERIOD_2;
                tick2 <= 1'b1;
            end else begin
                cnt2 <= cnt2 - 1'b1;
            end
        end
    end

    // =========================================================================
    // Timer 3 — 10ms
    // =========================================================================
    logic [19:0] cnt3;
    logic        tick3;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt3  <= PERIOD_3;
            tick3 <= 1'b0;
        end else begin
            tick3 <= 1'b0;
            if (cnt3 == 20'h0) begin
                cnt3  <= PERIOD_3;
                tick3 <= 1'b1;
            end else begin
                cnt3 <= cnt3 - 1'b1;
            end
        end
    end

    // =========================================================================
    // LED pulse stretcher
    // =========================================================================
    // The tick pulses are only 1 cycle (10ns) wide — too short to see on an LED.
    // We stretch each tick into a visible pulse using a short down-counter.
    // When a tick arrives, load the stretcher. While non-zero, keep LED lit.
    // This does NOT affect the timer accuracy — the tick is still cycle-exact.
    // We're just making it visible to a human eye.

    localparam [22:0] STRETCH = 23'd5_000_000; // 50ms visible pulse (long enough to see)

    logic [22:0] stretch0, stretch1, stretch2, stretch3;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stretch0 <= '0; stretch1 <= '0;
            stretch2 <= '0; stretch3 <= '0;
        end else begin
            // Load stretcher on tick, countdown to 0
            stretch0 <= tick0 ? STRETCH : (stretch0 > 0 ? stretch0 - 1'b1 : 23'h0);
            stretch1 <= tick1 ? STRETCH : (stretch1 > 0 ? stretch1 - 1'b1 : 23'h0);
            stretch2 <= tick2 ? STRETCH : (stretch2 > 0 ? stretch2 - 1'b1 : 23'h0);
            stretch3 <= tick3 ? STRETCH : (stretch3 > 0 ? stretch3 - 1'b1 : 23'h0);
        end
    end

    // =========================================================================
    // Outputs
    // =========================================================================
    assign led      = {stretch3 > 0, stretch2 > 0, stretch1 > 0, stretch0 > 0};
    assign tick_out = {tick3, tick2, tick1, tick0}; // Raw pulses for oscilloscope use

endmodule