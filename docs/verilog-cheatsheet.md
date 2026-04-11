# Verilog / SystemVerilog Cheatsheet

The stuff you will look up every single time. Bookmark this.
We're using SystemVerilog style from workshop 3 onward — it's just better,
and your tools all support it. The old `reg`/`wire` stuff is here for reference
when you inevitably have to read someone else's code from 2003.

---

## Module declaration

```systemverilog
// A module is a hardware block. It has ports (inputs/outputs).
// Everything in Verilog/SV lives inside a module.
module my_module (
    input  logic        clk,      // Clock — the heartbeat of your design
    input  logic        rst_n,    // Reset, active-low (that's what _n means)
    input  logic [7:0]  data_in,  // 8-bit input bus
    output logic [7:0]  data_out  // 8-bit output bus
);

    // Your logic goes here

endmodule
```

---

## Data types

```systemverilog
// Modern SystemVerilog: just use `logic` for everything.
// It works for inputs, outputs, registers, and wires.
// There's no reason to use wire or reg anymore. Let them go.
logic        my_bit;       // Single bit
logic [7:0]  my_byte;      // 8-bit vector, [7] is the MSB
logic [15:0] my_word;      // 16-bit vector
logic signed [7:0] signed_byte; // Signed 8-bit (-128 to 127)

// Old-school Verilog (you'll see this in the wild — don't be scared):
wire  [7:0] old_wire;      // Combinational connection (old style)
reg   [7:0] old_reg;       // Register (old style — confusingly also used for combo logic)

// Parameters — like constants, but for hardware configuration
parameter  CLK_FREQ = 100_000_000;  // 100 MHz (underscores are legal and helpful)
localparam HALF_PERIOD = CLK_FREQ / 2; // localparam = module-private constant
```

---

## always blocks

```systemverilog
// ── Sequential logic (clocked flip-flops) ──────────────────────────────────
// always_ff: "This block describes flip-flops. Update on clock edges."
// Use this for anything that needs to remember state across clock cycles.
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 8'h00;    // Reset: clear everything (non-blocking assignment!)
    end else begin
        counter <= counter + 1; // Increment every clock cycle
    end
end

// ── Combinational logic ────────────────────────────────────────────────────
// always_comb: "This block describes pure logic. No memory, no clock."
// The simulator re-evaluates this whenever any input changes.
always_comb begin
    case (opcode)
        2'b00: result = a + b;
        2'b01: result = a - b;
        2'b10: result = a & b;
        default: result = 8'h00; // Always have a default! Latches are evil.
    endcase
end

// ── Latch (please don't) ───────────────────────────────────────────────────
// always_latch: exists, works, but you probably don't want a latch.
// If your synthesis tool warns "inferred latch," your always_comb is missing
// a default assignment. Fix it before it fixes you.
```

---

## Blocking vs non-blocking assignment

This is the #1 source of beginner bugs. Memorize this table.

```systemverilog
// Non-blocking (<=): use in always_ff (sequential logic)
// Updates happen AFTER the always block finishes evaluating.
// All right-hand sides are read with old values. Then all left-hand sides update.
always_ff @(posedge clk) begin
    a <= b;  // a gets the OLD value of b
    b <= a;  // b gets the OLD value of a
    // Result: a and b are swapped! This is correct behavior for flip-flops.
end

// Blocking (=): use in always_comb (combinational logic)
// Updates happen IMMEDIATELY, in order, like normal code.
always_comb begin
    temp = a + b;   // temp is updated NOW
    result = temp * 2; // uses the UPDATED temp — this is what you want in combo logic
end

// Rule of thumb:
//   always_ff → use <=  (non-blocking)
//   always_comb → use =  (blocking)
// Break this rule and your simulation will disagree with your synthesis. Fun times.
```

---

## Number literals

