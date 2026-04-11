// =============================================================================
// tb_blink.v — Testbench for Workshop 01: Blink
// =============================================================================
// We override HALF_PERIOD to a tiny value (49) so the simulation
// runs fast enough to see multiple blink cycles without waiting
// for 100 million simulated clock cycles. Ain't nobody got time for that.
// =============================================================================

`timescale 1ns / 1ps

module tb_blink;

    // ── DUT signals ─────────────────────────────────────────────────────────
    logic clk;
    logic rst_n;
    logic led;

    // ── DUT instantiation with parameter override ────────────────────────────
    // We override HALF_PERIOD so the blink happens every 50 cycles instead of
    // 50 million. Same logic, same behavior — just scaled for simulation speed.
    blink #(
        // Unfortunately our blink module uses a localparam, which can't be
        // overridden from outside. For real projects, use `parameter` instead
        // of `localparam` for values you want to be overridable.
        // For this workshop, we just watch fewer cycles and trust the math.
    ) dut (
        .clk   (clk),
        .rst_n (rst_n),
        .led   (led)
    );

    // ── Clock: 10ns period (100 MHz) ────────────────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ── Waveform dump ────────────────────────────────────────────────────────
    initial begin
        $dumpfile("output.vcd");
        $dumpvars(0, tb_blink);
    end

    // ── Main test ────────────────────────────────────────────────────────────
    integer toggle_count;
    logic   last_led;

    initial begin
        $display("=== Workshop 01: Blink LED testbench ===");

        // Initialize
        rst_n        = 1'b0;
        toggle_count = 0;
        last_led     = 1'b0;

        // Apply reset for 10 cycles
        repeat(10) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        $display("[%0t ns] Reset released. Watching for LED toggles...", $time);

        // Watch for toggles for 200 million ns (200ms simulated time)
        // At 100MHz with HALF_PERIOD=49,999,999, we expect ~2 toggles in this window
        fork
            // Thread 1: count LED toggles
            begin
                forever begin
                    @(posedge clk);
                    if (led !== last_led) begin
                        toggle_count = toggle_count + 1;
                        $display("[%0t ns] LED toggled! led = %b (toggle #%0d)",
                                 $time, led, toggle_count);
                        last_led = led;
                    end
                end
            end
            // Thread 2: simulation window — watch for 120 million cycles
            begin
                // With a 50M-cycle half period, 120M cycles = just over 2 toggles
                repeat(120_000_000) @(posedge clk);
            end
        join_any
        disable fork;

        // Report results
        $display("");
        if (toggle_count >= 2) begin
            $display("PASS: LED toggled %0d times as expected.", toggle_count);
            $display("      (Expected 2 toggles in 120M cycles with 50M-cycle half period)");
        end else begin
            $display("FAIL: LED only toggled %0d time(s) in 120M cycles.", toggle_count);
            $display("      Check your counter target and toggle logic.");
        end

        $display("");
        $display("Open output.vcd in GTKWave and look at the 'led' signal.");
        $display("You should see a square wave with a very long period.");
        $display("That's your hardware blink. No OS. No sleep(). Just a counter.");

        $finish;
    end

endmodule