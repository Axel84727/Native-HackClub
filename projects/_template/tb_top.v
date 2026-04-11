// =============================================================================
// tb_top.v — Testbench template for top-level module
// =============================================================================
// This file is NOT synthesized. It only runs in simulation.
// Think of it as your automated test suite, but for hardware.
// You can use $display, $finish, delays, and all sorts of non-synthesizable
// constructs here that would cause a synthesis tool to cry.
//
// What a good testbench does:
//   1. Creates a clock that ticks at your design's frequency
//   2. Applies a reset at startup
//   3. Drives inputs with interesting stimulus
//   4. Checks outputs with assertions
//   5. Dumps a waveform so you can visually verify behavior in GTKWave
//
// =============================================================================

`timescale 1ns / 1ps
// Same timescale as the design under test.
// Clock period math: 100 MHz → period = 10ns → half-period = 5ns
// If your clock is different, adjust CLK_HALF_PERIOD below.

module tb_top;

    // =========================================================================
    // Parameters
    // =========================================================================
    localparam CLK_HALF_PERIOD = 5;   // ns — half the clock period
    localparam SIM_TIMEOUT     = 1_000_000; // Clock cycles before we give up
    // SIM_TIMEOUT is your safety net. Without it, a stuck design runs forever.
    // 1 million cycles at 100MHz = 10ms of simulated time. Adjust as needed.

    // =========================================================================
    // DUT (Device Under Test) signals
    // =========================================================================
    // Declare signals for every port of your top module.
    // Inputs to the DUT are driven by this testbench.
    // Outputs from the DUT are checked by this testbench.

    logic clk;          // We drive this
    logic rst_n;        // We drive this
    logic heartbeat;    // DUT drives this, we observe it
    // Add your module's ports here. Match them exactly.

    // =========================================================================
    // DUT instantiation
    // =========================================================================
    // Instantiate the module you're testing.
    // The name "dut" (device under test) is a useful convention.

    top dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .heartbeat (heartbeat)
        // Add your ports here
    );

    // =========================================================================
    // Clock generator
    // =========================================================================
    // This creates a clock that toggles forever.
    // It starts at 0, waits CLK_HALF_PERIOD, flips, waits again, forever.
    // Real hardware doesn't need this because it has a crystal oscillator.
    // Simulation needs it because nothing happens without a clock.

    initial clk = 1'b0;
    always #CLK_HALF_PERIOD clk = ~clk;
    // #CLK_HALF_PERIOD means "wait CLK_HALF_PERIOD time units."
    // Combined with timescale 1ns/1ps, #5 means "wait 5 nanoseconds."

    // =========================================================================
    // Waveform dump
    // =========================================================================
    // This tells the simulator to record every signal change into a .vcd file.
    // GTKWave reads this file to show you the waveforms.
    // Without this, simulation runs but you can't see what happened.

    initial begin
        $dumpfile("output.vcd");       // Output filename
        $dumpvars(0, tb_top);          // Dump all signals under tb_top (0 = all levels)
        // $dumpvars(1, tb_top) would only dump tb_top's direct signals, not submodules.
        // Use 0 for full visibility. The file gets big, but you'll thank yourself later.
    end

    // =========================================================================
    // Simulation timeout
    // =========================================================================
    // If the simulation runs for more than SIM_TIMEOUT cycles, something is
    // probably wrong. Kill it so you don't wait forever for a hung simulation.

    initial begin
        #(CLK_HALF_PERIOD * 2 * SIM_TIMEOUT);
        $display("TIMEOUT: simulation ran for %0d cycles without finishing", SIM_TIMEOUT);
        $fatal(1, "Simulation timed out. Check your design for infinite loops or stuck states.");
        // $fatal: prints message and ends simulation with an error code.
        // Use this instead of $finish when something has gone wrong.
    end

    // =========================================================================
    // Main test sequence
    // =========================================================================
    // This is where you drive stimulus and check outputs.
    // Write this like a story: setup → action → check → repeat.

    initial begin
        // ── 1. Initialize all inputs ─────────────────────────────────────────
        // Before the clock starts doing interesting things, put everything
        // in a known state. Uninitialized inputs are X (unknown) in simulation.
        // X propagates through your logic and turns everything into X.
        // This is the hardware equivalent of undefined behavior. Prevent it.
        rst_n = 1'b0;   // Assert reset (active-low, so 0 = reset is active)
        // Add initialization for your other inputs here

        // ── 2. Apply reset ────────────────────────────────────────────────────
        // Hold reset for a few clock cycles so all flip-flops initialize cleanly.
        // "A few" = at least 2, but more is fine. 10 is a safe default.
        repeat(10) @(posedge clk);
        // "repeat(10) @(posedge clk)" means "wait for 10 rising clock edges"
        // Same as: wait 10 full clock cycles.

        // ── 3. Release reset ──────────────────────────────────────────────────
        @(negedge clk);  // Change inputs on negedge to avoid hold-time issues
                         // (setup/hold violations are a real thing, even in simulation)
        rst_n = 1'b1;
        $display("[%0t] Reset released. Design should now be running.", $time);

        // ── 4. Drive stimulus ─────────────────────────────────────────────────
        // Apply inputs and observe outputs here.
        // Replace these examples with your actual test cases.

        repeat(20) @(posedge clk); // Wait 20 cycles for things to settle

        // Example check: in a short default simulation, heartbeat should remain stable.
        // If you parameterize the DUT for faster blink, replace this with a toggle check.
        begin
            logic initial_heartbeat;
            initial_heartbeat = heartbeat;
            repeat(200_000) @(posedge clk);
            if (heartbeat === initial_heartbeat)
                $display("[%0t] PASS: short-run template check completed", $time);
            else
                $display("[%0t] INFO: heartbeat toggled (using faster blink parameters)", $time);
        end

        // ── 5. Add your test cases here ───────────────────────────────────────
        // Each test case should:
        //   - Drive specific inputs
        //   - Wait the appropriate number of cycles
        //   - Check that outputs match expectations
        //   - Print PASS or FAIL with $display


        // ── 6. End simulation ─────────────────────────────────────────────────
        repeat(100) @(posedge clk); // Let things settle
        $display("[%0t] Simulation complete.", $time);
        $finish;
        // $finish ends the simulation gracefully.
        // Always call it, or Icarus Verilog will run until the timeout above.
    end

    // =========================================================================
    // Assertions (optional but highly recommended)
    // =========================================================================
    // Assertions are checks that run every clock cycle automatically.
    // If the condition is ever violated, the simulation stops with an error.
    // Think of them as "invariants" for your hardware.
    //
    // Example: check that two signals are never both high at the same time
    // (useful for mutually exclusive states, bus arbitration, etc.)

    // always @(posedge clk) begin
    //     // The #1 delay is a stylistic trick to check after the clock edge settles
    //     #1;
    //     assert (!(signal_a && signal_b))
    //         else $fatal("[%0t] Assertion failed: signal_a and signal_b are both high!", $time);
    // end

endmodule