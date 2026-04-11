`timescale 1ns / 1ps

module tb_blink;

    logic clk;
    logic rst_n;
    logic led;

    // Small parameters keep the demo simulation fast.
    blink #(
        .CLK_FREQ   (100),
        .BLINK_FREQ (1)
    ) dut (
        .clk   (clk),
        .rst_n (rst_n),
        .led   (led)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("output.vcd");
        $dumpvars(0, tb_blink);
    end

    initial begin
        rst_n = 1'b0;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;

        // Run long enough to show multiple LED transitions.
        repeat (400) @(posedge clk);

        $display("PASS: blink waveform generated. Inspect 'led' in output.vcd");
        $finish;
    end

endmodule