```systemverilog
// Format: <width>'<base><value>
4'b1010     // 4-bit binary: 1010
8'hFF       // 8-bit hex: 255
8'd42       // 8-bit decimal: 42
16'o777     // 16-bit octal (you'll basically never use this)
1'b0        // Single bit: 0
1'b1        // Single bit: 1

// Without a width prefix — be careful, these are 32-bit by default:
100         // 32-bit decimal 100
'h1A        // 32-bit hex — fine for parameters, risky in logic

// Special values:
8'hXX       // X = unknown (useful in testbenches to catch uninitialized signals)
8'hZZ       // Z = high impedance (tri-state — you'll know when you need this)
```

---

## Common constructs

```systemverilog
// ── if/else ────────────────────────────────────────────────────────────────
always_comb begin
    if (enable && !reset)
        out = in;
    else
        out = 8'h00; // Always assign in all branches! Prevent latches.
end

// ── case ───────────────────────────────────────────────────────────────────
always_comb begin
    case (state)        // Equivalent to a MUX or truth table in hardware
        2'd0: next = 2'd1;
        2'd1: next = 2'd2;
        2'd2: next = 2'd0;
        default: next = 2'd0; // ALWAYS have a default
    endcase
end

// ── Ternary (nice for simple muxes) ────────────────────────────────────────
assign out = (sel) ? input_a : input_b; // Hardware mux, one line

// ── Concatenation ──────────────────────────────────────────────────────────
logic [7:0] byte_val = {4'b1010, 4'b0101}; // Concatenate: result is 8'b10100101
logic [15:0] wide = {byte_a, byte_b};      // Stitch two bytes into a word

// ── Replication ────────────────────────────────────────────────────────────
logic [7:0] all_ones = {8{1'b1}};  // 8'b11111111 — replicate 1 eight times

// ── generate (for repeated structures) ────────────────────────────────────
// Use when you want to instantiate N copies of something
genvar i;
generate
    for (i = 0; i < 8; i++) begin : gen_bits
        // This creates 8 identical hardware blocks, all running in parallel.
        // Not a loop that runs 8 times. 8 things that exist simultaneously.
        my_submodule inst (.in(data[i]), .out(result[i]));
    end
endgenerate
```

---

## Module instantiation

```systemverilog
// Instantiating a submodule — connecting it to your top-level signals
// Use named port connections. Always. Positional connections are a trap.

my_module u_my_module (    // u_ prefix is a convention for "unit instance"
    .clk      (clk),       // .port_name(signal_name)
    .rst_n    (rst_n),
    .data_in  (data_bus),
    .data_out (result)
);

// If port name matches signal name, you can use .* (SystemVerilog shorthand)
// But only when you're feeling lazy AND confident. Usually just name them.
my_module u_my_module (.*); // connects all matching names automatically
```

---

## Common mistakes → fixes

| Mistake | Symptom | Fix |
|---|---|---|
| `=` in `always_ff` | Simulation differs from synthesis | Use `<=` in all `always_ff` blocks |
| Missing `default` in `case` | Synthesis warns "latch inferred" | Always add `default:` |
| Missing `else` branch in `always_comb` | Same latch warning | Always assign output in every branch |
| Driving the same signal from two `always` blocks | "Multiple drivers" error | Only one block drives each signal |
| `reg` vs `wire` confusion | Generally confusing | Switch to `logic` for everything |
| Forgetting `negedge rst_n` in sensitivity list | Reset never works | `always_ff @(posedge clk or negedge rst_n)` |
| Off-by-one in counter reset | Timing is one cycle off | Reset to 0, compare with `COUNT-1` |

---

## Useful system tasks (for simulation only)

```systemverilog
$display("Value of counter: %d", counter);  // Print to console (like printf)
$time                                        // Current simulation time
$finish;                                     // End the simulation
$stop;                                       // Pause simulation (in ModelSim)

// Waveform dump — put this in your testbench
initial begin
    $dumpfile("output.vcd");   // Output file name
    $dumpvars(0, tb_top);      // Dump all signals under tb_top (0 = all levels)
end

// Assert — simulation will error if condition is false
// (Only in simulation — synthesizer ignores these, they're your safety net)
assert (result == expected) else $fatal("Mismatch! result=%h expected=%h", result, expected);
```

---

*If you find a mistake in this cheatsheet, open a PR.
We're all learning here — including whoever wrote this.*