# Workshop 01 — Blink an LED

**Duration:** ~45 minutes  
**Concepts:** Clock dividers, counters, synchronous logic, GTKWave basics

---

## The goal

Make an LED blink at exactly 1 Hz. No `sleep()`. No OS. No microcontroller magic.
Just logic gates, a counter, and a clock.

This is the "Hello, World!" of FPGA development.
It teaches you more about hardware than it appears to.

---

## Background: why is this non-trivial?

On a microcontroller you'd write:
```c
while (1) {
    led = 1;
    delay_ms(500);
    led = 0;
    delay_ms(500);
}
```

Simple! But `delay_ms` works by wasting CPU cycles — burning time by counting
in a loop or waiting for a hardware timer peripheral. The OS can interrupt it.
Other interrupts can delay it. The timing is "close enough."

On an FPGA, there's no CPU to waste cycles on. There's no OS to interrupt you.
There's only a clock that ticks at 100 MHz, and logic that responds to every tick.

To blink at 1 Hz, you build a **clock divider**: a counter that counts 50,000,000
cycles (half of 100 million), then toggles the LED, then counts 50,000,000 more,
then toggles again. One full cycle = 1 second. Exact. Every time.

No scheduler. No jitter. Just math and gates.

---

## Step 1: Understand the math

Your FPGA clock: **100,000,000 Hz** (100 MHz)  
Desired blink rate: **1 Hz** (one full on-off cycle per second)  
LED must toggle every: **0.5 seconds** = **50,000,000 clock cycles**

So you need a counter that counts from **0 to 49,999,999**, then resets and toggles the LED.

How many bits does this counter need?
- 2²⁵ = 33,554,432 — not enough
- 2²⁶ = 67,108,864 — enough!
- You need a **26-bit counter**

This is hardware math. You do it once, in your head, before writing a single line.

---

## Step 2: Open the starter file

```bash
# Look at the starter file — it has the structure but not the logic
cat workshops/01-blink-led/starter/blink.v
```

You'll see a module with the right ports and some `TODO` comments.
Your job is to fill in the logic.

---

## Step 3: Implement the clock divider

Open `workshops/01-blink-led/starter/blink.v` in your editor.

You need to:
1. Declare a 26-bit counter register
2. In an `always_ff` block: on every clock edge, increment the counter
3. When the counter reaches 49,999,999: reset it and toggle the LED
4. On reset (`!rst_n`): clear everything to zero

**Hints:**
- Use `always_ff @(posedge clk or negedge rst_n)` for your sequential block
- Use `<=` (non-blocking assignment) inside `always_ff`
- `~led_state` flips a single bit
- `26'd49_999_999` is how you write the literal value 49,999,999 in 26-bit Verilog

If you get stuck, the solution is in `solution/blink.v` — but try it yourself first.
Struggle is where learning happens.

---

## Step 4: Simulate it

```bash
./tools/sim.sh workshops/01-blink-led/starter
```

GTKWave will open. To see the waveform:
1. In the left panel (Signal Search Tree), find the `led` signal
2. Double-click `led` to add it to the wave panel
3. Press `Ctrl + Shift + F` to zoom to fit
4. You should see a square wave — high for a long time, then low, repeating

**The waveform is your proof.** Not a comment. Not a claim. A waveform.

---

## Step 5: Answer these questions

After you get it working, think through these:

1. **What if you change `BLINK_FREQ` to 2?** What does the counter target become?
   Try it in simulation. Does the waveform look right?

2. **What if your clock was 50 MHz instead of 100 MHz?**
   What would you change to still blink at 1 Hz?

3. **Why do we use `negedge rst_n` in the sensitivity list?**
   What happens if you change it to just `posedge clk`?

4. **The LED blinks at exactly 1 Hz every single time you power on.**
   Explain why. (Hint: what does reset do? What happens if you didn't have reset?)

---

## Bonus challenge

Modify the design to:
- Blink 4 LEDs at 4 different frequencies: 1 Hz, 2 Hz, 4 Hz, 8 Hz
- Each LED should be driven by its own counter
- All four counters run simultaneously, in the same hardware

Then look at the waveform and notice: all four LEDs are updating every clock cycle.
They don't take turns. They all just... work. At the same time.

That's parallelism. Your CPU can't do that.

---

## Solution

`workshops/01-blink-led/solution/blink.v` — look here only after you've tried.