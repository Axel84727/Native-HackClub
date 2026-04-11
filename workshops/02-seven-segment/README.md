# Workshop 02 — 7-Segment Display

**Duration:** ~45 minutes  
**Concepts:** Combinational logic, lookup tables, case statements, MUX synthesis

---

## The goal

Drive a 7-segment display to show the digits 0–9, counting up once per second.
No libraries. No HAL. Just a truth table translated into gates.

---

## Background: what is combinational logic?

In workshop 01, you used **sequential logic** — flip-flops that remember state
across clock cycles. The output depended on *history*.

This workshop introduces **combinational logic** — circuits where the output
depends *only* on the current inputs. No memory. No clock.

A 7-segment decoder is a perfect example:
- Input: a 4-bit digit value (0–9, A–F)
- Output: a 7-bit pattern telling each segment whether to be on or off

Given input 3, the output is always the same pattern. Given input 7, always the same.
It doesn't matter what the previous input was. It doesn't matter what time it is.
It's a pure function. A truth table. A piece of wire logic.

On an FPGA, a `case` statement in `always_comb` synthesizes to a **MUX** —
a single hardware block where all 16 possible output patterns exist simultaneously
and the input just selects which one reaches the output.

Not 16 comparisons in sequence. One hardware selector. Instantaneous.

---

## Segment layout

```
 _
|_|
|_|

Segments:
  a = top horizontal bar
  b = top-right vertical bar
  c = bottom-right vertical bar
  d = bottom horizontal bar
  e = bottom-left vertical bar
  f = top-left vertical bar
  g = middle horizontal bar

Bit encoding: segments = {a, b, c, d, e, f, g}
Active-LOW on Basys3: 0 = segment ON, 1 = segment OFF
```

To display the digit **0**: turn on a, b, c, d, e, f — leave g off.
In active-low encoding: `7'b1000000` (g=1=off, everything else=0=on).

---

## Step 1: Build the decoder

Open `starter/seg7.v`. You'll find a module with the ports ready and a `case`
statement with empty bodies. Fill in the 7-bit pattern for each digit 0–9.

Use this reference table:

| Digit | a | b | c | d | e | f | g | Pattern (active-low) |
|---|---|---|---|---|---|---|---|---|
| 0 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | `7'b1000000` |
| 1 | ✗ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ | `7'b1111001` |
| 2 | ✓ | ✓ | ✗ | ✓ | ✓ | ✗ | ✓ | `7'b0100100` |
| 3 | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✓ | `7'b0110000` |
| 4 | ✗ | ✓ | ✓ | ✗ | ✗ | ✓ | ✓ | `7'b0011001` |
| 5 | ✓ | ✗ | ✓ | ✓ | ✗ | ✓ | ✓ | `7'b0010010` |
| 6 | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | `7'b0000010` |
| 7 | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ | `7'b1111000` |
| 8 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | `7'b0000000` |
| 9 | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ | `7'b0010000` |

**Always include a `default` case.** If you leave it out, the synthesizer may
infer a latch — a storage element you didn't ask for. Latches are sneaky bugs.
`default: segments = 7'b1111111;` (all off) is a perfectly safe default.

---

## Step 2: Add the counter

The decoder only translates a digit. Something needs to *generate* the digit
and change it every second.

Create `starter/counter_display.v` (new file). Your top-level module needs:
1. A clock divider (from workshop 01 — reuse that knowledge)
2. A 4-bit counter that increments on each 1 Hz tick
3. An instantiation of your `seg7` decoder

This is the first time you're **instantiating a submodule**.
Connect the counter output to the decoder input with named port connections.

---

## Step 3: Simulate

```bash
./tools/sim.sh workshops/02-seven-segment/starter
```

In GTKWave, add these signals:
- `digit_val` — should increment every 50 million cycles
- `segments` — should change pattern every time `digit_val` changes
- `clk_tick` — should be a narrow pulse every 50 million cycles

Zoom in on a transition. You should see `segments` update in the same cycle
that `digit_val` changes. That's combinational logic responding instantly.
No clock. No pipeline. Just immediate.

---

## Step 4: Questions

1. The `case` statement uses `always_comb`. What happens if you change it
   to `always_ff @(posedge clk)`? Simulate both. What's the difference?

2. Why does the Basys3 use active-LOW segment drives?
   (Hint: think about what happens at power-on before your FPGA is configured)

3. The Basys3 has 4 digits but we're only using one (`an = 4'b1110`).
   How would you show a 2-digit number? What additional logic would you need?
   (This is called "time-multiplexing" — look it up if curious)

4. How many LUTs (Look-Up Tables) does the synthesizer use for the `seg7` module?
   Run synthesis in Vivado and check the utilization report. Is it what you expected?

---

## Bonus challenge

Modify the counter to count in hexadecimal (0–F) instead of decimal (0–9).
The decoder already supports A–F — just change the wrap condition in the counter.

Then extend it to show a 2-digit hex counter (00–FF) using both digit positions.
You'll need to multiplex between the two digits — the display can only show one
at a time, but if you switch fast enough (>50 Hz), the human eye sees both.
This is called **persistence of vision** and it's a classic FPGA trick.

---

## Solution

`workshops/02-seven-segment/solution/seg7.v`