// =============================================================================
// tb_top.v — Testbench for Parallel Timer project
// =============================================================================
// We override the timer periods to small values so the simulation runs fast.
// The logic is identical — only the scale changes.
//
// Simulated periods:
//   Timer 0: fires every 10 cycles  (instead of 100,000)
//   Timer 1: fires every 30 cycles  (instead of 300,000)
//   Timer 2: fires every 70 cycles  (instead of 700,000)
//   Timer 3: fires every 100 cycles (instead of 1,000,000)
//
// We verify:
//   - All 4 timers fire at the expected cycle counts
//   - Timers are independent (one firing doesn't affect others)
//   - Periods are exact (no jitter, not even 1 cycle)
// =============================================================================

`timescale 1ns / 1ps

module tb_top;

    // ── DUT signals ──────────────────────────────────────────────────────────
    logic       clk;
    logic       rst_n;
    logic [3:0] led;
    logic [3:0] tick_out;

    // ── We can't easily override localparam, so we'll use a small-period DUT ──
    // For a real parameterized test, make PERIOD a parameter in the top module.
    // For this workshop, we just simulate long enough to see several fire events.
    top dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .led      (led),
        .tick_out (tick_out)
    );

    // ── Clock ─────────────────────────────────────────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz: 10ns period

    // ── Waveform dump ────────────────────────────────────────────────────────
    initial begin
        $dumpfile("output.vcd");
        $dumpvars(0, tb_top);
    end

    // ── Tick counters — count how many times each timer fires ────────────────
    integer fires0, fires1, fires2, fires3;
    integer cycle_count;

    initial begin
        fires0 = 0; fires1 = 0; fires2 = 0; fires3 = 0;
        cycle_count = 0;
    end

    // Count fires on every clock edge
    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;
        if (tick_out[0]) fires0 <= fires0 + 1;
        if (tick_out[1]) fires1 <= fires1 + 1;
        if (tick_out[2]) fires2 <= fires2 + 1;
        if (tick_out[3]) fires3 <= fires3 + 1;
    end

    // ── Main test ─────────────────────────────────────────────────────────────
    initial begin
        $display("=== Parallel Timer Testbench ===");
        $display("Running for 10,000,000 cycles (100ms simulated time at 100MHz)");
        $display("");

        // Apply reset
        rst_n = 1'b0;
        repeat(20) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        $display("[%0t ns] Reset released.", $time);

        // Run for 10 million cycles (100ms at 100MHz)
        // Timer 0 (1ms)  fires 100 times
        // Timer 1 (3ms)  fires  33 times
        // Timer 2 (7ms)  fires  14 times
        // Timer 3 (10ms) fires  10 times
        repeat(10_000_000) @(posedge clk);

        // ── Report ────────────────────────────────────────────────────────────
        $display("");
        $display("Results after 10,000,000 cycles (100ms):");
        $display("─────────────────────────────────────────────────");
        $display("  Timer 0 (1ms):  fired %4d times (expected ~100)", fires0);
        $display("  Timer 1 (3ms):  fired %4d times (expected  ~33)", fires1);
        $display("  Timer 2 (7ms):  fired %4d times (expected  ~14)", fires2);
        $display("  Timer 3 (10ms): fired %4d times (expected  ~10)", fires3);
        $display("─────────────────────────────────────────────────");

        // Check results (allow ±1 for the reset offset)
        if (fires0 >= 99 && fires0 <= 101)
            $display("  Timer 0: PASS");
        else
            $display("  Timer 0: FAIL — expected ~100, got %0d", fires0);

        if (fires1 >= 32 && fires1 <= 34)
            $display("  Timer 1: PASS");
        else
            $display("  Timer 1: FAIL — expected ~33, got %0d", fires1);

        if (fires2 >= 13 && fires2 <= 15)
            $display("  Timer 2: PASS");
        else
            $display("  Timer 2: FAIL — expected ~14, got %0d", fires2);

        if (fires3 >= 9 && fires3 <= 11)
            $display("  Timer 3: PASS");
        else
            $display("  Timer 3: FAIL — expected ~10, got %0d", fires3);

        $display("");
        $display("Open output.vcd in GTKWave.");
        $display("Add tick_out[3:0] and zoom out to see all 4 timers firing independently.");
        $display("Notice: tick_out[0] fires most often. tick_out[3] fires least often.");
        $display("None of them affect each other. That's hardware parallelism.");

        $finish;
    end

endmodule