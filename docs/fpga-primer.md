# FPGA Primer

Or: "What even is this thing and why does it fix everything?"

---

## The problem with CPUs

A CPU is a masterpiece of sequential engineering. It fetches an instruction,
decodes it, executes it, writes the result, and repeats — billions of times per second.

The keyword there is *repeats*. One thing. Then the next thing. Then the next.

This is fine for most software. It's not fine when you need to:
- Sample a sensor at an exact moment, every 1 microsecond, with zero jitter
- Process 64 signals truly simultaneously, not in a loop
- React to a hardware event within 10 nanoseconds, not "soon after the OS wakes up"

The OS doesn't help you here. The OS *is* the problem. It schedules your code,
interrupts it, reschedules it, and calls it "real-time" with a straight face.
It is not real-time. 10 milliseconds of latency jitter is not real-time.

---

## What an FPGA actually is

FPGA stands for **Field-Programmable Gate Array**.

Ignore the name. Here's what it actually is:

A chip full of **configurable logic blocks** — tiny circuits that can be wired
together in any configuration you want, *after* the chip was manufactured.
You program the chip by describing how the wires connect.

Not instructions. **Wires.**

When your FPGA design "runs," nothing is executing. There's no instruction pointer
moving through your code. Instead, electrons are flowing through gates that you
configured to implement your logic. Everything happens in parallel, simultaneously,
constrained only by the speed of electrons through silicon.

```
CPU:  [step 1] → [step 2] → [step 3] → [step 4]
       (one at a time, very fast, still one at a time)

FPGA: [logic A] ←→ [logic B]
      [logic C] ←→ [logic D]
      [logic E] ←→ [logic F]
       (everything at once, every clock cycle, for real)
```

---

## What HDL is (and isn't)

You describe an FPGA design using a **Hardware Description Language** — Verilog or VHDL.

The critical thing beginners get wrong: **HDL is not a programming language**.

You are not writing instructions for a processor to follow.
You are *describing a circuit* — what connects to what, what logic each block implements,
what happens when a clock edge arrives.

```verilog
// This looks like an if statement. It is NOT an if statement.
// It describes a multiplexer — a hardware component that selects between two inputs.
// The "if" exists at all times, simultaneously, in hardware.
always_comb begin
    if (select)
        out = input_a;   // This wire is active when select = 1
    else
        out = input_b;   // This wire is active when select = 0
end
```

When you write `always_comb`, you're not saying "when this code runs, do this."
You're saying "here is a piece of combinational logic that always, continuously,
reflects this relationship between inputs and outputs."

It's a description of structure. Not a sequence of operations.

---

## The clock

Almost everything interesting in digital hardware is **synchronous** —
it's tied to a clock signal that oscillates at a fixed frequency.

On every **rising edge** of the clock (the moment it goes from 0 to 1),
all registered outputs update simultaneously. Every flip-flop in the design
captures its input and presents its new output — all in the same instant.

```
Clock:  ___│‾‾‾│___│‾‾‾│___│‾‾‾│___
                ↑       ↑       ↑
              update  update  update   ← all flip-flops update here, simultaneously
```

On a 100 MHz FPGA, this happens 100,000,000 times per second.
Every clock cycle, every register in your entire design updates at once.
Not one at a time. All of them. At the same time.

Your CPU is jealous.

---

## Synthesis and place-and-route

You write Verilog. You don't run Verilog. Here's what actually happens:

1. **Synthesis** — Your HDL is compiled into a "netlist" — a description of logic gates
   and how they connect. This is like compiling C to assembly, but the assembly
   is a list of AND gates, OR gates, and flip-flops.

2. **Place and Route** — The synthesis tool looks at your netlist and figures out
   which physical gates on the FPGA chip to use, and how to wire them together.
   This is like the CPU's instruction scheduler, but for physical silicon.

3. **Bitstream generation** — The placed-and-routed design is converted into a
   binary file (the "bitfile") that programs the FPGA. Load this onto the chip
   and your circuit comes to life.

For simulation (which is what you'll do most of), none of this happens.
Icarus Verilog just interprets your HDL and simulates the behavior. Fast, easy, free.

---

## Key concepts at a glance

| Concept | What it means | CPU equivalent |
|---|---|---|
| **Module** | A hardware block with inputs and outputs | Function / class |
| **Port** | An input or output of a module | Function parameter / return |
| **Wire** | A connection between logic blocks | A variable (but it exists in hardware) |
| **Register (flip-flop)** | Stores a value across clock cycles | A variable that persists |
| **Clock edge** | When synchronous logic updates | The CPU fetch cycle |
| **Combinational logic** | Output depends only on current inputs, no memory | Pure function |
| **Sequential logic** | Output depends on inputs AND history | Stateful function |

---

## What FPGAs are good at (and bad at)

**Good at:**
- Nanosecond-precision timing
- True parallel processing (all gates run simultaneously)
- Custom interfaces for any hardware protocol
- Signal processing at hardware speed
- Problems where "approximately now" isn't good enough

**Not great at:**
- Floating-point math (possible, but costly in resources)
- General-purpose computation (use a CPU for that)
- Quick prototyping (synthesis takes minutes, not milliseconds)
- Anything where an Arduino would do the job just fine

---

## One sentence to remember

> An FPGA is a chip where you define the circuit — not the program —
> and every part of that circuit runs at the same time, every clock cycle, forever.

Everything else in this curriculum is an elaboration of that sentence.

Now go blink an LED. It'll make more sense once you've done it.